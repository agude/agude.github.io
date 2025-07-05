# _scripts/generate_ranking_tool_elo.py
import os
import json
import re
import yaml

# --- Configuration ---
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
BOOKS_DIR = os.path.join(PROJECT_ROOT, "_books")
OUTPUT_FILE = os.path.join(SCRIPT_DIR, "book_ranking_tool.html")

# --- HTML Template ---
# The entire HTML/CSS/JS for the tool is stored here as a multi-line string.
# Note the `__BOOKS_JSON_PAYLOAD__` placeholder.
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Book Ranking Tool</title>
    <style>
        body { font-family: sans-serif; background-color: #f0f2f5; color: #1c1e21; margin: 0; padding: 20px; }
        h1, h2 { text-align: center; }
        #comparison-container { display: flex; justify-content: center; align-items: flex-start; gap: 20px; margin-bottom: 30px; }
        .book-card { border: 2px solid transparent; border-radius: 8px; padding: 15px; text-align: center; cursor: pointer; transition: all 0.2s ease-in-out; background-color: #fff; box-shadow: 0 2px 4px rgba(0,0,0,0.1); width: 300px; }
        .book-card:hover { transform: translateY(-5px); border-color: #1877f2; }
        .book-card img { max-width: 100%; height: 300px; object-fit: contain; margin-bottom: 10px; }
        .book-card p { font-size: 1.1em; font-weight: bold; margin: 0; }
        #ranking-container { max-width: 800px; margin: 20px auto; }
        textarea { width: 100%; height: 400px; font-family: monospace; font-size: 14px; }
    </style>
    <script>
        // The Python script will replace the placeholder below with the actual JSON data.
        const BOOKS_JSON_PAYLOAD = __BOOKS_JSON_PAYLOAD__;

        document.addEventListener('DOMContentLoaded', () => {
            const bookAElement = document.getElementById('bookA');
            const bookBElement = document.getElementById('bookB');
            const imgA = document.getElementById('imgA');
            const titleA = document.getElementById('titleA');
            const imgB = document.getElementById('imgB');
            const titleB = document.getElementById('titleB');
            const rankedListTextarea = document.getElementById('ranked-list');

            let books = [];
            let bookA, bookB;

            const K_FACTOR = 100;

            function getExpectedScore(ratingA, ratingB) {
                return 1 / (1 + Math.pow(10, (ratingB - ratingA) / 400));
            }

            function updateScores(winner, loser) {
                const expectedScoreWinner = getExpectedScore(winner.elo, loser.elo);
                const expectedScoreLoser = getExpectedScore(loser.elo, winner.elo);
                winner.elo += K_FACTOR * (1 - expectedScoreWinner);
                loser.elo += K_FACTOR * (0 - expectedScoreLoser);
            }

            function pickTwoBooks() {
                let indexA, indexB;
                do {
                    indexA = Math.floor(Math.random() * books.length);
                    indexB = Math.floor(Math.random() * books.length);
                } while (indexA === indexB);
                bookA = books[indexA];
                bookB = books[indexB];
                displayBooks(bookA, bookB);
            }

            function displayBooks(bA, bB) {
                imgA.src = `..${bA.image}`;
                titleA.textContent = bA.title;
                imgB.src = `..${bB.image}`;
                titleB.textContent = bB.title;
            }

            function displayRankings() {
                books.sort((a, b) => b.elo - a.elo);
                // Appends the rounded ELO score as a comment to each book title.
                const rankedTitles = books.map(book => `  - ${book.title} # ${Math.round(book.elo)}`).join('\\n');
                rankedListTextarea.value = rankedTitles;
            }

            function handleChoice(winner, loser) {
                updateScores(winner, loser);
                displayRankings();
                pickTwoBooks();
            }

            function init() {
                try {
                    // No fetch needed! We use the embedded payload directly.
                    const data = BOOKS_JSON_PAYLOAD;
                    books = data.map(book => ({ ...book, elo: 1200 }));

                    if (books.length < 2) {
                        alert("Not enough books to compare. Check your _books directory.");
                        return;
                    }

                    bookAElement.addEventListener('click', () => handleChoice(bookA, bookB));
                    bookBElement.addEventListener('click', () => handleChoice(bookB, bookA));

                    displayRankings();
                    pickTwoBooks();
                } catch (error) {
                    console.error("Error initializing the ranking tool:", error);
                    alert("There was an error initializing the tool. Check the browser console for details.");
                }
            }

            init();
        });
    </script>
</head>
<body>
    <h1>Book Ranking Tool</h1>
    <div id="comparison-container">
        <div id="bookA" class="book-card">
            <img id="imgA" src="" alt="Book A Cover">
            <p id="titleA"></p>
        </div>
        <div id="bookB" class="book-card">
            <img id="imgB" src="" alt="Book B Cover">
            <p id="titleB"></p>
        </div>
    </div>
    <div id="ranking-container">
        <h2>Current Ranking</h2>
        <textarea id="ranked-list" readonly></textarea>
    </div>
</body>
</html>
"""


def extract_book_data():
    """
    Reads all markdown files from the BOOKS_DIR, extracts front matter,
    and returns a list of book dictionaries.
    """
    books = []
    if not os.path.isdir(BOOKS_DIR):
        print(f"Error: Directory '{BOOKS_DIR}' not found.")
        return books

    for filename in os.listdir(BOOKS_DIR):
        if filename.endswith(".md"):
            filepath = os.path.join(BOOKS_DIR, filename)
            try:
                with open(filepath, "r", encoding="utf-8") as f:
                    content = f.read()

                # --- FIX: Use a more robust regex for front matter extraction ---
                # This regex handles different line endings (\n or \r\n) and
                # is less strict about whitespace around the delimiters.
                # \A ensures we only match at the absolute start of the file.
                match = re.search(r"\A---\s*\n(.*?)\n---\s*", content, re.DOTALL)
                if not match:
                    print(f"Warning: No front matter found in '{filepath}'. Skipping.")
                    continue

                yaml_content = match.group(1)
                data = yaml.safe_load(yaml_content)

                if "title" in data and "image" in data:
                    books.append({"title": data["title"], "image": data["image"]})
                else:
                    print(
                        f"Warning: Skipping '{filepath}' due to missing 'title' or 'image' field."
                    )

            except yaml.YAMLError as e:
                print(f"Error parsing YAML in {filepath}: {e}")
            except Exception as e:
                print(f"An unexpected error occurred with file {filepath}: {e}")

    return books


def main():
    """Main execution: generates data and writes the self-contained HTML tool."""
    print(f"Reading book files from '{BOOKS_DIR}'...")
    book_list = extract_book_data()
    print(f"Found {len(book_list)} books.")

    # Convert the Python list of books to a JSON string.
    book_list_json = json.dumps(book_list)

    # Inject the JSON data into the HTML template by replacing the placeholder.
    final_html = HTML_TEMPLATE.replace("__BOOKS_JSON_PAYLOAD__", book_list_json)

    try:
        with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
            f.write(final_html)
        print(f"Successfully created self-contained ranking tool: '{OUTPUT_FILE}'")
    except IOError as e:
        print(f"Error writing to file '{OUTPUT_FILE}': {e}")


if __name__ == "__main__":
    main()
