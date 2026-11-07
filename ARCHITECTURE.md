# Filmbuster client architecture

This document is for contributors who need to change the client without
breaking the rest of it. It covers the shape of the code and the rules that
keep it that way. The code's doc comments are the API reference.

Filmbuster is a Flutter app for iOS, Android, macOS and the web. It browses
movie metadata and plays openly licensed films. Without configuration it runs
on a bundled catalogue (demo mode); given a backend URL it reads TMDB data
through that backend (live mode). The same build adapts to touch screens,
desktops and TV remotes.

## Layers

```
presentation/   screens, layouts, Cubits/Blocs, design system
      │ depends on
      ▼
domain/         models and repository interfaces (plain Dart)
      ▲ implements
      │
data/           API services, bundled catalogue, repository implementations

core/           configuration, DI, errors, network, routing, utilities
```

Dependencies point at `domain/`. `domain/` knows nothing about the other
layers, `presentation/` talks to repository interfaces and never to `data/`
classes, and only `data/` and `core/network/` know that HTTP exists.

The tests in `test/architecture/` check these rules:

| Rule | Reason |
| --- | --- |
| `domain/` imports only `dart:`, `equatable` and `domain/` | Models and interfaces stay plain Dart and test without a binding. |
| `presentation/` imports no `data/` and no `dio` | Screens see repository interfaces; `injector.dart` alone decides between demo and live data. |
| A feature imports no other feature | Shared code moves to `domain/`, `core/` or `presentation/widgets/`. |
| `presentation/widgets/` and `presentation/theme/` import no feature and no `go_router` | Shared components get data and callbacks from their callers. |
| `core/` imports `data/` and `presentation/` only in `di/injector.dart` and `router/app_router.dart` | These two files compose the app; everything else in `core/` is feature-agnostic. |
| `getIt` appears only in `core/di/` and `*_screen.dart` | Cubits and Blocs receive their dependencies through the constructor. |
| `DioException` appears only in `data/` and `core/network/` | Above them every error is an `AppFailure`. |
| Screens navigate through `AppRoutes`, never a path literal or a route name | A route change is one edit. |
| Only `MediaKitPlaybackEngine` uses `media_kit`'s `Player` | See [The player](#the-player). |

## Directory map

```
lib/
├─ main.dart          app entry: licenses, DI, media_kit, TV detection, router
├─ core/
│  ├─ app_ready/      start-up state shared by the splash and Home
│  ├─ config/         AppConfig (compile-time values), DataSourceMode
│  ├─ di/             injector.dart, the composition root
│  ├─ error/          AppFailure and its subtypes
│  ├─ licenses/       license texts Flutter's NOTICES lacks, content credits
│  ├─ logging/        AppLogger (debug builds only, strips URL queries)
│  ├─ network/        DioFactory, FailureMapper
│  ├─ router/         AppRoutes, the route table, typed route arguments
│  └─ utils/          DeviceDetector, ResponsiveLayout, ExternalUrl,
│                     TmdbImageUrl, media and text helpers
├─ domain/
│  ├─ models/         TmdbMovie, TmdbMovieDetails, MovieSource, PlayerSource, …
│  └─ repositories/   MovieRepository, PersonRepository,
│                     MovieSourcesRepository, OpenMovieRepository
├─ data/
│  ├─ local/          BundledCatalog and the demo repositories
│  ├─ remote/         TmdbApiService, MovieSourcesApiService, api_guard.dart
│  └─ repositories/   live repository implementations
└─ presentation/
   ├─ theme/          design tokens
   ├─ widgets/        design-system components and shared widgets
   ├─ screens/        MainScreen, the tab shell around Home and Search
   └─ features/       about, detail, home, person, player, search, splash
```

### A feature

```
features/<name>/
├─ bloc/      <name>_cubit.dart and <name>_state.dart
├─ view/      <Name>Screen: creates the Cubit, resolves dependencies, picks a layout
├─ layouts/   the screen body, one file per layout mode when they differ (optional)
└─ widgets/   parts used by this feature only
```

`view/` stays thin: it reads what it needs from `getIt`, provides the Cubit
and hands over to a layout.

The player adds `models/`, `services/`, `utils/` and `vr/` for its engine,
timings, gesture helpers and VR mode.

A widget used by more than one feature moves to `presentation/widgets/`. A
model that crosses a feature boundary moves to `domain/models/`; for example
`PlayerSource` travels from Detail to the player in `PlayerRouteArgs`.

## State

Features use Cubits. The player is the only Bloc, because its events carry
data and their order matters.

- States are `Equatable`. A screen with distinct phases (loading, content,
  error) gets a `sealed` state, so a `switch` over it is exhaustive and a new
  state fails to compile wherever it is not handled. `PlayerState` is one
  class: its controls stay on screen while it loads, seeks and recovers.
- After every `await`, check `isClosed` before `emit`: the screen may have
  been closed in the meantime.
- A Cubit that can receive answers out of order keeps a generation counter
  and drops stale results (`SearchCubit`, `DetailCubit`).
- A one-off message is data with an id, not a command: `PlayerState.notice`
  plus `noticeId`, which `copyWith(notice:)` increases. The view listens with
  `listenWhen` on the id, so a rebuild does not show the message again and a
  repeated message still shows.
- Anything time-dependent takes its durations through the constructor
  (`PlayerTimings`), so tests can shorten them.

## Errors

Everything that can fail ends as an `AppFailure`:

```
AppFailure (sealed)
├─ NetworkFailure     the server could not be reached
├─ TimeoutFailure     the request took too long
├─ ServerFailure      5xx or 429
├─ NotFoundFailure    404, or nothing usable in the answer
├─ ValidationFailure  the server rejected the request
├─ ParsingFailure     the payload does not match the contract
└─ UnknownFailure     anything else
```

`guardApiCall` in `data/remote/api_guard.dart` wraps each API call and uses
`FailureMapper` to convert transport errors. Each failure carries a `message`
written for the user; views show that message and never a stringified
exception. In a `catch` block, use `error.toAppFailure(stackTrace)`.

Parsing is strict. A response of the wrong shape is a `ParsingFailure`, never
an empty list, so a broken backend is reported instead of showing "nothing
found".

## Data sources: demo and live

One compile-time value picks the data source. An empty or missing
`API_BASE_URL` means demo mode; any other value means live mode.
`AppConfig.dataSource` derives the mode, and `core/di/injector.dart` is the
only place that branches on it.

| Interface | Demo | Live |
| --- | --- | --- |
| `MovieRepository` | `DemoMovieRepository` | `MovieRepositoryImpl` |
| `PersonRepository` | `DemoPersonRepository` | `PersonRepositoryImpl` |
| `MovieSourcesRepository` | `BundledCatalog` | `MovieSourcesRepositoryImpl` |
| `OpenMovieRepository` | `BundledCatalog` | `BundledCatalog` |

- Demo mode registers no `Dio`, so it cannot send a request. Live mode never
  falls back to bundled data.
- Widgets learn the mode only from values their `*Screen` passes in, such as
  `HomeLayout(isDemo:)`.
- `assets/demo/catalog.json` holds movie details in the API's shape plus an
  `openMovie` block with license, attribution, source page and streams.
  `BundledCatalog` parses it once and checks every reference; a damaged file
  is a `ParsingFailure`. The catalogue contains only CC BY and public-domain
  films, each credited in the app and in `NOTICE`, and no TMDB data.
- Bundled images use an `asset:` prefix. `TmdbImageUrl.build` returns `null`
  for them and `TmdbImageUrl.bundledAsset` gives the asset key; `MediaImage`
  handles both kinds.

### Playback sources

`DetailCubit` loads the movie and its sources concurrently.
`DetailSuccess.sources` is a sealed `SourcesStatus` (`SourcesLoading`,
`SourcesLoaded`, `SourcesFailed`), so a sources failure never fails the page,
and `retrySources()` reloads only the sources. Play opens the player with the
first playable source and offers the others as qualities. On the web, Detail
keeps only sources the browser can play (`isBrowserPlayable`). Source URLs
are played exactly as received.

### External links

`ExternalUrl` in `core/utils/` is the only caller of `url_launcher`. It opens
absolute `https` URLs in an external browser or app, never in an in-app web
view. Widgets show links with `TextLink` and pass
`ExternalUrl.onTapFor(uri)`, which disables the link when the URL is missing
or not allowed. Trailers come only from live data. The About screen shows the
TMDB notice and logo, a credit for every bundled film, and the open-source
licenses.

## Routing

Paths come from `AppRoutes` (`AppRoutes.detail(id)`, never `'/detail/$id'`).
`core/router/app_router.dart` holds the route table: Home and Search are
branches of a `StatefulShellRoute` inside `MainScreen`, and every other screen
opens full screen above it. Such a route names the root navigator as its
`parentNavigatorKey`; without it go_router pushes the screen inside the
current tab, under the tab bar.

Route arguments are typed objects passed as `extra` and declared in
`core/router/route_args.dart`. `extra` is lost on deep links and web reloads,
so a route that cannot work without it redirects: `/player` without
`PlayerRouteArgs` goes to Home. Back buttons call `context.popOrGoHome()`,
which also works when a screen was opened directly from a link.

## Layout modes

Two independent questions decide how a screen looks.

**Which layout: touch or leanback.** `DeviceDetector.isLeanback` decides it
from the input kind, not the screen width:

| Input kind | Detected by | Layout |
| --- | --- | --- |
| `directional` (TV remote, D-pad) | `MediaQuery.navigationModeOf` is `directional` | leanback |
| `touch` | iOS and Android | touch, at any width |
| `pointer` | macOS, Windows, Linux | leanback from 900 dp, touch below |

`main.dart` switches the app to directional navigation on an Android TV
(`DeviceDetector.detectTelevision`) or when built with
`--dart-define=FORCE_LEANBACK=true`, which is the way to try the TV layout on
any device. Each screen has one layout and asks `DeviceDetector` where touch
and leanback differ.
Leanback layouts must work with arrows and Enter alone: every control takes
focus, and traversal order is set with `FocusTraversalOrder` where the visual
order is not enough. In leanback the tabs move to a side rail.
`AdaptiveScaffold` reports the space its navigation covers to the body as
safe-area padding: in leanback the rail on the left and the dark lower half
of the bottom fade, on touch layouts the bottom bar. Lists inside a tab use
`SafeArea(bottom: false)` and pad their end with
`MediaQuery.paddingOf(context).bottom`. The tabs are the `AppTab` values;
the router builds one shell branch per value, in that order.

**How big: breakpoints.** `ResponsiveLayout.of(context)` maps the window width
to a breakpoint (compact, medium, large, xlarge) with a `scaleFactor`, page
gutters and the poster card size. Scale a dimension with `r.scaled(base)`
and a text style with `r.scaleText(style)`. A size that belongs to one
feature lives in that feature and switches on `r.breakpoint`. Body text is
capped at `ResponsiveLayout.maxTextWidth`. A horizontal rail such as
`MoviePosterReel` or `PersonsReel` spans the full width and insets its title
and first card by the page gutter itself, so screens place it unpadded.

## Design system

The app draws its own components. `MaterialApp`, `Scaffold` and `Navigator`
are used as infrastructure, but Material visuals such as `AppBar`,
`ElevatedButton` or `Slider` are not. `SliverAppBar` is used on Detail for
its collapsing behaviour only; its content is design-system widgets.

**Tokens** in `presentation/theme/`: `AppColors`, `AppGradients`,
`AppTextStyles`, `AppSpacing`, `AppRadius`, `AppDurations`, `AppShadows`,
`AppFocus` (the focus ring) and `AppMotion` (durations that collapse to zero
when the user reduces motion). Use a token before writing a literal.
`test/architecture/design_system_literals_test.dart` keeps a budget of the
literals left in `features/`; it may go down, never up. A literal that is
genuinely one-off carries a `// design-literal: <reason>` comment.

**Components** in `presentation/widgets/`:

- Controls: `AppFocusable` (focus, activation by Enter, Space and Select,
  semantics and the focus ring for any custom control), `AppIconButton`,
  `PrimaryButton`, `SecondaryButton`, `FocusableLiftCard`, `SelectableRow`,
  `AppSlider`, `TextLink`.
- Containers: `AppHeader`, `AppCard`, `GlassSheet`, `AdaptiveScaffold`,
  `GlassNavBar`.
- Media: `MediaImage` (decodes at display size, handles bundled and network
  images; every poster, backdrop and portrait goes through it),
  `MoviePosterCard`, `MoviePosterReel`, `RatingLabel`, `StaggeredEntrance`.
- Feedback: `LoadingStateView`, `ErrorStateView` and `EmptyStateView` replace
  a screen's content; `AppLoadingIndicator`, `ShimmerGroup` and
  `showErrorSnackBar`.
- Attribution: `TmdbAttribution`, `LicenseCredit`, `AttributionSection`,
  `CreditTile`, `DemoBadge`, `showAppLicensePage`.

New controls build on `AppFocusable` so that focus, keyboard activation and
the focus ring behave the same everywhere. Every interactive element has a
semantic label and a target of at least 48 dp.

## The player

The player streams video over HTTP through `media_kit`, which wraps mpv. A
remote stream can be slow or stop answering in the middle of a frame, so this
is the one part of the app with real complexity.

```
PlayerScreen            creates PlayerBloc with a PlaybackEngine from getIt,
                        hides the system bars and the system volume
                        indicator, turns PlayerCommands into Bloc events
└─ PlayerBloc           session state, viewer commands, deadlines
   ├─ PlaybackEngine    interface; MediaKitPlaybackEngine is the only
   │                    adapter around media_kit's Player
   ├─ SeekCoordinator   one seek at a time, escalating recovery
   ├─ StallWatchdog     asks for recovery when buffering lasts too long
   └─ ProgressThrottle  picks the engine statuses worth a new state
```

The player receives a ready `PlayerSource` and the movie's other sources in
`PlayerRouteArgs`. It depends on no repository and does not know where a
source came from.

**Engine boundary.** `PlaybackEngine` owns the `media_kit` player. It
publishes status (`PlaybackStatus`) and tracks (`PlayerTracks`) as broadcast
streams that survive `recreateAt`, which throws away an unresponsive player
and builds a new one at the same position. `PlayerState.engineGeneration`
tells the video surface to pick up the new render handle. Widgets never touch
the engine. The overlay takes a `PlayerOverlayData` slice of the state and
one `PlayerCommands` object, which `PlayerScreen` implements by adding events
to the Bloc (`PlayerPlayPauseToggled`, `PlayerSeekRequested`,
`PlayerAudioTrackSelected`, and so on).

Two properties of the stack shape this design:

1. **mpv waits on a network read forever** unless told otherwise. The engine
   sets reconnect and read-timeout options, so a stalled read becomes a
   recoverable error.
2. **`media_kit` runs every command behind one lock** and considers it done
   only when mpv answers. One unanswered command blocks every later `play`,
   `pause` or `seek`. So the Bloc never awaits a command without a deadline
   (`PlayerTimings.engineCommand`); when one expires, the viewer sees a
   notice and the engine is rebuilt. A command that fails outright is only
   logged.

**Seeking.** The view reports intent: `PlayerSeekRequested` for an absolute
position, `PlayerRelativeSeekRequested` for a skip. The Bloc collects a burst
of skips into one seek. `SeekCoordinator` tries a plain seek, then reopening
the stream, then rebuilding the engine, each within its own budget, and
merges requests that arrive meanwhile into the latest target.

**Keyboard and D-pad.** While no control has focus, the overlay itself holds
it: Left and Right seek in steps for as long as the key is held, and Up
brings the controls back with focus on the centre Play button. Once a control
has focus, the arrows move between the controls. Controls that fade out hand
focus back to the overlay.

**Rebuilds.** Position and buffer change many times a second. `ProgressThrottle`
lets the Bloc publish them at most every `PlayerTimings.progressStep`, and only the
controls rebuild for them; `PlayerState.sameSurfaceAs` keeps the video
surface out of those rebuilds.

**VR mode** (`vr/`) renders the same session side by side for a phone in a
headset, steered by head tracking and head gestures. Entering VR creates one
`VrCamera`: the mode picker's preview opens it and the spatial scene takes it
over, so only one camera session exists; the scene closes it when it ends.

## Testing

```bash
flutter test      # unit and widget tests, no network
flutter analyze
dart format lib test
tool/ci.sh        # all of the above, as CI runs them
```

`test/` mirrors `lib/` and is hermetic: no backend, no key, no network.
A test file sits at its subject's path (`lib/presentation/widgets/x.dart` is
tested in `test/widgets/x_test.dart`, `lib/presentation/features/f/bloc/` in
`test/features/f/bloc/`); a large subject may split its tests by aspect
(`home_layout_header_test.dart`). Checks without a single subject sit
apart: `test/architecture/` (source rules), `test/android/` (platform
resources), `test/demo_mode_test.dart` (the app in demo mode, screen to
screen) and `test/widgets/text_scale_contrast_test.dart` (text scale,
contrast and target sizes across the components; a new component adds its
cases to the maps there).

- Cubits and Blocs are tested with `bloc_test` against `mocktail` fakes of the
  repository interfaces (`test/support/mocks.dart`).
- `PlayerBloc` runs on a `FakePlaybackEngine` (`test/support/`) with
  millisecond `PlayerTimings`, inside `testWidgets` so its timeouts run on
  the test clock.
- Screen tests either compose demo mode with `useDemoDependencies()`
  (catalogue from disk, answered synchronously because real asset I/O does
  not complete inside the tester's fake clock) or register mocked
  repositories in `getIt` directly.
- Layout tests that measure text load the real font with `loadPoppins()`;
  the default test font would hide or invent overflows. Other shared helpers
  live in `test/support/`: `inApp` puts a widget on a themed screen,
  `test_view.dart` sets the screen size, text scale and reduced motion,
  `disk_assets.dart` serves assets from disk, `recording_url_launcher.dart`
  records the links the app opens, plus focus and Tab helpers and contrast
  ratios.
- Test names state behaviour ("a stream reopened after the viewer paused
  stays paused"), and each test follows arrange, act, assert.

Worth testing, in this order: state sequences, model parsing including
malformed payloads, pure logic in `core/utils/` and the player services, and
widget behaviour and semantics (not pixels).

## Running locally

`flutter run` with no configuration starts demo mode: the bundled catalogue,
no backend and no key. Only video playback uses the network.

For live data, run the backend and pass its URL at build time, either with
`--dart-define=API_BASE_URL=...` or from a local, git-ignored copy of
`.env.example` with `--dart-define-from-file=.env`. Nothing is read from a
file at runtime, and every value is readable in the compiled app, so these
values must never hold secrets.

On macOS the app is sandboxed. If it cannot reach a backend on your machine
or network, check the network client entitlement and the
`NSAllowsLocalNetworking` key in `macos/Runner/` first.

## Code style

Write for the next developer who reads the code.

- Follow [Effective Dart](https://dart.dev/effective-dart) and the Flutter
  style guide. Prefer framework building blocks to hand-written ones, for
  example `Shortcuts` and `Actions` over raw key handlers, and
  `MediaQuery.sizeOf` over `MediaQuery.of`. Use `const` constructors.
- Comment only what the code cannot say: why something is done, or a
  constraint that is not visible. Do not restate the code or describe its
  history. A doc comment on a public API is one summary sentence, plus a
  paragraph only when it adds information. Remove commented-out code and
  debug prints.
- Name things for what they mean. Avoid abbreviations other than well-known
  ones, and type suffixes in names.
- Keep files, classes and functions small, each with one job. When part of a
  widget has its own state or is reused, extract a private widget class
  instead of a `_buildX` method.
- One implementation per concept: one focus ring, one track picker, one way
  to activate a control. Do not add abstractions, options or defensive checks
  for cases that cannot happen.
- Keep the layer rules above. If a change needs to break one, change the rule
  here first.
- A behaviour change comes with a test that fails without it.
