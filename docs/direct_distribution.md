# Direct Distribution

Menu Bar Wattage has two separate release outputs:

- The Mac App Store build is validated with `scripts/app_store_preflight.sh` and submitted through App Store Connect.
- The direct-download build is a Developer ID Application-signed, Hardened Runtime, notarized Apple Silicon ZIP attached to a GitHub Release.

## One-time Apple setup

The Mac must have:

1. An installed **Developer ID Application** certificate whose team is `2F328AJX43`.
2. Xcode command-line tools and `xcodegen` (`brew install xcodegen`).
3. A `notarytool` keychain profile configured once, for example:

   ```sh
   xcrun notarytool store-credentials menu-bar-wattage-notary \
     --apple-id 'developer@example.com' \
     --team-id '2F328AJX43' \
     --password 'app-specific-password'
   ```

Use an app-specific password, never a normal Apple ID password. The profile name is local to the keychain and is not committed.

## Build and notarize

From the repository root, set the local profile name and run:

```sh
NOTARY_PROFILE=menu-bar-wattage-notary \
MARKETING_VERSION=1.0.0 \
CURRENT_PROJECT_VERSION=1 \
./scripts/direct_distribution.sh
```

The script regenerates the Xcode project, archives an arm64 app, signs it with `Developer ID Application`, verifies the Hardened Runtime, submits the ZIP to Apple, staples the ticket, validates it with `stapler` and `spctl`, then writes:

```text
.build/direct_distribution/MenuBarWattage-<version>-<build>-macOS-arm64.zip
.build/direct_distribution/MenuBarWattage-<version>-<build>-macOS-arm64.zip.sha256
```

The ZIP is rebuilt after stapling so the distributed artifact contains the stapled app. The checksum is generated from that final ZIP.

## Publish a GitHub Release

Run the opt-in publish flow after notarization. It creates GitHub Release `v1.0.0` against the current commit if the release does not exist, then uploads both files:

```sh
NOTARY_PROFILE=menu-bar-wattage-notary \
RELEASE_TAG=v1.0.0 \
./scripts/direct_distribution.sh --publish
```

This requires an authenticated `gh` CLI and a release tag that points to the current commit. Do not commit the ZIP, DMG, archive, signing identities, Apple credentials, or notarization profile to the repository.

## Troubleshooting and manual fallback

- `security find-identity -v -p codesigning` confirms the Developer ID certificate is installed.
- `xcrun notarytool history --keychain-profile "$NOTARY_PROFILE"` lists submissions.
- If automated submission is unavailable, submit the generated ZIP with `xcrun notarytool submit`, wait for an `Accepted` result, then run `xcrun stapler staple` and `xcrun stapler validate` on the app before rebuilding the final ZIP and checksum.
- `spctl --assess --type execute --verbose=4` is the final Gatekeeper check and must pass before publishing.
