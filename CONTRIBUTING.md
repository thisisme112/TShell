# Contributing to TShell

Thank you for helping improve TShell, a cross-platform SSH terminal and remote operations workstation built with Flutter.

## Getting Started

1. Install Flutter with the Android and Windows desktop toolchains you need.
2. Clone the repository and fetch dependencies:

   ```sh
   flutter pub get
   ```

3. Run the standard checks before opening a pull request:

   ```sh
   flutter analyze
   flutter test
   ```

4. For release-target changes, also build the relevant platform:

   ```sh
   flutter build windows --release
   flutter build apk --release
   ```

## Development Guidelines

- Keep user credentials, SSH keys, and host metadata out of logs and test fixtures.
- Prefer small, focused pull requests with clear descriptions.
- Add or update tests for behavior changes when practical.
- Keep UI text and workflows understandable for both desktop and Android users.
- Document any platform-specific limitation in the pull request.

## Pull Request Checklist

- [ ] `flutter analyze` passes.
- [ ] `flutter test` passes.
- [ ] Windows or Android build was run for platform-specific changes.
- [ ] Security-sensitive changes describe how secrets are protected.
- [ ] Documentation was updated for user-visible behavior changes.

## Issue Guidelines

When opening an issue, include:

- The TShell version or commit SHA.
- Operating system and architecture.
- Expected behavior.
- Actual behavior.
- Steps to reproduce.
- Screenshots or logs if helpful, with secrets removed.

## License

By contributing, you agree that your contributions are licensed under the MIT License.
