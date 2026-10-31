#!/usr/bin/env python
"""Release the legacy OMX node lock before delete this, in a generated copy.

Python 2/3 compatible. Pin the function rather than the whole platform file:
unrelated upstream updates pass through, but teardown changes require review.
"""

from __future__ import print_function

import hashlib
import os
import sys
import tempfile


FUNCTION_SHA256 = "594b4e4abd97cfb7a87d6d569727537b7e23894f5d7a0688342cc72739ab3014"
START = b"status_t OMXNodeInstance::freeNode(OMXMaster *master) {"
END = b"\nstatus_t OMXNodeInstance::sendCommand("


def fixup(source):
    if source.count(START) != 1 or source.count(END) != 1:
        raise ValueError("platform function layout changed; review OMX teardown")
    start = source.index(START)
    end = source.index(END, start)
    function = source[start:end]
    if hashlib.sha256(function).hexdigest() != FUNCTION_SHA256:
        raise ValueError("platform freeNode changed; review OMX teardown before building")

    # Include the existing conditional lock declaration in the new scope.
    scope_start = function.index(b"\n#ifndef ") + 1
    scope_end = function.index(b'    ALOGV("OMXNodeInstance going away.");')
    body = function[scope_start:scope_end].replace(
        b"    OMX_ERRORTYPE err = master->destroyComponentInstance(",
        b"    err = master->destroyComponentInstance(", 1)
    body = b"".join(b"    " + line if line.strip() and not line.startswith(b"#")
                    else line for line in body.splitlines(True))
    fixed = (function[:scope_start] + b"    OMX_ERRORTYPE err;\n    {\n" + body
             + b"    } // Release mLock before destroying the node.\n\n"
             + function[scope_end:])
    return source[:start] + fixed + source[end:]


def main(argv):
    if len(argv) != 3:
        raise ValueError("usage: fixup_free_node.py INPUT OUTPUT")
    source, destination = argv[1:]
    if os.path.realpath(source) == os.path.realpath(destination):
        raise ValueError("input and output must be different files")
    with open(source, "rb") as stream:
        result = fixup(stream.read())
    fd, temporary = tempfile.mkstemp(prefix=".omx-", dir=os.path.dirname(destination) or ".")
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(result)
        os.rename(temporary, destination)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


if __name__ == "__main__":
    try:
        main(sys.argv)
    except (IOError, OSError, ValueError) as error:
        sys.exit("LU5400 OMX fixup: " + str(error))
