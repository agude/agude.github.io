from typing import Dict, Union, TextIO, List, Tuple
import glob
import os.path as path
import re
import yaml


# Constants
MARKDOWN_EXTENSION = ".md"
BOOK_FILE_GLOB = f"../_books/*{MARKDOWN_EXTENSION}"

TEMPLATES = {
    "author": """---
layout: author_page
title: {item}
description: >
    Alex Gude's reviews of books written by {item}.
---
""",
    "series": """---
layout: series_page
title: {item}
description: >
    Alex Gude's reviews of books written in the {item} series.
---
""",
}


def normalize_filename(name: str) -> str:
    """
    Normalize a string for use as a filename.

    Args:
        name: String to normalize

    Returns:
        Normalized string suitable for filenames
    """
    normalized = name.lower()
    normalized = re.sub(r"[^\w\-_]+", "_", normalized)
    return re.sub(r"_+", "_", normalized)


def write_pages_to_dir(
    items: List[str], output_dir: str, template: str, markdown_extension: str = ".md"
) -> None:
    """
    Write content from a list of items to Markdown files in a directory.

    Args:
        items: List of items to write to separate Markdown files
        output_dir: Directory path for output files
        template: Template string for formatting content
        markdown_extension: File extension to use (default: ".md")
    """
    for item in items:
        filename = f"{normalize_filename(item)}{markdown_extension}"
        full_path = path.join(output_dir, filename)

        with open(full_path, "w") as write_file:
            write_file.write(template.format(item=item))


def extract_yaml_header_from_markdown(
    file_object: TextIO,
) -> Dict[str, Union[str, int, float, list, dict, None]]:
    """Extract YAML frontmatter from a markdown file."""
    content = file_object.read()

    if not content.startswith("---\n"):
        return {}

    try:
        end_delimiter_index = content.index("\n---\n", 4)
        yaml_content = content[4:end_delimiter_index]
        header_dict = yaml.safe_load(yaml_content)
        return header_dict if isinstance(header_dict, dict) else {}
    except (ValueError, yaml.YAMLError):
        return {}


def extract_metadata_from_files(files: List[str]) -> Tuple[List[str], List[str]]:
    """
    Extract author and series information from markdown files.

    Args:
        files: List of markdown file paths

    Returns:
        Tuple of (authors list, series list)
    """
    authors = set()
    series = set()

    for file in files:
        with open(file, "r") as opened_file:
            front_matter = extract_yaml_header_from_markdown(opened_file)

            if author := front_matter.get("book_author"):
                authors.add(author)
            if book_series := front_matter.get("series"):
                series.add(book_series)

    return sorted(authors), sorted(series)


def main():
    """Main execution function."""
    markdown_files = glob.glob(BOOK_FILE_GLOB)
    authors, series = extract_metadata_from_files(markdown_files)

    # Write author pages
    write_pages_to_dir(
        items=authors,
        output_dir="../books/authors/",
        template=TEMPLATES["author"],
        markdown_extension=MARKDOWN_EXTENSION,
    )

    # Write series pages
    write_pages_to_dir(
        items=series,
        output_dir="../books/series/",
        template=TEMPLATES["series"],
        markdown_extension=MARKDOWN_EXTENSION,
    )


if __name__ == "__main__":
    main()
