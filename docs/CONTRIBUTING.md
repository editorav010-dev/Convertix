# Contributing

## Branch Naming

```
feature/[tool]-[description]    →  feature/video-compression-slog2-filter
fix/[tool]-[description]        →  fix/audio-converter-flac-output-crash
refactor/[scope]-[description]  →  refactor/ffmpeg-service-cleanup
docs/[description]              →  docs/update-architecture-folder-structure
```

## Commit Messages

Follow conventional commits:

```
feat(video-compression): add HDR10 tone mapping filter chain
feat(audio-converter): add OPUS output support
fix(backend-service): handle timeout correctly on large PDF merge
fix(split-pdf): zip archive not opening on Android
docs(architecture): update folder structure after core refactor
refactor(ffmpeg-service): extract filter chain builder to separate method
chore(deps): upgrade ffmpeg_kit_flutter to 6.x
```

## Commit Rules

- One feature or fix per commit
- Never mix refactors with feature work in the same commit
- Include the affected tool name in the scope where possible
- Write the message in imperative: "add", "fix", "update" — not "added", "fixed"

## Branch Rules

1. Never commit directly to `main`
2. Every feature, fix, or refactor gets its own branch
3. PRs should be small and focused — one concern per PR
4. Run `flutter analyze` before pushing — zero issues allowed
5. Run `flutter test` before pushing — all tests must pass

## Documentation Sync (Mandatory)

When you make a change, update all affected docs **in the same commit**.

| Type of change | Files to update |
|---|---|
| New feature or tool | SPEC.md, ARCHITECTURE.md, ROADMAP.md, STATE.md |
| New backend endpoint | ARCHITECTURE.md (endpoint table + flow), SETUP.md |
| New Flutter dependency | SETUP.md (key deps table), pubspec.yaml |
| Folder structure change | ARCHITECTURE.md (folder tree) |
| Bug resolved | STATE.md (mark resolved, update active tasks) |
| Phase completed | ROADMAP.md (mark done), STATE.md (update current phase) |
| LOG/HDR profile added | SPEC.md (profiles table), log_profiles.dart, AGENTS.md |

The docs are not optional. If the docs drift from the code, agents reading them will produce wrong output.

## Code Style

- Follow the official Dart style guide
- `flutter_lints` is enabled — all rules enforced, no exceptions
- Keep widget files under 300 lines; extract sub-widgets when over
- No business logic in screen files — all logic lives in providers and services
- No direct FFmpegKit calls outside `ffmpeg_service.dart`
- No direct Dio calls outside `backend_service.dart`
- No hardcoded file paths — always use `path_provider`

## Adding a New LOG/HDR Profile

1. Add the profile to `log_profiles.dart` with a tested filter chain
2. Update the profiles table in `SPEC.md`
3. Update `AGENTS.md` to list the new profile in the guardrails section
4. Test on real LOG footage before merging
