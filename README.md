# Filmbuster

Filmbuster is a cross-platform movie catalogue client written in Flutter. It
browses movie metadata and plays openly licensed films.

- **Demo mode (default).** Works right after `git clone`, with no account,
  API key or server. The app reads a bundled offline catalogue of six open
  movies by the Blender Foundation and streams them from their public hosts.
- **Live mode.** Point the app at your own backend that implements the
  Filmbuster API v1 contract. The backend proxies TMDB metadata and lists
  playback sources; the client never calls the TMDB API itself and holds no
  TMDB key (it loads poster images from `image.tmdb.org`).

The mode is fixed at build time: an empty or absent `API_BASE_URL` builds the
demo app, any other value builds the live app. Live mode never falls back to
demo.

## Features

- Home with popular, top-rated and trending rows, search, movie and person
  pages.
- Playback with [media_kit](https://pub.dev/packages/media_kit) on mobile and
  desktop and the browser `<video>` element on the web, including an
  experimental VR cinema mode on mobile devices.
- Trailers open as external links.
- About screen with credits, the TMDB notice and the open-source licenses of
  every bundled package.

## Platforms

Android, iOS, macOS and the web.

## Quick start

Requirements: Flutter 3.47.x stable (Dart ^3.10). CI uses Flutter 3.47.9.

```bash
git clone https://github.com/devleloper/filmbuster.git
cd filmbuster
flutter pub get
flutter run                     # demo mode: no configuration needed
```

### Live mode

Build-time configuration only: nothing is read from files at runtime, and
every `--dart-define` value is readable inside the compiled app, so never pass
secrets.

```bash
# a single value
flutter run --dart-define=API_BASE_URL=http://localhost:8080

# or a local file based on the template (.env is ignored by git)
cp .env.example .env            # then set API_BASE_URL
flutter run --dart-define-from-file=.env
```

- The Android emulator reaches the host machine at `10.0.2.2`, not
  `localhost`.
- A live **web** build also needs the app's origin in the backend's CORS
  allowlist, the backend origin in the `connect-src` directive of
  `vercel.json` (or of your own hosting's Content Security Policy), and every
  video host your backend streams from in `media-src`.
- The backend contract is OpenAPI 3.1, Filmbuster API version 1.1.0:
  [`api/openapi.yaml`](api/openapi.yaml). Any server that implements it works
  with the client in live mode.

### Web build

```bash
flutter build web --release     # demo build, output in build/web
```

`vercel.json` holds the SPA rewrite and the security headers used for the
hosted demo.

## Architecture

Layers: `domain/` (models and repository interfaces, plain Dart) in the
centre; `data/` implements it, `presentation/` uses it, `core/` holds the
framework glue. Dependencies point inward only. State management
with Bloc/Cubit, navigation with go_router, dependency injection with get_it
(one composition root), HTTP with dio. Rules, directory map and data flow:
[ARCHITECTURE.md](ARCHITECTURE.md).

## Tests and checks

```bash
tool/ci.sh                      # pub get (locked), format check, analyze, tests
tool/ci.sh --build-web          # the same, plus flutter build web --release
```

CI runs `tool/ci.sh --build-web` on every pull request and on `main`
(`.github/workflows/ci.yml`). See [CONTRIBUTING.md](CONTRIBUTING.md).

## TMDB

This product uses TMDB and the TMDB APIs but is not endorsed, certified, or
otherwise approved by TMDB.

Movie metadata and images in live mode come from
[The Movie Database (TMDB)](https://www.themoviedb.org). The app shows this
notice and the TMDB logo on its About screen, as the
[TMDB API Terms of Use](https://www.themoviedb.org/api-terms-of-use) require.
Forks must keep the notice and use only the approved logos from
[TMDB's logos and attribution page](https://www.themoviedb.org/about/logos-attribution),
less prominent than the app's own logo.

## Open movies

The demo catalogue streams these films by the Blender Foundation from their
public hosts; the films are not part of this repository. Posters and backdrops
in `assets/demo/images/` are derived from the films' official stills.

| Film | License | Source |
| --- | --- | --- |
| Big Buck Bunny (2008) | CC BY 3.0 | <https://peach.blender.org/about/> |
| Elephants Dream (2006) | CC BY 2.5 | <https://orange.blender.org/> |
| Sintel (2010) | CC BY 3.0 | <https://durian.blender.org/about/> |
| Tears of Steel (2012) | CC BY 3.0 | <https://mango.blender.org/about/> |
| Cosmos Laundromat (2015) | CC BY 3.0 | <https://gooseberry.blender.org/about/> |
| Spring (2019) | CC BY 4.0 | <https://studio.blender.org/projects/spring/> |

Full credits are in [NOTICE](NOTICE) (section 7) and on the app's About
screen.

## Contributing and security

- [CONTRIBUTING.md](CONTRIBUTING.md): setup, checks, commit and pull request
  rules.
- [SECURITY.md](SECURITY.md): report vulnerabilities privately, never in a
  public issue.
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
- [CHANGELOG.md](CHANGELOG.md).

## License

The source code is licensed under the [MIT License](LICENSE),
Copyright (c) 2026 devleloper.

Exception: the Filmbuster name, the Filmbuster logos and the cassette image
are trademarks of devleloper, all rights reserved, and are not covered by the
MIT License. Forks and redistributed modified versions must replace them with
their own name and logo.

Third-party material (Poppins font, TMDB logo, native media libraries under
the LGPL, open movies) keeps its own license: see [NOTICE](NOTICE).
