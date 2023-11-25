#!/usr/bin/env python3

"""
Local HTTP server for development.
"""

import argparse
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import logging

DEFAULT_HOST = '127.0.0.1'
DEFAULT_PORT = 8000


class RequestHandler(SimpleHTTPRequestHandler):
    extensions_map = {
        '.wgsl': 'text/wgsl',
        '.js': 'text/javascript',
        '.mjs': 'text/javascript',
    }

    def do_GET(self) -> None:
        # Browser should never cache responses
        self.headers['Cache-Control'] = 'no-store'

        return super().do_GET()


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser()
    parser.add_argument('--host', default=DEFAULT_HOST)
    parser.add_argument('--port', type=int, default=DEFAULT_PORT)
    return parser.parse_args()


def main():
    logging.basicConfig(level=logging.INFO)
    args = parse_args()

    logging.info('Listening on http://%s:%d', args.host, args.port)


    with ThreadingHTTPServer((args.host, args.port), RequestHandler) as httpd:
        httpd.serve_forever()


if __name__ == '__main__':
    main()
