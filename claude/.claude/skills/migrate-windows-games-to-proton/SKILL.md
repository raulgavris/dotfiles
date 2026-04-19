---
name: migrate-windows-games-to-proton
description: Use this skill when the user wants to migrate Windows games (non-Steam installs — GOG, repacks, cracks, standalone EXEs) to Linux Steam as non-Steam shortcuts running under Proton, along with their save games from a mounted Windows partition. Triggers on phrases like "migrate games to Proton", "add non-Steam games to Steam", "import Windows saves to Linux", "move saves from Windows user folder to Wine prefix", "set up cracked games with Proton", or any dual-boot scenario where the user wants their Windows game catalog playable under Steam+Proton on Linux.
version: 1.0.0
---

# Migrate Windows games (and saves) into Steam + Proton

End-to-end workflow for wiring Windows-side games (GOG, repacks, standalone EXEs) into Steam on Linux as non-Steam shortcuts running under Proton, then copying save data from `Windows/Users/<name>/` into each game's Proton prefix — **without writing anything back to the Windows partition**.

## When this skill applies

- User has a mounted Windows partition (usually NTFS) alongside Linux Steam.
- User wants games to appear in Steam with correct names, icons, and grid art.
- User wants Documents/AppData/Saved Games saves carried over to Wine prefixes.
- The games are *not* Steam-installed (user owns via GOG, or has repack/crack installs).

**Do not use this skill** if the user just wants to reinstall a Steam-owned game on Linux — they should install from Steam directly, which handles Proton automatically.

## Non-negotiables

1. **Never write to the Windows partition.** Treat it as read-only even if it's mounted rw. Verify after copies by `stat`-ing source dirs and confirming mtimes are unchanged.
2. **Steam must be closed** before writing `shortcuts.vdf` or `config.vdf`. Steam rewrites both on shutdown and will clobber mid-session edits. Use `steam -shutdown` then wait for `pgrep -f 'Steam/ubuntu12_32/steam'` to return empty.
3. `shortcuts.vdf` is **binary VDF** — do not hand-edit. Use `scripts/build_shortcuts.py`. Its writer has a critical detail: the file needs a trailing `0x08` byte to terminate the root document after the `shortcuts` object's own `0x08`. Steam silently rejects the file (and logs `CSteamDoc::LoadShortcuts: failed to load shortcut file`) without it.
4. **Ask before shutting Steam down.** It's user-visible. If they're using Steam right now, confirm.

## High-level flow

1. **Discover state** — Windows user folder path, Linux Steam install, userdata id, installed Proton builds.
2. **Install Proton if missing.** Prefer GE-Proton (good compat for DRM-free / cracks). For Valve's bleeding-edge (currently "Proton 11 Beta"), install "Proton Experimental" via Steam itself (`steam steam://install/1493710`) — the CompatToolMapping name is `proton_experimental`.
3. **Build a manifest** of games: name, exe, start dir, known Steam appid (for art), list of `{src, dst}` save path pairs.
4. **Download Steam CDN artwork** (portrait 600x900, hero, logo, header) into `userdata/<id>/config/grid/` keyed by the *shortcut* appid.
5. **Shut Steam down.** Write `shortcuts.vdf` and add a `CompatToolMapping` entry per shortcut appid in `config.vdf`.
6. **Initialize each Proton prefix** with `proton run wineboot` (~1–5s each once the proto prefix is warm).
7. `rsync` saves from Windows into `<prefix>/drive_c/users/steamuser/...`.
8. **Restart Steam.** Ask the user to verify the games appear with art and launch one.

## Scripts

Helpers live in `scripts/` next to this SKILL.md. Copy them into a working directory (e.g. `~/Games-migration/`) and customize `manifest.py`.

- `scripts/manifest_template.py` — starter template: fill in Windows user root, Steam root, userid3, Proton tool name, games list, and per-game save mappings.
- `scripts/build_shortcuts.py` — computes non-Steam shortcut appids (`crc32('"'+exe+'"'+name) | 0x80000000`), writes `shortcuts.vdf`, updates `CompatToolMapping` in `config.vdf`. Backs up both to `.bak` before writing.
- `scripts/download_icons.sh` — pulls `library_600x900`, `library_hero`, `logo.png`, `header.jpg` from `steamcdn-a.akamaihd.net` using the *known Steam appid* for each game and derives a 256x256 square icon with ImageMagick `convert`.
- `scripts/copy_saves.py` — runs `proton run wineboot` per game to create the prefix, then rsyncs each `{src, dst}` save pair with `-a -u` (preserves timestamps, won't clobber newer files).
- `scripts/install_ge_proton.sh` — downloads the latest GE-Proton release from GitHub into `~/.steam/steam/compatibilitytools.d/`.
- `scripts/detect_steam.sh` — prints Steam userid3, config paths, and installed Proton dirs.

## Workflow (what you should actually do)

1. **Quick interview.** Confirm: path to mounted Windows partition (e.g. `/media/<user>/Windows`), path to game folders (often a separate SSD, e.g. `/media/<user>/Games/`), preferred Proton (default: GE-Proton). If the user wants Valve Proton 11 Beta, note it requires approval to run `steam steam://install/1493710`.

2. **Run `scripts/detect_steam.sh`.** Capture the userid3 and the Proton build list. If the list is empty, run `scripts/install_ge_proton.sh` (kick it off in the background — ~500 MB).

3. **Build the manifest.** For each game folder the user wants migrated:
   - Find the real game EXE. **Skip launchers**: `REDprelauncher.exe`, `Launcher.exe`, `idTechLauncher.exe`. Launch the actual game binary. Common paths:
     - Cyberpunk 2077: `bin/x64/Cyberpunk2077.exe`
     - The Witcher 3 GOTY: `bin/x64_dx12/witcher3.exe` (DX12) or `bin/x64/witcher3.exe` (DX11)
     - DOOM Eternal: `DOOMEternalx64vk.exe` (Vulkan)
     - RDR2: `RDR2.exe` (not `Launcher.exe`)
     - BeamNG.drive: `Bin64/BeamNG.drive.x64.exe`
   - Look up the Steam appid of each game (for art). See `references/save_paths.md`.
   - Enumerate save sources on the Windows partition. Check in priority order:
     - `OneDrive/Documents/<anything>` — **Documents is often redirected to OneDrive**. Check here *before* `Documents/`.
     - `Saved Games/<Publisher>/<Game>/`
     - `AppData/Local/<Game>/`
     - `AppData/Roaming/<Publisher>/<Game>/`
     - `AppData/Roaming/CPY_SAVES/CPY/<steamid>/` (CPY cracks)
     - `AppData/Roaming/EMPRESS/<steamid>/` (EMPRESS cracks)
     - `AppData/Roaming/Goldberg SocialClub Emu Saves/<game>/` (Goldberg / Rockstar cracks)
     - `AppData/Roaming/FLT/` (FLT cracks)
   - Map each Windows source to the matching Proton path under `drive_c/users/steamuser/`. `OneDrive/Documents/X` → `Documents/X`. `AppData/Local/X` → `AppData/Local/X`. `Saved Games/X` → `Saved Games/X`.

4. **Download art** with `scripts/download_icons.sh`. Writes to `~/.steam/steam/userdata/<id>/config/grid/`.

5. **Confirm with the user**, then `steam -shutdown`. Wait for the process to exit.

6. **Apply shortcuts + compat mapping:** `python3 build_shortcuts.py`. Backs up `shortcuts.vdf.bak` and `config.vdf.bak`.

7. **Init prefixes + copy saves:** `python3 copy_saves.py`. Sequential wineboot per game, then rsync each `{src, dst}`.

8. **Restart Steam:** `nohup steam >/dev/null 2>&1 & disown`. Check `~/.local/share/Steam/logs/console-linux.txt` for `CSteamDoc::LoadShortcuts: failed to load shortcut file`. If present, the shortcut file is malformed — verify the trailing `0x08` root terminator and the per-field encoding.

## Validation

- `stat` Windows source dirs before and after — mtimes unchanged → read-only access confirmed.
- `find <prefix>/drive_c/users/steamuser -mindepth 2 -maxdepth 4 -type d` per appid — expect the save subfolders present.
- Sanity-check one known save file (e.g. `AutoSave-0` for Cyberpunk 2077).
- `grep 'sanitize shortcut' ~/.local/share/Steam/logs/console_log.txt` — if any of your shortcuts triggered this message, Steam replaced your computed appid with its own. That means `appid` wasn't written correctly. Fix the script and re-apply.
- Inspect the written file: `xxd userdata/<id>/config/shortcuts.vdf | tail -2` should end with `08 08 08 08` (tags-end, shortcut-end, shortcuts-end, root-end) after the last shortcut.

## Caveats to call out to the user up front

- "Work properly" can't be verified without launching each game. A present shortcut is not a working game.
- **Profile-ID mismatch.** Games that save under a hashed profile subfolder (`Saved Games/God of War/<profileId>/`, `Documents/Marvel's Spider-Man 2/<steamid>/`, `Saved Games/Quantic Dream/Detroit Become Human/<id>/`) often regenerate a *different* ID when first launched under Proton (derived from Wine user/hardware). The old Windows save folder is then ignored. **Fix after first launch**: find the new profile ID the game created (e.g. `1637233498` for GoW on Linux vs `527563663` on Windows), then overwrite the new profile's save files with the Windows ones. Don't delete the new folder — it may hold engine defaults the game needs.
- **Repack "users/" dir.** Razor1911 / CODEX / other repacks sometimes save to `<game_install>/users/<steamid>/<game>/` instead of (or in addition to) the Documents location. If the user reports "cannot write in the game users folder", create it: `mkdir -p "<game>/users/<steamid>/<game name>"`, then mirror the Windows save there. Look for a `1911.json` / `codex.ini` / `goldberg_*.ini` in the game folder to confirm the crack variant and its save path.
- **NTFS3 read-only dirs after rsync.** When you rsync a save folder from the Windows NTFS partition onto another NTFS mount (e.g. the games SSD), `rsync -a` preserves mode bits — and Windows "read-only" attributes come across as `555` / `dr-xr-xr-x`. The game then can't write there. After any rsync *into* a dir the game will write to, always run: `chmod -R u+w "<dst>"`. Applies equally to `<prefix>/drive_c/users/steamuser/` targets if the dst folder already existed before the rsync.
- Multiplayer / kernel anti-cheat (RDR2 Online, Far Cry 6 Ubisoft services, cracked MP) generally won't work under Proton.
- GOG games: launch the real game EXE, not `REDprelauncher.exe` — the GOG launcher often fails under Proton without extra setup.
- First launch triggers shader compilation — expect stutter for the first 10–15 minutes.
- If a save folder source is empty, report it honestly. DiRT Rally 2.0's `Documents/My Games/DiRT Rally 2.0/` often holds only `hardwaresettings/` and `wheelsettings/` — actual saves can be cloud-only.

## References

- `references/save_paths.md` — common save-folder layouts per franchise and common Steam appids for art lookup.
- `references/vdf_format.md` — binary VDF fields Steam expects in `shortcuts.vdf`.
