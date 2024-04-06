import glob
import re
import os.path as path


MARKDOWN_EXTENSION = ".md"

AUTHOR_TEMPLATE = """---
layout: author_page
author_name: {author_name}
description: >
    Alex Gude's reviews of books written by {author_name}.
---

Below you'll find short reviews of {author_name}'s books:"""

# Read files in the book directory to get all authors
BOOK_FILE_GLOB = f"../_books/*{MARKDOWN_EXTENSION}"
markdown_files = glob.glob(BOOK_FILE_GLOB)

authors = []
for file in markdown_files:
    with open(file, "r") as opened_file:
        for line in opened_file.readlines():
            if line.startswith("book_author: "):
                author = line.split(": ")[1].strip()
                authors.append(author)

# Generate an author page for each distinct author
OUTPUT_DIRECTORY = "../books/authors/"
for author in sorted(set(authors)):
    normalized_author = author.lower()
    normalized_author = re.sub(r"[^\w]+", "_", normalized_author)
    file_name = f"{normalized_author}{MARKDOWN_EXTENSION}"
    full_path = path.join(OUTPUT_DIRECTORY, file_name)

    with open(full_path, "w") as write_file:
        contents = AUTHOR_TEMPLATE.format(author_name=author)
        write_file.write(contents)
