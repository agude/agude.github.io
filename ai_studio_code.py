import os
import re
import sys
import yaml

# --- Configuration ---
# Directories to scan for files that might contain links.
DIRECTORIES_TO_SCAN = ['_books', '_posts']
# Directory where the anthology book files are located.
BOOKS_DIR = '_books'

def get_front_matter(file_path):
    """Extracts front matter from a Jekyll markdown file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        matches = re.findall(r'^---\s*\n(.*?)\n---\s*\n', content, re.DOTALL)
        if matches:
            # Return the raw content and the parsed YAML
            return content, yaml.safe_load(matches[0])
        return content, {}
    except Exception as e:
        print(f"  - Warning: Could not read or parse file {file_path}: {e}")
        return None, {}

def find_anthology_titles():
    """
    Pass 1: Scan all books to find titles of books marked as anthologies.
    Returns a set of anthology titles for fast lookups.
    """
    print("--- Pass 1: Finding all anthology titles ---")
    anthology_titles = set()

    if not os.path.isdir(BOOKS_DIR):
        print(f"Error: Directory '{BOOKS_DIR}' not found.")
        return set()

    for filename in sorted(os.listdir(BOOKS_DIR)):
        if filename.endswith('.md'):
            file_path = os.path.join(BOOKS_DIR, filename)
            _, fm = get_front_matter(file_path)
            
            if fm and fm.get('is_anthology') is True:
                title = fm.get('title')
                if title:
                    anthology_titles.add(title.strip())
    
    print(f"Found {len(anthology_titles)} anthology titles.\n")
    return anthology_titles

def search_files_for_links(anthology_titles):
    """
    Pass 2: Search all content files for book_link tags that link to a known anthology.
    """
    print("--- Pass 2: Searching for {% book_link %} tags to anthologies ---")
    
    # Regex to find a book_link tag and capture the title inside either single or double quotes.
    book_link_pattern = re.compile(r"\{%\s*book_link\s+(['\"])(.+?)\1")
    
    found_count = 0
    
    for directory in DIRECTORIES_TO_SCAN:
        if not os.path.isdir(directory):
            continue
        for root, _, files in os.walk(directory):
            for filename in sorted(files):
                if filename.endswith('.md'):
                    file_path = os.path.join(root, filename)
                    
                    try:
                        with open(file_path, 'r', encoding='utf-8') as f:
                            lines = f.readlines()
                    except Exception as e:
                        print(f"Could not read {file_path}: {e}")
                        continue

                    file_had_match = False
                    for i, line in enumerate(lines):
                        for match in book_link_pattern.finditer(line):
                            linked_title = match.group(2).strip()
                            
                            if linked_title in anthology_titles:
                                if not file_had_match:
                                    print(f"\n[ File: {file_path} ]")
                                    file_had_match = True
                                
                                print(f"  - L{i+1}: {line.strip()}")
                                found_count += 1
    
    if found_count == 0:
        print("No direct links to anthologies using {% book_link %} were found.")

def main():
    """Main function to run the script."""
    anthology_titles = find_anthology_titles()
    
    if not anthology_titles:
        print("No anthologies found. Ensure `is_anthology: true` is set in your book files.")
        sys.exit(1)
        
    search_files_for_links(anthology_titles)
    
    print("\n--- Script finished. ---")
    print("Review the list above. Each item may need to be changed to a more specific {% short_story_link %} tag.")

if __name__ == "__main__":
    main()