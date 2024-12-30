# Android Debloater
> A streamlined CLI tool to remove bloatware from Android devices

## Features
- 🔍 Automatic device detection and information display
- 📱 Supports both Google and MIUI system apps
- 🎨 Beautiful progress visualization with colored output
- 📊 Detailed summary of disabled packages
- ⚡ Fast batch processing of multiple packages
- 💪 Error handling and status reporting

## Prerequisites
- ADB (Android Debug Bridge) installed on your system
- USB debugging enabled on your Android device
- Connected Android device via USB

## Usage
1. Connect your Android device via USB
2. Enable USB debugging on your device
3. Run the script:
```bash
chmod +x debloat.sh
./debloat.sh
```

## What it disables
The script disables various pre-installed apps including:
- Google apps (Photos, Meet, YouTube Music, etc.)
- MIUI system apps (Browser, Analytics, Cloud Service, etc.)
- System features (NFC, Remote Controller, etc.)

## Output
The script provides:
- Device information display
- Real-time progress bar
- Color-coded status messages
- Final summary with:
  - Successfully disabled packages
  - Already disabled packages
  - Failed operations
  - Total execution time

## Safety
- Non-destructive operations (packages are disabled, not removed)
- Preview of packages before execution
- Confirmation prompt before proceeding
- Error handling for missing ADB or device connection

## License
MIT License

## Contributing
Feel free to submit issues and pull requests.