# CodePad16 release notes

## 0.0.2

Second prototype release for Apple Silicon macOS.

### New

- Syntax highlighting for C, C++, C#, Java, JavaScript, TypeScript, Python, Swift, HTML, CSS, JSON, XML, and SQL
- Automatic language detection from the file extension, with a language picker in the status bar
- UTF-8 (with or without a BOM), UTF-16, UTF-32, and ISO-8859-1 file encodings, detected on open, preserved on save, and selectable in the status bar
- Full Unicode text, including accented characters, CJK, and emoji
- Session restore of open tabs with cursor, scroll, language, encoding, and unsaved changes
- Line-number gutter backed by Scintilla
- Drag-to-Applications disk image with an arranged Finder layout

### Fixed

- Text typed after switching tabs no longer disappears; edits now target the active document
- Unchanged document content is no longer reloaded into the editor during unrelated updates

### Included

- Native macOS editor window with multiple document tabs
- Open, save, and save as for UTF-8 text files
- Find in the current document
- Cat app icon and current line/column status indicator
- Reopen the editor window from the Dock after closing its last window
- Apple Silicon arm64 application bundle

### Limitations

This is an early prototype. Plugins and advanced search are not included. Swift uses the C-family lexer as an initial approximation. The app is ad-hoc signed and not notarized, so macOS may ask you to confirm the first launch.

The README credits Notepad++ and its author for making the source available; CodePad16 is an independent project and is not an official Notepad++ release.

## 0.0.1

First public prototype release for Apple Silicon macOS.

### Included

- Native macOS editor window with multiple document tabs
- Open, save, and save as for UTF-8 text files
- Find in the current document
- Cat app icon and current line/column status indicator
- Reopen the editor window from the Dock after closing its last window
- Apple Silicon arm64 application bundle

### Limitations

This is an early prototype. Syntax highlighting, plugins, session restore, encoding selection, and advanced search are not included. The app is ad-hoc signed and not notarized, so macOS may ask you to confirm the first launch.
