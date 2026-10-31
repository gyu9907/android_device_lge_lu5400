#!/usr/bin/env python
"""Create the existing LU5400 IFT trailer, failing on every incomplete step."""
from __future__ import print_function
import glob
import os
import shutil
import subprocess
import sys
import tempfile

def main(image):
    root = os.path.dirname(os.path.abspath(__file__))
    work = tempfile.mkdtemp(prefix='lu5400-ift-')
    env = os.environ.copy()
    env['LD_LIBRARY_PATH'] = os.path.join(root, 'ift/lib/lib_linux_32b') + ':' + env.get('LD_LIBRARY_PATH', '')
    try:
        subprocess.check_call([os.environ.get('UNPACKBOOTIMG', 'unpackbootimg'), '-i', image, '-o', work])
        pieces = []
        certificates = []
        for suffix in ('-zImage', '-ramdisk.gz'):
            matches = glob.glob(os.path.join(work, '*' + suffix))
            if len(matches) != 1:
                raise ValueError('expected exactly one ' + suffix)
            piece = matches[0]
            signed = piece + '.signed'
            config = os.path.join(root, 'reference/hs2.2/ref-config')
            subprocess.check_call([os.path.join(root, 'ift/ift'), 'M', '-image',
                '-iswtype', 'MLO', '-out', signed,
                '-keycfg', os.path.join(config, 'key_m.cfg'),
                '-ppacfg', os.path.join(config, 'ppa_m.cfg'),
                '-iswcfg', os.path.join(config, 'isw_m.cfg'),
                '-isw', piece, '-ppa', os.path.join(root, 'reference/hs2.2/ref-ppa/ppa_ref.emu')], env=env)
            with open(signed, 'rb') as stream:
                data = stream.read()
            offset = data.find(b'CertISW')
            if offset < 0 or data.find(b'CertISW', offset + 1) >= 0 or len(data) < offset + 848:
                raise ValueError('missing or ambiguous 848-byte IFT certificate')
            certificates.append(data[offset:offset+848])
            pieces.append(piece)
        output = os.path.join(work, 'boot.img')
        # Preserve the established LG signing layout and empty cmdline.
        subprocess.check_call([os.environ.get('MKBOOTIMG', 'mkbootimg'), '--base', '0x80000000',
            '--cmdline', '', '--kernel', pieces[0], '--ramdisk', pieces[1], '-o', output])
        with open(output, 'ab') as stream:
            for certificate in certificates:
                stream.write(certificate)
        shutil.copyfile(output, image)
    finally:
        shutil.rmtree(work)

if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit('usage: signimg.py BOOT_IMAGE')
    main(sys.argv[1])
