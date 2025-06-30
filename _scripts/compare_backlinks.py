#!/usr/bin/env python3
import sys
from pathlib import Path
from bs4 import BeautifulSoup


def get_canonical_backlinks(file_path: Path):
    """
    Parses an HTML file, finds the backlinks section, and returns a canonical
    representation of the links within it.

    Args:
        file_path: The Path object for the HTML file.

    Returns:
        - A sorted list of (text, href) tuples if the section is found.
        - None if the backlinks section is not present.
        - A string "FILE_NOT_FOUND" if the file doesn't exist.
    """
    if not file_path.is_file():
        return "FILE_NOT_FOUND"

    with open(file_path, "r", encoding="utf-8") as f:
        soup = BeautifulSoup(f, "html.parser")

    backlinks_aside = soup.find("aside", class_="book-backlinks")

    if not backlinks_aside:
        return None

    links = []
    # Find all list items and extract the text and href from the anchor tag within
    for li in backlinks_aside.find_all("li", class_="book-backlink-item"):
        a_tag = li.find("a")
        if a_tag and a_tag.has_attr("href"):
            # Normalize text by stripping and collapsing whitespace
            text = " ".join(a_tag.get_text(strip=True).split())
            href = a_tag["href"]
            links.append((text, href))

    # Sort the list to ensure comparison is order-independent
    return sorted(links)


def main():
    """
    Main function to find all book pages and compare their backlinks sections
    between an 'old' and 'new' directory.
    """
    base_dir = Path(".")
    old_dir = base_dir / "old"
    new_dir = base_dir / "new"

    if not old_dir.is_dir() or not new_dir.is_dir():
        print(
            f"Error: Both '{old_dir}' and '{new_dir}' directories must exist.",
            file=sys.stderr,
        )
        sys.exit(1)

    # Find all book review pages, excluding author and series list pages
    old_book_pages = [
        p
        for p in old_dir.glob("books/**/index.html")
        if p.parent.name not in ["authors", "series", "covers"]
    ]

    if not old_book_pages:
        print("Error: No book pages found in 'old/books/'.", file=sys.stderr)
        sys.exit(1)

    print(f"Comparing backlinks for {len(old_book_pages)} book pages...\n")

    differences_found = 0
    checked_files = 0

    for old_path in old_book_pages:
        # Construct the corresponding path in the 'new' directory
        relative_path = old_path.relative_to(old_dir)
        new_path = new_dir / relative_path
        checked_files += 1

        old_backlinks = get_canonical_backlinks(old_path)
        new_backlinks = get_canonical_backlinks(new_path)

        if old_backlinks != new_backlinks:
            differences_found += 1
            print(f"--- DIFFERENCE FOUND: {relative_path} ---")

            if new_backlinks == "FILE_NOT_FOUND":
                print("  - New file does not exist.")
            elif old_backlinks is None and new_backlinks is not None:
                print("  - Backlinks section ADDED in new file.")
                print(f"    New Links: {new_backlinks}")
            elif new_backlinks is None and old_backlinks is not None:
                print("  - Backlinks section REMOVED in new file.")
                print(f"    Old Links: {old_backlinks}")
            else:
                print("  - Backlink lists do not match.")
                print(f"    Old: {old_backlinks}")
                print(f"    New: {new_backlinks}")
            print("-" * (24 + len(str(relative_path))))
            print()

    print("\n--- Comparison Summary ---")
    print(f"Files checked: {checked_files}")
    print(f"Files with differences: {differences_found}")

    if differences_found == 0:
        print("\n✅ All backlink sections are identical.")
    else:
        print(f"\n❌ Found {differences_found} pages with backlink discrepancies.")
        sys.exit(1)  # Exit with an error code if differences were found


if __name__ == "__main__":
    main()
