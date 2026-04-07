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
            "id": "club909",
            "name": "Club 909",
            "subtitle": "Direct machine hits for techno and house",
            "voices": {
                "kick": {
                    "source_url": "https://freesound.org/people/ZeSoundResearchInc./sounds/145775/",
                    "credit": "ZeSoundResearchInc. - 909 kICK.WAV",
                },
                "snare": {
                    "source_url": "https://freesound.org/people/laffik/sounds/645870/",
                    "credit": "laffik - snare claps.wav",
                },
                "closedHat": {
                    "source_url": "https://freesound.org/people/TheEndOfACycle/sounds/674294/",
                    "credit": "TheEndOfACycle - Hi-Hat Closed Hit 01",
                },
                "openHat": {
                    "source_url": "https://freesound.org/people/thehorsevalse/sounds/615385/",
                    "credit": "thehorsevalse - OHH Open Hi-Hat_1.wav",
                },
                "shaker": {
                    "source_url": "https://freesound.org/people/dfeltch/sounds/171658/",
                    "credit": "dfeltch - tambourine one shot.wav",
                },
                "clave": {
                    "source_url": "https://freesound.org/people/Lynx_5969/sounds/418730/",
                    "credit": "Lynx_5969 - Synth Clap.wav",
                },
            },
        },
        {
            "id": "garagehouse",
            "name": "Garage / House",
            "subtitle": "Glossy 4x4 and shuffled top-end choices",
            "voices": {
                "kick": {
                    "source_url": "https://freesound.org/people/Mattc90/sounds/347625/",
                    "credit": "Mattc90 - Deep House Kick Drum 3",
                },
                "snare": {
                    "source_url": "https://freesound.org/people/Johnnie_Holiday/sounds/611462/",
                    "credit": "Johnnie_Holiday - Trap Snare (A).wav",
                },
                "closedHat": {
                    "source_url": "https://freesound.org/people/blakengouda/sounds/509969/",
                    "credit": "blakengouda - Hi-Hat Closed 5.mp3",
                },
                "openHat": {
                    "source_url": "https://freesound.org/s/91683/",
                    "credit": "zinzan_101 - jd open hat.wav",
                },
                "shaker": {
                    "source_url": "https://freesound.org/people/Sadiquecat/sounds/792492/",
                    "credit": "Sadiquecat - Big Maraca OS 4",
                },
                "clave": {
                    "source_url": "https://freesound.org/people/TheDCHeck/sounds/383011/",
                    "credit": "TheDCHeck - Clap 1.wav",
                },
            },
        },
        {
            "id": "acousticdry",
            "name": "Acoustic Dry",
            "subtitle": "Clean drum-kit hits with a tighter room",
            "voices": {
                "kick": {
                    "source_url": "https://freesound.org/people/Sound_Bar_KK/sounds/424662/",
                    "credit": "Sound_Bar_KK - Acoustic Drum Kick.wav",
                },
                "snare": {
                    "source_url": "https://freesound.org/s/264785/",
                    "credit": "johnthewizar - Snare 1.wav",
                },
                "closedHat": {
                    "source_url": "https://freesound.org/people/laserlife/sounds/401733/",
                    "credit": "laserlife - Closed hi-hat sample",
                },
                "openHat": {
                    "source_url": "https://freesound.org/people/BenjaminDavis0802/sounds/556810/",
                    "credit": "BenjaminDavis0802 - Open Hi Hat.wav",
                },
                "shaker": {
                    "source_url": "https://freesound.org/people/Joao_Janz/sounds/482587/",
                    "credit": "Joao_Janz - Cabasa 1_1",
                },
                "clave": {
                    "source_url": "https://freesound.org/people/KEVOY/sounds/82280/",
                    "credit": "KEVOY - acoustic side stick.wav",
                },
            },
        },
        {
            "id": "latinhand",
            "name": "Latin Hand Perc",
            "subtitle": "Bongo, maraca, clave, and bell color",
            "voices": {
                "lowTom": {
                    "source_url": "https://freesound.org/s/375291/",
                    "credit": "sgossner - Bongos (LowBongo2.wav)",
                },
                "midTom": {
                    "source_url": "https://freesound.org/people/menegass/sounds/99752/",
                    "credit": "menegass - Bongo2.wav",
                },
                "shaker": {
                    "source_url": "https://freesound.org/people/Sadiquecat/sounds/792496/",
                    "credit": "Sadiquecat - Big Maraca Two ways OS 4",
                },
                "clave": {
                    "source_url": "https://freesound.org/people/SamuelGremaud/sounds/517609/",
                    "credit": "SamuelGremaud - CLAVES",
                },
                "bell": {
                    "source_url": "https://freesound.org/s/375612/",
                    "credit": "sgossner - Cowbell (cowbell_ff_1.wav)",
                },
                "closedHat": {
                    "source_url": "https://freesound.org/people/Joao_Janz/sounds/482587/",
                    "credit": "Joao_Janz - Cabasa 1_1",
                },
            },
        },
        {
            "id": "foundhybrid",
            "name": "Found Hybrid",
            "subtitle": "Quirkier replacements for contrast listening",
            "voices": {
                "kick": {
                    "source_url": "https://freesound.org/people/phluidbox/sounds/339436/",
                    "credit": "phluidbox - 80s KICK wAv",
                },
                "snare": {
                    "source_url": "https://freesound.org/people/Unknown_Audio/sounds/416921/",
                    "credit": "Unknown_Audio - Metallic Snare.wav",
                },
                "closedHat": {
                    "source_url": "https://freesound.org/people/ntrier/sounds/437260/",
                    "credit": "ntrier - Tuba Percussion - Hi Hat Closed.wav",
                },
                "openHat": {
                    "source_url": "https://freesound.org/people/ntrier/sounds/437259/",
                    "credit": "ntrier - Tuba Percussion - Hi Hat Open.wav",
                },
                "shaker": {
                    "source_url": "https://freesound.org/people/8bitmyketison/sounds/701295/",
                    "credit": "8bitmyketison - Ceramic Clap",
                },
                "clave": {
                    "source_url": "https://freesound.org/people/hollandm/sounds/692817/",
                    "credit": "hollandm - Woodblock-double.wav",
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
