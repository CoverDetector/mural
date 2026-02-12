# Flashing ESP32 Without PlatformIO

Quick guide to flash the Mural ESP32 project without using PlatformIO.

---

## 🚀 Windows Users - Super Simple!

**If you have the pre-built binaries in `mural_binaries/` folder:**

1. Connect your ESP32 via USB
2. Double-click `mural_binaries/flash_esp32.bat`
3. Select your COM port when prompted
4. Wait for flashing to complete
5. Press RESET on your ESP32

**That's it!** The script automatically:
- ✅ Auto-installs Python if missing (using Windows Package Manager)
- ✅ Installs esptool automatically
- ✅ Detects your ESP32 COM port
- ✅ Flashes all 4 binary files at correct addresses

**If upload fails:** Hold the BOOT button on your ESP32 and try again.

**Note:** On first run, if Python is installed automatically, you may need to run the script twice (once to install Python, once to flash).

---

## 📦 Required Binary Files

You need these 4 files in `mural_binaries/` folder:

| File | Flash Address | Size | Description |
|------|---------------|------|-------------|
| **bootloader.bin** | 0x1000 | 18KB | ESP32 bootloader |
| **partitions.bin** | 0x8000 | 3KB | Partition table |
| **firmware.bin** | 0x10000 | 1.1MB | Main application |
| **littlefs.bin** | 0x13C000 | 2.8MB | Web interface files |

---

## ⚡ Linux/macOS - Quick Start

**If you have pre-built binaries:**

1. **Install esptool:**
   ```bash
   pip install esptool
   ```

2. **Flash all binaries** (replace `/dev/ttyUSB0` with your port):
   ```bash
   esptool.py --chip esp32 --port /dev/ttyUSB0 --baud 460800 \
     --before default_reset --after hard_reset write_flash -z \
     --flash_mode dio --flash_freq 80m --flash_size 4MB \
     0x1000 bootloader.bin \
     0x8000 partitions.bin \
     0x10000 firmware.bin \
     0x13C000 littlefs.bin
   ```

3. **Done!** Press RESET on your ESP32.

### Finding Your Serial Port

- **Linux:** `/dev/ttyUSB0` or `/dev/ttyACM0` - use `ls /dev/tty* | grep -E "(USB|ACM)"`
- **macOS:** `/dev/cu.usbserial-*` - use `ls /dev/cu.*`
- **Windows:** `COM3`, `COM4`, etc. - Check Device Manager → Ports (COM & LPT)

---

## 🔧 Building Binaries From Source

If you need to build the binaries yourself:

## 🔧 Building Binaries From Source

If you need to build the binaries yourself:

### Using PlatformIO (Recommended)

```bash
# 1. Build TypeScript worker
cd tsc
npm install
npm run build
cd ..

# 2. Build firmware
pio run

# 3. Build filesystem
pio run --target buildfs
```

Binaries will be in `.pio/build/esp32dev/`:
- `bootloader.bin`
- `partitions.bin`
- `firmware.bin`
- `littlefs.bin`

Then use the flashing methods above to upload.

---

## 🛠️ Troubleshooting

### Python Installation (Windows)
If automatic Python installation fails:
- **Manual install:** Download from [python.org/downloads](https://www.python.org/downloads/)
- **Important:** Check "Add Python to PATH" during installation
- **No winget?** Windows Package Manager comes with Windows 11; for Windows 10, update via Microsoft Store
- **After manual install:** Close all terminals and run the script again

### Upload Fails
- **Hold BOOT button** on ESP32 during upload
- **Try lower baud rate:** Change `460800` to `115200`
- **Check USB cable:** Must support data transfer (not just power)
- **Verify port:** Make sure no other program is using the port

### Web Interface Not Loading
- Verify `littlefs.bin` was flashed correctly at address `0x13C000`
- Check serial output for filesystem mount errors
- Make sure filesystem size matches partition table (2800KB)

### Permission Denied (Linux)
```bash
sudo usermod -a -G dialout $USER
# Log out and back in
```

---

## 📋 Complete Flash Layout Reference

Based on `partitions.csv`:

| Name | Type | Address | Size | What to Flash |
|------|------|---------|------|---------------|
| bootloader | - | 0x1000 | 16KB | ✅ bootloader.bin |
| partitions | - | 0x8000 | 3KB | ✅ partitions.bin |
| nvs | data | 0x9000 | 24KB | Auto-managed |
| phy_init | data | 0xF000 | 4KB | Auto-managed |
| factory | app | 0x10000 | 1200KB | ✅ firmware.bin |
| spiffs | data | 0x13C000 | 2800KB | ✅ littlefs.bin |

**You only flash 4 files.** NVS and phy_init are managed automatically by ESP32.

---

## ⚙️ Quick Reference

### Flash All (Complete Install)
```bash
esptool.py --chip esp32 --port COM3 --baud 460800 write_flash -z \
  0x1000 bootloader.bin \
  0x8000 partitions.bin \
  0x10000 firmware.bin \
  0x13C000 littlefs.bin
```

### Flash Firmware Only (Quick Update)
```bash
esptool.py --chip esp32 --port COM3 --baud 460800 write_flash \
  0x10000 firmware.bin
```

### Flash Filesystem Only (Web Files Update)
```bash
esptool.py --chip esp32 --port COM3 --baud 460800 write_flash \
  0x13C000 littlefs.bin
```

### Erase Everything
```bash
esptool.py --chip esp32 --port COM3 erase_flash
```

---

## 📚 Additional Resources

## 📚 Additional Resources

- [esptool.py documentation](https://docs.espressif.com/projects/esptool/en/latest/)
- [Arduino ESP32 core](https://github.com/espressif/arduino-esp32)
- [ESP32 partition tables](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-guides/partition-tables.html)
- [LittleFS for ESP32](https://github.com/lorol/LITTLEFS)
