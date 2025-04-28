import os
import re
import argparse

# --- Configuration ---
# Directory containing the files to process (e.g., your Jekyll project root)
# Use '.' for the current directory where the script is run.
TARGET_DIR = '.'
# File extensions to process
FILE_EXTENSIONS = ('.md', '.markdown', '.html')

# --- Regex Patterns and Replacements ---
# Order matters, especially for author links!
REPLACEMENTS = [
    # 1. Author Link (Possessive) - MUST run before non-possessive
    {
        'find': re.compile(r'\{%\s*include\s+author_link\.html\s+name\s*=\s*(.*?)\s+possessive\s*=\s*true\s*%\}'),
        'replace': r'{% author_link \1 possessive %}',
        'description': 'Author Link (Possessive)'
    },
    # 2. Author Link (Non-Possessive)
    {
        'find': re.compile(r'\{%\s*include\s+author_link\.html\s+name\s*=\s*(.*?)\s*%\}'),
        'replace': r'{% author_link \1 %}',
        'description': 'Author Link (Non-Possessive)'
    },
    # 3. Book Link
    {
        'find': re.compile(r'\{%\s*include\s+book_link\.html\s+title\s*=\s*(.*?)\s*%\}'),
        'replace': r'{% book_link \1 %}',
        'description': 'Book Link'
    },
    # 4. Series Link
    {
        'find': re.compile(r'\{%\s*include\s+series_link\.html\s+series\s*=\s*(.*?)\s*%\}'),
        'replace': r'{% series_link \1 %}',
        'description': 'Series Link'
    },
]

# --- Functions ---

def process_file(filepath, dry_run=False):
    """Reads a file, applies replacements, and writes back if changed."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f_in:
            original_content = f_in.read()
    except Exception as e:
        print(f"  Error reading {filepath}: {e}")
        return 0 # Indicate 0 changes

    modified_content = original_content
    file_changed = False
    change_count = 0

    for item in REPLACEMENTS:
        # Use re.sub() which replaces all occurrences in the string
        new_content, num_subs = item['find'].subn(item['replace'], modified_content)
        if num_subs > 0:
            print(f"  Applied '{item['description']}' replacement ({num_subs} times)")
            modified_content = new_content
            file_changed = True
            change_count += num_subs

    if file_changed and not dry_run:
        try:
            with open(filepath, 'w', encoding='utf-8') as f_out:
                f_out.write(modified_content)
            print(f"  -> Saved changes to {filepath}")
        except Exception as e:
            print(f"  Error writing {filepath}: {e}")
            return 0 # Indicate 0 changes despite attempt
    elif file_changed and dry_run:
        print(f"  -> Would save changes to {filepath} (Dry Run)")

    return change_count

# --- Main Execution ---

def main():
    parser = argparse.ArgumentParser(description="Replace Jekyll include tags with custom plugin tags.")
    parser.add_argument(
        "target_dir",
        nargs='?',
        default=TARGET_DIR,
        help=f"Directory to process (default: '{TARGET_DIR}')"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be changed without modifying files."
    )
    args = parser.parse_args()

    root_dir = args.target_dir
    dry_run = args.dry_run
    total_changes = 0

    print("="*50)
    print("Jekyll Include Tag Replacer")
    print("="*50)
    print(f"Processing directory: {os.path.abspath(root_dir)}")
    if dry_run:
        print("DRY RUN MODE: No files will be modified.")
    print("="*50)
    print("\nWARNING: MAKE SURE YOU HAVE A BACKUP OR YOUR FILES ARE UNDER VERSION CONTROL (GIT) BEFORE RUNNING WITHOUT --dry-run!\n")

    # Walk through the directory
    for dirpath, _, filenames in os.walk(root_dir):
        # Skip hidden directories like .git, _site, vendor etc.
        if os.path.basename(dirpath).startswith(('.', '_')) and os.path.basename(dirpath) not in ['_posts', '_pages', '_layouts', '_includes', '_books']: # Adjust if you have includes in other _dirs
             print(f"Skipping directory: {dirpath}")
             continue

        for filename in filenames:
            if filename.lower().endswith(FILE_EXTENSIONS):
                filepath = os.path.join(dirpath, filename)
                print(f"Processing: {filepath}...")
                changes = process_file(filepath, dry_run)
                if changes > 0:
                    total_changes += changes
                else:
                    print("  No relevant tags found.")

    print("\n" + "="*50)
    print("Processing Complete.")
    if dry_run:
        print(f"Total changes that would be made: {total_changes}")
    else:
        print(f"Total changes made: {total_changes}")
    print("="*50)

if __name__ == "__main__":
    main()
