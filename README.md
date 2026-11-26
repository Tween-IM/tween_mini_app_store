# Tween Mini App Store

A Flutter mini-app marketplace starter with a WebView runtime, website publishing flow, community app suggestions, and local ZIP package import.

> **Project status:** Starter/demo implementation (`0.1.0`). The storefront and submission flows are designed to be extended with a production backend. Listings, suggestions, and the in-session library currently use demo/in-memory data.

## Contents

- [Overview](#overview)
- [Features](#features)
- [Screens and flows](#screens-and-flows)
- [Getting started](#getting-started)
- [Run the example app](#run-the-example-app)
- [Add Tween Mini App Store to another Flutter app](#add-tween-mini-app-store-to-another-flutter-app)
- [Uploadable mini-app ZIP format](#uploadable-mini-app-zip-format)
- [Project structure](#project-structure)
- [Platform notes](#platform-notes)
- [Production roadmap and limitations](#production-roadmap-and-limitations)
- [Security considerations](#security-considerations)
- [Contributing](#contributing)
- [License](#license)

## Overview

Tween Mini App Store is a reusable Flutter package and example host application for discovering and opening lightweight web mini-apps.

A mini app can be a website or a small HTML/CSS/JavaScript package. The host app presents app listings and launches selected web content in an embedded WebView.

The project is intended as a foundation for a branded mini-app store—not as a finished, cloud-backed marketplace.

## Features

### Storefront and discovery

- Play Store-inspired Material storefront with Tween branding
- Featured discovery banner and app shelves
- Explore, Categories, Search, and My Apps destinations
- Search across listing name, description, developer, category, keywords, and URL
- Category browsing based on available listing data
- App detail view with descriptions, cover/screenshot images, and optional support/privacy links
- Web mini-app launch through the in-app runtime

### Developer submissions

- Publish a website or PWA listing
- Fetch available website metadata to help prefill a listing
- Editable title, description, icon/cover, screenshots, category, and related listing details
- Suggest a public GitHub project for review
- Suggest an app idea
- Browse demo community suggestions and support a suggestion

### Local ZIP package import

- Select a mini-app ZIP from the device
- Validate the `.zip` file and archive signature
- Find an `index.html` entry point
- Extract the package for local use
- Reject unsafe archive paths and enforce package size/file-count limits
- Prefill listing information from HTML metadata where available
- Launch extracted web content using the existing WebView runtime

## Screens and flows

- **Explore:** Featured and recommended mini apps
- **Categories:** Browse listings by category
- **Search:** Find listings by supported metadata
- **My Apps:** In-session library of apps opened or submitted
- **App details:** Listing information and launch action
- **Publish website:** Metadata-assisted listing submission
- **Community suggestions:** GitHub project and idea suggestions
- **Upload package:** Import a local web mini-app ZIP

## Getting started

### Requirements

Install the following tools before building:

- Flutter SDK (Dart is included with Flutter)
- Android Studio and Android SDK for Android builds
- Xcode for iOS builds on macOS
- Git and GitHub Desktop (optional, for repository workflow)

Use a Flutter version compatible with the constraints in `pubspec.yaml`.

### Clone the repository

```bash
git clone https://github.com/<YOUR-GITHUB-USERNAME>/tween_mini_app_store.git
cd tween_mini_app_store
```

Replace `<YOUR-GITHUB-USERNAME>` with the account that hosts this repository.

### Install package dependencies

From the package root:

```bash
flutter pub get
```

Then install the example app dependencies:

```bash
cd example
flutter pub get
```

## Run the example app

From the repository root:

```bash
cd example
flutter run
```

To list connected devices:

```bash
flutter devices
```

Then select a device in Android Studio or pass its ID:

```bash
flutter run -d <DEVICE_ID>
```

### Android SDK note

The example Android app is configured to compile against Android API 36. Install **Android SDK Platform 36** in Android Studio's SDK Manager if Gradle reports that the platform is missing.

The package's `file_picker` dependency should be resolved to a version compatible with this Android configuration. After changing dependencies, run `flutter pub get` and check the resolved version in `pubspec.lock`.

## Add Tween Mini App Store to another Flutter app

This repository contains a reusable Flutter package and an example host app.

For local development, you can reference the package from another Flutter app using a path dependency:

```yaml
dependencies:
  tween_mini_app_store:
    path: ../tween_mini_app_store
```

Adjust the relative path to match your workspace. Then run:

```bash
flutter pub get
```

Import the package's public API:

```dart
import 'package:tween_mini_app_store/tween_mini_app_store.dart';
```

The package exports the mini-app models, repository interfaces, storefront/runtime screens, submission screens, suggestion flow, and package importer. Review the example app in `example/lib/main.dart` for the current integration pattern.

## Uploadable mini-app ZIP format

A ZIP package should contain a web app entry point named `index.html`. CSS, JavaScript, images, fonts, and other static assets can be placed alongside it or in subfolders.

Example:

```text
my-mini-app.zip
├── index.html
├── css/
│   └── style.css
├── js/
│   └── app.js
└── assets/
    └── icon.png
```

Use relative asset paths in your HTML:

```html
<link rel="stylesheet" href="css/style.css">
<script src="js/app.js"></script>
```

The current local importer applies these limits:

- Maximum compressed ZIP size: **25 MB**
- Maximum expanded package size: **60 MB**
- Maximum number of archive entries: **1,500**
- Required entry point: `index.html`

The importer checks archive paths to help prevent path traversal. A package is extracted into the app's local documents area and opened by the host WebView.

**Important:** ZIP import is a local demo feature. It does not upload the package to a public server or make it available to other users.

## Project structure

```text
tween_mini_app_store/
├── lib/
│   ├── tween_mini_app_store.dart  # Package public exports
│   └── src/
│       ├── models/                # Mini-app and suggestion models
│       ├── repository/             # Repository interfaces/demo data
│       ├── screens/                # Storefront and submission UI
│       └── services/                # ZIP importer and related services
├── example/
│   ├── lib/main.dart               # Example host application
│   └── android/                    # Android host configuration
├── test/                            # Package tests, when present
├── pubspec.yaml
├── pubspec.lock
├── CHANGELOG.md
└── README.md
```

## Platform notes

- **Android / iOS:** The WebView runtime and local ZIP import are intended for supported native builds. Platform-specific WebView and file-picker configuration may be required.
- **Desktop:** ZIP extraction and local file access may be supported by the configured Flutter plugins; validate the runtime on each target desktop platform.
- **Flutter Web:** Browser security and CORS restrictions apply. The current local-file ZIP import flow is not a hosted web publishing system. Web deployment should use server-side package storage and a hosted URL/runtime.

Test the package on each platform you plan to release.

## Production roadmap and limitations

The current repository is a starter implementation. Before launching a public marketplace, plan to add:

- Persistent backend storage for listings and user libraries
- Developer accounts, authentication, and ownership checks
- Hosted package storage and delivery
- Server-side package inspection, malware scanning, and moderation
- Admin review tools and submission status management
- Persistent community suggestions and voting
- Server-backed analytics and reporting
- Clear privacy, terms, and support policies
- Production error handling, logging, and automated tests

Current demo behavior includes:

- Listing and suggestion data is in-memory and may reset when the app restarts
- My Apps is an in-session library, not a synced account library
- GitHub project submissions are suggestions for review; they are not automatically built or imported
- Website metadata fetching may fail for sites that block requests or have restrictive browser CORS policies
- A locally imported ZIP is available on the importing device; it is not automatically published to the cloud

## Security considerations

Treat submitted websites and uploaded ZIP files as untrusted content.

For a production implementation:

- Validate URLs and allow only HTTP/HTTPS
- Apply server-side SSRF protections to metadata and preview endpoints
- Validate DNS and redirect destinations; block private and reserved IP ranges
- Limit upload size, expanded size, file count, processing time, and redirects
- Reject archive traversal and unexpected file types
- Scan and review uploaded packages before distribution
- Do not place API secrets, signing keys, or credentials in the Flutter client
- Define WebView navigation, JavaScript, download, and external-link policies

The ZIP importer performs local checks, but those checks are not a substitute for a secure production upload and moderation service.

## Contributing

Contributions, bug reports, and feature suggestions are welcome.

1. Fork the repository.
2. Create a branch for your change.
3. Make and test the change.
4. Submit a pull request with a clear description.

For bugs, include your Flutter version, target platform, reproduction steps, and relevant logs. Please remove personal information and secrets from logs before sharing.

## License

No open-source license has been selected for this repository yet. Until a license is added, all rights remain with the copyright holder and reuse is not automatically granted.

If you intend to distribute this project publicly, choose and add a license file before inviting external contributions.
