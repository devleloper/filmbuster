# Contributing to Filmbuster

Thanks for your interest. This guide covers setup, the checks every change
must pass, and how pull requests are reviewed. By taking part you agree to
follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Setup

1. Install Flutter 3.47.x stable (CI uses 3.47.9) and the platform tools for
   the targets you work on (Xcode for iOS and macOS, Android SDK for Android,
   Chrome for the web).
2. Clone and fetch packages:

   ```bash
   git clone https://github.com/devleloper/filmbuster.git
   cd filmbuster
   flutter pub get
   ```

3. Run the app. Without configuration it starts in demo mode, which needs no
   server or key:

   ```bash
   flutter run
   ```

   For live mode against your own backend, see the README ("Live mode").
   Keep local values in `.env` (ignored by git), never in committed files.

## Checks

All checks live in one script, and CI runs the same script:

```bash
tool/ci.sh                      # pub get (locked), format check, analyze, tests
tool/ci.sh --build-web          # the same, plus flutter build web --release
```

A pull request is ready for review only when `tool/ci.sh --build-web` passes
locally. If you change `pubspec.yaml`, commit the updated `pubspec.lock`:
CI runs `flutter pub get --enforce-lockfile`.

## Code style

- Format with `dart format lib test`; CI fails on unformatted files.
- `flutter analyze` must report no issues; the rules are in
  `analysis_options.yaml`. Do not silence a lint without a comment that
  explains why.
- Follow the layer rules in [ARCHITECTURE.md](ARCHITECTURE.md): `domain/` has
  no Flutter or HTTP imports, widgets never call API services, and
  dependencies come through constructors.
- New behaviour comes with tests in `test/` (unit tests for logic, widget
  tests for UI).
- Do not commit secrets, API keys, signing files or personal data. Any
  `--dart-define` value is readable inside the compiled app.

## Content rules

- Playback sources must be legal to stream: openly licensed films, public
  domain works, or media the user owns. Changes that add unlicensed
  copyrighted content, or tools to obtain it, are not accepted.
- Keep the TMDB notice and the third-party credits in `NOTICE` and on the
  About screen. A new bundled asset (font, image, animation) needs its source
  and license added to `NOTICE` in the same pull request.
- The Filmbuster name and logos are trademarks of devleloper (see the
  README, "License"). Do not add or change brand assets without asking first.

## Commits

Use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):

```
<type>(<optional scope>): <summary in the imperative mood>
```

Types: `feat`, `fix`, `perf`, `refactor`, `test`, `docs`, `build`, `ci`,
`chore`. Mark breaking changes with `!` after the type (`feat!: …`) and a
`BREAKING CHANGE:` footer.

## Pull requests

1. Open an issue first for anything larger than a small fix, so the approach
   can be agreed before you write code.
2. Branch from `main` and keep one concern per pull request.
3. Fill in the pull request template: what changed, why, how you tested it,
   and screenshots for UI changes.
4. Add a line under `[Unreleased]` in [CHANGELOG.md](CHANGELOG.md) for any
   user-visible change.
5. CI (`ci / checks`) must be green. `main` keeps a linear history, so pull
   requests are squash-merged or rebased.

## Reporting bugs and security issues

- Bugs and feature ideas: use the issue templates. Do not paste tokens,
  private server addresses or other personal data into issues or logs.
- Security vulnerabilities: never open a public issue. Follow
  [SECURITY.md](SECURITY.md).

## License

By contributing you agree that your contribution is licensed under the
[MIT License](LICENSE) of this project.
