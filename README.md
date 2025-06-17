# Android Debloater
> A professional CLI tool to safely remove bloatware from Android devices with enhanced features and robust error handling

## ✨ Features

### Core Functionality
- 🔍 **Automatic device detection** with comprehensive device information
- 📱 **Multi-vendor support** (Google, MIUI/Xiaomi, and generic Android)
- �️ **Safe operations** - packages are disabled, not permanently removed
- 📦 **Categorized packages** with detailed descriptions
- 🔄 **Backup creation** before making any changes

### User Experience
- 🎨 **Beautiful colored interface** with progress animations
- 📊 **Real-time progress tracking** with visual progress bars
- 🔧 **Interactive menu** with multiple operation modes
- � **Comprehensive logging** to timestamped log files
- 💼 **Professional summary reports** with detailed statistics

### Safety & Reliability
- ⚡ **Robust error handling** with detailed error messages
- 🔍 **Pre-flight checks** for ADB installation and device connectivity
- 📋 **Package verification** before attempting to disable
- � **Multiple confirmation prompts** to prevent accidental execution
- 📊 **Detailed status reporting** for each operation

## 🔧 Prerequisites

### Required Software
- **ADB (Android Debug Bridge)** installed and accessible in PATH
- **Bash shell** (version 4.0 or higher recommended)

### Device Requirements
- **USB debugging enabled** on your Android device
- **Device connected** via USB cable
- **Developer options** enabled

### Installation Instructions
```bash
# Ubuntu/Debian
sudo apt install android-tools-adb

# macOS (with Homebrew)
brew install android-platform-tools

# Arch Linux
sudo pacman -S android-tools

# Manual installation
# Download from: https://developer.android.com/studio/releases/platform-tools
```

## 🚀 Usage

### Quick Start
```bash
# Make script executable
chmod +x debloat.sh

# Run the script
./debloat.sh
```

### Interactive Options
When you run the script, you'll be presented with several options:
- **[p]** Proceed with debloating (full process)
- **[s]** Show detailed package list by category
- **[b]** Create backup only (no changes made)
- **[q]** Quit without making any changes

### Command Examples
```bash
# Standard execution
./debloat.sh

# Check script syntax
bash -n debloat.sh

# View logs
cat logs/debloat_*.log

# View backup
cat backups/package_states_*.txt
```

## 📦 Package Categories

### Google Services
- Google Photos, Meet, YouTube Music
- Personal Safety, Feedback, Chrome
- Device Lock Controller, Parental Controls
- Google One, Assistant features

### MIUI/Xiaomi Services
- MIUI Service Framework, Bug Report
- Mi Drop, Music Player, Cloud Service
- Mi Browser, System Ads, Analytics
- Mi Store, Wallpapers, Remote Controller
- Mi Home (Smart Home)

### System Services
- WPS Office, NFC Service

## 📊 Output & Reporting

### Device Information Display
```
╔═══════════════════════════════════════════════════════════╗
║                   Android Debloater v2.0.0                ║
╠═══════════════════════════════════════════════════════════╣
║ Manufacturer:   Samsung
║ Model:          Galaxy S21
║ Android:        13
║ Build:          TP1A.220624.014
║ Security Patch: 2024-01-01
╚═══════════════════════════════════════════════════════════╝
```

### Progress Visualization
```
Progress: [████████████████████████████████████████] 100% (25/25)
```

### Comprehensive Summary
```
╔═══════════════════════════════════════════════════════════╗
║                        SUMMARY REPORT                        ║
╠═══════════════════════════════════════════════════════════╣
║ Script Version:     2.0.0
║ Execution Time:     0m 15s
║ Started At:         2024-06-17 14:30:15
║ Completed At:       2024-06-17 14:30:30
╠═══════════════════════════════════════════════════════════╣
║                      PACKAGE STATISTICS                      ║
╠═══════════════════════════════════════════════════════════╣
║ ✓ Successfully Disabled:  18
║ ℹ Already Disabled:        3
║ ⚠ Not Found/Skipped:       4
║ ✗ Failed:                  0
║ 📦 Total Packages:         25
╠═══════════════════════════════════════════════════════════╣
║                    ✓ OPERATION SUCCESSFUL                    ║
╚═══════════════════════════════════════════════════════════╝
```

## 🛡️ Safety Features

### Backup Creation
- Automatic backup of current package states before any changes
- Timestamped backup files in `./backups/` directory
- Includes device information and package states

### Error Prevention
- Multiple confirmation prompts
- Package existence verification
- Device connectivity validation
- ADB installation checks

### Non-Destructive Operations
- Packages are **disabled**, not permanently removed
- Can be re-enabled through Android settings
- System stability is maintained

## 📁 File Structure

```
android-debloater/
├── debloat.sh              # Main script
├── README.md               # Documentation
├── logs/                   # Execution logs (auto-created)
│   └── debloat_YYYYMMDD_HHMMSS.log
└── backups/                # Package state backups (auto-created)
    └── package_states_YYYYMMDD_HHMMSS.txt
```

## 🔧 Troubleshooting

### Common Issues

**"ADB is not installed"**
```bash
# Install ADB using your package manager
sudo apt install android-tools-adb  # Ubuntu/Debian
brew install android-platform-tools  # macOS
```

**"No Android device connected"**
- Ensure USB debugging is enabled
- Try different USB cable/port
- Check device authorization: `adb devices`

**"Package not found" warnings**
- Normal behavior - not all packages exist on every device
- Different manufacturers include different bloatware

### Advanced Troubleshooting
```bash
# Check ADB connection
adb devices

# Check package list
adb shell pm list packages | grep -i "package_name"

# Manual package disable
adb shell pm disable-user --user 0 "package.name"

# View detailed logs
tail -f logs/debloat_*.log
```

## 🔄 Version History

### v2.0.0 (Current)
- ✨ Complete rewrite with enhanced features
- 🎨 Beautiful colored interface with progress animations
- 🛡️ Robust error handling and safety checks
- 📦 Categorized packages with descriptions
- 📝 Comprehensive logging and backup system
- 🔧 Interactive menu with multiple options
- 📊 Professional summary reports

### v1.0.0 (Legacy)
- Basic package disabling functionality
- Simple progress bar
- Basic error handling

## 📄 License

MIT License - see LICENSE file for details

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for:
- Additional package definitions
- Bug fixes
- Feature enhancements
- Documentation improvements

## ⚠️ Disclaimer

This tool modifies system package states on your Android device. While the operations are non-destructive (packages can be re-enabled), use at your own risk. Always ensure you have a backup of important data before running any system modification tools.

## Contributing
Feel free to submit issues and pull requests.