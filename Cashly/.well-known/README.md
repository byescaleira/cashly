# Universal Links — apple-app-site-association

`apple-app-site-association` is the bridge between web URLs at
`cashly.app/<path>` and the iOS / macOS / visionOS app's universal
link handler. Apple downloads this file from
`https://cashly.app/.well-known/apple-app-site-association` (no
`.json` extension, `application/json` Content-Type) when the app is
installed.

## Before shipping

1. **Replace `TEAM_ID`** with the real Apple Developer team
   prefix in both `applinks.details[].appIDs[0]` and
   `webcredentials.apps[0]`. Find it under
   Certificates → Identifiers → App ID.

2. **Host the file at**
   `https://cashly.app/.well-known/apple-app-site-association`.
   No redirect, no `Content-Type: text/html`, served over HTTPS
   with a valid certificate.

3. **Enable the Associated Domains capability** in the Xcode
   project for the Cashly target and add
   `applinks:cashly.app` (plus `webcredentials:cashly.app` if
   the app reads / writes shared web credentials).

4. **Wire the SwiftUI handler.** `Cashly/Cashly/CashlyApp.swift`
   already routes URLs through `MainDeeplink.resolve` via
   `onOpenURL`. Universal links arrive on the same callback —
   no extra plumbing.

## Component matching

`MainDeeplink.resolve` already parses `cashly://`-scheme URLs.
Universal links use the same host names as the AASA `/` paths
above. When `MainDeeplink.resolve` doesn't recognise a path it
returns `nil` and the system falls back to Safari, which is the
desired behaviour for unsupported routes.

## Verifying

After uploading the file, validate with:

```bash
curl -I https://cashly.app/.well-known/apple-app-site-association
# expect: 200, Content-Type: application/json
```

And once the app is installed on a TestFlight device:

```
xcrun simctl openurl booted https://cashly.app/paywall?trigger=limit
```

The app should launch directly into the paywall sheet with the
`limitReached` trigger.

## Why this file lives here

Source of truth — the same JSON shape will be deployed by whichever
infra owns `cashly.app`. Keeping it in-repo makes the contract
reviewable in PRs and pins the supported route surface alongside
`MainDeeplink`.
