#!/usr/bin/env python
"""Redirect the verified ICS camera's libexif dependency to device-local jhead.

Works with the Android build's Python 2 as well as Python 3. Only the generated
copy is changed; the vendor blob remains identical to proprietary-files.txt.
"""

from __future__ import print_function

import hashlib
import struct
import sys


def fixup(data, expected_sha1):
    if hashlib.sha1(data).hexdigest() != expected_sha1:
        raise ValueError("camera blob SHA-1 does not match proprietary-files.txt")
    if data[:7] != b"\x7fELF\x01\x01\x01":
        raise ValueError("expected a little-endian ELF32 camera library")
    if struct.unpack_from("<H", data, 18)[0] != 40:
        raise ValueError("expected an ARM camera library")

    phoff = struct.unpack_from("<I", data, 28)[0]
    phsize, phnum = struct.unpack_from("<HH", data, 42)
    segments = [struct.unpack_from("<8I", data, phoff + i * phsize)
                for i in range(phnum)]
    dynamic = [p for p in segments if p[0] == 2]  # PT_DYNAMIC
    if len(dynamic) != 1:
        raise ValueError("expected one dynamic segment")

    entries = []
    segment = dynamic[0]
    for offset in range(segment[1], segment[1] + segment[4], 8):
        tag, value = struct.unpack_from("<II", data, offset)
        if tag == 0:  # DT_NULL
            break
        entries.append((tag, value))
    strtabs = [value for tag, value in entries if tag == 5]  # DT_STRTAB
    if len(strtabs) != 1:
        raise ValueError("expected one dynamic string table")
    address = strtabs[0]
    loads = [p for p in segments
             if p[0] == 1 and p[2] <= address < p[2] + p[4]]
    if len(loads) != 1:
        raise ValueError("dynamic string table is not file-backed")
    strtab = loads[0][1] + address - loads[0][2]

    old = b"libexif.so\x00"
    new = b"libjex.so\x00"
    matches = [strtab + value for tag, value in entries
               if tag == 1 and data[strtab + value:strtab + value + len(old)] == old]
    if len(matches) != 1:
        raise ValueError("expected exactly one libexif.so DT_NEEDED entry")
    offset = matches[0]
    return data[:offset] + new.ljust(len(old), b"\x00") + data[offset + len(old):]


def main(argv):
    if len(argv) != 4:
        raise ValueError("usage: fixup_camera.py INPUT OUTPUT proprietary-files.txt")
    source, destination, manifest = argv[1:]
    if source == destination:
        raise ValueError("input and output must be different files")
    with open(manifest) as stream:
        hashes = [line.strip().split("|", 1)[1] for line in stream
                  if line.startswith("lib/hw/camera.omap4.so|")]
    if len(hashes) != 1:
        raise ValueError("expected one camera hash in proprietary-files.txt")
    with open(source, "rb") as stream:
        result = fixup(stream.read(), hashes[0])
    with open(destination, "wb") as stream:
        stream.write(result)


if __name__ == "__main__":
    try:
        main(sys.argv)
    except (IOError, ValueError, struct.error) as error:
        sys.exit("LU5400 camera fixup: " + str(error))
