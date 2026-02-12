# ESP32 Flash Script for Windows
# This script checks for Python, installs esptool, and flashes the ESP32 firmware

Write-Host "=== ESP32 Firmware Flash Script ===" -ForegroundColor Cyan
Write-Host ""

# Function to check if a command exists
function Test-CommandExists {
    param($command)
    $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
}

# Step 1: Check for Python
Write-Host "Step 1: Checking for Python..." -ForegroundColor Yellow
if (Test-CommandExists python) {
    $pythonVersion = python --version
    Write-Host "Python is installed: $pythonVersion" -ForegroundColor Green
} else {
    Write-Host "Python is not installed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Attempting to install Python automatically..." -ForegroundColor Yellow
    
    # Try to install Python using winget (Windows Package Manager)
    if (Test-CommandExists winget) {
        Write-Host "Installing Python using Windows Package Manager..." -ForegroundColor Cyan
        winget install --id Python.Python.3.12 --silent --accept-source-agreements --accept-package-agreements
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Python installed successfully!" -ForegroundColor Green
            Write-Host "Refreshing environment variables..." -ForegroundColor Yellow
            
            # Refresh PATH environment variable
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            
            # Verify installation
            Start-Sleep -Seconds 2
            if (Test-CommandExists python) {
                $pythonVersion = python --version
                Write-Host "Python verified: $pythonVersion" -ForegroundColor Green
            } else {
                Write-Host "Python installed but not in PATH yet." -ForegroundColor Yellow
                Write-Host "Please close this window and run the script again." -ForegroundColor Yellow
                pause
                exit 1
            }
        } else {
            Write-Host "Automatic installation failed." -ForegroundColor Red
            Write-Host ""
            Write-Host "Please install Python manually from https://www.python.org/downloads/" -ForegroundColor Yellow
            Write-Host "Make sure to check 'Add Python to PATH' during installation!" -ForegroundColor Yellow
            Start-Process "https://www.python.org/downloads/"
            pause
            exit 1
        }
    } else {
        Write-Host "Windows Package Manager (winget) not found." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Please install Python manually from https://www.python.org/downloads/" -ForegroundColor Yellow
        Write-Host "Make sure to check 'Add Python to PATH' during installation!" -ForegroundColor Yellow
        Write-Host ""
        $response = Read-Host "Would you like to open the Python download page? (Y/N)"
        if ($response -eq "Y" -or $response -eq "y") {
            Start-Process "https://www.python.org/downloads/"
        }
        Write-Host ""
        Write-Host "After installing Python, please run this script again." -ForegroundColor Yellow
        pause
        exit 1
    }
}

# Step 2: Check and install esptool
Write-Host ""
Write-Host "Step 2: Checking for esptool..." -ForegroundColor Yellow
$esptoolInstalled = $false
try {
    $esptoolVersion = python -m esptool version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "esptool is already installed" -ForegroundColor Green
        $esptoolInstalled = $true
    }
} catch {
    $esptoolInstalled = $false
}

if (-not $esptoolInstalled) {
    Write-Host "Installing esptool..." -ForegroundColor Yellow
    python -m pip install --upgrade pip
    python -m pip install esptool
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "esptool installed successfully" -ForegroundColor Green
    } else {
        Write-Host "Failed to install esptool" -ForegroundColor Red
        pause
        exit 1
    }
}

# Step 3: Check for binary files
Write-Host ""
Write-Host "Step 3: Checking for binary files..." -ForegroundColor Yellow
$binariesPath = "$PSScriptRoot"
$requiredFiles = @(
    @{Name="bootloader.bin"; Address="0x1000"},
    @{Name="partitions.bin"; Address="0x8000"},
    @{Name="firmware.bin"; Address="0x10000"},
    @{Name="littlefs.bin"; Address="0x13C000"}
)

$allFilesExist = $true
foreach ($file in $requiredFiles) {
    $filePath = Join-Path $binariesPath $file.Name
    if (Test-Path $filePath) {
        $fileSize = [math]::Round((Get-Item $filePath).Length / 1KB, 1)
        Write-Host "  Found: $($file.Name) - ${fileSize}KB at $($file.Address)" -ForegroundColor Green
    } else {
        Write-Host "  Missing: $($file.Name)" -ForegroundColor Red
        $allFilesExist = $false
    }
}

if (-not $allFilesExist) {
    Write-Host ""
    Write-Host "Error: Some binary files are missing from: $binariesPath" -ForegroundColor Red
    pause
    exit 1
}

# Step 4: Detect COM ports
Write-Host ""
Write-Host "Step 4: Detecting COM ports..." -ForegroundColor Yellow
$comPorts = [System.IO.Ports.SerialPort]::getportnames()

if ($comPorts.Count -eq 0) {
    Write-Host "No COM ports detected!" -ForegroundColor Red
    Write-Host "Please connect your ESP32 and try again." -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "Available COM ports:" -ForegroundColor Green
$comPorts | ForEach-Object { Write-Host "  - $_" }

# Step 5: Select COM port
Write-Host ""
if ($comPorts.Count -eq 1) {
    $selectedPort = $comPorts[0]
    Write-Host "Auto-selected: $selectedPort" -ForegroundColor Cyan
} else {
    $selectedPort = Read-Host "Enter the COM port for your ESP32 (e.g., COM3)"
    if (-not $selectedPort.StartsWith("COM")) {
        $selectedPort = "COM" + $selectedPort
    }
}

# Step 6: Flash the ESP32
Write-Host ""
Write-Host "Step 6: Flashing ESP32 on $selectedPort..." -ForegroundColor Yellow
Write-Host ""
Write-Host "IMPORTANT: If upload fails, hold the BOOT button on your ESP32!" -ForegroundColor Yellow
Write-Host ""
Start-Sleep -Seconds 2

$bootloaderPath = Join-Path $binariesPath "bootloader.bin"
$partitionsPath = Join-Path $binariesPath "partitions.bin"
$firmwarePath = Join-Path $binariesPath "firmware.bin"
$littlefsPath = Join-Path $binariesPath "littlefs.bin"

Write-Host "Executing flash command..." -ForegroundColor Cyan
Write-Host ""

# Build the command
$flashCommand = "python -m esptool --chip esp32 --port $selectedPort --baud 460800 --before default_reset --after hard_reset write_flash -z --flash_mode dio --flash_freq 80m --flash_size 4MB 0x1000 `"$bootloaderPath`" 0x8000 `"$partitionsPath`" 0x10000 `"$firmwarePath`" 0x13C000 `"$littlefsPath`""

# Show the command being executed
Write-Host "Command:" -ForegroundColor DarkGray
Write-Host $flashCommand -ForegroundColor DarkGray
Write-Host ""

# Execute the flash command
Invoke-Expression $flashCommand

# Check result
Write-Host ""
if ($LASTEXITCODE -eq 0) {
    Write-Host "================================" -ForegroundColor Green
    Write-Host "Flash completed successfully!" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now press the RESET button on your ESP32." -ForegroundColor Cyan
} else {
    Write-Host "================================" -ForegroundColor Red
    Write-Host "Flash failed!" -ForegroundColor Red
    Write-Host "================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting tips:" -ForegroundColor Yellow
    Write-Host "1. Hold the BOOT button while uploading" -ForegroundColor Yellow
    Write-Host "2. Try a different USB cable (data cable required)" -ForegroundColor Yellow
    Write-Host "3. Try lower baud rate: Change 460800 to 115200 in script" -ForegroundColor Yellow
    Write-Host "4. Make sure no other program is using the COM port" -ForegroundColor Yellow
}

Write-Host ""
pause
