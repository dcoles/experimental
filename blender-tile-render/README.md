# Blender Tile Render

A simple tile-based renderer for Blender scenes.

Not production quality (see [Limitations](#limitations)).

## Getting started

1. Download [`blender-3.5-splash.blend`](https://www.blender.org/download/demo/splash/blender-3.5-splash.blend) and put in this directory.
2. Start Blender using the arguments: `blender -noaudio --background --log-level 0 --python tile-web.py`
3. Open [http://localhost:8080/](http://localhost:8080/) in your browser

Parameters can be adjusted in [`index.html`](index.html).

## Limitations

- Only one HTTP request can be handled at a time (single-threaded HTTP server)
- `COLS` should evenly divide `WIDTH` and `HEIGHT` to avoid "fractional" pixels
- Some scenes don't render correctly when only rendering within a clipping boundary
- There may be artifacts near the tile edges
