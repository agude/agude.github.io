"""Keep the golden edge posts exercising every registered plugin tag."""

import re
from pathlib import Path

PLUGIN_ROOT = Path(__file__).resolve().parents[2] / "_plugins/src"
EDGE_POSTS = Path(__file__).resolve().parents[2] / "_bin/golden_edges/_posts"
TAG_REGISTRATION = re.compile(r"Liquid::Template\.register_tag\(\s*([^,\s]+)")
LITERAL_TAG = re.compile(r"['\"]([^'\"]+)['\"]\Z")
LIQUID_TAG = re.compile(r"{%\s*([A-Za-z_][A-Za-z0-9_]*)\b")


def _registered_plugin_tags() -> set[str]:
    tags = set()

    for source_path in PLUGIN_ROOT.rglob("*.rb"):
        source = source_path.read_text()
        for argument in TAG_REGISTRATION.findall(source):
            literal = LITERAL_TAG.fullmatch(argument)
            if literal:
                tags.add(literal.group(1))
            elif source_path.name == "display_book_lists_tag.rb" and argument == "name":
                list_definition = re.search(r"LISTS\s*=\s*\{(.*?)\n\s*\}\.freeze", source, re.S)
                assert list_definition, f"Could not read dynamic tag list in {source_path}"
                tags.update(
                    re.findall(r"['\"](display_[a-z0-9_]+)['\"]\s*=>", list_definition.group(1))
                )
            elif source_path.name == "backlink_builder.rb" and argument == "tag_name":
                link_tags = re.search(r"LINK_TAGS\s*=\s*%w\[(.*?)\]\.freeze", source, re.S)
                assert link_tags, f"Could not read dynamic link tags in {source_path}"
                tags.update(link_tags.group(1).split())
            else:
                raise AssertionError(
                    f"Unrecognized dynamic Liquid tag registration in {source_path}: {argument}"
                )

    return tags


def test_every_registered_liquid_tag_appears_in_golden_edge_posts():
    post_sources = sorted(EDGE_POSTS.glob("*.md"))
    assert post_sources, "Golden edge posts are missing"
    post_content = "\n".join(path.read_text() for path in post_sources)
    used_tags = set(LIQUID_TAG.findall(post_content))

    missing_tags = sorted(_registered_plugin_tags() - used_tags)
    assert not missing_tags, f"Golden edge posts do not exercise registered tags: {missing_tags}"
