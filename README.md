# Climate Timeline 💚

A static site that provides a temperature heatmap for various cities around the world. Highly inspired by the GitHub contributions graph. Highlights important climate-related events on the timeline.

See the live site at <https://climate.mery.cloud/>.

## Running locally

The project is structured into two main parts:
- `analyzer`: A Python module that fetches data from Open-Meteo and writes it to JSON files.
- `www`: A Gleam module that builds the static site using the generated JSON files.

```bash
uv run --directory analyzer main.py         # Run data analyzer
cd www && gleam run -m build                # Build static site
python -m http.server --directory dist 8000 # Serve static site
```

Then open <http://localhost:8000> in your browser.

## Development

### Adding a new city

Just add a new line to `cities.txt` with the local name of the city. Please try to keep the list sorted:

```bash
sort -o cities.txt cities.txt # Sort city list
```

Then run the analyzer and build the site again, it should pick up the new city automatically 🎉.

### Adding an event

Events are stored in a json file at `events.json`. They have the following format:

```json
[
  {
    "id": "some_event_2020", // Used as a slug, should be unique
    "date": "YYYY-MM-DD",
    "display_name": "Event Name",
    "description": "A longer description of the event.",
    "wiki_link": "https://en.wikipedia.org/..." // Link to the relevant Wikipedia article
  }
]
```

## Acknowledgements

The data is provided by [Open-Meteo](https://open-meteo.com/). It's awesome that such a nice API is available for free!
