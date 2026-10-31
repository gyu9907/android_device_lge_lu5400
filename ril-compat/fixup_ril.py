#!/usr/bin/env python
"""Make the verified LG CRT destructor PIC; leave original vendor blobs intact."""
from __future__ import print_function
import hashlib
import struct
import sys

BLOBS = {
    '8b68a6d3d613aa06fafa9603cc69ff9c07b9693d6fd67be57d503b37ba3db0da': (0x5698, 0x29a10),
    '5cdaf4c8cb30f19d0f9689db61f8dc5cf7ee9ed0bab7d16af6def12dd4029bf2': (0x8b8, 0x2130),
    '3401bcf7a327d5605378d20b887a0ceac8f179759fec6e5d0a3f1faeb8cbe840': (0x9e0, 0x2150),
    'f126cd5aad4058f50ce7ba612f672bcb330c34de6115e3a71447a3df14a6b539': (0x3080, 0xc6f0),
}

def fixup(original):
    sha = hashlib.sha256(original).hexdigest()
    if sha not in BLOBS:
        raise ValueError('unexpected LG RIL input SHA-256')
    data = bytearray(original)
    entry, handle = BLOBS[sha]
    h = struct.unpack_from('<16sHHIIIIIHHHHHH', data)
    if h[0][:7] != b'\x7fELF\x01\x01\x01' or h[1:3] != (3, 40):
        raise ValueError('expected ARM ELF32 DSO')
    ph = [struct.unpack_from('<8I', data, h[5] + i*h[9]) for i in range(h[10])]
    def offset(addr):
        segs = [p for p in ph if p[0] == 1 and p[2] <= addr < p[2]+p[4]]
        if len(segs) != 1: raise ValueError('unmapped ELF address')
        return segs[0][1] + addr - segs[0][2]
    dyn = [p for p in ph if p[0] == 2][0]
    entries = []
    for pos in range(dyn[1], dyn[1]+dyn[4], 8):
        tag, val = struct.unpack_from('<II', data, pos)
        if tag == 0: break
        entries.append((tag, val))
    tags = dict(entries)
    if tags[19] != 8: raise ValueError('unexpected relocation size')
    relpos, relsize = offset(tags[17]), tags[18]
    rels = [struct.unpack_from('<II', data, p) for p in range(relpos, relpos+relsize, 8)]
    readonly = []
    for addr, info in rels:
        seg = [p for p in ph if p[0] == 1 and p[2] <= addr < p[2]+p[5]][0]
        if not seg[6] & 2: readonly.append((addr, info))
    literal = entry+12
    if readonly != [(literal, 23)] or rels[0] != (literal, 23):
        raise ValueError('unexpected text relocation layout')
    code = offset(entry)
    words = struct.unpack_from('<4I', data, code)
    if words[0:2] != (0xe28f0004, 0xe5900000) or words[3] != handle or words[2] >> 24 != 0xea:
        raise ValueError('unexpected CRT destructor instructions')
    # ldr r0,[pc,#4]; add r0,pc,r0; b __cxa_finalize@plt; relative handle
    # ARM PC at the ADD is entry+12. No runtime write to RX memory remains.
    struct.pack_into('<4I', data, code, 0xe59f0004, 0xe08f0000, words[2], handle-literal)
    data[relpos:relpos+relsize] = data[relpos+8:relpos+relsize] + b'\0'*8
    updated = []
    for tag, val in entries:
        if tag == 22: continue  # DT_TEXTREL, now no read-only relocations
        if tag == 18: val -= 8
        if tag == 0x6ffffffa: val -= 1  # DT_RELCOUNT
        if tag == 30: val &= ~4  # DF_TEXTREL only
        updated.append((tag, val))
    packed = b''.join(struct.pack('<II', *e) for e in updated)
    data[dyn[1]:dyn[1]+dyn[4]] = packed + b'\0'*(dyn[4]-len(packed))
    # Keep readelf/debugger section metadata consistent with DT_RELSZ.
    for i in range(h[12]):
        pos = h[6] + i*h[11]
        sh = struct.unpack_from('<10I', data, pos)
        if sh[1] == 9 and sh[4] == relpos:
            if sh[5] != relsize: raise ValueError('relocation section size mismatch')
            struct.pack_into('<I', data, pos+20, relsize-8)
    return data

if __name__ == '__main__':
    if len(sys.argv) != 3 or sys.argv[1] == sys.argv[2]:
        sys.exit('usage: fixup_ril.py INPUT OUTPUT (distinct paths)')
    with open(sys.argv[1], 'rb') as f: result = fixup(f.read())
    with open(sys.argv[2], 'wb') as f: f.write(result)
