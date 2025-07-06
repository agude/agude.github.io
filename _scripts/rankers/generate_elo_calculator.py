# _scripts/generate_elo_calculator.py
import os
import json
import re
import yaml

# --- Configuration ---
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
BOOKS_DIR = os.path.join(PROJECT_ROOT, "_books")
OUTPUT_FILE = os.path.join(SCRIPT_DIR, "elo_calculator_tool.html")

# --- HTML Template ---
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ELO Assignment & Calculation Tool</title>
    <style>
        body { font-family: sans-serif; background-color: #f4f4f4; color: #333; margin: 0; padding: 20px; }
        h1, h2, h3 { text-align: center; color: #1c1e21; }
        .main-container { display: flex; gap: 30px; max-width: 1600px; margin: auto; }
        .panel { flex: 1; background: #fff; padding: 20px; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        textarea { width: 100%; height: 300px; font-family: monospace; font-size: 14px; line-height: 1.5; border: 1px solid #ccc; border-radius: 4px; }
        button { display: block; width: 100%; padding: 12px; font-size: 16px; font-weight: bold; color: #fff; background-color: #1877f2; border: none; border-radius: 6px; cursor: pointer; margin-top: 10px; }
        button:hover { background-color: #166fe5; }
        .config-item { display: flex; align-items: center; gap: 10px; margin-bottom: 10px; }
        .config-item label { font-weight: bold; }
        .config-item input { padding: 5px; border: 1px solid #ccc; border-radius: 4px; width: 80px; }
        #calculator-panel { flex: 2; }
        .calculator-layout { display: flex; gap: 20px; margin-top: 15px; }
        .source-list, .selection-list { flex: 1; border: 1px solid #ddd; padding: 10px; border-radius: 4px; height: 500px; overflow-y: auto; }
        .list-item { display: flex; align-items: center; gap: 10px; padding: 8px; border-bottom: 1px solid #eee; font-size: 14px; }
        .list-item:last-child { border-bottom: none; }
        .list-item img { width: 40px; height: 60px; object-fit: cover; border-radius: 3px; }
        .list-item.selected { background-color: #e7f3ff; }
        .list-item .actions button { font-size: 12px; padding: 4px 8px; width: auto; display: inline-block; margin: 0 2px; }
        .list-item .actions .add-beats-btn { background-color: #42b72a; }
        .list-item .actions .add-loses-btn { background-color: #f02849; }
        .list-item .actions button:hover { opacity: 0.8; }
        .selection-list .list-item .actions button { background-color: #606770; }
        #result-display { text-align: center; margin-top: 20px; padding: 15px; background: #e7f3ff; border: 1px solid #1877f2; border-radius: 8px; }
        #result-elo { font-size: 2em; font-weight: bold; color: #1877f2; }
        #result-logic { font-size: 0.9em; color: #606770; }
    </style>
</head>
<body>
    <h1>ELO Assignment & Calculation Tool</h1>
    <div class="main-container">
        <div id="assignment-panel" class="panel">
            <h2>1. Assign ELO to Ordered List</h2>
            <p>Paste your ordered list (one title per line, e.g., from the sorting tool).</p>
            <textarea id="initial-list" placeholder="  - Title A&#10;  - - Title B&#10;  - Title C"></textarea>
            <div class="config-item">
                <label for="base-elo">Base ELO:</label>
                <input type="number" id="base-elo" value="1200">
                <label for="step-elo">Step:</label>
                <input type="number" id="step-elo" value="8">
            </div>
            <button id="assign-elo-btn">Assign ELOs</button>
            <p style="margin-top: 20px;">This list will be used as the source for the calculator.</p>
            <textarea id="list-with-elo" readonly></textarea>
        </div>

        <div id="calculator-panel" class="panel">
            <h2>2. Calculate ELO for a New Item</h2>
            <p>Select items the new book <strong>beats</strong> and <strong>loses to</strong> from the source list.</p>
            <div class="calculator-layout">
                <div class="source-container">
                    <h3>Source Books (with ELO)</h3>
                    <div id="source-books-list" class="source-list"></div>
                </div>
                <div class="selections-container">
                    <h3>New Item Beats:</h3>
                    <div id="beats-list" class="selection-list"></div>
                    <h3>New Item Loses To:</h3>
                    <div id="loses-to-list" class="selection-list"></div>
                </div>
            </div>
            <div id="result-display">
                <h3>Calculated ELO for New Item</h3>
                <div id="result-elo">--</div>
                <div id="result-logic">Select items to see a result.</div>
            </div>
             <button id="reset-calc-btn" style="background-color: #606770; margin-top: 20px;">Reset Calculator</button>
        </div>
    </div>

    <script>
        const BOOKS_DATA_MAP = __BOOKS_DATA_MAP__;
        let ratedBooks = []; // Holds { title, elo }

        document.addEventListener('DOMContentLoaded', () => {
            const assignBtn = document.getElementById('assign-elo-btn');
            const resetBtn = document.getElementById('reset-calc-btn');

            assignBtn.addEventListener('click', handleAssignElo);
            resetBtn.addEventListener('click', resetCalculator);

            function handleAssignElo() {
                const initialList = document.getElementById('initial-list').value;
                const baseElo = parseInt(document.getElementById('base-elo').value, 10);
                const step = parseInt(document.getElementById('step-elo').value, 10);
                const outputArea = document.getElementById('list-with-elo');

                const titles = initialList.split('\\n')
                    .map(line => {
                        // Removes leading spaces/hyphens and trailing comments.
                        return line.trim().replace(/^[-\s]*/, '').replace(/#.*$/, '').trim();
                    })
                    .filter(Boolean);

                if (titles.length === 0) return;

                const middleIndex = Math.floor(titles.length / 2);
                ratedBooks = titles.map((title, index) => ({
                    title: title,
                    // Top item (index 0) gets the highest score.
                    elo: baseElo - (index - middleIndex) * step
                }));

                const outputText = ratedBooks.map(book => `  - ${book.title} # ${book.elo}`).join('\\n');
                outputArea.value = outputText;

                populateSourceList();
            }

            function populateSourceList() {
                const sourceListContainer = document.getElementById('source-books-list');
                sourceListContainer.innerHTML = ''; // Clear previous
                resetCalculator();

                ratedBooks.forEach(book => {
                    const item = createListItem(book, 'source');
                    sourceListContainer.appendChild(item);
                });
            }

            function createListItem(book, type) {
                const item = document.createElement('div');
                item.className = 'list-item';
                item.dataset.title = book.title;
                item.dataset.elo = book.elo;

                const bookData = BOOKS_DATA_MAP[book.title] || { image: '' };
                const imageHtml = bookData.image ? `<img src="..${bookData.image}" alt="${book.title}">` : '';

                let actionsHtml = '';
                if (type === 'source') {
                    actionsHtml = `
                        <div class="actions">
                            <button class="add-beats-btn" onclick="addToSelection(this, 'beats')">Beats</button>
                            <button class="add-loses-btn" onclick="addToSelection(this, 'loses')">Loses To</button>
                        </div>`;
                } else {
                     actionsHtml = `<div class="actions"><button onclick="removeFromSelection(this)">Remove</button></div>`;
                }

                item.innerHTML = `
                    ${imageHtml}
                    <div class="info">
                        <strong>${book.title}</strong><br>
                        <small>ELO: ${book.elo}</small>
                    </div>
                    <div style="flex-grow: 1;"></div>
                    ${actionsHtml}
                `;
                return item;
            }

            window.addToSelection = (btn, type) => {
                const sourceItem = btn.closest('.list-item');
                const title = sourceItem.dataset.title;
                const elo = parseInt(sourceItem.dataset.elo, 10);

                const targetListId = type === 'beats' ? 'beats-list' : 'loses-to-list';
                const targetList = document.getElementById(targetListId);

                const newItem = createListItem({ title, elo }, 'selection');
                targetList.appendChild(newItem);

                sourceItem.classList.add('selected');
                btn.parentElement.innerHTML = '<i>Selected</i>'; // Disable buttons

                calculateNewElo();
            };

            window.removeFromSelection = (btn) => {
                const selectionItem = btn.closest('.list-item');
                const title = selectionItem.dataset.title;
                selectionItem.remove();

                // Re-enable the item in the source list
                const sourceItem = document.querySelector(`#source-books-list .list-item[data-title="${title}"]`);
                if (sourceItem) {
                    sourceItem.classList.remove('selected');
                    sourceItem.querySelector('.actions').innerHTML = `
                        <button class="add-beats-btn" onclick="addToSelection(this, 'beats')">Beats</button>
                        <button class="add-loses-btn" onclick="addToSelection(this, 'loses')">Loses To</button>`;
                }

                calculateNewElo();
            };

            function calculateNewElo() {
                const beatsList = document.getElementById('beats-list');
                const losesToList = document.getElementById('loses-to-list');
                const resultEloEl = document.getElementById('result-elo');
                const resultLogicEl = document.getElementById('result-logic');

                const beatElos = [...beatsList.querySelectorAll('.list-item')].map(item => parseInt(item.dataset.elo, 10));
                const losesToElos = [...losesToList.querySelectorAll('.list-item')].map(item => parseInt(item.dataset.elo, 10));

                const floorElo = beatElos.length > 0 ? Math.max(...beatElos) : 400;
                const ceilingElo = losesToElos.length > 0 ? Math.min(...losesToElos) : 2000;

                if (floorElo > ceilingElo) {
                    resultEloEl.textContent = 'Error';
                    resultLogicEl.textContent = `Logical conflict: The item cannot beat a book with ELO ${floorElo} and lose to a book with ELO ${ceilingElo}.`;
                    resultEloEl.style.color = '#f02849';
                    return;
                }

                const newElo = Math.round((floorElo + ceilingElo) / 2);
                resultEloEl.textContent = newElo;
                resultLogicEl.textContent = `Average of highest "Beats" (${floorElo}) and lowest "Loses To" (${ceilingElo}).`;
                resultEloEl.style.color = '#1877f2';
            }

            function resetCalculator() {
                document.getElementById('beats-list').innerHTML = '';
                document.getElementById('loses-to-list').innerHTML = '';
                document.getElementById('result-elo').textContent = '--';
                document.getElementById('result-logic').textContent = 'Select items to see a result.';
                document.getElementById('result-elo').style.color = '#1877f2';

                // Reset all source items
                document.querySelectorAll('#source-books-list .list-item').forEach(item => {
                    item.classList.remove('selected');
                    const actionsDiv = item.querySelector('.actions');
                    if (actionsDiv) {
                        actionsDiv.innerHTML = `
                            <button class="add-beats-btn" onclick="addToSelection(this, 'beats')">Beats</button>
                            <button class="add-loses-btn" onclick="addToSelection(this, 'loses')">Loses To</button>`;
                    }
                });
            }
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
                    book_map[data["title"]] = {"image": data["image"]}
            except Exception as e:
                print(f"An error occurred with file {filepath}: {e}")
    return book_map


def main():
    """Main execution: generates data and writes the self-contained HTML tool."""
    print(f"Reading book files from '{BOOKS_DIR}'...")
    book_map = extract_book_data_map()
    print(f"Found data for {len(book_map)} books.")
    book_map_json = json.dumps(book_map, indent=2)
    final_html = HTML_TEMPLATE.replace("__BOOKS_DATA_MAP__", book_map_json)
    try:
        with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
            f.write(final_html)
        print(f"Successfully created ELO calculation tool: '{OUTPUT_FILE}'")
    except IOError as e:
        print(f"Error writing to file '{OUTPUT_FILE}': {e}")


if __name__ == "__main__":
    main()
