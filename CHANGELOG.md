# Changelog

All notable changes to Astral are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project uses [Semantic Versioning](https://semver.org/).


## [7.32.0](https://github.com/RosemyneH/ElvUI_Astral/releases/tag/v7.32.0) (2026-09-06)

### Features

* Master Astral toggle and per-module options under `/ec` → Astral
* Granular control over GM icon, micro button, and Project Astral hub/transmog/popup skins

### Fixes

* GM icon initialization no longer errors before private settings load
* Character menu (`C`) is skinned again with ElvUI Enhanced

## [7.31.0](https://github.com/RosemyneH/ElvUI_Astral/releases/tag/v7.31.0) (2026-09-05)

### Features

* Astral texture replaces the Blizzard GM icon in chat and on 3D name tags
* Project Astral transmogrify UI skin with compact layout, slot-aware appearance previews, and hover rotation

## [7.30.0](https://github.com/RosemyneH/ElvUI_Astral/releases/tag/v7.30.0) (2026-09-05)

### Features

* GM chat icon is colored text instead of a stretched texture

### Fixes

* GM nameplate icons keep the Blizzard nameplate font

## [7.29.0](https://github.com/RosemyneH/ElvUI_Astral/releases/tag/v7.29.0) (2026-09-05)

### Features

* Use AwesomeWotLK `C_NamePlate` when the client patch is present, and attach plates already on screen

### Fixes

* Buff frames no longer error when `C_VanityCollection` is missing

## [7.28.0](https://github.com/RosemyneH/ElvUI_Astral/releases/tag/v7.28.0) (2026-09-05)

### Features

* ElvUI skin for Project Astral (panels, tabs, hover, toasts, and confirm popups)
* Astral hub button on the ElvUI micro bar

### Fixes

* GM chat icon no longer stretches into a long bar
* `.mythic items` is never sent (Ascension leftover)
* Chat no longer errors on channel notices (`string.isNilOrEmpty`)
* Bag search recognizes Mythic item quality after login

## [7.27.0](https://github.com/RosemyneH/ElvUI_Astral/releases/tag/v7.27.0) (2026-09-05)

### Features

* Initial public Astral pack for World of Warcraft 3.3.5a
* ElvUI core, OptionsUI, AddOnSkins, Enhanced, EnhancedFriendsList, ExtraActionBars, DTBars2, and Party Damage
* Automated GitHub Releases with changelog from Conventional Commits
