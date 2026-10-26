#!/usr/bin/env python3
"""Package a macOS iconset's PNGs into an ICNS container."""
import struct
import sys
from pathlib import Path

CHUNKS = (
    (b"icp4", "icon_16x16.png", 16),
    (b"icp5", "icon_32x32.png", 32),
    (b"icp6", "icon_32x32@2x.png", 64),
    (b"ic07", "icon_128x128.png", 128),
    (b"ic08", "icon_256x256.png", 256),
    (b"ic09", "icon_512x512.png", 512),
    (b"ic10", "icon_512x512@2x.png", 1024),
)


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("Usage: assemble-icns.py ICONSET_DIR OUTPUT.icns")
    iconset = Path(sys.argv[1])
    output = Path(sys.argv[2])
    payload = bytearray()
    for chunk_type, filename, expected_size in CHUNKS:
        image = (iconset / filename).read_bytes()
        if image[:8] != b"\x89PNG\r\n\x1a\n":
            raise SystemExit(f"{filename} is not a PNG")
        width, height = struct.unpack(">II", image[16:24])
        if (width, height) != (expected_size, expected_size):
            raise SystemExit(f"{filename} must be {expected_size}x{expected_size}")
        payload.extend(struct.pack(">4sI", chunk_type, len(image) + 8))
        payload.extend(image)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(b"icns" + struct.pack(">I", len(payload) + 8) + payload)


if __name__ == "__main__":
    main()
