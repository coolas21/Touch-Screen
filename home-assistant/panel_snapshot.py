"""Repair + shrink a Eufy camera snapshot for the bedroom ESPHome panel.

Eufy snapshots are 95-290 KB and their second quantization table (DQT) is a
few bytes shorter than its declared length. Browsers tolerate that, but
ffmpeg / Pillow / the panel's JPEGDEC reject the file. This pads every short
DQT segment, then uses ffmpeg to write a small baseline JPEG.

Usage: python3 panel_snapshot.py <folder> <name>
  reads  <folder>/<name>_full.jpg, writes <folder>/<name>.jpg
"""
import struct
import subprocess
import sys

folder, name = sys.argv[1], sys.argv[2]
src = f"{folder}/{name}_full.jpg"
fixed = f"{folder}/{name}_fixed.jpg"
out = f"{folder}/{name}.jpg"

data = open(src, "rb").read()

# Right at a doorbell/person event the add-on may hand back Eufy's 288x176
# event thumbnail (which can't be decoded) instead of a live frame. Exit 3 so
# the HA script captures again.
_i = 2
while _i < len(data) - 9:
    if data[_i] == 0xFF and data[_i + 1] in (0xC0, 0xC2):
        if (data[_i + 7] << 8 | data[_i + 8]) <= 320:
            sys.exit(3)
        break
    _i += 1
res = bytearray(data[:2])  # SOI
i = 2
while i < len(data) - 3:
    if data[i] != 0xFF:
        break
    marker = data[i + 1]
    seg_len = struct.unpack(">H", data[i + 2:i + 4])[0]
    if marker == 0xDA:  # start of scan: copy the rest unchanged
        res += data[i:]
        break
    end = i + 2 + seg_len
    # find where the next marker really starts
    nxt = data.find(b"\xff", i + 4)
    while nxt != -1 and data[nxt + 1] == 0xFF:
        nxt += 1
    if marker == 0xDB and nxt != -1 and nxt < end:
        body = data[i + 4:nxt]
        body += bytes([body[-1]]) * (end - nxt)  # pad the short table
        res += data[i:i + 4] + body
        i = nxt
        continue
    res += data[i:end]
    i = end

open(fixed, "wb").write(bytes(res))
subprocess.run(
    ["ffmpeg", "-y", "-loglevel", "error", "-i", fixed,
     "-vf", "scale=trunc(sqrt(19000*iw/ih)/2)*2:-2", "-q:v", "6", out],
    check=True,
)
