#!/bin/bash
# بناء كبسولة تاز — weak link (زي أحمد، يمنع الكراش) + arm64
SDK=$(xcrun --sdk iphoneos --show-sdk-path); CLANG=$(xcrun --sdk iphoneos -f clang)
"$CLANG" -arch arm64 -isysroot "$SDK" -mios-version-min=15.0 -dynamiclib -fobjc-arc -O2 \
  -weak_framework UIKit -weak_framework CoreGraphics -weak_framework QuartzCore -framework Foundation \
  -install_name @executable_path/TAZPlus.dylib -o TAZPlus.dylib TAZCapsule.m
codesign -f -s - TAZPlus.dylib
echo "built + signed: $(lipo -archs TAZPlus.dylib)"
