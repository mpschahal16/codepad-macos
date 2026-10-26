# CodePad for macOS

A small, native macOS text and code editor prototype for Apple Silicon. It is an independent project with a familiar tabbed-editor workflow; it is not an official Notepad++ release and is not affiliated with the Notepad++ project.

## Current features

- Native macOS window and controls, built with SwiftUI and AppKit
- Matching cat logo in the app icon and window header
- Multiple open documents in tabs
- New, open, save, and save as
- UTF-8 text files
- Native Find interface (`⌘F`)
- Unsaved-change indicator and close confirmation
- File-type label and line count
- Menu and keyboard shortcuts for common actions

This is a prototype, not feature parity with Notepad++. Syntax highlighting, plugins, session restore, encoding selection, and advanced search are not implemented yet.

## Build on Apple Silicon

Requirements: macOS 13 or later and Xcode Command Line Tools (Swift 5.9 or later).

```sh
./scripts/build-app.sh
open dist/CodePad.app
```

The script builds for the host architecture. Run it on an Apple Silicon Mac to produce an `arm64` app. The app is ad-hoc signed for local testing, but it is not Developer ID signed or notarized, so macOS may show a security prompt when opening it.

## How the Notepad++ source informed the design

The linked source separates application-level command handling (`PowerEditor/src/Notepad_plus.cpp` and `NppCommands.cpp`), document and file state (`ScintillaComponent/Buffer.*`), and the editor view (`ScintillaComponent/ScintillaEditView.*`, backed by Scintilla and Lexilla). This prototype keeps the same broad separation between document lifecycle, editor view, and commands, but uses native macOS APIs rather than copying the Windows-specific UI code.

The editable SVG is in `Assets/cat-logo.svg`; the matching Core Graphics renderer is in `scripts/render-icon.swift`. Regenerate the ICNS bundle with `./scripts/make-icon.sh`.

The linked Notepad++ repository is licensed under GPL-3.0 with additional project terms. This prototype does not include source files from that repository; it is licensed separately under GPL-3.0-or-later. Read `LICENSE` before redistributing.

## Open-source status

Contributions and issue reports are welcome. Please use the name and visual identity of this independent project when publishing it; do not present it as an official Notepad++ macOS release.
