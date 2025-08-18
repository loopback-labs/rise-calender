# From your repo root
xcodebuild \
  -project rise.xcodeproj \
  -scheme rise \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath build \
  clean build

# Install (copy) to /Applications
cp -R build/Build/Products/Release/rise.app /Applications/

# Launch
open /Applications/rise.app
