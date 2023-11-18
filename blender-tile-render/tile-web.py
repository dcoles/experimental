#!/usr/bin/env -S blender -noaudio --background --log-level 0 --python

# HTTP-server for Blender rending

import argparse
import http.server
import json
import os
import shutil
import socketserver
import sys
import tempfile
import urllib.parse

import bpy

HTTPStatus = http.server.HTTPStatus
urlsplit = urllib.parse.urlsplit
parse_qs = urllib.parse.parse_qs
unquote = urllib.parse.unquote
urlencode = urllib.parse.urlencode

PORT = 8080

g_last_file = None
g_cycles_device = 'CPU'


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.url = urlsplit(self.path)
        self.query = parse_qs(self.url.query)

        if self.url.path.startswith('/render/'):
            handler = self.handle_render
        elif self.url.path == '/':
            handler = self.handle_index
        else:
            self.send_response(HTTPStatus.NOT_FOUND, 'Not Found')
            self.end_headers()
            return

        try:
            handler()
        except ValueError as e:
            msg = f'{type(e).__name__} {e}'
            print(f'Bad Request! {msg}')
            self.send_response(HTTPStatus.BAD_REQUEST, str(e))
            self.end_headers()
        except Exception as e:
            msg = f'{type(e).__name__} {e}'
            print(f'Exception! {msg}')
            self.send_response(HTTPStatus.INTERNAL_SERVER_ERROR, msg)
            self.end_headers()

    def handle_render(self):
        """
        Handle /render/{filename}?args...
        """
        global g_last_file
        global g_cycles_device

        parts = self.url.path.split('/')
        if len(parts) != 3:
            self.send_response(HTTPStatus.BAD_REQUEST, 'expected /render/FILENAME.blend')
            self.end_headers()
            return

        path = unquote(parts[2])

        if not path:
            # Show available .blend files
            files = [filename for filename in os.listdir() if filename.endswith('.blend')]

            self.send_response(HTTPStatus.OK, 'OK')
            self.send_header('Content-Type', 'text/json')
            self.end_headers()

            self.wfile.write(json.dumps({'files': files}, indent='  ').encode('ascii'))
            return

        print(f'Rendering {path}...')

        if path != g_last_file:
            bpy.ops.wm.open_mainfile(filepath=path)
            g_last_file = path

        scn = bpy.context.scene
        scn.render.engine = 'CYCLES'
        scn.cycles.device = 'GPU'

        scn.render.image_settings.file_format = 'PNG'

        scn.render.threads_mode = 'FIXED'
        scn.render.threads = os.cpu_count() # Should be 2x number of CPU cores (hyper-threading)

        scn.render.use_persistent_data = True

        cycles_device = self.query['cyclesDevice'][0] if 'cyclesDevice' in self.query else g_cycles_device
        print(f'  cyclesDevice: {cycles_device}')
        set_cycles_device(cycles_device)

        if 'resolutionX' in self.query:
            resolution_x = int(self.query['resolutionX'][0])
            print(f'  resolutionX: {resolution_x}')
            scn.render.resolution_x = resolution_x

        if 'resolutionY' in self.query:
            resolution_y = int(self.query['resolutionY'][0])
            print(f'  resolutionY: {resolution_y}')
            scn.render.resolution_y = resolution_y

        if 'resolutionPercentage' in self.query:
            resolution_percentage = int(self.query['resolutionPercentage'][0])
            print(f'  resolutionPercentage: {resolution_percentage}')
            scn.render.resolution_percentage = resolution_percentage
        else:
            scn.render.resolution_percentage = 100

        cols = int(self.query['cols'][0]) if 'cols' in self.query else 1
        if cols > 1:
            print(f'  cols: {cols}')

        n = int(self.query['n'][0]) if 'n' in self.query else 0

        if n >= cols**2 or n < 0:
            raise ValueError(f'n must be between 0 and cols^2 - 1')

        self.send_response(HTTPStatus.OK, 'OK')
        self.send_header('Content-type', 'image/png')
        self.end_headers()

        with tempfile.NamedTemporaryFile(delete=False) as f:
            render_tile(f, n, cols)
            shutil.copyfileobj(f, self.wfile)

        # Workaround for Windows having some funny delete-on-close behaviour
        # that causes "Permission Denied" errors.
        os.unlink(f.name)

    def handle_index(self):
        """
        Handle GET /
        """
        self.send_response(HTTPStatus.OK, 'OK')
        self.send_header('Content-Type', 'text/html')
        self.end_headers()

        with open('index.html', 'rb') as f:
            shutil.copyfileobj(f, self.wfile)


def set_cycles_device(cycles_device):
    """
    Force cycles acceleration device (e.g. 'CUDA', 'OPTIX', 'HIP', 'ONEAPI', ...).
    """
    # This is how blender CLI does it.
    import _cycles
    _cycles.set_device_override(cycles_device)


def render_tile(f, n = 0, cols = 1):
    """
    Render one or more tiles.

    tile: If given, only render this tile (0-indexed).
    cols: Number of tiles per axis (e.g. 2 = 2x2 = 4 tiles).
    """
    scn = bpy.context.scene

    if cols > 1:
        scn.render.use_border = True
        scn.render.use_crop_to_border = True

    max_n = cols**2 -1
    if n > max_n or n < 0:
        raise ValueError(f'Invalid tile index (must be min: 0, max: {max_n})')

    x = n % cols
    y = n // cols

    # This sadly doesn't work inside Kubernetes
    #scn.render.filepath = f'/proc/{os.getpid()}/fd/{f.fileno()}'
    #scn.render.use_file_extension = False

    scn.render.filepath = f.name
    scn.render.use_file_extension = False

    print(f'Rendering Tile {n}')

    # These values are from the bottom-left.
    # Note: montage is from the top-left
    scn.render.border_min_x = x / cols
    scn.render.border_max_x = scn.render.border_min_x + (1.0 / cols)
    scn.render.border_min_y = (cols - 1 - y) / cols
    scn.render.border_max_y = scn.render.border_min_y + (1.0 / cols)

    bpy.ops.render.render(animation=False, write_still=True)


def main():
    global g_cycles_device

    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=PORT)
    parser.add_argument('--cycles-device', choices=['CUDA', 'OPTIX', 'HIP', 'ONEAPI', 'CPU'])
    arg_start = sys.argv.index('--python') + 2
    args = parser.parse_args(sys.argv[arg_start:]) # skip blender arguments

    if args.cycles_device:
        print(f'Set default Cycles device to {args.cycles_device}')
        g_cycles_device = args.cycles_device

    with socketserver.TCPServer(("", args.port), Handler) as httpd:
        print(f'Serving at http://0.0.0.0:{args.port}/')
        httpd.serve_forever()


if __name__ == '__main__':
    returncode = 0

    try:
        main()
    except SystemExit as e:
        returncode = e.code
    except Exception as e:
        print(f'Python Exception! {type(e).__name__} {e}')
        returncode = 1
    finally:
        # Without this, Blender keeps running after the script finishes
        sys.exit(returncode)
