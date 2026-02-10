# [getmural.me](https://getmural.me)

Please find the main documentation on https://getmural.me. 

## Development Setup

### Prerequisites
- VS Code with Dev Containers extension
- Docker Desktop
- [USBIPD-WIN](https://github.com/dorssel/usbipd-win/releases) (for Windows USB passthrough)

### Quick Start

1. **Open in Dev Container**
   - Press `F1` → `Dev Containers: Reopen in Container`
   - Wait for container build (first time takes a few minutes)

2. **Attach ESP32 (Windows)**
   ```powershell
   # List USB devices
   usbipd list
   
   # Attach ESP32 (replace 3-2 with your bus ID)
   usbipd attach --wsl --busid 3-2
   ```

3. **Build and Upload**
   ```bash
   # Build
   platformio run
   
   # Upload to ESP32
   platformio run --target upload --upload-port /dev/ttyUSB0
   ```

# Additional Information

## Positioning of the Drawing on the Wall

Here's how the image is prepared and drawn:

- The user defines the pin distance as part of the setup in the UI. For example 1 meter (or 1000mm). (This is d_pins in the image below.)
- The top margin is 20% of that distance, so the top of the image will be 200mm below the line between the two pins.
- Each side also has a 20% margin, so you'll get total of 60% of the horizontal distance, or 600mm.
- Now that we have the max width (600mm). The SVG is resized so its width is 600 and the height gets resized proportionally.
- Then a processing step is performed on the SVG to figure out what to actually draw, with each SVG unit being treated as millimeter.
- Finally it's converted into a simple format for Mural to draw, containing mostly its coordinate movement commands and pen up/down. This file is then uploaded to the microcontroller and executed line by line.

![image_positioning](/images/doc/muralbot_image_positioning.svg)

## Mural's Kinematic Model

Please find the kinematic model [here](KinematicModel.md).
