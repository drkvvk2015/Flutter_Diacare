#!/bin/bash

# DiaCare Production Build Script for macOS/Linux

echo "╔════════════════════════════════════════╗"
echo "║  DiaCare Production Build System      ║"
echo "╚════════════════════════════════════════╝"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Pre-build checks
echo -e "\n${YELLOW}🔍 Running pre-build checks...${NC}"

# Check Flutter
if command -v flutter &> /dev/null; then
    echo -e "${GREEN}✓ Flutter is installed${NC}"
else
    echo -e "${RED}✗ Flutter not found. Please install Flutter SDK.${NC}"
    exit 1
fi

# Clean and prepare
echo -e "\n${YELLOW}🧹 Cleaning previous builds...${NC}"
flutter clean
flutter pub get

echo -e "\n${YELLOW}⚙️  Generating code...${NC}"
flutter pub run build_runner build --delete-conflicting-outputs

echo -e "\n${YELLOW}🔎 Running code analysis...${NC}"
flutter analyze

# Build Android
echo -e "\n${YELLOW}📦 Building Android...${NC}"
flutter build apk --release --split-per-abi
flutter build appbundle --release

# Build iOS (on macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "\n${YELLOW}📦 Building iOS...${NC}"
    flutter build ios --release
    flutter build ipa --release
else
    echo -e "\n${RED}⚠️  iOS builds require macOS${NC}"
fi

# Build Web
echo -e "\n${YELLOW}📦 Building Web...${NC}"
flutter build web --release --web-renderer canvaskit

echo -e "\n${GREEN}✨ Build process completed!${NC}"
echo -e "\n${YELLOW}📋 Build Locations:${NC}"
echo -e "  Android APK: ${CYAN}build/app/outputs/flutter-apk/${NC}"
echo -e "  Android Bundle: ${CYAN}build/app/outputs/bundle/release/${NC}"
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "  iOS IPA: ${CYAN}build/ios/ipa/${NC}"
fi
echo -e "  Web: ${CYAN}build/web/${NC}"

echo -e "\n${GREEN}🚀 Happy Deploying!${NC}"
