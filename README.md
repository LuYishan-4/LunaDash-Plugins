# LunaDash Community Plugins

This repository is the submission gate, registry, and browser website for LunaDash Plugin SDK 2.\n\nCatalogue: https://luyishan-4.github.io/LunaDash-Plugins/

Every community plugin lives under `plugins/<id>/` and enters the registry through a pull request. Validation is based on the same SDK 2 contracts used by LunaDash: the target registry, manifest validator, and settings-schema validator are synchronized from `LuYishan-4/LunaDash` branch `fix/Compositor/pluginCi`.

The repository follows the publishing model of `caelestia-kde-plugins`—one plugin per directory, generated index, CI, and maintainer review—but the plugin format itself is LunaDash's.

## Publishing flow

```text
author -> plugins/<id>/ -> pull request -> SDK validation + review
       -> merge -> generated index.json -> Astro catalogue -> LunaDash Store
```
 
## SDK 2 plugin types

| Type | Purpose |
| --- | --- |
| `quickshell` | QML/JavaScript visual extensions |
| `effect` | C11/C++20 native synchronous SDK hooks |
| `opengl` | GLSL packages hosted by supported visual targets |

Each package declares one target or a `targets` array. Multi-target packages may combine QML, native effects, and OpenGL implementations; each target keeps its own type, mode, entry, and settings. The authoritative target/type combinations and single-owner policy are in `contracts/targets.json`.

## Repository layout

- `plugins/<id>/`: published plugins.
- `template-plugin/`: copy-me SDK 2 starter.
- `contracts/`: LunaDash SDK validator/settings/target snapshots.
- `schemas/`: editor-friendly JSON Schemas.
- `scripts/`: registry validation and index generation.
- `index.json`: catalogue consumed by LunaDash.
- `site/`: Astro browser site.

See [CONTRIBUTING.md](CONTRIBUTING.md) before submitting a plugin.

## Source of truth

The runtime contract comes from LunaDash:
- `docs/en/PLUGINS.md`
- `docs/en/PLUGIN_TARGETS.md`
- `docs/en/SETTINGS_API.md`
- `data/plugins/targets.json`
- `cmake/plugins/ValidatePlugin.py`
- `cmake/plugins/SettingsSchema.py`

Store-only fields never replace the LunaDash runtime manifest.

## Audio Wave runtime

Audio Wave 1.0.1a requires the LunaDash `audio-spectrum` shell helper and `parec` (Arch: `libpulse`; Debian/Ubuntu: `pulseaudio-utils`), connected to PulseAudio or PipeWire-Pulse. It monitors playback output, never the default microphone, and keeps PCM in memory only. A 32-band stereo FFT replaces the earlier MPRIS/volume-driven sine animation. Logarithmic gain and frame-time attack/release smoothing make quiet playback visible without amplifying silence. Height, gain, opacity, bar count and mirrored frequency layout remain configurable. Missing audio support shows a diagnostic with bounded reconnect attempts. Desktop widgets stay inside the wallpaper Background layer.

新版 Audio Wave 使用真實播放輸出 FFT 頻譜，搭配對數增益與逐幀平滑，不再靠 MPRIS 與音量設定產生假動畫。需要本體的 `audio-spectrum` helper 和 `parec`；不讀取預設麥克風，不儲存音訊。版本仍為 `1.0.1a`，本體新版 Store 會依來源雜湊辨識同版號修訂。

Audio Wave now has a separate **Wave amplitude** multiplier (default 1.8×, up to 3×), which applies even when upgrading with an older saved height. Adaptive peak normalization makes quiet playback visible while retaining distinct frequency peaks; a PCM noise gate keeps silence at baseline. Attack/release is 22/140 ms, with configurable spacing and gain. The multiplier changes display height without inventing audio activity.

新版增加獨立振幅倍率（預設 1.8 倍、最高 3 倍），保留舊設定更新也會生效。自動峰值正規化讓小聲音訊更明顯，保留各頻帶高低差，搭配 PCM 靜音門檻與 22/140 ms 逐幀平滑；可另外調整間距及增益。

Audio Wave defaults to two side groups: **24 bars per side**, **10 px spacing** and a **40% clear center**. Bass is mapped to the outer edges and the higher bands taper inward. These are new settings, so upgrades with an older 88-bar configuration also adopt the side layout. Turn off **Keep the center clear** to use the previous full-width bar count, spacing and mirror controls.

預設改成左右各 24 根、間隔 10 px，中央 40% 留白。低頻與主要起伏集中螢幕兩側，向中央逐漸降低；舊的 88 根設定更新後也會套用兩側配置。關閉「Keep the center clear」可恢復整排模式。
