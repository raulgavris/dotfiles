"""Manifest template for game migration — copy this into your working dir
(e.g. ~/Games-migration/manifest.py) and fill in the values below.

Each entry describes a non-Steam game to add to Steam and the save
locations (read-only, from Windows) to copy into its Proton prefix.

- saves[].src  → path relative to WIN_ROOT
- saves[].dst  → path relative to <prefix>/drive_c/users/steamuser/
"""

from pathlib import Path

# Mount point of the Windows partition + user folder (the one containing
# Documents, AppData, Saved Games, OneDrive).
WIN_ROOT = Path("/media/YOU/Windows/Users/YOUR_WINDOWS_USER")

# Root folder containing the game install directories on Linux.
GAMES_ROOT = Path("/media/YOU/YourGamesSSD/Games")

# Linux Steam install root. Usually one of:
#   ~/.steam/steam
#   ~/.local/share/Steam
STEAM_ROOT = Path.home() / ".steam" / "steam"

# Steam userdata id (SteamID3). Find it with:
#   ls ~/.steam/steam/userdata/
STEAM_USERID3 = "XXXXXXXX"

# Compat tool name — either a GE-Proton folder name (e.g. "GE-Proton10-34")
# or a Valve built-in name like "proton_experimental" (current 11-beta),
# "proton_hotfix", "proton_9", "proton_8".
PROTON_NAME = "GE-Proton10-34"


# One entry per game. Steam appid is the *real* Steam appid of the game
# used only for downloading art from Steam CDN.
GAMES = [
    # {
    #     "name": "Cyberpunk 2077",
    #     "exe": GAMES_ROOT / "Cyberpunk 2077" / "bin" / "x64" / "Cyberpunk2077.exe",
    #     "start_dir": GAMES_ROOT / "Cyberpunk 2077",
    #     "steam_appid": 1091500,
    #     "saves": [
    #         {"src": "Saved Games/CD Projekt Red/Cyberpunk 2077",
    #          "dst": "Saved Games/CD Projekt Red/Cyberpunk 2077"},
    #         {"src": "OneDrive/Documents/CD Projekt Red/Cyberpunk 2077",
    #          "dst": "Documents/CD Projekt Red/Cyberpunk 2077"},
    #         {"src": "AppData/Local/CD Projekt Red/Cyberpunk 2077",
    #          "dst": "AppData/Local/CD Projekt Red/Cyberpunk 2077"},
    #     ],
    # },
]
