#!/usr/bin/env python3
"""Check that the built site switches colors between light and dark schemes.

The color tokens in `_sass/_variables.scss` are `light-dark()` values, which
resolve against the `color-scheme` an element inherits. If `:root` loses
`color-scheme: light dark`, or a subtree sets `color-scheme: light`, those
elements stop switching while the source still parses and every contrast
ratio still passes. This check catches that in a browser.

Each probe names an element and a CSS property that a scheme-dependent token
styles. Every page in `_site/` that links the site stylesheet (redirect stubs
excluded) is loaded in headless Chromium once with
`prefers-color-scheme: light` and once with `dark`, and each probe reads the
first matching element. A probe fails when:

- its computed value is the same in both schemes;
- it is the page background and does not equal `white` (light) or
  `theme_color_dark` from `_config.yml` (dark).

A probe that matches no page also fails, so no probe goes unchecked.

Exit codes: 0 when every check passes, 1 when any fails, 2 on bad input or
when a page does not load with status 200.

Usage:
    uv run --group browser python ci/check_color_scheme.py ../_site
Example: ../_site
"""

from __future__ import annotations

import argparse
import asyncio
import re
import sys
from dataclasses import dataclass
from pathlib import Path

import yaml
from check_image_sizes import SITE_ORIGIN, route_handler

EXIT_CLEAN = 0
EXIT_FAILED = 1
EXIT_UNUSABLE = 2

CONFIG_YML = Path(__file__).resolve().parents[2] / "_config.yml"
STYLESHEET = "/assets/css/main.css"
REDIRECT = 'http-equiv="refresh"'
# Pages loaded at once in each scheme.
CONCURRENCY = 8
SKIPPED = re.compile(r"\.(?:avif|gif|jpe?g|png|svg|webp|woff2?|ttf|otf)(?:\?.*)?$")
SCHEMES = ("light", "dark")


@dataclass(frozen=True)
class Probe:
    """An element and the CSS property a scheme-dependent token styles.

    `target` and each `within` entry are a tag name or a `.class`; `within`
    lists ancestors from outermost to innermost, as a descendant selector.
    """

    name: str
    target: str
    prop: str
    within: tuple[str, ...] = ()

    @property
    def selector(self) -> str:
        return " ".join((*self.within, self.target))


PAGE_BACKGROUND = Probe("page background", "body", "background-color")

# Probes inside `main` stay clear of the sidebar, which is dark in both
# schemes by design.
PROBES = (
    PAGE_BACKGROUND,
    Probe("body text", "body", "color"),
    Probe("content link", "a", "color", ("main", "p")),
    Probe("heading", "h2", "color", ("main",)),
    Probe("strong", "strong", "color", ("main",)),
    Probe("blockquote text", "blockquote", "color", ("main",)),
    Probe("blockquote rule", "blockquote", "border-left-color", ("main",)),
    Probe("inline code text", "code", "color", ("main", "p")),
    Probe("inline code background", "code", "background-color", ("main", "p")),
    Probe("horizontal rule", "hr", "border-top-color", ("main",)),
    Probe("hover card", ".book-link-preview", "background-color", ("main",)),
    Probe("hover card author", ".book-link-preview-author", "color", ("main",)),
)


def site_pages(site: Path) -> list[str]:
    """Return the path of every page that uses the site stylesheet.

    Redirect stubs are skipped: they navigate away before they can be read.
    """
    paths = []
    for file in sorted(site.rglob("*.html")):
        text = file.read_text(encoding="utf-8", errors="replace")
        if STYLESHEET not in text or REDIRECT in text:
            continue
        path = "/" + file.relative_to(site).as_posix()
        paths.append(path.removesuffix("index.html"))
    return paths


@dataclass(frozen=True)
class Reading:
    """A probe's computed value on one page in each scheme."""

    page: str
    probe: Probe
    light: str
    dark: str


def failures(
    readings: list[Reading], background: dict[str, str], probes: tuple[Probe, ...] = PROBES
) -> list[str]:
    """Return every failed check.

    `background` maps each scheme to the expected page background, as the
    browser computes it.
    """
    read = {r.probe for r in readings}
    found = [f"`{p.name}` ({p.selector}) matched no page" for p in probes if p not in read]
    for r in readings:
        where = f"{r.page} `{r.probe.name}` ({r.probe.selector} {r.probe.prop})"
        if r.light == r.dark:
            found.append(f"{where}: {r.light} in both schemes")
        if r.probe == PAGE_BACKGROUND:
            for scheme, value in zip(SCHEMES, (r.light, r.dark), strict=True):
                if value != background[scheme]:
                    found.append(f"{where}: {value} in {scheme}, expected {background[scheme]}")
    return found


READ_JS = """
probes => probes.map(([selector, prop]) => {
  const el = document.querySelector(selector);
  return el ? getComputedStyle(el).getPropertyValue(prop) : null;
})
"""

# The browser's computed form of a CSS color, so expected values compare
# equal to computed ones without color math here.
NORMALIZE_JS = """
value => {
  const el = document.createElement('div');
  el.style.color = value;
  document.body.append(el);
  const computed = getComputedStyle(el).color;
  el.remove();
  return computed;
}
"""


async def read_site(
    site: Path, baseurl: str, site_url: str, pages: list[str], expected: dict[str, str]
) -> tuple[list[Reading], dict[str, str], list[str]]:
    """Read every probe on every page in each scheme.

    Returns the readings for probes found on a page, `expected` (scheme ->
    CSS color) normalized by the browser, and every page that did not load
    with status 200. Readings are empty when any page failed to load.
    """
    from playwright.async_api import async_playwright

    handler = route_handler(site, baseurl, (SITE_ORIGIN, site_url.rstrip("/")))
    query = [[p.selector, p.prop] for p in PROBES]
    values: dict[tuple[str, str], list[str | None]] = {}
    errors: list[str] = []
    normalized: dict[str, str] = {}
    limit = asyncio.Semaphore(CONCURRENCY)

    async with async_playwright() as p:
        browser = await p.chromium.launch()
        for scheme in SCHEMES:
            context = await browser.new_context(color_scheme=scheme)
            await context.route("**/*", handler)
            # Images and fonts carry no colors this check reads.
            await context.route(SKIPPED, lambda route: route.abort())

            async def read(path: str, context=context, scheme=scheme) -> None:
                async with limit:
                    page = await context.new_page()
                    try:
                        response = await page.goto(SITE_ORIGIN + baseurl + path)
                        if response is None or response.status != 200:
                            status = response.status if response else "no response"
                            errors.append(f"{path}: {status} in {scheme}")
                            return
                        values[path, scheme] = await page.evaluate(READ_JS, query)
                    finally:
                        await page.close()

            try:
                await asyncio.gather(*(read(path) for path in pages))
                page = await context.new_page()
                await page.goto(SITE_ORIGIN + baseurl + pages[0])
                normalized[scheme] = await page.evaluate(NORMALIZE_JS, expected[scheme])
            finally:
                await context.close()
        await browser.close()

    if errors:
        return [], normalized, sorted(errors)

    readings = []
    for path in pages:
        pairs = zip(PROBES, values[path, "light"], values[path, "dark"], strict=True)
        for probe, light, dark in pairs:
            if light is not None and dark is not None:
                readings.append(Reading(path, probe, light, dark))
    return readings, normalized, []


def report(readings: list[Reading]) -> str:
    """Return a table of each probe's page count and distinct values."""
    lines = ["| Probe | Pages | Light | Dark |", "|---|---|---|---|"]
    for probe in PROBES:
        rs = [r for r in readings if r.probe == probe]
        light = ", ".join(sorted({r.light for r in rs})) or "-"
        dark = ", ".join(sorted({r.dark for r in rs})) or "-"
        lines.append(f"| {probe.name} | {len(rs)} | {light} | {dark} |")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("site", type=Path, help="the built site directory (_site)")
    parser.add_argument("--baseurl", default="", help="the site's baseurl, if any")
    parser.add_argument(
        "--site-url",
        default="https://alexgude.com",
        help="the production URL that absolute URLs use",
    )
    args = parser.parse_args(argv)

    if not (args.site / "index.html").is_file():
        print(f"error: {args.site} is not a built site (no index.html)", file=sys.stderr)
        return EXIT_UNUSABLE

    config = yaml.safe_load(CONFIG_YML.read_text(encoding="utf-8"))
    expected = {"light": "white", "dark": config["theme_color_dark"]}

    pages = site_pages(args.site)
    if not pages:
        print(f"error: no page in {args.site} links {STYLESHEET}", file=sys.stderr)
        return EXIT_UNUSABLE
    readings, background, unloaded = asyncio.run(
        read_site(args.site, args.baseurl.rstrip("/"), args.site_url, pages, expected)
    )
    if unloaded:
        for error in unloaded:
            print(f"error: {error}", file=sys.stderr)
        return EXIT_UNUSABLE
    if not readings:
        print("error: read no probes", file=sys.stderr)
        return EXIT_UNUSABLE

    failed = failures(readings, background)
    print(report(readings))
    print(f"\n{len(pages)} pages, {len(readings)} readings, {len(failed)} failures")
    for failure in failed:
        print(f"FAIL {failure}")
    return EXIT_FAILED if failed else EXIT_CLEAN


if __name__ == "__main__":
    sys.exit(main())
