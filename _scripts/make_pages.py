import glob
import re
import os.path as path


MARKDOWN_EXTENSION = ".md"

AUTHOR_TEMPLATE = """---
layout: author_page
author_name: {item}
description: >
    Alex Gude's reviews of books written by {item}.
---

Below you'll find short reviews of {item}'s books:"""

SERIES_TEMPLATE = """---
layout: series_page
series_name: {item}
description: >
    Alex Gude's reviews of books written in the {item} series.
---
"""


def append_value_by_key(items: list, key: str, line: str) -> list:
    """Appends a value from a line to a list based on a specified key.

    This function takes a list of strings (items), a key (key), and a line of
    text (line) as input.

    It checks if the line starts with the provided key (key:). If it does, it
    extracts the value after the colon (':'), removes any leading or trailing
    whitespace using strip(), and only appends the value to the items list if
    it's not "null".

    The function then returns the modified items list.

    Args:
        items: A list of strings to which values will be appended.
        key: The key to look for at the beginning of the line.
        line: The line of text to extract the value from.

    Returns:
        The list items potentially with the appended value.
    """
    if line.startswith(key):
        item = line.split(": ")[1].strip()
        if item != "null":
            items.append(item)

    return items


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


# Define pattern to match markdown files in book directory
BOOK_FILE_GLOB = f"../_books/*{MARKDOWN_EXTENSION}"
markdown_files = glob.glob(BOOK_FILE_GLOB)

authors = []
series = []
for file in markdown_files:
    with open(file, "r") as opened_file:
        for line in opened_file.readlines():
            authors = append_value_by_key(authors, "book_author: ", line)
            series = append_value_by_key(series, "series: ", line)

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
