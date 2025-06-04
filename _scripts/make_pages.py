from typing import Dict, Union, TextIO, List, Tuple
import glob
import os
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
same_as_urls:
---""",
    "series": """---
layout: series_page
title: {item}
description: >
    Alex Gude's reviews of books written in the {item} series.
---""",
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
    # Replace non-alphanumeric (excluding hyphen and underscore) with underscore
    normalized = re.sub(r"[^\w\-_]+", "_", normalized)
    # Replace multiple underscores with a single underscore
    normalized = re.sub(r"_+", "_", normalized)
    # Remove leading/trailing underscores that might result
    normalized = normalized.strip("_")
    return normalized


def write_pages_to_dir(
    items: List[str], output_dir: str, template: str, markdown_extension: str = ".md"
) -> None:
    """
    Write content from a list of items to Markdown files in a directory.
    Skips writing if a file with the normalized name already exists.

    Args:
        items: List of items to write to separate Markdown files
        output_dir: Directory path for output files
        template: Template string for formatting content
        markdown_extension: File extension to use (default: ".md")
    """
    os.makedirs(output_dir, exist_ok=True)  # Ensure output directory exists
    for item in items:
        if not item or not item.strip():  # Skip empty or whitespace-only items
            print(f"Skipping empty item for page generation in {output_dir}.")
            continue

        filename = f"{normalize_filename(item)}{markdown_extension}"
        full_path = path.join(output_dir, filename)

        if path.exists(full_path):
            print(f"Skipping '{full_path}': File already exists.")
        else:
            try:
                with open(full_path, "w", encoding="utf-8") as write_file:
                    write_file.write(template.format(item=item))
                print(f"Created '{full_path}'")
            except Exception as e:
                print(f"Error writing file '{full_path}': {e}")


def extract_yaml_header_from_markdown(
    file_object: TextIO,
) -> Dict[str, Union[str, int, float, list, dict, None]]:
    """Extract YAML frontmatter from a markdown file."""
    content = file_object.read()

    if not content.startswith("---\n"):
        return {}

    try:
        # Corrected regex to find the end delimiter more robustly
        match = re.search(r"\n---\n", content[4:])
        if not match:
            return {}  # No end delimiter found after the first one

        end_delimiter_index = match.start() + 4  # Get the start of the '---'
        yaml_content = content[4:end_delimiter_index]
        header_dict = yaml.safe_load(yaml_content)
        return header_dict if isinstance(header_dict, dict) else {}
    except (ValueError, yaml.YAMLError) as e:
        print(f"Error parsing YAML from a file: {e}")
        return {}


def extract_metadata_from_files(files: List[str]) -> Tuple[List[str], List[str]]:
    """
    Extract author and series information from markdown files.

    Args:
        files: List of markdown file paths

    Returns:
        Tuple of (authors list, series list)
    """
    authors_set = set()
    series_set = set()

    for file_path in files:
        try:
            with open(file_path, "r", encoding="utf-8") as opened_file:
                front_matter = extract_yaml_header_from_markdown(opened_file)

                # Process book_authors (can be string or list)
                authors_fm_value = front_matter.get("book_authors")
                if isinstance(authors_fm_value, str):
                    cleaned_author = authors_fm_value.strip()
                    if cleaned_author:
                        authors_set.add(cleaned_author)
                elif isinstance(authors_fm_value, list):
                    for author_item in authors_fm_value:
                        if isinstance(author_item, str):
                            cleaned_author = author_item.strip()
                            if cleaned_author:
                                authors_set.add(cleaned_author)

                # Process series (typically a single string)
                book_series_fm_value = front_matter.get("series")
                if isinstance(book_series_fm_value, str):
                    cleaned_series = book_series_fm_value.strip()
                    # Handle 'null' or empty strings explicitly for series if needed,
                    # though an empty string after strip won't be added.
                    # 'null' as a string would be added unless filtered.
                    if cleaned_series and cleaned_series.lower() != "null":
                        series_set.add(cleaned_series)
        except Exception as e:
            print(f"Error processing file '{file_path}': {e}")

    return sorted(list(authors_set)), sorted(list(series_set))


def main():
    """Main execution function."""
    # Adjust glob path if script is not in a direct subdirectory of project root
    script_dir = path.dirname(path.abspath(__file__))
    project_root = path.abspath(
        path.join(script_dir, "..")
    )  # Assumes script is in a child dir of root

    book_file_glob_path = path.join(project_root, "_books", f"*{MARKDOWN_EXTENSION}")
    authors_output_dir = path.join(project_root, "books", "authors")
    series_output_dir = path.join(project_root, "books", "series")

    markdown_files = glob.glob(book_file_glob_path)
    if not markdown_files:
        print(f"No book files found at: {book_file_glob_path}")
        return

    authors, series = extract_metadata_from_files(markdown_files)

    print(f"\nFound {len(authors)} unique authors.")
    print(f"Found {len(series)} unique series titles.\n")

    # Write author pages
    if authors:
        print("Writing author pages...")
        write_pages_to_dir(
            items=authors,
            output_dir=authors_output_dir,
            template=TEMPLATES["author"],
            markdown_extension=MARKDOWN_EXTENSION,
        )
    else:
        print("No authors found to write pages for.")

    # Write series pages
    if series:
        print("\nWriting series pages...")
        write_pages_to_dir(
            items=series,
            output_dir=series_output_dir,
            template=TEMPLATES["series"],
            markdown_extension=MARKDOWN_EXTENSION,
        )
    else:
        print("No series found to write pages for.")

    print("\nScript finished.")


if __name__ == "__main__":
    main()
