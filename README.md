# Portal

[![GitHub Release](https://img.shields.io/github/v/release/aoyn1xw/Portal?include_prereleases)](https://github.com/aoyn1xw/Portal/releases)
[![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/aoyn1xw/Portal/total)](https://github.com/aoyn1xw/Portal/releases)
[![GitHub License](https://img.shields.io/github/license/aoyn1xw/Portal?color=%23C96FAD)](https://github.com/aoyn1xw/Portal/blob/main/LICENSE)
[![Sponsor Me](https://img.shields.io/static/v1?label=Sponsor&message=%E2%9D%A4&logo=GitHub&color=%23fe8e86)](https://github.com/sponsors/aoyn1xw)
[![Discord](https://img.shields.io/discord/1302670238583623761?style=flat&label=discord)](https://wsfteam.xyz/discord)

Portal is a powerful iOS/iPadOS app signer and installer that lets you sign, manage, and install applications directly on your device. Built with SwiftUI, it provides a native, privacy-focused experience where all signing happens locally on your device — no external servers required for core functionality.

<p align="center">
  <img src="Images/erdis_komisches_iphone_ding.png" alt="Portal App Mockup" width="800">
</p>

### Features

- **Modern SwiftUI Interface** — Clean, intuitive UI with support for light, dark, and tinted app icons.
- **Sign & Install Apps** — Sign IPA files using your `.p12` certificate and `.mobileprovision` profile, then install directly to your device.
- **Multiple Installation Methods** — Choose between local server installation or pairing-based installation via VPN for more reliable installs.
- **Certificate Management** — Import, view, and manage multiple certificates with PPQ check status indicators.
- **Advanced Signing Options**:
  - Customize app name, bundle identifier, and appearance (Light/Dark/Default)
  - PPQ protection with dynamic bundle ID modification
  - Remove URL schemes, plugins, and provisioning files for detection avoidance
  - Force localization for custom display names
  - File sharing and iTunes support toggles
  - Minimum iOS version patching
  - **Liquid Glass support** for iOS 26 compatibility
- **Tweak Injection** — Inject `.dylib` and `.deb` files using [ElleKit](https://github.com/tealbathingsuit/ellekit), with configurable injection paths and folders.
- **Default Frameworks** — Configure frameworks that are automatically injected into all apps during signing.
- **Library Management** — Organize imported and signed apps with sorting, filtering, and batch operations.
- **Notifications** — Get notified when app signing completes.
- **Privacy First** — No tracking, no analytics. Everything happens on your device.
- **100% Open Source** — Transparent codebase under GPL-3.0 license.

## Download

Visit [releases](https://github.com/aoyn1xw/Portal/releases) and get the latest `.ipa`.

<a href="https://celloserenity.github.io/altdirect/?url=https://raw.githubusercontent.com/aoyn1xw/Portal/refs/heads/main/app-repo.json" target="_blank">
   <img src="https://github.com/CelloSerenity/altdirect/blob/main/assets/png/AltSource_Blue.png?raw=true" alt="Add AltSource" width="200">
</a>
<a href="https://github.com/aoyn1xw/Portal/releases/latest/download/Portal.ipa" target="_blank">
   <img src="https://github.com/CelloSerenity/altdirect/blob/main/assets/png/Download_Blue.png?raw=true" alt="Download .ipa" width="200">
</a>

## How does it work?

How Portal works is a bit complicated, with having multiple ways to install, app management, tweaks, etc. However, I'll point out how the important features work here.

To start off, we need a validly signed IPA. We can achieve this with Zsign, using a provided IPA using a `.p12` and `.mobileprovision` pair.

#### Install (Server)

- Use a locally hosted server for hosting the IPA files used for installation, including other assets such as icons, etc. 
  - On iOS 18, we need a few entitlements: `Associated Domains`, `Custom Network Protocol`, `MDM Managed Associated Domains`, `Network Extensions`
- Make sure to include valid https SSL certificates as the next URL requires a valid HTTPS connection, for us we use [*.backloop.dev](https://backloop.dev/).
- We then use `itms-services://?action=download-manifest&url=<PLIST_URL>` to attempt to initiate an install, by using `UIApplication.open`.

However, due to the changes with iOS 18 with entitlements we will need to provide an alternative way of installing. We have two options here, a way to install locally fully using the local server (the one I have just shown) or use an external HTTPS server that serves as our middle man for our `PLIST_URL`, while having the files still local to us. Lets show the latter.

- This time, lets not include https SSL certificates, rather just have a plain insecure local server.
- Instead of a locally hosting our `PLIST_URL`, we use [plistserver](https://github.com/nekohaxx/plistserver) to host a server online specifically for retrieving it. This still requires a valid HTTPS connection.
- Now, to even initiate the install (due to lack of entitlements from the former) we need to trick iOS into opening the `itms-services://` URL, we can do this by summoning a Safari webview to a locally hosted HTML page with a script to forcefully redirect us to that itms-services URL.

Since itms-services initiates the install automatically, we don't need to do anything extra after the process. Though, what we do is monitor the streaming progress of the IPA being sent.

#### Install (Pairing)

- Establish a heartbeat with a TCP provider (the app will need this for later).
  - For it to be successful, we need a [pairing file](https://github.com/jkcoxson/idevice_pair) and a [VPN](https://apps.apple.com/us/app/localdevvpn/id6755608044).
- Once we have these and the connection was successfully established, we can move on to the installation part.
  - Before installing, we need to check for the connection to the socket that has been created, routed to `10.7.0.1`, if this succeeds we're ready.
- When preparing for installation, we need to establish another connection but for `AFC` using the TCP provider.
- Once the connection was established we need to created a staging directory to `/PublicStaging/` and upload our IPA there.
- Then, using our connection to `AFC` we can command it to install that IPA directly. Similar to `ideviceinstaller`, but fully on your phone.

Due to how it works right now we need both a VPN and a lockdownd pairing file, this means you will need a computer for its initial setup. Though, if you don't want to do these you can just use the server way of installing instead (but at a cost of less reliability). 

## Credits

- Original [Feather](https://github.com/khcrysalis/Feather) project by [khcrysalis](https://github.com/khcrysalis)

## Disclaimer

This project is maintained here, on GitHub. Releases are distributed here, on GitHub. We do not currently have a project website outside of this repository. Please make sure to avoid any sites that host our software as they are often malicious and are there to mislead to user.
