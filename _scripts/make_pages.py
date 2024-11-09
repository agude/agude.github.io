from typing import Dict, Union, TextIO
import glob
import os.path as path
import re
import yaml


MARKDOWN_EXTENSION = ".md"

AUTHOR_TEMPLATE = """---
layout: author_page
title: {item}
description: >
    Alex Gude's reviews of books written by {item}.
---
"""

SERIES_TEMPLATE = """---
layout: series_page
title: {item}
description: >
    Alex Gude's reviews of books written in the {item} series.
---
"""


def write_pages_to_dir(
    items: list, output_dir: str, template: str, markdown_extension: str = "md"
) -> None:
    """Writes content from a list of items to Markdown files in a directory.

    This function takes a list of items (`items`), an output directory path
    (`output_dir`), a template string (`template`) to use for formatting the
    content, and an optional markdown extension string (`markdown_extension`) as
    input.

    The function iterates through each item in the items list. For each item:

        1. It normalizes the item by converting it to lowercase and replacing
           characters not allowed in filenames with underscores. It also
           replaces consecutive underscores with a single underscore.
        2. It constructs a filename by combining the normalized item with the
           provided markdown extension (default: "md").
        3. It joins the output directory path with the filename to create a
           full path.
        4. It opens the file in write mode ("w").
        5. It formats the template string using the current item data and
           writes the formatted content to the opened file.

    Args:
        items: A list of items to write to separate Markdown files.

        output_dir: The directory path to write the generated Markdown files.

        template: A string template used to format the content for each file.
        The template should accept an "item" argument.

        markdown_extension: The file extension to use for the generated
        Markdown files (default: "md").

    Returns:
        None
    """
    for item in items:
        normalized_item = item.lower()
        # Replace characters that are not allowed in filenames with
        # underscores, and then replace multiple underscores with a single
        # underscore
        normalized_item = re.sub(r"[^\w\-_]+", "_", normalized_item)
        normalized_item = re.sub(r"_+", "_", normalized_item)

        file_name = f"{normalized_item}{markdown_extension}"
        full_path = path.join(output_dir, file_name)

        with open(full_path, "w") as write_file:
            contents = template.format(item=item)
            write_file.write(contents)


def extract_yaml_header_from_markdown(file_object: TextIO) -> Dict[str, Union[str, int, float, list, dict, None]]:
    """
    Extracts YAML frontmatter from a markdown file.

    Args:
        file_object: A file object (opened markdown file) to read from

    Returns:
        A dictionary containing the parsed YAML header data.
        Returns empty dict if no valid YAML header is found.

    Example:
        Given markdown content:
        ---
        title: My Post
        date: 2024-01-01
        tags: [python, markdown]
        ---
        # Content here

        Would return:
        {
            'title': 'My Post',
            'date': '2024-01-01',
            'tags': ['python', 'markdown']
        }
    """
    content = file_object.read()

    # Check if the file starts with YAML delimiter
    if not content.startswith('---\n'):
        return {}

    # Find the closing delimiter
    try:
        end_delimiter_index = content.index('\n---\n', 4)  # Start search after first delimiter
    except ValueError:
        return {}  # No closing delimiter found

    # Extract the YAML content between delimiters
    yaml_content = content[4:end_delimiter_index]

    try:
        # Parse YAML content into a dictionary
        header_dict = yaml.safe_load(yaml_content)
        return header_dict if isinstance(header_dict, dict) else {}
    except yaml.YAMLError:
        return {}  # Return empty dict if YAML parsing fails


# Define pattern to match markdown files in book directory
BOOK_FILE_GLOB = f"../_books/*{MARKDOWN_EXTENSION}"
markdown_files = glob.glob(BOOK_FILE_GLOB)

authors = []
series = []
for file in markdown_files:
    with open(file, "r") as opened_file:
        front_matter_yaml = extract_yaml_header_from_markdown(opened_file)

        author = front_matter_yaml.get("book_author")
        book_series = front_matter_yaml.get("series")

        if author:
            authors.append(author)
        if book_series:
            series.append(book_series)

# Write authors to separate Markdown files
authors = sorted(set(authors))
write_pages_to_dir(
    items=authors,
    output_dir="../books/authors/",
    template=AUTHOR_TEMPLATE,
    markdown_extension=MARKDOWN_EXTENSION,
)

# Similar process for series data
series = sorted(set(series))
write_pages_to_dir(
    items=series,
    output_dir="../books/series/",
    template=SERIES_TEMPLATE,
    markdown_extension=MARKDOWN_EXTENSION,
)
