"""Compute appids for each game, write shortcuts.vdf (binary), update config.vdf.

Steam must be CLOSED before writing these files or changes will be clobbered.
"""
import os
import sys
import zlib
import shutil
import struct
import pathlib
import re
from manifest import GAMES, STEAM_ROOT, STEAM_USERID3, PROTON_NAME


def shortcut_appid(exe: str, appname: str) -> int:
    """32-bit unsigned AppID used by Steam for non-Steam shortcuts.
    This is the id used for compatdata/<appid>/ and modern grid artwork."""
    data = f'"{exe}"{appname}'.encode()
    crc = zlib.crc32(data) & 0xFFFFFFFF
    return crc | 0x80000000


def legacy_grid_appid(exe: str, appname: str) -> int:
    """Legacy 64-bit grid id, >> 32 yields appid used for old-style
    <appid>.png grid images. Kept so we can populate both filenames."""
    top = shortcut_appid(exe, appname)
    return (top << 32) | 0x02000000


# ---- Binary VDF writer ----------------------------------------------------

def _b(s: str) -> bytes:
    return s.encode("utf-8") + b"\x00"


def write_string(key, value):
    return b"\x01" + _b(key) + _b(value)


def write_int(key, value):
    return b"\x02" + _b(key) + struct.pack("<I", value & 0xFFFFFFFF)


def write_object(key, body):
    return b"\x00" + _b(key) + body + b"\x08"


def build_shortcut(index: int, game: dict) -> bytes:
    exe_path = str(game["exe"])
    start_dir = str(game["start_dir"])
    name = game["name"]
    # Allow pinning the appid when a user has already created the shortcut
    # in Steam (or when we've intentionally moved the prefix). Steam does not
    # recompute appid when the user edits a shortcut's exe via the UI.
    appid = game.get("override_appid") or shortcut_appid(exe_path, name)
    icon_path = str(pathlib.Path.home() / ".steam/steam/userdata" / STEAM_USERID3
                    / "config/grid" / f"{appid}_icon.png")

    body = b""
    body += write_int("appid", appid)
    body += write_string("AppName", name)
    body += write_string("Exe", f'"{exe_path}"')
    body += write_string("StartDir", f'"{start_dir}"')
    body += write_string("icon", icon_path)
    body += write_string("ShortcutPath", "")
    body += write_string("LaunchOptions", game.get("launch_options", ""))
    body += write_int("IsHidden", 0)
    body += write_int("AllowDesktopConfig", 1)
    body += write_int("AllowOverlay", 1)
    body += write_int("OpenVR", 0)
    body += write_int("Devkit", 0)
    body += write_string("DevkitGameID", "")
    body += write_int("DevkitOverrideAppID", 0)
    body += write_int("LastPlayTime", 0)
    body += write_string("FlatpakAppID", "")
    body += write_object("tags", b"")

    return write_object(str(index), body)


def build_shortcuts_vdf(games: list) -> bytes:
    body = b""
    for i, g in enumerate(games):
        body += build_shortcut(i, g)
    # Binary VDF needs a trailing 0x08 after the outer object to terminate the
    # root document — Steam's parser rejects the file silently without it.
    return write_object("shortcuts", body) + b"\x08"


# ---- config.vdf (text KeyValues) CompatToolMapping -----------------------

def update_compat_tool_mapping(config_vdf_path: pathlib.Path, appid_to_tool: dict):
    """Insert/overwrite CompatToolMapping for each shortcut appid.

    Implementation: parse minimally. Find the Valve/Steam CompatToolMapping block
    and splice entries. If absent, insert after the Steam block opens.
    """
    text = config_vdf_path.read_text()
    # Regex find existing CompatToolMapping block body (matched braces, crude).
    pattern = re.compile(r'"CompatToolMapping"\s*\n\s*\{', re.MULTILINE)
    m = pattern.search(text)
    if m:
        start_body = m.end()
        # find matching closing brace
        depth = 1
        i = start_body
        while i < len(text) and depth > 0:
            if text[i] == '{':
                depth += 1
            elif text[i] == '}':
                depth -= 1
            i += 1
        end_body = i - 1  # points at the '}'
        inner = text[start_body:end_body]
        # Remove any existing entries for these appids
        for appid in appid_to_tool.keys():
            inner = re.sub(
                rf'"{appid}"\s*\n\s*\{{[^}}]*\}}\s*\n?',
                '',
                inner,
            )
        # Append new entries with tabs
        new_entries = ""
        for appid, tool in appid_to_tool.items():
            new_entries += (
                f'\t\t\t\t\t"{appid}"\n'
                f'\t\t\t\t\t{{\n'
                f'\t\t\t\t\t\t"name"\t\t"{tool}"\n'
                f'\t\t\t\t\t\t"config"\t\t""\n'
                f'\t\t\t\t\t\t"priority"\t\t"250"\n'
                f'\t\t\t\t\t}}\n'
            )
        new_text = text[:start_body] + inner.rstrip() + "\n" + new_entries + text[end_body:]
        config_vdf_path.write_text(new_text)
        return True

    # CompatToolMapping not found — insert under "Software"/"Valve"/"Steam"
    steam_pattern = re.compile(r'"Steam"\s*\n\s*\{', re.MULTILINE)
    m = steam_pattern.search(text)
    if not m:
        raise RuntimeError("Couldn't find Steam block in config.vdf")
    insert_at = m.end()
    block_lines = ['\n\t\t\t\t"CompatToolMapping"\n\t\t\t\t{']
    for appid, tool in appid_to_tool.items():
        block_lines.append(
            f'\t\t\t\t\t"{appid}"\n'
            f'\t\t\t\t\t{{\n'
            f'\t\t\t\t\t\t"name"\t\t"{tool}"\n'
            f'\t\t\t\t\t\t"config"\t\t""\n'
            f'\t\t\t\t\t\t"priority"\t\t"250"\n'
            f'\t\t\t\t\t}}'
        )
    block_lines.append('\t\t\t\t}')
    new_text = text[:insert_at] + "\n".join(block_lines) + text[insert_at:]
    config_vdf_path.write_text(new_text)
    return True


def main():
    shortcuts_path = STEAM_ROOT / "userdata" / STEAM_USERID3 / "config" / "shortcuts.vdf"
    config_vdf_path = STEAM_ROOT / "config" / "config.vdf"
    shortcuts_path.parent.mkdir(parents=True, exist_ok=True)

    # Back up if exists
    for p in [shortcuts_path, config_vdf_path]:
        if p.exists():
            shutil.copy2(p, p.with_suffix(p.suffix + ".bak"))

    # Write shortcuts.vdf
    data = build_shortcuts_vdf(GAMES)
    shortcuts_path.write_bytes(data)

    # Update CompatToolMapping
    appid_map = {}
    for g in GAMES:
        aid = g.get("override_appid") or shortcut_appid(str(g["exe"]), g["name"])
        appid_map[aid] = PROTON_NAME
        print(f"{g['name']:<45} appid={aid}  compatdata=~/.steam/steam/steamapps/compatdata/{aid}")

    if config_vdf_path.exists():
        update_compat_tool_mapping(config_vdf_path, appid_map)

    print()
    print(f"Wrote {shortcuts_path}")
    print(f"Updated {config_vdf_path}")


if __name__ == "__main__":
    main()
