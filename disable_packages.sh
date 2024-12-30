#!/bin/bash

# Improved ASCII Art Intro
cat << "EOF"
  ________     ___   _ _  __ _____ 
 |  ____\ \   / / \ | | |/ // ____|
 | |__   \ \_/ /|  \| | ' /| (___  
 |  __|   \   / | . ` |  <  \___ \ 
 | |       | |  | |\  | . \ ____) |
 |_|       |_|  |_| \_|_|\_\_____/ 
                                   
 F Y N K S - Package Disabler Script     
EOF

# Get device information
DEVICE_MODEL=$(adb shell getprop ro.product.model 2>/dev/null || echo "Unknown")
ANDROID_VER=$(adb shell getprop ro.build.version.release 2>/dev/null || echo "Unknown")
BUILD_NUM=$(adb shell getprop ro.build.display.id 2>/dev/null || echo "Unknown")
SECURITY_PATCH=$(adb shell getprop ro.build.version.security_patch 2>/dev/null || echo "Unknown")

# Display device information
echo -e "\n${BLUE}╔════════════════ Device Information ═══════════════╗${RESET}"
echo -e "${BLUE}║${RESET} Model:          ${GREEN}${DEVICE_MODEL}${RESET}"
echo -e "${BLUE}║${RESET} Android:        ${GREEN}${ANDROID_VER}${RESET}"
echo -e "${BLUE}║${RESET} Build:          ${GREEN}${BUILD_NUM}${RESET}"
echo -e "${BLUE}║${RESET} Security Patch: ${GREEN}${SECURITY_PATCH}${RESET}"
echo -e "${BLUE}╚══════════════════════════════════════════════════╝${RESET}\n"


# Function to check if the terminal supports colors
supports_colors() {
  if [ -t 1 ]; then
    ncolors=$(tput colors 2>/dev/null || echo 0)
    [ "$ncolors" -ge 8 ]
  else
    return 1
  fi
}

# Set color variables
if supports_colors; then
  RED=$(tput setaf 1)
  GREEN=$(tput setaf 2)
  YELLOW=$(tput setaf 3)
  BLUE=$(tput setaf 4)
  RESET=$(tput sgr0)
else
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  RESET=""
fi

# Configs
VERSION="1.0.0"
START_TIME=$(date +%s)
START_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DISABLED_COUNT=0
ALREADY_DISABLED_COUNT=0
FAILED_COUNT=0
DEVICE_MODEL=$(adb shell getprop ro.product.model 2>/dev/null || echo "Unknown")

# Check if ADB is installed
if ! command -v adb &>/dev/null; then
  echo -e "${RED}[Error]${RESET} ADB is not installed. Please install it first."
  exit 1
fi

# List of packages to disable
PACKAGES=(
  "com.google.android.apps.photos"          # Google Photos
  "com.google.android.apps.tachyon"         # Google Meet
  "com.google.android.apps.youtube.music"   # YouTube Music
  "com.google.android.apps.safetyhub"       # Personal Safety
  "com.google.android.feedback"             # Google Feedback
  "com.android.chrome"                      # Chrome Browser
  "com.google.android.devicelockcontroller" # Device Lock Controller
  "com.google.android.gms.supervision"      # Google Parental Controls
  "com.google.android.apps.subscriptions.red" # Google One
  "com.miui.miservice"                      # MIUI Service Framework
  "com.miui.bugreport"                      # MIUI Bug Report
  "com.xiaomi.midrop"                       # Mi Drop (File Transfer)
  "com.miui.player"                         # MIUI Music Player
  "com.miui.cloudservice"                   # Mi Cloud
  "com.mi.globalbrowser"                    # Mi Browser
  "com.miui.msa.global"                     # MIUI System Ads
  "com.miui.huanji"                         # MIUI Data Migration
  "com.miui.analytics"                      # MIUI Analytics
  "com.mi.global.shop"                      # Mi Store
  "com.miui.android.fashiongallery"         # MIUI Wallpapers
  "com.android.hotwordenrollment.okgoogle"  # Google Assistant Enrollment
  "com.android.hotwordenrollment.xgoogle"   # Google Assistant Extended
  "cn.wps.xiaomi.abroad.lite"               # WPS Office
  "com.android.nfc"                         # NFC Service
  "com.duokan.phone.remotecontroller"       # Mi Remote Controller
  "com.xiaomi.smarthome"                    # Mi Home
)

# Display disabled packages to user
echo -e "${BLUE}[Info]${RESET} The following packages will be disabled:"
for PACKAGE in "${PACKAGES[@]}"; do
  echo "  - $PACKAGE"
done

read -p "${YELLOW}[Prompt]${RESET} Press Enter to proceed or Ctrl+C to cancel..."

# Ensure ADB server is running
adb start-server

# Check if the device is connected
DEVICE=$(adb devices | grep -w "device")
if [ -z "$DEVICE" ]; then
  echo -e "${RED}[Error]${RESET} No Android device connected. Ensure USB debugging is enabled."
  exit 1
fi

progress_bar() {
  local PROGRESS=$1
  local TOTAL=$2
  local PERCENT=$((PROGRESS * 100 / TOTAL))
  local FILLED=$((PERCENT / 2))
  local EMPTY=$((50 - FILLED))
  local FILLED_SUB=$((PROGRESS * 50 / TOTAL))
  
  # Unicode blocks for smoother progress bar
  local BLOCK_FULL="█"
  local BLOCK_EMPTY="░"
  
  printf "\n\r  ["
  for ((i=0; i<FILLED_SUB; i++)); do
    printf "${GREEN}${BLOCK_FULL}${RESET}"
  done
  for ((i=FILLED_SUB; i<50; i++)); do
    printf "${BLOCK_EMPTY}"
  done
  printf "]  ${GREEN}%3d%%${RESET}" "$PERCENT"
}

# Function to disable a package on the connected device
disable_package() {
  local PACKAGE="$1"
  if adb shell pm list packages -d | grep -q "$PACKAGE"; then
    echo -e "${YELLOW}⚠ Already disabled: $PACKAGE${RESET}"
    ((ALREADY_DISABLED_COUNT++))
  elif adb shell pm disable-user "$PACKAGE" >/dev/null 2>&1; then
    echo -e "${GREEN}✔ Successfully disabled: $PACKAGE${RESET}"
    ((DISABLED_COUNT++))
  else
    echo -e "${RED}✘ Failed to disable: $PACKAGE${RESET}"
    ((FAILED_COUNT++))
  fi
}


# Main script logic
echo -e "\n${BLUE}[Info]${RESET} Starting package disable process on connected Android device..."
echo -e "${BLUE}───────────────────────────────────────────────────────${RESET}"
TOTAL=${#PACKAGES[@]}

for i in "${!PACKAGES[@]}"; do
  printf "  "  # Consistent indentation
  disable_package "${PACKAGES[$i]}"
  progress_bar $((i + 1)) $TOTAL
  echo -e ""  # Add newline for better spacing
done

progress_bar $TOTAL $TOTAL
echo -e "\n${BLUE}───────────────────────────────────────────────────────${RESET}"
echo -e "${BLUE}[Script Info]${RESET}"
echo -e "Version:              ${VERSION}"
echo -e "Start time:          ${START_TIMESTAMP}"
echo -e "\n${BLUE}[Summary]${RESET}"
echo -e "${GREEN}✔ Successfully disabled:${RESET} $DISABLED_COUNT"
echo -e "${YELLOW}⚠ Already disabled:${RESET}    $ALREADY_DISABLED_COUNT"
echo -e "${RED}✘ Failed:${RESET}             $FAILED_COUNT"
echo -e "${BLUE}📦 Total packages:${RESET}    ${#PACKAGES[@]}"
echo -e "${BLUE}⌛ Total time:${RESET}        ${MINUTES}m ${SECONDS}s"
echo -e "${BLUE}───────────────────────────────────────────────────────${RESET}\n"
