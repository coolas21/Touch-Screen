# Nightstand stand

A desk stand for the Hosyond 4.0" ESP32-32E panel, styled like the Stream Deck stand: a flat base,
two triangular fins, and the screen in landscape leaning back at 60°. The board's RGB LED shines
through a window in the back and lights up the white base behind the screen.

| Front | Back |
|---|---|
| ![front](preview_front.png) | ![back](preview_back.png) |

## Parts

| File | Print orientation | Notes |
|---|---|---|
| `stl/holder.stl` | back plate on the bed | Tray the board drops into. USB-C opening in the right side, LED window in the back, 4 corner pads the PCB rests on. |
| `stl/bezel.stl` | face down | Front frame. Screwed on from the back, so no screws show on the front. |
| `stl/stand.stl` | as exported (base on the bed) | Base, front ledge, and two fins with locating pegs. |

White PLA, 0.2 mm layers, 3 walls, 15-20% infill. No supports needed.

**Hardware:** 4 × M3 × 12 screws (pan or socket head), self-tapping straight into the bezel.
Stick your rubber pads anywhere on the flat bottom of the base.

## Board measurements

The model is set to these measurements from the real board (front view, screen in landscape,
USB-C on the right). They're the parameters at the top of `nightstand_stand.scad`. Change them and
re-export the STLs if anything is off (OpenSCAD: set `part`, F6, File → Export → STL).

| What | Measured | Parameter |
|---|---|---|
| PCB outline | 111.11 × 60.88 mm (LCDwiki) | `board_w`, `board_h` |
| Lit screen area | 83 × 55 mm, 12 mm from the left edge, 3 mm from the top | `active_*` |
| USB-C port | Right edge, centred, on the back of the PCB, 3 mm tall. The opening is 15 × 8 mm, centred on the port, for the plug housing. | `usb_*` |
| Tallest part on the back | 5 mm (the holder allows 5.5) | `rear_clear` |
| RGB LED | 52 mm from the right edge, 31 mm from the top. The back window is a 34 × 20 mm slot centred on it. | `led_*` |

## Assembly

1. Drop the board into the holder, screen up. It rests on the four corner pads.
2. Put the bezel on and screw it down from the back with the 4 M3 screws.
3. Set the assembled screen on the stand: the bottom edge sits on the front ledge and the
   four pegs on the fins go into the holes in the back. It isn't screwed down, so you can lift it
   off to get at the USB port or the BOOT/RESET buttons. A dab of glue or double-sided tape on
   the pegs makes it permanent.
4. A right-angle USB-C cable keeps the side tidy.

## Tweaking

- `tilt`: screen angle from horizontal (60° matches the Stream Deck).
- `rear_extend`: how far the base reaches behind the screen (the glow area).
- `wall`: bezel border width.
- If the board rattles, put a strip of thin foam tape on the corner pads.
- If the bezel presses on the edge of the touch panel and causes stray touches, increase
  `window_margin` or add 0.2-0.3 mm to `stack_front`.
