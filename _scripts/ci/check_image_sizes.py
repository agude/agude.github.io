#!/usr/bin/env python3
"""Measure every image slot in the built site and check its responsive sizes.

Loads sample pages from `_site/` in headless Chromium at each CSS breakpoint
and at 1x, 2x, and 3x pixel density, and records three widths per image:

- slot: the CSS pixels the layout gives the image;
- declared: the width its `sizes` attribute claims (eager images only;
  `sizes="auto, ..."` uses the slot width);
- delivered: the width of the file the browser chose (`currentSrc`).

A slot is the CSS context an image sits in, named by the image's id or
class, or by its nearest ancestor with a class (`.card-book-cover img`).
Every image in a slot is sized by the same CSS rule, so each slot is
sampled on a few pages rather than every page.

Images with `srcset` fail the check when:

- `sizes` understates the slot (the browser may pick a blurry copy) or
  overstates it by more than SIZES_SLACK (it may pick a needlessly large one);
- the delivered file is narrower than the slot at min(DPR, 2) and the
  source is wider (a wider candidate exists or could be generated);
- the delivered file is more than WASTE_FACTOR times the slot at the DPR.

- a `srcset` width descriptor differs from the width of the file it names.

Delivered widths are read by decoding the file, never from the descriptor.

Hover previews (book-link and footnote cards) are hidden until hovered, so
they are revealed before measuring. A slot found in the HTML but never
visible at any viewport fails the check, so no slot goes unmeasured.

Images without `srcset` and SVGs are reported, never failed. The report
lists each slot's width range and the widths a `srcset` for it would need.

Exit codes: 0 when every check passes, 1 when any fails, 2 on bad input.

Usage:
    uv run --group browser python ci/check_image_sizes.py ../_site
Example: ../_site
"""

from __future__ import annotations

import argparse
import asyncio
import math
import re
import sys
from collections import defaultdict
from dataclasses import dataclass
from html.parser import HTMLParser
from pathlib import Path

EXIT_CLEAN = 0
EXIT_FAILED = 1
EXIT_UNUSABLE = 2

# Breakpoints are read from this file; each is tested one pixel below and at
# its width, so every layout the stylesheet defines is measured.
VARIABLES_SCSS = Path(__file__).resolve().parents[2] / "_sass" / "_variables.scss"
BREAKPOINT = re.compile(r"^\$[\w-]*breakpoint:\s*([\d.]+)em;", re.MULTILINE)
# Common phone, desktop, and wide screens, added to the breakpoint widths.
EXTRA_WIDTHS = (320, 390, 1280, 1920)
VIEWPORT_HEIGHT = 900
DPRS = (1, 2, 3)
# Above 2x the eye gains little for the bytes, so 3x screens need only 2x.
MAX_USEFUL_DPR = 2
PAGES_PER_SLOT = 2
IMAGES_PER_SLOT = 3

TOLERANCE = 0.05
SIZES_SLACK = 1.1
WASTE_FACTOR = 2.0

SITE_ORIGIN = "https://site.test"
# Shows the hover previews, as a hover would, so their images get a layout
# width and load. Wide screens anchor previews with `position: fixed`, which
# no scroll reaches without a hovered anchor; `absolute` keeps them in the
# document. The cover's width (5em) does not depend on the position.
REVEAL_CSS = (
    ".book-link-preview, .footnote-preview "
    "{ display: flow-root !important; position: absolute !important; }"
)
VOID_ELEMENTS = frozenset(
    [
        "area",
        "base",
        "br",
        "col",
        "embed",
        "hr",
        "img",
        "input",
        "link",
        "meta",
        "source",
        "track",
        "wbr",
    ]
)


@dataclass(frozen=True)
class Measurement:
    """One image on one page at one viewport width and pixel density."""

    page: str
    viewport: int
    dpr: int
    slot: str
    src: str
    slot_width: float
    declared: float | None
    has_srcset: bool
    vector: bool
    delivered: int
    widest_available: int
    # "<url> is <N>w, srcset says <M>w" for each descriptor that is wrong.
    mismatches: tuple[str, ...] = ()


def problems(m: Measurement) -> list[str]:
    """Return why this measurement fails the check; empty when it passes."""
    if not m.has_srcset or m.vector or m.slot_width <= 0:
        return []

    found = [f"srcset descriptor is wrong: {mismatch}" for mismatch in m.mismatches]
    if m.declared is not None:
        if m.declared < m.slot_width * (1 - TOLERANCE):
            found.append(
                f"sizes declares {m.declared:.0f}px for a {m.slot_width:.0f}px slot (understated)"
            )
        elif m.declared > m.slot_width * SIZES_SLACK:
            found.append(
                f"sizes declares {m.declared:.0f}px for a {m.slot_width:.0f}px slot (overstated)"
            )

    need = m.slot_width * min(m.dpr, MAX_USEFUL_DPR)
    if m.delivered < need * (1 - TOLERANCE) and m.widest_available > m.delivered:
        found.append(
            f"delivered {m.delivered}w for a {need:.0f}px need; "
            f"the source is {m.widest_available}w, so a wider candidate is possible"
        )
    if m.delivered > m.slot_width * m.dpr * WASTE_FACTOR:
        found.append(
            f"delivered {m.delivered}w for a {m.slot_width * m.dpr:.0f}px slot "
            f"at {m.dpr}x (over {WASTE_FACTOR:g}x)"
        )
    return found


def viewport_widths(scss: str) -> list[int]:
    """Return the widths to test: one below and at each breakpoint, plus extras."""
    widths = set(EXTRA_WIDTHS)
    for em in BREAKPOINT.findall(scss):
        px = round(float(em) * 16)
        widths.update((px - 1, px))
    return sorted(widths)


class _SlotScanner(HTMLParser):
    """Collect the slot key of every <img> in a page."""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.stack: list[list[str]] = []
        self.slots: set[str] = set()

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = dict(attrs)
        classes = (values.get("class") or "").split()
        if tag == "img":
            self.slots.add(slot_key(values.get("id"), classes, reversed(self.stack)))
        elif tag not in VOID_ELEMENTS:
            self.stack.append(classes)

    def handle_endtag(self, tag: str) -> None:
        if tag not in VOID_ELEMENTS and self.stack:
            self.stack.pop()


def slot_key(img_id, img_classes, ancestor_classes) -> str:
    """Name an image's slot; must match SLOT_KEY_JS."""
    if img_id:
        return f"#{img_id}"
    if img_classes:
        return "img." + ".".join(img_classes)
    for depth, classes in enumerate(ancestor_classes):
        if depth >= 4:
            break
        if classes:
            return "." + ".".join(classes) + " img"
    return "img"


def sample_pages(site: Path, per_slot: int = PAGES_PER_SLOT) -> dict[str, list[str]]:
    """Return slot key -> up to `per_slot` page paths that contain it."""
    pages: dict[str, list[str]] = defaultdict(list)
    for file in sorted(site.rglob("index.html")):
        text = file.read_text(encoding="utf-8", errors="replace")
        if "<img" not in text:
            continue
        scanner = _SlotScanner()
        scanner.feed(text)
        path = "/" + str(file.parent.relative_to(site)).removeprefix(".") + "/"
        path = path.replace("//", "/")
        for slot in scanner.slots:
            if len(pages[slot]) < per_slot:
                pages[slot].append(path)
    return dict(pages)


SLOT_KEY_JS = """
img => {
  if (img.id) return '#' + img.id;
  if (img.classList.length) return 'img.' + [...img.classList].join('.');
  let e = img.parentElement;
  for (let i = 0; i < 4 && e; i++, e = e.parentElement) {
    if (e.classList.length) return '.' + [...e.classList].join('.') + ' img';
  }
  return 'img';
}
"""

# Returns one measurement per image, resolving `sizes` the way the browser
# does: the first entry whose media condition matches, its length measured
# on a probe element. `auto` on a lazy image means the slot width.
MEASURE_JS = (
    """
(img) => {
  const slotKey = """
    + SLOT_KEY_JS
    + """;
  const splitTop = s => {
    const out = []; let depth = 0, start = 0;
    for (let i = 0; i < s.length; i++) {
      if (s[i] === '(') depth++;
      else if (s[i] === ')') depth--;
      else if (s[i] === ',' && depth === 0) { out.push(s.slice(start, i)); start = i + 1; }
    }
    out.push(s.slice(start));
    return out.map(x => x.trim()).filter(Boolean);
  };
  const lengthPx = len => {
    const probe = document.createElement('div');
    probe.style.cssText = 'position:absolute;visibility:hidden;width:' + len;
    document.body.appendChild(probe);
    const px = probe.getBoundingClientRect().width;
    probe.remove();
    return px;
  };
  const declared = () => {
    const sizes = img.getAttribute('sizes');
    if (!sizes) return null;
    const entries = splitTop(sizes);
    if (entries[0] === 'auto' && img.loading === 'lazy') return null;
    for (const entry of entries) {
      if (entry === 'auto') continue;
      const m = entry.match(/^(.*\\))\\s*(\\S+)$/);
      if (!m) return lengthPx(entry);
      if (matchMedia(m[1]).matches) return lengthPx(m[2]);
    }
    return null;
  };
  const candidates = (img.getAttribute('srcset') || '').split(',').map(c => c.trim().split(/\\s+/))
    .filter(c => c.length === 2 && c[1].endsWith('w'))
    .map(([url, w]) => [new URL(url, location.href).href, parseInt(w, 10)]);
  return {
    slot: slotKey(img),
    src: img.getAttribute('src'),
    slot_width: img.getBoundingClientRect().width,
    declared: declared(),
    has_srcset: candidates.length > 0,
    vector: /\\.svg([?#]|$)/i.test(img.currentSrc),
    candidates,
    current_src: img.currentSrc,
    // The injector sets `width` to the source file's width.
    source_width: parseInt(img.getAttribute('width'), 10) || 0,
  };
}
"""
)


# Decodes a file and returns its displayed width (EXIF orientation applied,
# as for an <img>).
FILE_WIDTH_JS = """
async url => {
  const response = await fetch(url);
  if (!response.ok) throw new Error(url + ' returned ' + response.status);
  const bitmap = await createImageBitmap(await response.blob());
  const width = bitmap.width;
  bitmap.close();
  return width;
}
"""


async def file_width(page, url: str, cache: dict[str, int]) -> int:
    """Return the decoded width of the file at `url`, decoding each URL once."""
    if url not in cache:
        cache[url] = await page.evaluate(FILE_WIDTH_JS, url)
    return cache[url]


async def to_measurement(browser_page, data: dict, cache: dict[str, int], **where) -> Measurement:
    """Turn MEASURE_JS output into a Measurement, decoding the files it names."""
    candidates = data.pop("candidates")
    current_src = data.pop("current_src")
    source_width = data.pop("source_width")
    if data["vector"]:
        return Measurement(**where, **data, delivered=0, widest_available=0)

    widths = {url: await file_width(browser_page, url, cache) for url, _ in candidates}
    mismatches = tuple(
        f"{url} is {widths[url]}w, srcset says {declared}w"
        for url, declared in candidates
        if widths[url] != declared
    )
    return Measurement(
        **where,
        **data,
        delivered=await file_width(browser_page, current_src, cache),
        widest_available=max([source_width, *widths.values()]),
        mismatches=mismatches,
    )


async def measure_page(context, page_path: str, slots: set[str], viewport: int, dpr: int, cache):
    """Measure the first IMAGES_PER_SLOT images of each wanted slot on a page."""
    # Imported here so the browser-free functions load without Playwright.
    from playwright.async_api import TimeoutError as PlaywrightTimeout

    page = await context.new_page()
    try:
        await page.goto(SITE_ORIGIN + page_path, wait_until="load")
        await page.add_style_tag(content=REVEAL_CSS)
        taken: dict[str, int] = defaultdict(int)
        results = []
        for handle in await page.query_selector_all("img"):
            slot = await handle.evaluate(SLOT_KEY_JS)
            if slot not in slots or taken[slot] >= IMAGES_PER_SLOT:
                continue
            if not await handle.evaluate("img => img.getBoundingClientRect().width > 0"):
                continue
            taken[slot] += 1
            await handle.scroll_into_view_if_needed()
            try:
                await page.wait_for_function(
                    "img => img.complete && img.currentSrc !== ''", arg=handle, timeout=10_000
                )
            except PlaywrightTimeout as error:
                src = await handle.get_attribute("src")
                raise RuntimeError(
                    f"{page_path} @ {viewport}px {dpr}x: `{slot}` {src} never loaded"
                ) from error
            data = await handle.evaluate(MEASURE_JS)
            results.append(
                await to_measurement(page, data, cache, page=page_path, viewport=viewport, dpr=dpr)
            )
        return results
    finally:
        await page.close()


def route_handler(site: Path, baseurl: str, origins: tuple[str, ...]):
    """Serve `_site/` for requests to `origins`; every other request gets 404.

    The production origin is served too, because absolute `src` values name
    it; no request leaves the machine.
    """
    root = site.resolve()

    async def handle(route):
        url = route.request.url
        origin = next((o for o in origins if url.startswith(o + "/")), None)
        if origin is None:
            await route.fulfill(status=404, body="")
            return
        path = url[len(origin) :].split("?")[0].split("#")[0].removeprefix(baseurl)
        file = (root / path.lstrip("/")).resolve()
        if file.is_dir():
            file = file / "index.html"
        if file.is_file() and file.is_relative_to(root):
            await route.fulfill(path=str(file))
        else:
            await route.fulfill(status=404, body="")

    return handle


async def measure_site(
    site: Path, baseurl: str, site_url: str, sampled: dict[str, list[str]]
) -> list[Measurement]:
    """Measure the sampled pages at every viewport width and pixel density."""
    from playwright.async_api import async_playwright

    by_page: dict[str, set[str]] = defaultdict(set)
    for slot, paths in sampled.items():
        for path in paths:
            by_page[path].add(slot)

    handler = route_handler(site, baseurl, (SITE_ORIGIN, site_url.rstrip("/")))
    widths = viewport_widths(VARIABLES_SCSS.read_text())
    results: list[Measurement] = []
    file_widths: dict[str, int] = {}
    limit = asyncio.Semaphore(4)

    async with async_playwright() as p:
        browser = await p.chromium.launch()

        async def run(viewport: int, dpr: int) -> None:
            async with limit:
                context = await browser.new_context(
                    viewport={"width": viewport, "height": VIEWPORT_HEIGHT},
                    device_scale_factor=dpr,
                )
                await context.route("**/*", handler)
                try:
                    for path, slots in sorted(by_page.items()):
                        results.extend(
                            await measure_page(
                                context, baseurl + path, slots, viewport, dpr, file_widths
                            )
                        )
                finally:
                    await context.close()

        await asyncio.gather(*(run(w, d) for w in widths for d in DPRS))
        await browser.close()
    return results


def report(measurements: list[Measurement], sampled: dict[str, list[str]]) -> tuple[str, list[str]]:
    """Return a per-slot summary table and the list of failures.

    Every slot in `sampled` must have been measured at least once.
    """
    by_slot: dict[str, list[Measurement]] = defaultdict(list)
    for m in measurements:
        by_slot[m.slot].append(m)

    lines = [
        "| Slot | srcset | Slot width (CSS px) | 1x / 2x need | Delivered widths |",
        "|---|---|---|---|---|",
    ]
    for slot, ms in sorted(by_slot.items()):
        widths = [m.slot_width for m in ms]
        widest = max(widths)
        if any(m.vector for m in ms):
            need = "vector"
        else:
            need = f"{math.ceil(widest)} / {math.ceil(widest * MAX_USEFUL_DPR)}"
        delivered = sorted({m.delivered for m in ms if not m.vector})
        shown = ", ".join(map(str, delivered[:6])) + (" ..." if len(delivered) > 6 else "")
        lines.append(
            f"| `{slot}` | {'yes' if any(m.has_srcset for m in ms) else 'no'} "
            f"| {min(widths):.0f}-{widest:.0f} | {need} | {shown or '-'} |"
        )

    failures = [
        f"`{slot}` on {', '.join(pages)} was never visible, so it was not measured"
        for slot, pages in sampled.items()
        if slot not in by_slot
    ]
    for m in measurements:
        for problem in problems(m):
            failures.append(f"{m.page} @ {m.viewport}px {m.dpr}x `{m.slot}` {m.src}: {problem}")
    return "\n".join(lines), sorted(set(failures))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("site", type=Path, help="the built site directory (_site)")
    parser.add_argument("--baseurl", default="", help="the site's baseurl, if any")
    parser.add_argument(
        "--site-url",
        default="https://alexgude.com",
        help="the production URL that absolute src values use",
    )
    args = parser.parse_args(argv)

    if not (args.site / "index.html").is_file():
        print(f"error: {args.site} is not a built site (no index.html)", file=sys.stderr)
        return EXIT_UNUSABLE

    sampled = sample_pages(args.site)
    measurements = asyncio.run(
        measure_site(args.site, args.baseurl.rstrip("/"), args.site_url, sampled)
    )
    if not measurements:
        print("error: measured no images", file=sys.stderr)
        return EXIT_UNUSABLE

    table, failures = report(measurements, sampled)
    print(table)
    print(f"\n{len(measurements)} measurements, {len(failures)} failures")
    for failure in failures:
        print(f"FAIL {failure}")
    return EXIT_FAILED if failures else EXIT_CLEAN


if __name__ == "__main__":
    sys.exit(main())
