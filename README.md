# CleanDrop

CleanDrop is a native macOS SwiftUI utility for finding files related to an app bundle and moving selected items to Trash after review.

It is meant to be an AppCleaner-style helper for apps on your own Mac. It does not crack, bypass, patch, or modify other apps.

## What Is In This Repo

This repository includes both:

- A ready-to-open macOS app bundle at `dist/CleanDrop.app`.
- The full SwiftUI source code, Xcode project, services, view models, and tests used to build it.

The prebuilt app is included for convenience, but the implementation is not hidden behind a random binary. You can inspect the code, build it yourself in Xcode, or run the included app directly.

## What It Does

- Accepts a dragged `.app` bundle.
- Reads app metadata such as bundle identifier, display name, executable name, and bundle path.
- Scans common macOS app-support locations for related files.
- Shows every detected file or folder in a review screen before anything is moved.
- Lets you select or deselect each candidate.
- Moves selected items to macOS Trash using `FileManager.trashItem`.
- Writes a local cleanup report after completion.

## Safety Rules

CleanDrop is intentionally conservative:

- It never deletes files immediately after drag-and-drop.
- It never deletes files immediately after scanning.
- It never permanently deletes files.
- It always shows a review screen first.
- It requires a final confirmation before moving anything to Trash.
- Low-confidence, shared vendor, risky, and system-level matches are unchecked by default.
- Shared folders such as broad vendor directories are shown as risky/shared and left unchecked.
- `/System` is never scanned for deletion candidates.
- Symlinks are not followed outside the scanned directory.

The confirmation step shows the selected item count, estimated size, app name, and a warning if risky/shared files are selected.

## Privacy

CleanDrop is local-only.

- No API keys.
- No analytics.
- No telemetry.
- No network calls.
- No external services.
- No shell-script dependency for app cleanup.

The app uses native macOS APIs such as `FileManager`, `Bundle`, `NSWorkspace`, and SwiftUI.

## Included App Bundle

A prebuilt app bundle is included here:

```text
dist/CleanDrop.app
```

Because this is locally built and ad-hoc signed, macOS may show a security warning the first time you open it. If that happens, right-click the app and choose **Open**, or build it yourself from source.

## Build From Source

Open the Xcode project:

```text
CleanDrop.xcodeproj
```

Choose the `CleanDrop` scheme and run it.

This repository also includes a Swift Package manifest so the source can be checked with:

```sh
swift build
```

## Tests

Unit tests cover:

- Bundle metadata extraction.
- Default selection safety rules.
- Matching confidence for app-specific, shared, and system-level files.

```sh
swift test
```

On some machines, `swift test` requires a full Xcode installation rather than only Command Line Tools.

## Permissions

macOS may block access to some Library folders. If CleanDrop reports permission issues, grant Full Disk Access in:

```text
System Settings > Privacy & Security > Full Disk Access
```

Permission failures are reported in the app instead of being treated as silent success.
