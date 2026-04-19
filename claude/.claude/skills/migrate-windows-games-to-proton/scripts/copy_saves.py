"""Copy saves from Windows (read-only) into each game's Proton prefix.

For each game in the manifest, ensure its compatdata/<appid>/pfx/drive_c/users/steamuser/
tree contains the save subfolders, then rsync the Windows source into the matching
destination. Skips gracefully when the Windows source does not exist.

This script NEVER writes to the Windows partition.
"""
import os
import sys
import shutil
import subprocess
from pathlib import Path

from build_shortcuts import shortcut_appid
from manifest import GAMES, WIN_ROOT, STEAM_ROOT, PROTON_NAME


COMPAT_BASE = STEAM_ROOT / "steamapps" / "compatdata"
PROTON_DIR = STEAM_ROOT / "compatibilitytools.d" / PROTON_NAME


def ensure_prefix(appid: int) -> Path:
    prefix = COMPAT_BASE / str(appid) / "pfx"
    if (prefix / "drive_c" / "users" / "steamuser").exists():
        return prefix
    print(f"  [wineboot] initializing prefix for {appid} ...")
    env = os.environ.copy()
    env["STEAM_COMPAT_CLIENT_INSTALL_PATH"] = str(STEAM_ROOT)
    env["STEAM_COMPAT_DATA_PATH"] = str(COMPAT_BASE / str(appid))
    (COMPAT_BASE / str(appid)).mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [str(PROTON_DIR / "proton"), "run", "wineboot", "-i"],
        env=env,
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return prefix


def copy_save(src: Path, dst: Path) -> tuple[bool, str]:
    if not src.exists():
        return False, f"  skip (source missing): {src}"
    if not src.is_dir():
        return False, f"  skip (not dir): {src}"
    dst.mkdir(parents=True, exist_ok=True)
    # rsync preserves timestamps, avoids overwriting newer files.
    cmd = ["rsync", "-a", "-u", "--info=stats0,flist0,progress0",
           str(src) + "/", str(dst) + "/"]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        return False, f"  rsync failed: {r.stderr.strip()}"
    # Windows NTFS "read-only" attribute arrives as mode 555 and blocks the
    # game from writing new saves. Restore user-write on everything we copied.
    subprocess.run(["chmod", "-R", "u+w", str(dst)], check=False)
    # Count files copied
    try:
        n = sum(1 for _ in dst.rglob("*") if _.is_file())
    except Exception:
        n = -1
    return True, f"  copied {src.name}/ -> {dst}  ({n} files total in dst)"


def main():
    for g in GAMES:
        appid = g.get("override_appid") or shortcut_appid(str(g["exe"]), g["name"])
        print(f"\n=== {g['name']}  (appid={appid}) ===")
        prefix = ensure_prefix(appid)
        steamuser = prefix / "drive_c" / "users" / "steamuser"
        if not steamuser.exists():
            print(f"  ERROR: no steamuser dir at {steamuser}; wineboot failed")
            continue
        for entry in g["saves"]:
            src = WIN_ROOT / entry["src"]
            dst = steamuser / entry["dst"]
            ok, msg = copy_save(src, dst)
            print(msg)


if __name__ == "__main__":
    main()
