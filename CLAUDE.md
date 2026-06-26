# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

WSL Manager is a Flutter Windows desktop application (portable EXE, no installer) for visually managing WSL2 instances: create, start/stop, delete, duplicate, rename, snapshots, templates, CPU/RAM monitoring, and systray integration.

- **Flutter** stable channel >= 3.22, **Dart** >= 3.4
- **Target**: Windows 11 x64 only
- The `wsl_manager/` directory is the Flutter project. The `wsl_manager_output/` directory holds the design documentation (TODO.md, README.md, docs/).

## Commands

All commands run from `wsl_manager/`:

```powershell
# Install dependencies
flutter pub get

# Run in development
flutter run -d windows

# Generate Riverpod provider code (required after modifying providers)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for code generation
dart run build_runner watch --delete-conflicting-outputs

# Generate app icons
dart run flutter_launcher_icons

# Analyze
flutter analyze

# Format
dart format lib/

# Test
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Build release
flutter build windows --release
# Output: build\windows\x64\runner\Release\

# Build portable ZIP (build + package)
.\scripts\build_portable.ps1
# Output: dist\WSLManager_portable.zip
```

## Architecture

### Layer structure (`lib/`)

```
main.dart          — window_manager init, flutter_acrylic Mica effect, systray init
app.dart           — MaterialApp.router, theme, go_router config
models/            — Plain Dart data classes: WslInstance, WslTemplate, WslSnapshot, AppConfig
services/          — All side-effecting logic (WSL commands, file I/O, network)
providers/         — Riverpod providers (AsyncNotifierProvider, StreamProvider)
screens/           — Feature screens with nested widgets/
widgets/           — Shared reusable widgets
utils/             — Constants, WslParser, validators
```

### State management

**Riverpod** (flutter_riverpod ^2.5.1) with code generation (`@riverpod` annotation). Every provider file requires `dart run build_runner build` after changes. Key providers:

- `InstancesNotifier` (AsyncNotifierProvider) — drives the dashboard list
- `monitoringStream` (StreamProvider) — polling CPU/RAM via `/proc/stat` and `/proc/meminfo`
- `ConfigNotifierProvider` — user settings from `config.json`

### Routing

**go_router** routes:
- `/` → DashboardScreen
- `/instance/:name` → InstanceDetailScreen
- `/create` → CreateWizardScreen
- `/templates` → TemplatesScreen
- `/snapshots` → SnapshotsScreen
- `/settings` → SettingsScreen

### WSL interaction

All WSL calls go through `WslService` using `dart:io Process.run()` / `Process.start()`. Long-running operations (`--export`, `--import`, `--set-version`) must use `Process.start()` (non-blocking) or be run in an `Isolate` — never `Process.run()`, which will block the UI.

**Critical gotcha — UTF-16 encoding**: `wsl --list --verbose` outputs UTF-16 LE on Windows. Decode manually if the raw bytes contain null `\x00` characters:
```dart
final bytes = result.stdout as List<int>;
final decoded = utf8.decode(bytes.where((b) => b != 0).toList());
```
The parsing logic lives in `lib/utils/wsl_parser.dart`.

### Local data storage

Persisted to `%LOCALAPPDATA%\WSLManager\` via `path_provider`'s `getApplicationSupportDirectory()`:
- `templates.json` — WslTemplate list
- `snapshots.json` — WslSnapshot list
- `config.json` — AppConfig
- `templates\` and `snapshots\` — `.tar` files

All read/write is handled by `StorageService`.

### UAC elevation

The app launches without admin rights (`asInvoker` in `Runner.exe.manifest`). Elevation is requested on-demand only for `wsl --set-version` (WSL1↔WSL2 conversion). The `UacService` uses `win32`'s `OpenProcessToken`/`GetTokenInformation` to detect elevation state and `ShellExecuteEx` with `runas` to relaunch. A `UacBanner` widget is shown on the dashboard when not elevated.

### Systray

Requires a `.ico` file (not PNG) at `assets/icons/app_icon.ico`. The menu is regenerated on every instance state change. Window close behaviour is configurable: if `config.minimizeToTray == true`, closing the window hides it instead of quitting.

## Key packages

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management |
| `go_router` | Navigation |
| `win32` | UAC detection, ShellExecuteEx |
| `window_manager` | Window size/title/titlebar |
| `flutter_acrylic` | Mica/Acrylic effect (Windows 11) |
| `system_tray` | Systray icon and menu |
| `process_run` | Shell command helpers |
| `dio` | HTTP downloads with progress |
| `path_provider` | AppData directory |
| `file_picker` | .tar file selection |
| `percent_indicator` | CPU/RAM gauges |

## Development notes

- **Mock mode**: For development without WSL installed, add a mock path in `WslService` guarded by `kDebugMode && Platform.isMacOS` (or similar).
- **Passwords**: Never log or persist passwords. Clear String variables holding passwords immediately after the WSL command completes.
- **WSL registry**: Instance metadata (install path, creation date) is in `HKCU\Software\Microsoft\Windows\CurrentVersion\Lxss\`.
- **Rename = export + import + unregister**: WSL has no native rename command; simulate it in `WslService.renameInstance()`.
- **Files encoding**: All project source files must be UTF-8 without BOM, LF line endings.
- **Design docs**: `wsl_manager_output/TODO.md` contains the full 144-task development guide with code snippets for every service method, widget, and provider. Consult it before implementing any feature.

## Release

Utilise le skill projet `/git-release` (`.claude/skills/git-release/SKILL.md`) pour le cycle complet de release.
Ce skill remplace le skill global : il utilise l'API REST GitHub (pas `gh` CLI, non installé), déclenche le build via `workflow_dispatch`, et connaît les spécificités du projet (token Windows Credential Manager, exclusion de `.claude/settings.local.json`, format de tag `V<major>.<minor>.<patch>`).
