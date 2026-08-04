#!/usr/bin/env python3

import argparse
import os
import re

parser = argparse.ArgumentParser(description="Enter the filename")

parser.add_argument("file", type=str, help="The filename")
args = parser.parse_args()

filename = args.file
if(re.match(r"\.[^.]+", filename)):
    raise ValueError(f"File is a hidden file -> '{filename!r}'")

name, ext = os.path.splitext(filename)

if not ext:
    raise ValueError(f"The file '{name!r}' doesn't have an extension")
else:
    print(f"The file's extension: {ext!r}")

