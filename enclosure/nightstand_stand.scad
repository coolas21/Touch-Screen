// Nightstand stand for the Hosyond 4.0" ESP32-32E touch panel (LCDwiki E32R40T).
//
// Three printed parts, styled after the Stream Deck desk stand (flat base,
// triangular supports, panel leaning back):
//   holder - tray the board drops into. USB notch in the side, window in the
//            back so the on-board RGB LED glows onto the base behind it.
//   bezel  - front frame, screwed on from the back with 4x M3 so no screws show.
//   stand  - base plate with a front ledge and two triangular fins. The
//            holder+bezel "pod" sits on the fins' pegs; it is not screwed down,
//            so it lifts off to reach the USB port or the BOOT/RESET buttons.
//
// Coordinates for the board are as seen from the FRONT (looking at the
// screen), from the board's bottom-left corner, with the panel in landscape.
// If you measure from the back, x_front = board_w - x_back.
//
// Render one part at a time (set `part`), then F6 and export STL.

part = "assembly"; // [assembly, holder, bezel, stand]

/* [Board: measure your board and check these first] */
board_w   = 111.11; // PCB outline, long side (LCDwiki)
board_h   = 60.88;  // PCB outline, short side (LCDwiki)
stack_front = 5.65; // back of PCB to front of the touch panel (LCDwiki "D")
rear_clear  = 9.0;  // tallest part on the back of the PCB (ESP32 module, USB-C, JST, buttons)
fit       = 0.4;    // clearance around the PCB on each side

active_w  = 83.52;  // lit area of the LCD (LCDwiki)
active_h  = 55.68;
active_x  = (board_w - active_w) / 2; // board left edge -> left edge of lit area (MEASURE)
active_y  = (board_h - active_h) / 2; // board bottom edge -> bottom edge of lit area (MEASURE)
window_margin = 0.8; // extra opening around the lit area on each side

/* [USB port] */
usb_side  = "both";    // [left, right, both] which short edge(s) get a notch
usb_y     = board_h/2; // port centre, from the board's bottom edge
usb_open_w = 13;       // notch width, sized for a USB-C plug's overmold
usb_open_h = 8;        // notch height below the board (rest is open to the bezel)
usb_center_below_pcb = 1.6; // port centreline below the back face of the PCB

/* [RGB LED window] */
led_x     = board_w/2; // window centre from board left edge (front view)
led_y     = board_h/2; // window centre from board bottom edge
led_win_w = 34;        // window size; big on purpose so it clears the LED
led_win_h = 20;        // even if the position above is a few mm off

/* [Holder and bezel] */
wall      = 8;     // border around the board (holds the bezel screws)
back_t    = 3;     // back plate thickness
corner_r  = 4;     // outer corner radius
pad       = 6.5;   // square corner pads the PCB rests on
bezel_t   = 4.5;   // bezel thickness
bezel_chamfer = 1.2;
screw_d   = 3.4;   // M3 clearance hole in the holder
screw_pilot = 2.5; // M3 self-tapping pilot in the bezel
screw_head_d = 6.2; // counterbore for an M3 pan/socket head
screw_len = 12;    // M3 x 12
screw_inset = 4.3; // hole centre from the outer edges

/* [Stand] */
tilt      = 60;    // panel angle from horizontal (Stream Deck look ~60)
base_t    = 5;     // base plate thickness
front_margin = 5;  // base plate in front of the ledge
rear_extend = 42;  // base plate behind the fins: this is where the LED glows
fin_t     = 8;     // fin thickness
fin_offset = 34;   // fin centre from the middle, left and right
fin_frac  = 0.75;  // how far up the pod the fins reach
peg_d     = 6;     // locating pegs on the fins
peg_h     = 2.4;
peg_fit   = 0.4;   // extra diameter on the holes in the holder

$fn = 48;
eps = 0.01;

// ---------- derived ----------
pocket_w = board_w + 2*fit;
pocket_h = board_h + 2*fit;
outer_w  = pocket_w + 2*wall;
outer_h  = pocket_h + 2*wall;
z_pcb    = back_t + rear_clear;      // back face of the PCB
holder_d = z_pcb + stack_front;      // holder rim is flush with the touch panel
pod_t    = holder_d + bezel_t;
bx0      = wall + fit;               // board origin inside the holder
by0      = wall + fit;
screw_pts = [for (x = [screw_inset, outer_w - screw_inset])
             for (y = [screw_inset, outer_h - screw_inset]) [x, y]];
cbore_depth = holder_d - (screw_len - (bezel_t - 0.9));
fin_len  = outer_h * fin_frac;
peg_v    = [outer_h * 0.28, fin_len - 9]; // peg positions up the slope
peg_x    = [outer_w/2 - fin_offset, outer_w/2 + fin_offset];

// ---------- helpers ----------
module rrect(w, h, r, t) {
    hull() for (x = [r, w - r]) for (y = [r, h - r])
        translate([x, y, 0]) cylinder(r = r, h = t);
}

// rounded slab with the top edge chamfered by c
module rrect_chamf(w, h, r, t, c) {
    hull() {
        rrect(w, h, r, t - c);
        translate([c, c, 0]) rrect(w - 2*c, h - 2*c, max(r - c, 0.5), t);
    }
}

module slot(w, h, t) { // rounded slot centred on the origin
    r = min(w, h) / 2;
    hull() for (d = [-(w/2 - r), w/2 - r])
        translate(w >= h ? [d, 0, 0] : [0, d * h / w, 0]) cylinder(r = r, h = t);
}

// ---------- holder ----------
module holder() {
    difference() {
        rrect(outer_w, outer_h, corner_r, holder_d);

        // pocket for the board, from the back plate up
        translate([wall, wall, back_t]) rrect(pocket_w, pocket_h, 1, holder_d);

        // LED window
        translate([bx0 + led_x, by0 + led_y, -eps]) slot(led_win_w, led_win_h, back_t + 2*eps);

        // USB notch, open to the rim (the bezel closes it from the front)
        usb_z = z_pcb - usb_center_below_pcb - usb_open_h/2;
        for (s = (usb_side == "both") ? [0, 1] : (usb_side == "left") ? [0] : [1])
            translate([s == 0 ? -eps : outer_w - wall - eps, by0 + usb_y - usb_open_w/2, usb_z])
                cube([wall + 2*eps, usb_open_w, holder_d]);

        // bezel screws from the back
        for (p = screw_pts) translate([p[0], p[1], 0]) {
            translate([0, 0, -eps]) cylinder(d = screw_d, h = holder_d + 2*eps);
            translate([0, 0, -eps]) cylinder(d = screw_head_d, h = cbore_depth + eps);
        }

        // holes for the stand's pegs
        for (x = peg_x) for (v = peg_v)
            translate([x, v, -eps]) cylinder(d = peg_d + peg_fit, h = back_t + 2*eps);
    }
    // corner pads the PCB rests on
    for (x = [bx0 - fit, bx0 + board_w + fit - pad])
        for (y = [by0 - fit, by0 + board_h + fit - pad])
            translate([x, y, back_t - eps]) cube([pad, pad, rear_clear + eps]);
}

// ---------- bezel (modelled in place: back face at z=0, front at z=bezel_t) ----------
module bezel() {
    ww = active_w + 2*window_margin;
    wh = active_h + 2*window_margin;
    wx = bx0 + active_x - window_margin;
    wy = by0 + active_y - window_margin;
    c  = bezel_chamfer;
    difference() {
        rrect_chamf(outer_w, outer_h, corner_r, bezel_t, c);
        // window with a 45 degree bevel opening toward the front
        hull() {
            translate([wx, wy, -eps]) cube([ww, wh, bezel_t - c + eps]);
            translate([wx - c, wy - c, bezel_t - c]) cube([ww + 2*c, wh + 2*c, c + eps]);
        }
        for (p = screw_pts)
            translate([p[0], p[1], -eps]) cylinder(d = screw_pilot, h = bezel_t - 0.9 + eps);
    }
}

// pod = holder + bezel in holder coordinates
module pod() {
    color("white") holder();
    color("whitesmoke") translate([0, 0, holder_d]) bezel();
}

// ---------- stand ----------
// World coordinates: x across, y toward the back, z up.
// The pod's back-bottom edge sits at (y = yB, z = base_t); its back face runs
// up and back at `tilt`, and its bottom face rests on the front ledge.
sa = sin(tilt); ca = cos(tilt);
yB = front_margin + pod_t * sa;
yA = yB + fin_len * ca;
zA = base_t + fin_len * sa;
base_d = yA + rear_extend;

// map pod coordinates (x, v up the slope, w out of the back face) to the world
module place_pod() {
    translate([0, yB, base_t]) multmatrix([[1, 0, 0, 0], [0, ca, -sa, 0], [0, sa, ca, 0], [0, 0, 0, 1]]) children();
}

module stand() {
    // base plate
    rrect_chamf(outer_w, base_d, 6, base_t, 1.5);

    // front ledge under the pod's bottom face
    translate([outer_w, 0, 0]) rotate([0, -90, 0])
        linear_extrude(outer_w)
            polygon([[base_t - eps, yB], [base_t + pod_t * ca, yB - pod_t * sa],
                     [base_t - eps, yB - pod_t * sa]]);

    // triangular fins
    for (x = peg_x)
        translate([x + fin_t/2, 0, 0]) rotate([0, -90, 0])
            linear_extrude(fin_t)
                polygon([[base_t - eps, yB], [zA, yA], [base_t - eps, yA]]);

    // locating pegs, normal to the slope
    place_pod() for (x = peg_x) for (v = peg_v)
        translate([x, v, -eps]) {
            cylinder(d = peg_d, h = peg_h - 0.6 + eps);
            translate([0, 0, peg_h - 0.6]) cylinder(d1 = peg_d, d2 = peg_d - 1.2, h = 0.6);
        }
}

// ---------- output ----------
if (part == "holder") holder();
else if (part == "bezel") translate([0, outer_h, bezel_t]) rotate([180, 0, 0]) bezel(); // face down
else if (part == "stand") stand();
else {
    color("white") stand();
    place_pod() pod();
}
