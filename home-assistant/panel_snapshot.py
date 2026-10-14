"""Repair + shrink a Eufy camera snapshot for the bedroom ESPHome panel.

Eufy snapshots are 95-290 KB and their second quantization table (DQT) is a
few bytes shorter than its declared length. Browsers tolerate that, but
ffmpeg / Pillow / the panel's JPEGDEC reject the file. This pads every short
DQT segment, then uses ffmpeg to write a small baseline JPEG.

Usage: python3 panel_snapshot.py <folder> <name>
  reads  <folder>/<name>_full.jpg, writes <folder>/<name>_0.jpg .. _N.jpg
  (horizontal strips) and prints "WxHxN" for the panel.

Strips are only replaced once all new ones are written, so the panel can
always download the last good picture.
"""
import os
import struct
import subprocess
import sys

folder, name = sys.argv[1], sys.argv[2]
src = f"{folder}/{name}_full.jpg"
fixed = f"{folder}/{name}_fixed.jpg"

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
# The panel has no PSRAM, so it can't hold a full-size picture at once (and
# LVGL scaling garbles it). Instead the picture is sized to fill the 330x320
# box on the panel at full resolution and cut into strips 48 rows tall
# (<= ~32 KB decoded each). The panel downloads and paints them one by one.
# Red and blue are swapped because the panel's display (BGR) draws photos
# with them reversed; 4:2:0 because its JPEG decoder rejects 4:4:4.
BOX_W, BOX_H, STRIP = 330, 320, 48
big = f"{folder}/{name}_big.png"
subprocess.run(
    ["ffmpeg", "-y", "-loglevel", "error", "-i", fixed,
     "-vf", f"scale={BOX_W}:{BOX_H}:force_original_aspect_ratio=decrease,"
            "scale=trunc(iw/2)*2:trunc(ih/2)*2,"
            "colorchannelmixer=rr=0:rb=1:bb=0:br=1",
     big],
    check=True,
)
probe = subprocess.run(
    ["ffprobe", "-v", "error", "-show_entries", "stream=width,height",
     "-of", "csv=p=0", big],
    check=True, capture_output=True, text=True,
).stdout.strip().split(",")
w, h = int(probe[0]), int(probe[1])
n = (h + STRIP - 1) // STRIP
for i in range(n):
    rows = min(STRIP, h - i * STRIP)
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", big,
         "-vf", f"crop={w}:{rows}:0:{i * STRIP},format=yuvj420p",
         "-q:v", "4", f"{folder}/{name}_{i}_new.jpg"],
        check=True,
    )
for i in range(n):
    os.replace(f"{folder}/{name}_{i}_new.jpg", f"{folder}/{name}_{i}.jpg")
os.remove(big)
# geometry for the panel: width x height x strips
print(f"{w}x{h}x{n}")
