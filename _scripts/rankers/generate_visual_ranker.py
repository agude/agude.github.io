# _scripts/generate_visual_ranker.py
import os
import json
import re
import yaml

# --- Configuration ---
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
BOOKS_DIR = os.path.join(PROJECT_ROOT, "_books")
OUTPUT_FILE = os.path.join(SCRIPT_DIR, "visual_book_ranker.html")

# --- HTML Template ---
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Visual Book Ranker</title>
    <style>
        body { font-family: sans-serif; background-color: #f0f2f5; color: #1c1e21; margin: 0; padding: 0; display: flex; height: 100vh; }
        h1, h2 { text-align: center; color: #1c1e21; }
        .container { padding: 20px; overflow-y: auto; }
        #text-container { flex: 1; border-right: 2px solid #ddd; }
        #cards-container-wrapper { flex: 2; }
        textarea#ranked-list { width: 100%; height: 85%; font-family: monospace; font-size: 14px; line-height: 1.5; border: 1px solid #ccc; border-radius: 4px; }
        #cards-container { display: flex; flex-direction: column; gap: 10px; padding: 10px; }
        .book-card {
            display: flex;
            align-items: center;
            background-color: #fff;
            border: 1px solid #ddd;
            border-radius: 8px;
            padding: 10px;
            cursor: grab;
            box-shadow: 0 2px 4px rgba(0,0,0,0.05);
            transition: box-shadow 0.2s ease-in-out, transform 0.2s ease-in-out;
        }
        .book-card:hover { box-shadow: 0 4px 8px rgba(0,0,0,0.1); }
        .book-card img { width: 60px; height: 90px; object-fit: cover; border-radius: 4px; margin-right: 15px; }
        .book-card p { font-size: 1.1em; font-weight: bold; margin: 0; flex-grow: 1; }
        .book-card .rank-number { font-size: 1.2em; font-weight: bold; color: #888; margin-right: 15px; width: 30px; text-align: right; }
        /* Style for the item being dragged */
        .book-card.dragging { opacity: 0.5; background: #cce5ff; cursor: grabbing; }
    </style>
</head>
<body>
    <div id="text-container" class="container">
        <h1>Text List</h1>
        <p>Edit this list directly or drag the cards to reorder.</p>
        <textarea id="ranked-list" spellcheck="false">
  - Book Title Example 1
  - Book Title Example 2 # 1216
  - Book Title Example 3
        </textarea>
    </div>

    <div id="cards-container-wrapper" class="container">
        <h1>Visual Ranking</h1>
        <div id="cards-container"></div>
    </div>

    <script>
        // Injected by the Python script
        const BOOKS_DATA_MAP = __BOOKS_DATA_MAP__;

        document.addEventListener('DOMContentLoaded', () => {
            const textarea = document.getElementById('ranked-list');
            const cardsContainer = document.getElementById('cards-container');

            // --- Main Functions ---

            /**
             * Reads the textarea, clears the cards, and re-renders them in the correct order.
             */
            function renderCardsFromText() {
                // 1. Clear existing cards
                cardsContainer.innerHTML = '';

                // 2. Get titles from textarea
                const titles = textarea.value
                    .split('\\n')
                    .map(line => line.trim())
                    .filter(line => line.startsWith('- '))
                    .map(line => {
                        // Clean up the title: remove leading '- ' and trailing '# ELO' comment
                        return line.replace(/^- /, '').replace(/#.*$/, '').trim();
                    });

                // 3. Create and append a card for each title
                titles.forEach((title, index) => {
                    const bookData = BOOKS_DATA_MAP[title];
                    if (bookData) {
                        const card = document.createElement('div');
                        card.className = 'book-card';
                        card.draggable = true;
                        card.dataset.title = title; // Store original title for later
                        card.innerHTML = `
                            <span class="rank-number">${index + 1}.</span>
                            <img src="..${bookData.image}" alt="Cover for ${title}">
                            <p>${title}</p>
                        `;
                        cardsContainer.appendChild(card);
                    }
                });

                // 4. Add drag listeners to the newly created cards
                addDragListeners();
            }

            /**
             * Reads the current order of cards and updates the textarea.
             */
            function updateTextFromCards() {
                const cards = [...cardsContainer.querySelectorAll('.book-card')];
                const textLines = cards.map(card => `  - ${card.dataset.title}`);
                textarea.value = textLines.join('\\n');
            }

            /**
             * Updates the visible rank number on each card based on its current DOM order.
             */
            function updateCardRanks() {
                const cards = cardsContainer.querySelectorAll('.book-card');
                cards.forEach((card, index) => {
                    const rankNumberEl = card.querySelector('.rank-number');
                    if (rankNumberEl) {
                        rankNumberEl.textContent = `${index + 1}.`;
                    }
                });
            }

            // --- Drag and Drop Logic ---

            function addDragListeners() {
                const cards = document.querySelectorAll('.book-card');
                cards.forEach(card => {
                    card.addEventListener('dragstart', () => {
                        card.classList.add('dragging');
                    });

                    card.addEventListener('dragend', () => {
                        card.classList.remove('dragging');
                        // After a drop, update the text area AND the visual numbers.
                        updateTextFromCards();
                        updateCardRanks();
                    });
                });
            }

            cardsContainer.addEventListener('dragover', e => {
                e.preventDefault(); // Necessary to allow dropping
                const afterElement = getDragAfterElement(cardsContainer, e.clientY);
                const dragging = document.querySelector('.dragging');
                if (afterElement == null) {
                    cardsContainer.appendChild(dragging);
                } else {
                    cardsContainer.insertBefore(dragging, afterElement);
                }
            });

            function getDragAfterElement(container, y) {
                const draggableElements = [...container.querySelectorAll('.book-card:not(.dragging)')];

                return draggableElements.reduce((closest, child) => {
                    const box = child.getBoundingClientRect();
                    const offset = y - box.top - box.height / 2;
                    if (offset < 0 && offset > closest.offset) {
                        return { offset: offset, element: child };
                    } else {
                        return closest;
                    }
                }, { offset: Number.NEGATIVE_INFINITY }).element;
            }


            // --- Initial Setup ---

            // When the text is manually changed, re-render the cards
            textarea.addEventListener('input', renderCardsFromText);

            // Initial load
            renderCardsFromText();
        });
    </script>
</body>
</html>
"""


def extract_book_data_map():
    """
    Reads all markdown files from the BOOKS_DIR and returns a dictionary
    mapping book titles to their data (e.g., image path).
    """
    book_map = {}
    if not os.path.isdir(BOOKS_DIR):
        print(f"Error: Directory '{BOOKS_DIR}' not found.")
        return book_map

    for filename in os.listdir(BOOKS_DIR):
        if filename.endswith(".md"):
            filepath = os.path.join(BOOKS_DIR, filename)
            try:
                with open(filepath, "r", encoding="utf-8") as f:
                    content = f.read()

                match = re.search(r"\A---\s*\n(.*?)\n---\s*", content, re.DOTALL)
                if not match:
                    continue

                data = yaml.safe_load(match.group(1))
                if "title" in data and "image" in data:
                    # Use the title as the key in the map
                    book_map[data["title"]] = {"image": data["image"]}
                else:
                    print(
                        f"Warning: Skipping '{filepath}' due to missing 'title' or 'image'."
                    )

            except Exception as e:
                print(f"An error occurred with file {filepath}: {e}")

    return book_map


def main():
    """Main execution: generates data and writes the self-contained HTML tool."""
    print(f"Reading book files from '{BOOKS_DIR}'...")
    book_map = extract_book_data_map()
    print(f"Found data for {len(book_map)} books.")

    if not book_map:
        print("No book data found. The tool will be empty.")

    # Convert the Python dictionary to a JSON string for injection.
    book_map_json = json.dumps(book_map, indent=2)

    # Inject the JSON data map into the HTML template.
    final_html = HTML_TEMPLATE.replace("__BOOKS_DATA_MAP__", book_map_json)

    try:
        with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
            f.write(final_html)
        print(f"Successfully created visual ranking tool: '{OUTPUT_FILE}'")
    except IOError as e:
        print(f"Error writing to file '{OUTPUT_FILE}': {e}")


if __name__ == "__main__":
    main()
