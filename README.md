# Bedroom Touch Panel

ESPHome + LVGL wall panel for Home Assistant on the **Hosyond 4.0" ESP32-32E**
(ESP32-D0WD-V3, 4 MB flash, no PSRAM, ST7796S 320x480 SPI LCD, XPT2046 resistive touch).
Hardware reference: <https://www.lcdwiki.com/4.0inch_ESP32-32E_Display>

## Screens (landscape 480x320, tabs along the bottom)

| Tab | What it does |
|---|---|
| **Home** | Clock and date, outside temperature and weather, Bedroom / Living / Upstairs temperatures, and buttons for the bedroom Lamps, Bed LED and Fan (lit when on). |
| **Scenes** | **Good Night**: closes Garage 1-3, all lights off except the Bathroom LED, front door and back porch, kitchen WLED to the red nightlight. **Movie**: dining room off at once while Living Room Dimmer 1 (Dimmer 2 follows via its device group) fades from its current level to 1% over 1.5 s, then off (stays off if already off; kitchen and foyer untouched). **All Off** (asks first): all lights off except the Bathroom LED, front door, back porch and kitchen WLED. Scripts are in `home-assistant/bedroom_panel.yaml`. |
| **Doors** | Garage 1/2/3: tap to open or close, with a confirmation step. Shop, Mower and Chicken doors show status only. Green = closed, red = open. |
| **Cams** | Front Door and Driveway buttons show the **last picture HA stored** for that camera instantly, filling the left side of the screen, with the camera name and the time it was taken on the right. The pop-up also **opens automatically** when the doorbell rings or a person is seen on the driveway, waits up to 15 s for HA's fresh picture, and closes after 30 s or on tap. |
| **Reset** | Restarts flaky Tasmota devices (BedLED, Shop Lights Int/Ext, ShopOS, Chicken Door, Pool). Sends `Restart 1` **directly to the device over HTTP**, so it works even if Home Assistant or MQTT is down. The dot shows online (green) or offline (red) as Home Assistant sees it. Every restart asks for confirmation. |
| **Setup** | **Display** brightness, **Dark Mode** (dark navy theme; off = white look) and **Auto at night** (dark from sunset to sunrise), accent light (**LED On / Off**, brightness, Warm/Teal/Blue/Purple, Breathe), Wi-Fi signal, IP address. |

The screen dims after 1 minute and turns off after 5 minutes. Once it has dimmed, the **first tap only wakes it** to full brightness, and the next tap selects.
A red **No HA** badge shows in the top-right corner when the panel isn't connected to Home Assistant. The board's RGB LED is an **accent light** (Setup tab or the "Accent Light" entity in HA).

## Files

- `esphome/bedroom-panel.yaml`: the device config.
- `esphome/secrets.example.yaml`: the secret names it expects.
- `home-assistant/bedroom_panel.yaml`: the three scene scripts (goes in `/config/packages/`).

## First-time setup

1. **Secrets:** in the ESPHome dashboard, click **SECRETS** and fill in `wifi_password`
   (the panel's API key and OTA password are already generated there).
2. **Build:** open the `bedroom-panel` card, then **⋮ → Install → Manual download → Factory format**.
3. **Flash over USB (first time only):** plug the board into your computer, open
   <https://web.esphome.io> in Chrome or Edge, click **Connect**, pick the CH340 port, then **Install** and choose the downloaded `.bin`.
   If it won't connect, hold **BOOT** while tapping **RESET**.
   After this, updates go over Wi-Fi from the dashboard.
4. **Add to Home Assistant:** it shows up under *Settings → Devices & services* as discovered. Click **Configure**.
5. **Allow actions (required):** *Settings → Devices & services → ESPHome → Bedroom Panel → ⚙ Configure* →
   turn on **"Allow the device to perform Home Assistant actions"**. Without this, the scene, door and light buttons do nothing.

## If the picture or touch is off

- **Mirrored or upside down:** in `display: transform:`, flip `mirror_x` and/or `mirror_y`.
- **Colours look negative:** toggle `invert_colors`. If **red and blue are swapped**, change `color_order` to `rgb`.
- **Touch is in the wrong place:** open the device **LOGS** in the ESPHome dashboard, then tap the
  four corners. Each tap logs `touch x=.. y=.. raw_x=.. raw_y=..`. Put the smallest and largest
  raw values into `touchscreen: calibration:` (`x_min/x_max/y_min/y_max`). If touches follow your finger
  in the wrong direction, flip the touch `transform` `mirror_x` / `mirror_y`.

## Changing things

- **Scene contents:** edit the scripts in `home-assistant/bedroom_panel.yaml` (no reflash needed).
- **Reset list:** each device is an `rst_*` script (IP address) plus a button and dot on the Reset tab.

## Memory note

This board has no PSRAM. The LVGL draw buffer is 12% so a 240x147 snapshot fits.
HA shows **Free Memory** and **Largest Free Block** sensors for the panel. If snapshots
fail with "No picture yet", check those first.

## Camera snapshots

Eufy's saved event thumbnails can't be decoded outside the Eufy app, and its
full photos are 100-300 KB, far too big for this board's RAM. So HA keeps its
own small copy of each camera's latest picture. When the doorbell rings or a
person is seen at the front door, or a person or vehicle is seen on the
driveway, `script.panel_cam_snapshot`:
1. captures a fresh live frame through the Eufy add-on (`eufy_event_gateway.capture_snapshot`),
2. repairs and shrinks it with `home-assistant/panel_snapshot.py` (ffmpeg) to a ~5 KB
   baseline JPEG of about 19,000 pixels, with red and blue swapped (the BGR panel
   draws photos with them reversed),
3. replaces `door.jpg` / `drive.jpg` in a random folder under `/config/www` (the old
   picture stays until the new one is complete),
4. writes the time into `input_text.panel_cam_door_time` / `panel_cam_drive_time`.
   The panel watches those, so an open pop-up switches to the new picture at once.

The panel scales the picture up (LVGL `LV_IMAGE_ALIGN_CONTAIN`) to fill a 330x320 box.

Setup: copy `panel_snapshot.py` to `/config/`, create `/config/www/panel_<random>/`,
put the same random name in `bedroom_panel.yaml` and in ESPHome `secrets.yaml`
(`panel_cam_path`).
