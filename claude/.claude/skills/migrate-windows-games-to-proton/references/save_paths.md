# Common Windows save-folder layouts and Steam appids

Use this as a starting map. Confirm paths exist on the specific Windows install before putting them in the manifest — repacks and cracks often redirect.

## Checking OneDrive first

Windows installs with OneDrive often redirect `Documents`, `Pictures`, `Desktop` to `OneDrive/Documents/`, etc. Check `Users/<name>/OneDrive/Documents/` **before** `Users/<name>/Documents/`.

## Crack/repack save roots

- `AppData/Roaming/CPY_SAVES/CPY/<steamid>/` — CPY
- `AppData/Roaming/EMPRESS/<appid>/remote/<appid>/remote/` — EMPRESS on Windows. On Linux/Proton this same crack writes to **`<prefix>/drive_c/users/Public/Documents/Steam/RUNE/<appid>/remote/`** instead. The files are AES-GCM encrypted with `key = SHA256("{Identifier}MANCUBUS{basename}")[0:16]` where `Identifier` is the SteamID64 of the crack account — **different between platforms**. Direct copy = "corrupt save" because the key differs. See `scripts/doom_reencrypt.py` for the DOOM Eternal decrypt-and-re-encrypt routine (ported from `icex/DOOMSaveManager/Crypto.cs`). RUNE's `Identifier` is `Id3ToId64("6112203") = 76561197966377931`. Also align `<RUNE>/settings/user_steam_id.txt` to the RUNE SteamID64 and make sure the game folder's `steam_emu.ini` has `AccountId=6112203`. The `settings/` (account_name, language) and `steam_settings/` (offline.txt, dlc.txt) subtrees can be copied verbatim.
- `AppData/Roaming/FLT/` — FLT (usually steam_id.txt)
- `AppData/Roaming/Goldberg SocialClub Emu Saves/<game>/` — Goldberg / Rockstar cracks
- `AppData/Roaming/.1911/<Game Name>/profile/` — Razor1911 Linux/Proton fallback. Same repack that writes to Goldberg on Windows may write here under Wine. If Windows saves are in `Goldberg SocialClub Emu Saves/<Game>/<hash>/`, copy them **into** the `.1911/<Game>/profile/` directory the Razor1911 loader creates on first launch.
- `Documents/CPY_SAVES/` (sometimes a duplicate mirror)

## Per-game notes

| Game | Likely save locations (Windows → map to Proton prefix drive_c/users/steamuser/) | Real EXE | Steam AppID |
|------|--------------------------------------------------------------------------------|---------|-------------|
| Assetto Corsa Competizione | `OneDrive/Documents/Assetto Corsa Competizione/` + `AppData/Local/AC2/` | `acc.exe` | 805550 |
| BeamNG.drive | `AppData/Local/BeamNG.drive/` | `Bin64/BeamNG.drive.x64.exe` | 284160 |
| Cyberpunk 2077 | `Saved Games/CD Projekt Red/Cyberpunk 2077/` + `OneDrive/Documents/CD Projekt Red/Cyberpunk 2077/` + `AppData/Local/CD Projekt Red/Cyberpunk 2077/` | `bin/x64/Cyberpunk2077.exe` | 1091500 |
| Detroit: Become Human | `Saved Games/Quantic Dream/Detroit Become Human/` | `DetroitBecomeHuman.exe` | 1222140 |
| DiRT Rally 2.0 | `OneDrive/Documents/My Games/DiRT Rally 2.0/` (often settings only; campaign saves can be cloud-only) | `dirtrally2.exe` | 690790 |
| DOOM Eternal (EMPRESS repack) | Windows saves: `AppData/Roaming/EMPRESS/782330/remote/782330/remote/` (AES-GCM encrypted, Identifier = contents of `remote/settings/user_steam_id.txt`, e.g. `76561199979096720`). **Linux target: `<prefix>/drive_c/users/Public/Documents/Steam/RUNE/782330/remote/`** (Identifier = RUNE `Id3ToId64("6112203") = 76561197966377931`). Direct copy = "corrupt save"; must re-encrypt. **Use `scripts/doom_reencrypt.py`** — it decrypts with the Windows Identifier and re-encrypts with the RUNE Identifier. Also copy `Saved Games/id Software/DOOMEternal/` (engine config, not crypted). Set `RUNE/782330/settings/user_steam_id.txt` = `76561197966377931` afterwards. | `DOOMEternalx64vk.exe` | 782330 |
| Far Cry 6 | `OneDrive/Documents/My Games/Far Cry 6/` | `bin/FarCry6.exe` | 2369390 |
| God of War | `Saved Games/God of War/<profileID>/` | `GoW.exe` | 1593500 |
| Marvel's Spider-Man: Miles Morales | `OneDrive/Documents/Marvel's Spider-Man Miles Morales/<steamid>/` + `AppData/Roaming/Insomniac Games/Marvel's Spider-Man Miles Morales/` | `MilesMorales.exe` | 1817070 |
| Marvel's Spider-Man 2 | `OneDrive/Documents/Marvel's Spider-Man 2/<steamid>/` + `AppData/Roaming/Insomniac Games/Marvel's Spider-Man 2/` | `Spider-Man2.exe` | 2651280 |
| Red Dead Redemption 2 (Razor1911) | Windows: `AppData/Roaming/Goldberg SocialClub Emu Saves/RDR2/<hash>/`. **Linux target: `AppData/Roaming/.1911/Red Dead Redemption 2/profile/`** — the Razor1911 loader uses a different path on Wine than on Windows even though the game folder is identical. Also: `OneDrive/Documents/Rockstar Games/Red Dead Redemption 2/`. | **`Launcher.exe`** — never `RDR2.exe`; the launcher is what initializes the Goldberg user state the crack needs | 1174180 |
| The Witcher 3: Wild Hunt | `OneDrive/Documents/The Witcher 3/` (contains `gamesaves/` + settings) | `bin/x64_dx12/witcher3.exe` (DX12) or `bin/x64/witcher3.exe` | 292030 |
| Assassin's Creed Odyssey | `OneDrive/Documents/Assassin's Creed Odyssey/` | — | 812140 |
| Assassin's Creed Valhalla | `OneDrive/Documents/Assassin's Creed Valhalla/` | — | 2208920 |
| The Last of Us Part I | `Saved Games/The Last of Us Part I/` | — | 1888930 |
| Wolfenstein Youngblood | `Saved Games/MachineGames/Wolfenstein Youngblood/` | — | 895250 |

## Proton compat tool names

Values you can put in `PROTON_NAME` inside `manifest.py`:

- `GE-Proton10-34` (or whatever tag you installed into `~/.steam/steam/compatibilitytools.d/`)
- `proton_experimental` — Valve's current bleeding-edge (Proton 11 beta at time of writing). Install via `steam steam://install/1493710`.
- `proton_hotfix`
- `proton_9`
- `proton_8`

The name is the folder name under `~/.steam/steam/compatibilitytools.d/` (GE) or the `name` field in the toolmanifest inside `~/.steam/steam/steamapps/common/Proton - <version>/` (Valve).

## When saves are "empty"

- ACC's `OneDrive/Documents/Assetto Corsa Competizione/Savegames/` is sometimes empty because the actual campaign progress lives in `OneDrive/Documents/Assetto Corsa Competizione/Config/` and `Customs/`. Copy the whole ACC folder.
- DiRT Rally 2.0's Documents folder usually only has `hardwaresettings/` and `wheelsettings/` — actual run history is cloud-only and nothing to migrate.
- Spider-Man MM's `Documents/Marvel's Spider-Man Miles Morales/<steamid>/` may be empty if the user never played past the prologue; Roaming `Insomniac Games/` still holds shader cache worth copying to avoid recompile.
