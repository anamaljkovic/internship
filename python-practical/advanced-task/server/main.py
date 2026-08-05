#!/usr/bin/env python3

"""
Entry point for the pizza server. Starts a threaded HTTP server
using the request handler defined in handlers.py.
"""

from http.server import ThreadingHTTPServer
from server.handlers import PizzaRequestHandler

HOST = "localhost"
PORT = 8000


def main():
    server = ThreadingHTTPServer((HOST, PORT), PizzaRequestHandler)
    print(f"Pizza server running on http://{HOST}:{PORT}")
    server.serve_forever()


if __name__ == "__main__":
    main()