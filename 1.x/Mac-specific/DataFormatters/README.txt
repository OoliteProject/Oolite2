This project builds a data formatter plug-in for Xcode which sets up debugger
data formatters for various Oolite classes and structs, as well as most JSAPI
types.

All the actual data formatters are set up in CustomDataViews.plist; the bundle
is just a stub to allow it to be installed without overwriting/modifying your
main CustomDataViews.plist (which is set up automatically by Xcode).

To install, cd to this directory and run "xcodebuild install". Alternatively,
build from Xcode and copy the bundle to:
~/Library/Application Support/Developer/Shared/Xcode/CustomDataViews/
