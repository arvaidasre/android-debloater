#!/bin/bash

#====================================================================
# Android Debloater Script
# Version: 2.0.0
# Description: Safely disable bloatware packages on Android devices
# Author: Android Debloater
# License: MIT
#====================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Script configuration
readonly SCRIPT_NAME="Android Debloater"
readonly VERSION="2.0.0"
readonly LOG_DIR="./logs"
readonly BACKUP_DIR="./backups"

# Initialize counters
DISABLED_COUNT=0
ALREADY_DISABLED_COUNT=0
FAILED_COUNT=0
SKIPPED_COUNT=0

# Timing
readonly START_TIME=$(date +%s)
readonly START_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Create necessary directories
mkdir -p "$LOG_DIR" "$BACKUP_DIR"

# Log file with timestamp
readonly LOG_FILE="$LOG_DIR/debloat_$(date +%Y%m%d_%H%M%S).log"

#====================================================================
# Color and UI Functions
#====================================================================

# Function to check if the terminal supports colors
supports_colors() {
    if [[ -t 1 ]]; then
        local ncolors
        ncolors=$(tput colors 2>/dev/null || echo 0)
        (( ncolors >= 8 ))
    else
        return 1
    fi
}

# Initialize color variables
init_colors() {
    if supports_colors; then
        readonly RED=$(tput setaf 1)
        readonly GREEN=$(tput setaf 2)
        readonly YELLOW=$(tput setaf 3)
        readonly BLUE=$(tput setaf 4)
        readonly MAGENTA=$(tput setaf 5)
        readonly CYAN=$(tput setaf 6)
        readonly WHITE=$(tput setaf 7)
        readonly BOLD=$(tput bold)
        readonly RESET=$(tput sgr0)
    else
        readonly RED="" GREEN="" YELLOW="" BLUE="" MAGENTA="" CYAN="" WHITE="" BOLD="" RESET=""
    fi
}

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    case "$level" in
        "ERROR") echo -e "${RED}[ERROR]${RESET} $message" >&2 ;;
        "WARN")  echo -e "${YELLOW}[WARN]${RESET} $message" ;;
        "INFO")  echo -e "${BLUE}[INFO]${RESET} $message" ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS]${RESET} $message" ;;
        *) echo "$message" ;;
    esac
}

# Initialize colors
init_colors

#====================================================================
# Device Information Functions
#====================================================================

get_device_info() {
    DEVICE_MODEL=$(adb shell getprop ro.product.model 2>/dev/null | tr -d '\r' || echo "Unknown")
    ANDROID_VER=$(adb shell getprop ro.build.version.release 2>/dev/null | tr -d '\r' || echo "Unknown")
    BUILD_NUM=$(adb shell getprop ro.build.display.id 2>/dev/null | tr -d '\r' || echo "Unknown")
    SECURITY_PATCH=$(adb shell getprop ro.build.version.security_patch 2>/dev/null | tr -d '\r' || echo "Unknown")
    MANUFACTURER=$(adb shell getprop ro.product.manufacturer 2>/dev/null | tr -d '\r' || echo "Unknown")
}

# Display device information with enhanced styling
display_device_info() {
    echo -e "\n${BOLD}${BLUE}╔═══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}${BOLD}                   Android Debloater v${VERSION}                ${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}╠═══════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET} ${CYAN}Manufacturer:${RESET}   ${GREEN}${MANUFACTURER}${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET} ${CYAN}Model:${RESET}          ${GREEN}${DEVICE_MODEL}${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET} ${CYAN}Android:${RESET}        ${GREEN}${ANDROID_VER}${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET} ${CYAN}Build:${RESET}          ${GREEN}${BUILD_NUM}${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET} ${CYAN}Security Patch:${RESET} ${GREEN}${SECURITY_PATCH}${RESET}"
    echo -e "${BOLD}${BLUE}╚═══════════════════════════════════════════════════════════╝${RESET}\n"
}

#====================================================================
# Validation and Safety Functions
#====================================================================

# Check if ADB is installed and accessible
check_adb() {
    if ! command -v adb &>/dev/null; then
        log "ERROR" "ADB is not installed or not in PATH"
        echo -e "${RED}${BOLD}Prerequisites missing!${RESET}"
        echo -e "Please install Android Debug Bridge (ADB) first:"
        echo -e "  ${CYAN}• Ubuntu/Debian:${RESET} sudo apt install android-tools-adb"
        echo -e "  ${CYAN}• macOS:${RESET} brew install android-platform-tools"
        echo -e "  ${CYAN}• Windows:${RESET} Download from Android Developer website"
        exit 1
    fi
    log "INFO" "ADB found at: $(command -v adb)"
}

# Check device connection
check_device_connection() {
    log "INFO" "Starting ADB server..."
    adb start-server >/dev/null 2>&1
    
    local device_count
    device_count=$(adb devices | grep -c "device$" || echo 0)
    
    if (( device_count == 0 )); then
        log "ERROR" "No Android device connected"
        echo -e "${RED}${BOLD}No device detected!${RESET}"
        echo -e "Please ensure:"
        echo -e "  ${CYAN}• USB debugging is enabled${RESET}"
        echo -e "  ${CYAN}• Device is connected via USB${RESET}"
        echo -e "  ${CYAN}• You've authorized this computer${RESET}"
        echo -e "  ${CYAN}• Try: ${YELLOW}adb devices${RESET}"
        exit 1
    elif (( device_count > 1 )); then
        log "WARN" "Multiple devices detected ($device_count)"
        echo -e "${YELLOW}${BOLD}Multiple devices detected!${RESET}"
        echo -e "Please connect only one device or specify device ID"
        adb devices
        exit 1
    fi
    
    log "SUCCESS" "Device connected successfully"
}

# Create backup of current package states
create_backup() {
    local backup_file="$BACKUP_DIR/package_states_$(date +%Y%m%d_%H%M%S).txt"
    log "INFO" "Creating backup of current package states..."
    
    {
        echo "# Package states backup - $(date)"
        echo "# Device: $MANUFACTURER $DEVICE_MODEL"
        echo "# Android: $ANDROID_VER"
        echo "# Generated by: $SCRIPT_NAME v$VERSION"
        echo ""
        
        for package in "${PACKAGES[@]}"; do
            local pkg_name="${package%% *}"  # Extract package name
            local state
            if adb shell pm list packages -d | grep -q "$pkg_name"; then
                state="DISABLED"
            elif adb shell pm list packages -e | grep -q "$pkg_name"; then
                state="ENABLED"
            else
                state="NOT_FOUND"
            fi
            echo "$pkg_name $state"
        done
    } > "$backup_file"
    
    log "SUCCESS" "Backup created: $backup_file"
}

#====================================================================
# Package Management Functions
#====================================================================

# Enhanced package list with categories and descriptions
declare -A PACKAGE_CATEGORIES=(
    ["Google Services"]="com.google.android.apps.photos|Google Photos|Photo storage and sharing
com.google.android.apps.tachyon|Google Meet|Video conferencing
com.google.android.apps.youtube.music|YouTube Music|Music streaming service
com.google.android.apps.safetyhub|Personal Safety|Safety and emergency features
com.google.android.feedback|Google Feedback|App feedback collection
com.android.chrome|Chrome Browser|Web browser
com.google.android.devicelockcontroller|Device Lock Controller|Device security management
com.google.android.gms.supervision|Google Parental Controls|Family management
com.google.android.apps.subscriptions.red|Google One|Cloud storage subscription
com.android.hotwordenrollment.okgoogle|Google Assistant Enrollment|Voice assistant setup
com.android.hotwordenrollment.xgoogle|Google Assistant Extended|Enhanced voice features"
    
    ["MIUI Services"]="com.miui.miservice|MIUI Service Framework|MIUI system service
com.miui.bugreport|MIUI Bug Report|System error reporting
com.xiaomi.midrop|Mi Drop|File transfer service
com.miui.player|MIUI Music Player|Default music player
com.miui.cloudservice|Mi Cloud|Xiaomi cloud services
com.mi.globalbrowser|Mi Browser|Default web browser
com.miui.msa.global|MIUI System Ads|Advertisement framework
com.miui.huanji|MIUI Data Migration|Device data transfer
com.miui.analytics|MIUI Analytics|Usage analytics collection
com.mi.global.shop|Mi Store|Xiaomi app store
com.miui.android.fashiongallery|MIUI Wallpapers|Wallpaper collection
com.duokan.phone.remotecontroller|Mi Remote Controller|IR remote control
com.xiaomi.smarthome|Mi Home|Smart home management"
    
    ["System Services"]="cn.wps.xiaomi.abroad.lite|WPS Office|Office suite
com.android.nfc|NFC Service|Near Field Communication"
)

# Extract packages array from categories
PACKAGES=()
for category in "${PACKAGE_CATEGORIES[@]}"; do
    while IFS='|' read -r package_name description long_desc; do
        PACKAGES+=("$package_name")
    done <<< "$category"
done

# Enhanced progress bar with animations
show_progress_bar() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    
    # Create progress bar
    local bar=""
    for ((i=0; i<filled; i++)); do
        bar+="${GREEN}█${RESET}"
    done
    for ((i=filled; i<width; i++)); do
        bar+="${WHITE}░${RESET}"
    done
    
    printf "\r  ${BOLD}Progress:${RESET} [%s] ${BOLD}%3d%%${RESET} ${CYAN}(%d/%d)${RESET}" \
           "$bar" "$percentage" "$current" "$total"
}

# Enhanced package disable function with better error handling
disable_package() {
    local package="$1"
    local package_desc="$2"
    
    # Check if package exists
    if ! adb shell pm list packages | grep -q "^package:$package$"; then
        log "WARN" "Package not found: $package"
        echo -e "    ${YELLOW}⚠ Not found:${RESET} $package ${WHITE}($package_desc)${RESET}"
        ((SKIPPED_COUNT++))
        return 1
    fi
    
    # Check if already disabled
    if adb shell pm list packages -d | grep -q "^package:$package$"; then
        log "INFO" "Package already disabled: $package"
        echo -e "    ${CYAN}ℹ Already disabled:${RESET} $package ${WHITE}($package_desc)${RESET}"
        ((ALREADY_DISABLED_COUNT++))
        return 0
    fi
    
    # Attempt to disable package
    if adb shell pm disable-user --user 0 "$package" >/dev/null 2>&1; then
        log "SUCCESS" "Successfully disabled: $package"
        echo -e "    ${GREEN}✓ Disabled:${RESET} $package ${WHITE}($package_desc)${RESET}"
        ((DISABLED_COUNT++))
        return 0
    else
        log "ERROR" "Failed to disable: $package"
        echo -e "    ${RED}✗ Failed:${RESET} $package ${WHITE}($package_desc)${RESET}"
        ((FAILED_COUNT++))
        return 1
    fi
}

# Display packages by category
display_packages_by_category() {
    echo -e "${BOLD}${BLUE}Packages to be processed:${RESET}\n"
    
    for category in "${!PACKAGE_CATEGORIES[@]}"; do
        echo -e "${BOLD}${MAGENTA}$category:${RESET}"
        while IFS='|' read -r package_name description long_desc; do
            echo -e "  ${CYAN}•${RESET} $description ${WHITE}($package_name)${RESET}"
            echo -e "    ${WHITE}$long_desc${RESET}"
        done <<< "${PACKAGE_CATEGORIES[$category]}"
        echo ""
    done
}

# Interactive confirmation with enhanced options
get_user_confirmation() {
    echo -e "${BOLD}${YELLOW}⚠ WARNING:${RESET} This will disable ${#PACKAGES[@]} packages on your device"
    echo -e "A backup will be created before making any changes.\n"
    
    while true; do
        echo -e "${BOLD}Choose an option:${RESET}"
        echo -e "  ${GREEN}[p]${RESET} Proceed with debloating"
        echo -e "  ${CYAN}[s]${RESET} Show detailed package list"
        echo -e "  ${YELLOW}[b]${RESET} Create backup only (no changes)"
        echo -e "  ${RED}[q]${RESET} Quit without changes"
        echo ""
        
        read -p "Enter your choice [p/s/b/q]: " -n 1 -r choice
        echo ""
        
        case $choice in
            [Pp])
                log "INFO" "User confirmed proceeding with debloating"
                return 0
                ;;
            [Ss])
                display_packages_by_category
                ;;
            [Bb])
                create_backup
                echo -e "${GREEN}Backup completed. Exiting without making changes.${RESET}"
                exit 0
                ;;
            [Qq])
                log "INFO" "User cancelled operation"
                echo -e "${YELLOW}Operation cancelled by user.${RESET}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please enter p, s, b, or q.${RESET}\n"
                ;;
        esac
    done
}


#====================================================================
# Main Execution Functions
#====================================================================

# Main debloating process
run_debloating_process() {
    local total=${#PACKAGES[@]}
    local current=0
    
    echo -e "${BOLD}${BLUE}Starting debloating process...${RESET}"
    echo -e "${BLUE}${'─' * 60}${RESET}\n"
    
    # Process packages by category
    for category in "${!PACKAGE_CATEGORIES[@]}"; do
        echo -e "${BOLD}${MAGENTA}Processing $category:${RESET}"
        
        while IFS='|' read -r package_name description long_desc; do
            ((current++))
            disable_package "$package_name" "$description"
            show_progress_bar "$current" "$total"
            sleep 0.1  # Small delay for visual effect
        done <<< "${PACKAGE_CATEGORIES[$category]}"
        
        echo -e "\n"
    done
    
    echo -e "\n${BLUE}${'─' * 60}${RESET}"
}

# Calculate and display execution time
calculate_execution_time() {
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    echo "$minutes" "$seconds"
}

# Generate comprehensive summary
display_final_summary() {
    local time_data
    read -r minutes seconds <<< "$(calculate_execution_time)"
    
    echo -e "${BOLD}${BLUE}╔═══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}${BOLD}                        SUMMARY REPORT                        ${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}╠═══════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET} ${CYAN}Script Version:${RESET}     ${WHITE}$VERSION${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET} ${CYAN}Execution Time:${RESET}     ${WHITE}${minutes}m ${seconds}s${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET} ${CYAN}Started At:${RESET}         ${WHITE}$START_TIMESTAMP${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET} ${CYAN}Completed At:${RESET}       ${WHITE}$(date '+%Y-%m-%d %H:%M:%S')${RESET}"
    echo -e "${BOLD}${BLUE}╠═══════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}${BOLD}                      PACKAGE STATISTICS                      ${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}╠═══════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET} ${GREEN}✓ Successfully Disabled:${RESET} ${BOLD}${GREEN}$(printf "%3d" $DISABLED_COUNT)${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET} ${CYAN}ℹ Already Disabled:${RESET}      ${BOLD}${CYAN}$(printf "%3d" $ALREADY_DISABLED_COUNT)${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET} ${YELLOW}⚠ Not Found/Skipped:${RESET}    ${BOLD}${YELLOW}$(printf "%3d" $SKIPPED_COUNT)${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET} ${RED}✗ Failed:${RESET}               ${BOLD}${RED}$(printf "%3d" $FAILED_COUNT)${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET} ${WHITE}📦 Total Packages:${RESET}       ${BOLD}${WHITE}$(printf "%3d" ${#PACKAGES[@]})${RESET}"
    echo -e "${BOLD}${BLUE}╠═══════════════════════════════════════════════════════════╣${RESET}"
    
    # Status indicator
    if (( FAILED_COUNT == 0 && DISABLED_COUNT > 0 )); then
        echo -e "${BOLD}${BLUE}║${RESET}${BOLD}                    ${GREEN}✓ OPERATION SUCCESSFUL${RESET}${BOLD}                    ${BLUE}║${RESET}"
    elif (( FAILED_COUNT > 0 && DISABLED_COUNT > 0 )); then
        echo -e "${BOLD}${BLUE}║${RESET}${BOLD}                  ${YELLOW}⚠ PARTIAL SUCCESS${RESET}${BOLD}                     ${BLUE}║${RESET}"
    elif (( DISABLED_COUNT == 0 )); then
        echo -e "${BOLD}${BLUE}║${RESET}${BOLD}                   ${CYAN}ℹ NO CHANGES MADE${RESET}${BOLD}                     ${BLUE}║${RESET}"
    else
        echo -e "${BOLD}${BLUE}║${RESET}${BOLD}                    ${RED}✗ OPERATION FAILED${RESET}${BOLD}                    ${BLUE}║${RESET}"
    fi
    
    echo -e "${BOLD}${BLUE}╚═══════════════════════════════════════════════════════════╝${RESET}"
    
    # Additional information
    echo -e "\n${CYAN}📋 Log file:${RESET} $LOG_FILE"
    
    if (( DISABLED_COUNT > 0 )); then
        echo -e "${GREEN}💡 Tip:${RESET} Restart your device to ensure all changes take effect"
    fi
    
    if (( FAILED_COUNT > 0 )); then
        echo -e "${YELLOW}💡 Note:${RESET} Some failures are normal - packages may not exist on all devices"
    fi
    
    echo ""
}

#====================================================================
# Main Script Execution
#====================================================================

main() {
    # Initialize
    log "INFO" "Starting $SCRIPT_NAME v$VERSION"
    
    # Pre-flight checks
    check_adb
    check_device_connection
    
    # Get device information
    get_device_info
    display_device_info
    
    # User interaction
    get_user_confirmation
    
    # Create backup
    create_backup
    
    # Execute debloating
    run_debloating_process
    
    # Show final summary
    display_final_summary
    
    log "INFO" "Script execution completed"
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
