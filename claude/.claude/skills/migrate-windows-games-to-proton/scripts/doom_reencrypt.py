"""Port DOOM Eternal saves from Windows EMPRESS → Linux RUNE (Proton).

Encryption scheme (from icex/DOOMSaveManager, Crypto.cs):
  AAD    = f"{Identifier}MANCUBUS{basename(file)}"
  key    = SHA256(AAD)[0:16]    (AES-128-GCM)
  nonce  = first 12 bytes of file
  ct+tag = remaining bytes

Identifier differs by platform:
  EMPRESS (Windows): contents of
      AppData/Roaming/EMPRESS/782330/remote/settings/user_steam_id.txt
  RUNE (Linux/Proton): Id3ToId64(RuneID) where RuneID comes from the
      Linux-side RUNE account. icex/DOOMSaveManager hardcodes RuneID=6112203
      → SteamID64 = 6112203 + 76561197960265728 = 76561197966377931.

We decrypt with the Windows identifier, re-encrypt with the RUNE identifier,
and place files at <prefix>/drive_c/users/Public/Documents/Steam/RUNE/782330/remote/.
"""
from __future__ import annotations
import argparse
import hashlib
import os
import secrets
import shutil
from pathlib import Path

from cryptography.hazmat.primitives.ciphers.aead import AESGCM


STEAM_ID3_TO_ID64_OFFSET = 76561197960265728


def id3_to_id64(sid3: str) -> str:
    return str(int(sid3) + STEAM_ID3_TO_ID64_OFFSET)


def aad_for(identifier: str, filename: str) -> bytes:
    return f"{identifier}MANCUBUS{filename}".encode("utf-8")


def key_for(aad: bytes) -> bytes:
    return hashlib.sha256(aad).digest()[:16]


def decrypt_file(identifier: str, src: Path) -> bytes:
    data = src.read_bytes()
    aad = aad_for(identifier, src.name)
    key = key_for(aad)
    nonce, ct = data[:12], data[12:]
    return AESGCM(key).decrypt(nonce, ct, aad)


def encrypt_file(identifier: str, dst_name: str, plaintext: bytes) -> bytes:
    aad = aad_for(identifier, dst_name)
    key = key_for(aad)
    nonce = secrets.token_bytes(12)
    ct = AESGCM(key).encrypt(nonce, plaintext, aad)
    return nonce + ct


def reencrypt_tree(src_root: Path, dst_root: Path, src_id: str, dst_id: str) -> list[tuple[Path, bool, str]]:
    results: list[tuple[Path, bool, str]] = []
    for src in src_root.rglob("*"):
        if not src.is_file():
            continue
        if src.name.endswith("-BACKUP"):
            continue
        rel = src.relative_to(src_root)
        dst = dst_root / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        try:
            plaintext = decrypt_file(src_id, src)
        except Exception as e:
            results.append((rel, False, f"decrypt failed: {e}"))
            continue
        try:
            out = encrypt_file(dst_id, src.name, plaintext)
        except Exception as e:
            results.append((rel, False, f"encrypt failed: {e}"))
            continue
        dst.write_bytes(out)
        results.append((rel, True, f"{len(plaintext)} bytes"))
    return results


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--win-empress-root", required=True,
                    help="e.g. /media/bogdan/Windows/Users/icebo/AppData/Roaming/EMPRESS/782330")
    ap.add_argument("--linux-rune-root", required=True,
                    help="e.g. ~/.steam/steam/steamapps/compatdata/<appid>/pfx/drive_c/users/Public/Documents/Steam/RUNE/782330")
    ap.add_argument("--rune-id3", default="6112203",
                    help="SteamID3 of the Linux RUNE account (hardcoded to 6112203 in upstream tool)")
    args = ap.parse_args()

    win_root = Path(args.win_empress_root).expanduser()
    lin_root = Path(args.linux_rune_root).expanduser()

    # Source: Windows EMPRESS saves at <win_root>/remote/<appid>/remote/
    win_saves = win_root / "remote" / "782330" / "remote"
    if not win_saves.is_dir():
        raise SystemExit(f"Windows save path not found: {win_saves}")

    # Windows identifier: plaintext user_steam_id.txt in remote/settings/
    win_id_file = win_root / "remote" / "settings" / "user_steam_id.txt"
    src_id = win_id_file.read_text().strip()
    dst_id = id3_to_id64(args.rune_id3)
    print(f"src_id (EMPRESS): {src_id}")
    print(f"dst_id (RUNE):    {dst_id}  (= SteamID3 {args.rune_id3} + {STEAM_ID3_TO_ID64_OFFSET})")

    # Destination: Linux RUNE remote/
    lin_saves = lin_root / "remote"
    lin_saves.mkdir(parents=True, exist_ok=True)

    print(f"\nRe-encrypting {win_saves} -> {lin_saves} ...")
    results = reencrypt_tree(win_saves, lin_saves, src_id, dst_id)
    for rel, ok, msg in results:
        mark = "OK" if ok else "FAIL"
        print(f"  [{mark}] {rel}: {msg}")

    # Also mirror settings/ and steam_settings/ verbatim (plaintext config)
    for sub in ("remote/settings", "steam_settings"):
        src = win_root / sub
        if not src.is_dir():
            continue
        # settings/ lives at <lin_root>/settings, steam_settings/ at <lin_root>/steam_settings
        dst = lin_root / ("settings" if sub == "remote/settings" else "steam_settings")
        dst.mkdir(parents=True, exist_ok=True)
        for f in src.iterdir():
            if f.is_file():
                shutil.copy2(f, dst / f.name)
        print(f"copied config: {src} -> {dst}")

    # Also copy the Windows PROFILE contents to the 'profile' (lowercase) dir
    # in case Wine opens that casing. We don't re-encrypt because profile.bin
    # is already handled in the loop above under PROFILE/.
    upper = lin_saves / "PROFILE"
    lower = lin_saves / "profile"
    if upper.is_dir():
        lower.mkdir(exist_ok=True)
        for f in upper.iterdir():
            shutil.copy2(f, lower / f.name)
        print(f"mirrored PROFILE/ -> profile/ (case-insensitive Wine)")


if __name__ == "__main__":
    main()
