# Changelog

All notable changes to Astral are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project uses [Semantic Versioning](https://semver.org/).


## [7.32.0](https://github.com/RosemyneH/ElvUI_Astral/compare/v7.31.0...v7.32.0) (2026-09-06)


### Features

* **actionbars:** add Project Astral button to the ElvUI micro bar ([231024e](https://github.com/RosemyneH/ElvUI_Astral/commit/231024e662ee721c7c8b6117a9e46ed535b25daa))
* **addonskins:** Skin Project Astral transmogrify UI. ([d26b987](https://github.com/RosemyneH/ElvUI_Astral/commit/d26b987ad52d5627a92611ddbe1aa984a7913be9))
* **chat:** Standardize GM chat icon to colored text ([e044c10](https://github.com/RosemyneH/ElvUI_Astral/commit/e044c102e0b0480212e071c4148c1016263bbd16))
* **compat:** use AwesomeWotLK nameplates and stub missing APIs ([65567de](https://github.com/RosemyneH/ElvUI_Astral/commit/65567de15c11e1571fe694931a68f427c71ae39d))
* **gm-icon:** Use Astral texture for GM chat and nameplate tags. ([5afbfc2](https://github.com/RosemyneH/ElvUI_Astral/commit/5afbfc2ddce47a2dd625f57873d733dbb4a0373f))
* **skins:** theme Project Astral windows, hover, and popups to ElvUI ([eb35b04](https://github.com/RosemyneH/ElvUI_Astral/commit/eb35b04211f15414cc2e9762349179ccdf947ccb))


### Bug Fixes

* **auras:** do not require C_VanityCollection on Astral ([6f63336](https://github.com/RosemyneH/ElvUI_Astral/commit/6f63336d4c0f277c6863cfd2c47b718d1bebdb45))
* **chat:** compact GM icon, block .mythic items, and stop crashing on channel notices ([c72181e](https://github.com/RosemyneH/ElvUI_Astral/commit/c72181e457c948d5d6405c67e71c794ad0d0b5a3))
* **fonts:** Preserve Blizzard nameplate font for GM icons ([d9673c8](https://github.com/RosemyneH/ElvUI_Astral/commit/d9673c882c6217dd64b671c14582d47c84044f23))

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
