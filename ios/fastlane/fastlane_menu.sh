#!/bin/bash

# Fastlane interactive menu — clipVAuLt (same pattern as Depozio / Triftly)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FASTLANE_DIR="$SCRIPT_DIR"
IOS_DIR="$(dirname "$FASTLANE_DIR")"

if [ ! -f "$FASTLANE_DIR/Fastfile" ]; then
    echo -e "${RED}Error: Fastfile not found.${NC}"
    exit 1
fi

cd "$IOS_DIR" || exit 1

declare -a lane_numbers
declare -a lane_commands
declare -a lane_descriptions
counter=1

clear
echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║${NC}          ${BOLD}Fastlane Menu — clipVAuLt${NC}                  ${BOLD}${CYAN}║${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BOLD}${YELLOW}📱 iOS Lanes${NC}"
echo -e "${YELLOW}────────────────────────────────────────────────────────────${NC}"
echo ""

add_lane() {
    lane_numbers[$counter]=$counter
    lane_commands[$counter]="$1"
    lane_descriptions[$counter]="$2"
    echo -e "  ${GREEN}[$counter]${NC} ${BOLD}$1${NC}"
    echo -e "      ${CYAN}→${NC} $2"
    echo ""
    ((counter++))
}

add_lane "ios build_debug" "Build iOS app for development (Debug)"
add_lane "ios build_release" "Build iOS app for release (no codesign)"
add_lane "ios build_ipa" "Build IPA (development signing)"
add_lane "ios build_ipa export_method:app-store" "Build IPA (App Store / TestFlight)"
add_lane "ios upload_testflight" "🚀 Auto-increment, build, upload TestFlight"
add_lane "ios create_app" "Register app in App Store Connect"
add_lane "ios setup_appstore_signing" "Fetch Distribution cert + profile"
add_lane "ios increment_build" "Increment Xcode build number"
add_lane "ios clean" "Clean iOS build artifacts"

echo -e "${BOLD}${MAGENTA}🤖 Android Lanes${NC}"
echo -e "${MAGENTA}────────────────────────────────────────────────────────────${NC}"
echo ""

add_lane "android build_debug" "Build Android debug APK"
add_lane "android build_release_apk" "Build Android release APK"
add_lane "android build_release_bundle" "Build Android release App Bundle"
add_lane "android clean" "Clean Android build artifacts"

echo -e "${BOLD}${BLUE}🔧 Common Lanes${NC}"
echo -e "${BLUE}────────────────────────────────────────────────────────────${NC}"
echo ""

add_lane "get_dependencies" "flutter pub get"
add_lane "test" "flutter test"
add_lane "clean_all" "Clean all platforms"

echo -e "${YELLOW}────────────────────────────────────────────────────────────${NC}"
echo -e "  ${GREEN}[0]${NC} ${BOLD}Exit${NC}"
echo ""
echo -ne "${BOLD}Select a lane [0-$((counter-1))]: ${NC}"
read -r choice

if [ "$choice" = "0" ] || [ -z "$choice" ]; then
    echo "Bye."
    exit 0
fi

if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -ge "$counter" ]; then
    echo -e "${RED}Invalid selection.${NC}"
    exit 1
fi

selected_lane="${lane_commands[$choice]}"
selected_desc="${lane_descriptions[$choice]}"

echo ""
echo -e "${BOLD}${GREEN}Selected:${NC} ${BOLD}$selected_lane${NC}"
echo -e "${CYAN}Description:${NC} $selected_desc"
echo ""
echo -e "${YELLOW}Running: bundle exec fastlane $selected_lane${NC}"
echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"
echo ""

# Prefer bundle if available
if command -v bundle >/dev/null 2>&1 && [ -f "$IOS_DIR/Gemfile" ]; then
    bundle exec fastlane $selected_lane
    exit_code=$?
else
    fastlane $selected_lane
    exit_code=$?
fi

# Retry TestFlight once after pod install if it failed
if [ $exit_code -ne 0 ] && [[ "$selected_lane" == *"upload_testflight"* ]]; then
    echo ""
    echo -e "${YELLOW}⚠️  Build failed. Attempting pod install then retry...${NC}"
    cd "$IOS_DIR" || exit 1
    if command -v bundle >/dev/null 2>&1; then
        bundle exec pod install --repo-update
    else
        pod install --repo-update
    fi
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}🔄 Retrying...${NC}"
        if command -v bundle >/dev/null 2>&1; then
            bundle exec fastlane $selected_lane
            exit_code=$?
        else
            fastlane $selected_lane
            exit_code=$?
        fi
    fi
fi

echo ""
echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"
if [ $exit_code -eq 0 ]; then
    echo -e "${BOLD}${GREEN}✅ Lane completed successfully!${NC}"
else
    echo -e "${BOLD}${RED}❌ Lane failed with exit code $exit_code${NC}"
fi
echo ""
exit $exit_code
