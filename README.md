# Climate Thingy

## Running

```bash
uv run --directory analyzer main.py         # Run data analyzer
cd www && gleam run -m build                # Build static site
python -m http.server --directory dist 8000 # Serve static site
```

Then open <http://localhost:8000> in your browser.

## Development

```bash
sort -o cities.txt cities.txt # Sort city list
```
