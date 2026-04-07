#!/usr/bin/env python3

import json
import re
import sys
from pathlib import Path
from urllib.parse import urlparse

import requests


ROOT = Path(__file__).resolve().parent.parent
SAMPLES_ROOT = ROOT / "SuperSimple" / "Resources" / "Samples"
APP_MANIFEST_PATH = SAMPLES_ROOT / "sample-library.json"
DOCS_MANIFEST_PATH = ROOT / "Docs" / "sample-library-manifest.json"

ALLOWED_LICENSES = {
    "CC0": (
        "http://creativecommons.org/publicdomain/zero/1.0/",
        "https://creativecommons.org/publicdomain/zero/1.0/",
    ),
    "CC-BY": (
        "http://creativecommons.org/licenses/by/3.0/",
        "https://creativecommons.org/licenses/by/3.0/",
        "http://creativecommons.org/licenses/by/4.0/",
        "https://creativecommons.org/licenses/by/4.0/",
    ),
}

SAMPLE_LIBRARY = {
    "packs": [
        {
            "id": "real",
            "name": "Real",
            "subtitle": "Acoustic drum kit first, with faithful world duplicates where needed",
            "voices": {
                "click": {
                    "source_url": "https://freesound.org/people/KEVOY/sounds/82280/",
                    "credit": "KEVOY - acoustic side stick.wav",
                },
                "kick": {
                    "source_url": "https://freesound.org/people/Sound_Bar_KK/sounds/424662/",
                    "credit": "Sound_Bar_KK - Acoustic Drum Kick.wav",
                },
                "snare": {
                    "source_url": "https://freesound.org/s/264785/",
                    "credit": "johnthewizar - Snare 1.wav",
                },
                "clap": {
                    "source_url": "https://freesound.org/people/totalcult/sounds/388546/",
                    "credit": "totalcult - Clap 01.wav",
                },
                "crossStick": {
                    "source_url": "https://freesound.org/people/KEVOY/sounds/82280/",
                    "credit": "KEVOY - acoustic side stick.wav",
                },
                "closedHat": {
                    "source_url": "https://freesound.org/people/laserlife/sounds/401733/",
                    "credit": "laserlife - Closed hi-hat sample",
                },
                "openHat": {
                    "source_url": "https://freesound.org/people/BenjaminDavis0802/sounds/556810/",
                    "credit": "BenjaminDavis0802 - Open Hi Hat.wav",
                },
                "hiHatFoot": {
                    "source_url": "https://freesound.org/people/pjcohen/sounds/93910/",
                    "credit": "pjcohen - SkibaCustomHiHats1145Top1215BottomFootPedalCloseChick.wav",
                },
                "ride": {
                    "source_url": "https://freesound.org/people/pjcohen/sounds/93907/",
                    "credit": "pjcohen - KZildjianIstanbul20Ride2220GramsSkibaModifiedWash.wav",
                },
                "brushTap": {
                    "source_url": "https://freesound.org/people/captain%20k%20man/sounds/125022/",
                    "credit": "captain k man - Snare Normal Hit Brushes.wav",
                },
                "brushSweep": {
                    "source_url": "https://freesound.org/people/pagliacciao1/sounds/699469/",
                    "credit": "pagliacciao1 - SWSHSNAR.WAV",
                },
                "shaker": {
                    "source_url": "https://freesound.org/people/Joao_Janz/sounds/482587/",
                    "credit": "Joao_Janz - Cabasa 1_1",
                },
                "maraca": {
                    "source_url": "https://freesound.org/people/sgossner/sounds/375707/",
                    "credit": "sgossner - Maraca (maraca_shake.wav)",
                },
                "guache": {
                    "source_url": "https://freesound.org/people/Joao_Janz/sounds/482587/",
                    "credit": "Joao_Janz - Cabasa 1_1",
                },
                "clave": {
                    "source_url": "https://freesound.org/people/SamuelGremaud/sounds/517609/",
                    "credit": "SamuelGremaud - CLAVES",
                },
                "agogo": {
                    "source_url": "https://freesound.org/people/BlueCircleSounds/sounds/524026/",
                    "credit": "BlueCircleSounds - Agogo High3.wav",
                },
                "tambora": {
                    "source_url": "https://freesound.org/people/el.papa.montero/sounds/510789/",
                    "credit": "el.papa.montero - Tambora clavada.mp3",
                },
                "llamador": {
                    "source_url": "https://freesound.org/people/el.papa.montero/sounds/510790/",
                    "credit": "el.papa.montero - Barril prensado.mp3",
                },
                "alegre": {
                    "source_url": "https://freesound.org/people/KJose/sounds/620245/",
                    "credit": "KJose - bongo_slaps.flac",
                },
                "surdo": {
                    "source_url": "https://freesound.org/people/Vivabarca1899/sounds/144146/",
                    "credit": "Vivabarca1899 - Surdo.wav",
                },
                "pandeiro": {
                    "source_url": "https://freesound.org/people/katusm/sounds/527967/",
                    "credit": "katusm - Pandeiro",
                },
                "tamborim": {
                    "source_url": "https://freesound.org/people/ellamedeiros/sounds/406983/",
                    "credit": "ellamedeiros - tamborim.wav",
                },
                "caixa": {
                    "source_url": "https://freesound.org/people/Sassaby/sounds/531788/",
                    "credit": "Sassaby - Caixa Tarol Rim",
                },
                "congaLow": {
                    "source_url": "https://freesound.org/people/Joao_Janz/sounds/477895/",
                    "credit": "Joao_Janz - Yamaha PSR-36 Conga Low",
                },
            },
        },
        {
            "id": "world",
            "name": "World",
            "subtitle": "Country-specific drums first, with kit voices still available",
            "voices": {
                "click": {
                    "source_url": "https://freesound.org/people/KEVOY/sounds/82280/",
                    "credit": "KEVOY - acoustic side stick.wav",
                },
                "kick": {
                    "source_url": "https://freesound.org/people/Sound_Bar_KK/sounds/424662/",
                    "credit": "Sound_Bar_KK - Acoustic Drum Kick.wav",
                },
                "snare": {
                    "source_url": "https://freesound.org/s/264785/",
                    "credit": "johnthewizar - Snare 1.wav",
                },
                "clap": {
                    "source_url": "https://freesound.org/people/totalcult/sounds/388546/",
                    "credit": "totalcult - Clap 01.wav",
                },
                "crossStick": {
                    "source_url": "https://freesound.org/people/KEVOY/sounds/82280/",
                    "credit": "KEVOY - acoustic side stick.wav",
                },
                "closedHat": {
                    "source_url": "https://freesound.org/people/laserlife/sounds/401733/",
                    "credit": "laserlife - Closed hi-hat sample",
                },
                "openHat": {
                    "source_url": "https://freesound.org/people/BenjaminDavis0802/sounds/556810/",
                    "credit": "BenjaminDavis0802 - Open Hi Hat.wav",
                },
                "hiHatFoot": {
                    "source_url": "https://freesound.org/people/pjcohen/sounds/93910/",
                    "credit": "pjcohen - SkibaCustomHiHats1145Top1215BottomFootPedalCloseChick.wav",
                },
                "ride": {
                    "source_url": "https://freesound.org/people/pjcohen/sounds/93907/",
                    "credit": "pjcohen - KZildjianIstanbul20Ride2220GramsSkibaModifiedWash.wav",
                },
                "brushTap": {
                    "source_url": "https://freesound.org/people/captain%20k%20man/sounds/125022/",
                    "credit": "captain k man - Snare Normal Hit Brushes.wav",
                },
                "brushSweep": {
                    "source_url": "https://freesound.org/people/pagliacciao1/sounds/699469/",
                    "credit": "pagliacciao1 - SWSHSNAR.WAV",
                },
                "shaker": {
                    "source_url": "https://freesound.org/people/Joao_Janz/sounds/482587/",
                    "credit": "Joao_Janz - Cabasa 1_1",
                },
                "maraca": {
                    "source_url": "https://freesound.org/people/sgossner/sounds/375707/",
                    "credit": "sgossner - Maraca (maraca_shake.wav)",
                },
                "guache": {
                    "source_url": "https://freesound.org/people/Joao_Janz/sounds/482587/",
                    "credit": "Joao_Janz - Cabasa 1_1",
                },
                "clave": {
                    "source_url": "https://freesound.org/people/SamuelGremaud/sounds/517609/",
                    "credit": "SamuelGremaud - CLAVES",
                },
                "agogo": {
                    "source_url": "https://freesound.org/people/BlueCircleSounds/sounds/524026/",
                    "credit": "BlueCircleSounds - Agogo High3.wav",
                },
                "tambora": {
                    "source_url": "https://freesound.org/people/el.papa.montero/sounds/510789/",
                    "credit": "el.papa.montero - Tambora clavada.mp3",
                },
                "llamador": {
                    "source_url": "https://freesound.org/people/el.papa.montero/sounds/510790/",
                    "credit": "el.papa.montero - Barril prensado.mp3",
                },
                "alegre": {
                    "source_url": "https://freesound.org/people/KJose/sounds/620245/",
                    "credit": "KJose - bongo_slaps.flac",
                },
                "surdo": {
                    "source_url": "https://freesound.org/people/Vivabarca1899/sounds/144146/",
                    "credit": "Vivabarca1899 - Surdo.wav",
                },
                "pandeiro": {
                    "source_url": "https://freesound.org/people/katusm/sounds/527967/",
                    "credit": "katusm - Pandeiro",
                },
                "tamborim": {
                    "source_url": "https://freesound.org/people/ellamedeiros/sounds/406983/",
                    "credit": "ellamedeiros - tamborim.wav",
                },
                "caixa": {
                    "source_url": "https://freesound.org/people/Sassaby/sounds/531788/",
                    "credit": "Sassaby - Caixa Tarol Rim",
                },
                "congaLow": {
                    "source_url": "https://freesound.org/people/Joao_Janz/sounds/477895/",
                    "credit": "Joao_Janz - Yamaha PSR-36 Conga Low",
                },
            },
        },
    ]
}


def extract_preview_url(html: str) -> str:
    match = re.search(r"https://cdn\.freesound\.org/previews/[^\"']+-hq\.mp3", html)
    if not match:
        raise RuntimeError("Could not find HQ preview URL")
    return match.group(0)


def extract_license(html: str) -> tuple[str, str]:
    for license_code, urls in ALLOWED_LICENSES.items():
        for url in urls:
            if url in html:
                return license_code, url
    raise RuntimeError("Sound page did not expose an allowed CC0 or CC-BY license")


def download_file(session: requests.Session, url: str, destination: Path) -> None:
    response = session.get(url, timeout=30)
    response.raise_for_status()
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(response.content)


def output_filename(preview_url: str, pack_id: str, voice: str) -> str:
    extension = Path(urlparse(preview_url).path).suffix or ".mp3"
    return f"{pack_id}-{voice}{extension}"


def main() -> int:
    manifest = {"packs": []}
    session = requests.Session()
    session.headers.update({"User-Agent": "Mozilla/5.0"})

    for pack in SAMPLE_LIBRARY["packs"]:
        pack_entry = {
            "id": pack["id"],
            "name": pack["name"],
            "subtitle": pack["subtitle"],
            "voices": {},
        }
        pack_directory = SAMPLES_ROOT / pack["id"]

        for voice, sample in pack["voices"].items():
            page_response = session.get(sample["source_url"], timeout=30)
            page_response.raise_for_status()
            preview_url = extract_preview_url(page_response.text)
            license_code, license_url = extract_license(page_response.text)
            filename = output_filename(preview_url, pack["id"], voice)
            destination = pack_directory / filename
            download_file(session, preview_url, destination)

            pack_entry["voices"][voice] = {
                "source_url": sample["source_url"],
                "preview_url": preview_url,
                "license": license_code,
                "license_url": license_url,
                "credit": sample["credit"],
                "resource_subdirectory": f"Samples/{pack['id']}",
                "resource_filename": filename,
                "bundle_path": str(destination.relative_to(ROOT)),
            }

            print(f"Downloaded {pack['id']}/{filename} [{license_code}]")

        manifest["packs"].append(pack_entry)

    SAMPLES_ROOT.mkdir(parents=True, exist_ok=True)
    APP_MANIFEST_PATH.write_text(json.dumps(manifest, indent=2) + "\n")
    DOCS_MANIFEST_PATH.parent.mkdir(parents=True, exist_ok=True)
    DOCS_MANIFEST_PATH.write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Wrote bundle manifest to {APP_MANIFEST_PATH}")
    print(f"Wrote docs manifest to {DOCS_MANIFEST_PATH}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
