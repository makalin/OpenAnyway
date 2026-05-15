# OpenAnyway

A tiny macOS utility that helps users open unsigned or quarantined applications without using Terminal commands.

Drag & drop an `.app` file into OpenAnyway and it automatically removes the macOS quarantine attribute so the application can launch normally.

Built for:
- indie developers
- open-source apps
- beta software
- internal tools
- unsigned builds
- hobby projects

---

## Why?

Recent macOS versions aggressively block unsigned applications downloaded from the internet.

Users are often told to run commands like:

```bash
xattr -d com.apple.quarantine /Applications/MyApp.app
````

For many users this is:

* confusing
* intimidating
* unsafe-looking
* too technical

OpenAnyway provides a simple visual alternative.

---

## Features

* Drag & drop `.app` support
* Removes quarantine attribute
* One-click app launch
* Minimal interface
* Offline-first
* Lightweight
* Open source
* No analytics
* No background services

---

## Planned Features

* Batch processing
* Finder extension
* Quick Actions support
* App verification details
* Download folder auto-detection
* History panel
* CLI mode
* Dark mode customization

---

## How It Works

OpenAnyway uses native macOS system tools internally:

```bash
xattr -d com.apple.quarantine
```

Optionally:

```bash
spctl --add
```

No SIP disabling.
No system patching.
No hacks.

---

## Security Notice

Only remove quarantine warnings from applications you trust.

OpenAnyway does not bypass macOS security protections — it simply provides an easier interface for trusted software workflows.

Always download applications from reputable sources.

---

## Possible Tech Stack

* SwiftUI
* Rust
* Tauri
* Objective-C
* Native Cocoa
* CLI version

---

## Example Workflow

1. Download unsigned app
2. macOS blocks it
3. Drag app into OpenAnyway
4. Click "Open"
5. App launches normally

---

## Inspiration

Created after repeated Gatekeeper issues affecting indie developers and open-source projects distributing unsigned applications.

Modern macOS increasingly favors paid code-signing workflows, making experimentation and open distribution harder for small developers and hobbyists.

OpenAnyway aims to make trusted unsigned apps easier to use.

---

## License

MIT
