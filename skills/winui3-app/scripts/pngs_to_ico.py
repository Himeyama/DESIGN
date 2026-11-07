#!/usr/bin/env python3
"""Pack four RGBA PNGs into a Windows ICO without changing the images."""

import argparse
import struct
from pathlib import Path

SIZES = (16, 32, 48, 256)
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def read_png(directory: Path, name: str, size: int) -> bytes:
    path = directory / f"{name}-{size}.png"
    data = path.read_bytes()
    if len(data) < 33 or data[:8] != PNG_SIGNATURE or data[12:16] != b"IHDR":
        raise ValueError(f"Not a valid PNG header: {path}")
    width, height, bit_depth, color_type = struct.unpack_from(">IIBB", data, 16)
    if (width, height) != (size, size):
        raise ValueError(f"Expected {size}x{size}: {path} is {width}x{height}")
    if bit_depth != 8 or color_type != 6:
        raise ValueError(f"Expected an 8-bit RGBA PNG: {path}")
    return data


def make_ico(directory: Path, name: str) -> Path:
    images = [read_png(directory, name, size) for size in SIZES]
    offset = 6 + len(images) * 16
    entries = []
    for size, image in zip(SIZES, images, strict=True):
        dimension = 0 if size == 256 else size
        entries.append(struct.pack("<BBBBHHII", dimension, dimension, 0, 0, 1, 32, len(image), offset))
        offset += len(image)
    output = directory / f"{name}.ico"
    output.write_bytes(struct.pack("<HHH", 0, 1, len(images)) + b"".join(entries) + b"".join(images))
    return output


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path, help="Directory containing AppIcon-16.png and the other sizes")
    parser.add_argument("--name", default="AppIcon", help="PNG prefix and output ICO name")
    args = parser.parse_args()
    try:
        print(make_ico(args.directory, args.name))
    except (OSError, ValueError) as error:
        parser.exit(1, f"Error: {error}\n")


if __name__ == "__main__":
    main()
