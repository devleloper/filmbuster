# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
A release tag `vX.Y.Z` matches `version: X.Y.Z+N` in `pubspec.yaml`; the build
number `N` grows with every store or web build.

## [Unreleased]

## [1.0.0] - Unreleased

First public release.

### Added

- Demo mode as the default build: a bundled offline catalogue of six open
  movies by the Blender Foundation (Big Buck Bunny, Elephants Dream, Sintel,
  Tears of Steel, Cosmos Laundromat, Spring) that works without any server or
  key, with a "Demo" badge on Home.
- Live mode selected at build time with `--dart-define=API_BASE_URL=…` or
  `--dart-define-from-file=.env`, against any backend that implements the
  Filmbuster API v1 contract (1.1.0), including its playback-source list.
- Home with popular, top-rated and trending rows; search that ranks exact
  title matches first; movie and person pages.
- Playback with media_kit on Android, iOS and macOS and the browser video
  element on the web, with an experimental VR cinema mode on mobile devices.
- Trailers and source pages open as external links.
- About screen with the TMDB notice and logo, open-movie credits and the
  licenses of all bundled packages.
- Error messages for backend problem responses (RFC 9457).
- `tool/ci.sh`: one script for format, analysis, tests and the web build,
  used locally and in CI.
- MIT license, `NOTICE` with third-party terms, and community files.

### Security

- Build-time configuration only: no configuration file is bundled with the
  app.
- Release builds log nothing by default, and logged URLs have their query
  strings redacted.
- Security headers and a Content Security Policy for the hosted web build
  (`vercel.json`).

[Unreleased]: https://github.com/devleloper/filmbuster/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/devleloper/filmbuster/releases/tag/v1.0.0
