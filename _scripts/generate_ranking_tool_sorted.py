# _scripts/generate_ranking_tool_mergesort.py
import os
import json
import re
import yaml

# --- Configuration ---
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
BOOKS_DIR = os.path.join(PROJECT_ROOT, "_books")
OUTPUT_FILE = os.path.join(SCRIPT_DIR, "book_ranking_tool_mergesort.html")

# --- HTML Template ---
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Book Sorting Tool (Merge Sort)</title>
    <style>
        body { font-family: sans-serif; background-color: #f0f2f5; color: #1c1e21; margin: 0; padding: 20px; }
        h1, h2 { text-align: center; }
        #comparison-container { display: flex; justify-content: center; align-items: flex-start; gap: 20px; margin-bottom: 20px; min-height: 420px; }
        .book-card { border: 2px solid transparent; border-radius: 8px; padding: 15px; text-align: center; cursor: pointer; transition: all 0.2s ease-in-out; background-color: #fff; box-shadow: 0 2px 4px rgba(0,0,0,0.1); width: 300px; }
        .book-card:hover { transform: translateY(-5px); border-color: #1877f2; }
        .book-card.disabled { cursor: not-allowed; opacity: 0.5; }
        .book-card img { max-width: 100%; height: 300px; object-fit: contain; margin-bottom: 10px; }
        .book-card p { font-size: 1.1em; font-weight: bold; margin: 0; }
        #ranking-container { max-width: 800px; margin: 20px auto; }
        #status { text-align: center; font-size: 1.2em; color: #606770; margin-bottom: 20px; }
        textarea { width: 100%; height: 400px; font-family: monospace; font-size: 14px; }
    </style>
    <script>
        const BOOKS_JSON_PAYLOAD = __BOOKS_JSON_PAYLOAD__;

        document.addEventListener('DOMContentLoaded', () => {
            const bookAElement = document.getElementById('bookA');
            const bookBElement = document.getElementById('bookB');
            const imgA = document.getElementById('imgA');
            const titleA = document.getElementById('titleA');
            const imgB = document.getElementById('imgB');
            const titleB = document.getElementById('titleB');
            const rankedListTextarea = document.getElementById('ranked-list');
            const statusElement = document.getElementById('status');
            const comparisonContainer = document.getElementById('comparison-container');

            let books = [];
            let comparisonResolver = null;

            // --- Core Merge Sort Logic ---

            async function startSort() {
                statusElement.textContent = "Starting the sort...";
                // Shuffle for good measure, ensures variety in initial comparisons
                books = BOOKS_JSON_PAYLOAD.sort(() => Math.random() - 0.5);

                if (books.length < 2) {
                    alert("Not enough books to sort.");
                    return;
                }

                const sortedBooks = await mergeSort(books);
                displayFinalRanking(sortedBooks);
            }

            async function mergeSort(arr) {
                if (arr.length <= 1) {
                    return arr;
                }

                const middle = Math.floor(arr.length / 2);
                const left = arr.slice(0, middle);
                const right = arr.slice(middle);

                // Recursively sort both halves
                const sortedLeft = await mergeSort(left);
                const sortedRight = await mergeSort(right);

                // Merge the sorted halves
                return await merge(sortedLeft, sortedRight);
            }

            async function merge(left, right) {
                let resultArray = [], leftIndex = 0, rightIndex = 0;

                while (leftIndex < left.length && rightIndex < right.length) {
                    // Present the choice to the user
                    const winner = await presentComparison(left[leftIndex], right[rightIndex]);

                    if (winner === left[leftIndex]) {
                        resultArray.push(left[leftIndex]);
                        leftIndex++;
                    } else {
                        resultArray.push(right[rightIndex]);
                        rightIndex++;
                    }
                    // Display current progress
                    displayRankings(resultArray.concat(left.slice(leftIndex)).concat(right.slice(rightIndex)));
                }

                // Concatenate remaining elements
                return resultArray.concat(left.slice(leftIndex)).concat(right.slice(rightIndex));
            }

            function presentComparison(bookA, bookB) {
                return new Promise(resolve => {
                    comparisonResolver = resolve; // Store the resolver function

                    // Display books and enable cards
                    imgA.src = `..${bookA.image}`;
                    titleA.textContent = bookA.title;
                    imgB.src = `..${bookB.image}`;
                    titleB.textContent = bookB.title;
                    bookAElement.classList.remove('disabled');
                    bookBElement.classList.remove('disabled');
                    statusElement.textContent = "Which book is better?";

                    // Attach one-time click listeners
                    bookAElement.onclick = () => handleChoice(bookA);
                    bookBElement.onclick = () => handleChoice(bookB);
                });
            }

            function handleChoice(chosenBook) {
                // Disable cards to prevent double-clicking
                bookAElement.classList.add('disabled');
                bookBElement.classList.add('disabled');
                bookAElement.onclick = null;
                bookBElement.onclick = null;

                if (comparisonResolver) {
                    comparisonResolver(chosenBook); // Resolve the promise with the chosen book
                    comparisonResolver = null;
                }
            }

            function displayRankings(bookArray) {
                const rankedTitles = bookArray.map(book => `  - ${book.title}`).join('\\n');
                rankedListTextarea.value = rankedTitles;
            }



            function displayFinalRanking(sortedBooks) {
                displayRankings(sortedBooks);
                statusElement.textContent = "Sorting Complete!";
                comparisonContainer.innerHTML = "<h2>All books have been ranked.</h2>";
            }

            startSort();
        });
    </script>
</head>
<body>
    <h1>Book Sorting Tool</h1>
    <h2 id="status">Loading...</h2>
    <div id="comparison-container">
        <div id="bookA" class="book-card disabled">
            <img id="imgA" src="" alt="Book A Cover">
            <p id="titleA"></p>
        </div>
        <div id="bookB" class="book-card disabled">
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

    book_list_json = json.dumps(book_list, indent=2)
    final_html = HTML_TEMPLATE.replace("__BOOKS_JSON_PAYLOAD__", book_list_json)

    try:
        with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
            f.write(final_html)
        print(f"Successfully created self-contained sorting tool: '{OUTPUT_FILE}'")
    except IOError as e:
        print(f"Error writing to file '{OUTPUT_FILE}': {e}")


if __name__ == "__main__":
    main()