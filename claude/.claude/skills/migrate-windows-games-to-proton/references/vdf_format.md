# shortcuts.vdf binary format (what Steam wants)

Steam stores non-Steam shortcuts in a binary VDF file at:

```
~/.steam/steam/userdata/<SteamID3>/config/shortcuts.vdf
```

This file uses a tagged key-value format. Each field is prefixed with a type byte.

## Type bytes

| Byte | Meaning                                |
|------|----------------------------------------|
| 0x00 | Object start (followed by key\0 body 0x08) |
| 0x01 | String (followed by key\0 value\0)     |
| 0x02 | Int32 (followed by key\0 4-byte little-endian) |
| 0x08 | Object end                             |

## Overall structure

```
0x00 "shortcuts\0"
  0x00 "0\0"   (first shortcut, keyed by index)
    <fields>
  0x08
  0x00 "1\0"
    <fields>
  0x08
  ...
0x08   ← end of "shortcuts" object
0x08   ← end of root document   ← CRITICAL, Steam silently rejects without it
```

The root-level 0x08 is easy to miss and is the difference between Steam loading 12 shortcuts and logging `CSteamDoc::LoadShortcuts: failed to load shortcut file`.

An empty shortcuts.vdf that Steam itself writes looks like:

```
00 73 68 6F 72 74 63 75 74 73 00 08 08
   s  h  o  r  t  c  u  t  s \0
```

Note the **two** trailing 0x08 bytes.

## Fields per shortcut (in order)

Steam tolerates missing optional fields but normalizes them on next write. For a clean entry:

| Type | Key | Notes |
|------|-----|-------|
| 0x02 | `appid` | Unsigned 32-bit derived from `crc32('"'+exe+'"'+name) \| 0x80000000`. If you write 0, Steam logs `sanitize shortcut app id` and computes its own — often with a different hash than yours, breaking downstream compatdata and grid paths. |
| 0x01 | `AppName` | Shown in the library |
| 0x01 | `Exe` | **Must be wrapped in quotes** in the string value: `"/path/to/game.exe"` |
| 0x01 | `StartDir` | Also quoted: `"/path/to/game/"` |
| 0x01 | `icon` | Absolute path to a .png/.ico. Usually `~/.steam/steam/userdata/<id>/config/grid/<appid>_icon.png` |
| 0x01 | `ShortcutPath` | Usually empty string |
| 0x01 | `LaunchOptions` | Used for things like `%command% --fullscreen`. Empty string if none. |
| 0x02 | `IsHidden` | 0 |
| 0x02 | `AllowDesktopConfig` | 1 |
| 0x02 | `AllowOverlay` | 1 |
| 0x02 | `OpenVR` | 0 |
| 0x02 | `Devkit` | 0 |
| 0x01 | `DevkitGameID` | "" |
| 0x02 | `DevkitOverrideAppID` | 0 |
| 0x02 | `LastPlayTime` | 0 |
| 0x01 | `FlatpakAppID` | "" |
| 0x00 | `tags` | Empty object: `0x00 tags\0 0x08` |

Then 0x08 closes the shortcut.

## Two different "appids" Steam uses

For a single non-Steam shortcut, Steam computes **two** identifiers:

1. **Shortcut AppID** (unsigned 32-bit): `crc32('"'+exe+'"'+name) | 0x80000000`. Used for:
   - The `appid` field in shortcuts.vdf
   - The compatdata prefix path (`steamapps/compatdata/<appid>/`)
   - The CompatToolMapping key in config.vdf
   - Modern grid filenames in `userdata/<id>/config/grid/<appid>p.jpg`, `<appid>_hero.jpg`, `<appid>_logo.png`, `<appid>.jpg`, `<appid>_icon.png`

2. **Big Picture / legacy 64-bit GameID**: `(shortcut_appid << 32) | 0x02000000`. Appears in Steam logs (`Adding process X for gameID Y`) and some older grid paths. You rarely need to write this yourself.

## config.vdf CompatToolMapping

After writing shortcuts.vdf, also add a mapping per shortcut appid under `InstallConfigStore/Software/Valve/Steam/CompatToolMapping` in `~/.steam/steam/config/config.vdf`:

```
"CompatToolMapping"
{
    "3441974770"
    {
        "name"     "GE-Proton10-34"
        "config"   ""
        "priority" "250"
    }
    ...
}
```

`name` must match either a subdir under `~/.steam/steam/compatibilitytools.d/` (for GE/custom) or a built-in Valve tool name (`proton_experimental`, `proton_hotfix`, `proton_9`, `proton_8`).

`config.vdf` is **text** KeyValues — safe to edit with regex or a tokenizing parser.

## Why Steam must be closed

Steam reads both files at startup and rewrites them on shutdown from its in-memory state. If you write while it's running, your changes get clobbered on the next shutdown. Always:

1. `steam -shutdown`
2. Wait for `pgrep -f 'Steam/ubuntu12_32/steam\b'` to return empty
3. Write your files
4. Start Steam again
