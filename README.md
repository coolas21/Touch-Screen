# Bedroom Touch Panel

ESPHome + LVGL wall panel for Home Assistant on the **Hosyond 4.0" ESP32-32E**
(ESP32-D0WD-V3, 4 MB flash, no PSRAM, ST7796S 320x480 SPI LCD, XPT2046 resistive touch).
Hardware reference: <https://www.lcdwiki.com/4.0inch_ESP32-32E_Display>

## Screens (landscape 480x320, tabs along the bottom)

| Tab | What it does |
|---|---|
| **Home** | Clock and date, outside temperature and weather, Bedroom / Living / Upstairs temperatures, and buttons for the bedroom Lamps, Bed LED and Fan (lit when on). |
| **Scenes** | Good Night, Movie, All Off (Home Assistant scripts in `home-assistant/bedroom_panel.yaml`). |
| **Doors** | Garage 1/2/3: tap to open or close, with a confirmation step. Shop, Mower and Chicken doors show status only. Green = closed, red = open. |
| **Reset** | Restarts flaky Tasmota devices (BedLED, Shop Lights Int/Ext, ShopOS, Chicken Door, Pool). Sends `Restart 1` **directly to the device over HTTP**, so it works even if Home Assistant or MQTT is down. The dot shows online (green) or offline (red) as Home Assistant sees it. Every restart asks for confirmation. |
| **Setup** | Screen brightness slider, Wi-Fi signal, IP address. |

The screen dims after 1 minute and turns off after 5 minutes. A touch wakes it, and the wake-up touch never presses a button.
The board's RGB LED turns **red** when the panel isn't connected to Home Assistant.

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
