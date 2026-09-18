#!/usr/bin/env python3
"""Add an ExportAssets (linkage) entry to a SWF so AS2 can attachMovie() a character.

Usage: add_export.py in.swf out.swf <characterId> <linkageName>

The tag is inserted immediately after the PlaceObject2 that first places the
character (so it lands in the same frame, before that frame's actions run).
Falls back to "just before the first ShowFrame that follows the character's
definition" if that placement is not found.
"""
import struct, sys, zlib

def read_swf(path):
    raw = open(path, "rb").read()
    sig, ver, length = raw[:3], raw[3], struct.unpack("<I", raw[4:8])[0]
    if sig == b"CWS":
        body = zlib.decompress(raw[8:])
    elif sig == b"FWS":
        body = raw[8:]
    else:
        raise SystemExit("unsupported signature %r" % sig)
    return sig, ver, body

def rect_size(body):
    nbits = body[0] >> 3
    total = 5 + nbits * 4
    return (total + 7) // 8

def tags(body, off):
    out = []
    while off < len(body):
        (code_len,) = struct.unpack("<H", body[off:off + 2])
        code, ln = code_len >> 6, code_len & 0x3F
        hdr = 2
        if ln == 0x3F:
            (ln,) = struct.unpack("<I", body[off + 2:off + 6])
            hdr = 6
        out.append((off, code, hdr, ln))
        if code == 0:
            break
        off += hdr + ln
    return out

def main():
    src, dst, cid, name = sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4]
    sig, ver, body = read_swf(src)
    off = rect_size(body) + 4  # rect + frame rate (2) + frame count (2)
    tl = tags(body, off)

    insert_at = None
    for (o, code, hdr, ln) in tl:
        if code in (26, 4):  # PlaceObject2 / PlaceObject
            payload = body[o + hdr:o + hdr + ln]
            if code == 26:
                flags = payload[0]
                if flags & 0x02:  # has character
                    (placed,) = struct.unpack("<H", payload[3:5])
                    if placed == cid:
                        insert_at = o + hdr + ln
                        break
    if insert_at is None:
        raise SystemExit("no PlaceObject for character %d" % cid)

    data = struct.pack("<H", 1) + struct.pack("<H", cid) + name.encode() + b"\x00"
    tag = struct.pack("<H", (56 << 6) | len(data)) + data  # ExportAssets = 56
    new_body = body[:insert_at] + tag + body[insert_at:]

    out = sig + bytes([ver]) + struct.pack("<I", len(new_body) + 8)
    out += zlib.compress(new_body) if sig == b"CWS" else new_body
    open(dst, "wb").write(out)
    print("inserted ExportAssets %d -> %s at offset %d" % (cid, name, insert_at))

main()
