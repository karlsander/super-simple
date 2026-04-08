#!/usr/bin/env python3

import json
import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
SPLICE_ROOT = Path("/Users/kall/Splice - user-5808997461/sounds")
SAMPLES_ROOT = ROOT / "SuperSimple" / "Resources" / "Samples"
WORLD_ROOT = SAMPLES_ROOT / "world"
APP_MANIFEST_PATH = SAMPLES_ROOT / "sample-library.json"
DOCS_MANIFEST_PATH = ROOT / "Docs" / "sample-library-manifest.json"

VOICE_MAP = {
    "kick": {
        "source": "packs/Andreas Klein - Jazz Drums/splice-export__andreas-klein-jazz-drums_edited/one_shot/Drums/Kick/RT_Jazz_Drums_Jazz_Kit_Floor_Kick_f_Drums_Andreas_Klein_one_shot.wav",
    },
    "snare": {
        "source": "packs/Andreas Klein - Jazz Drums/splice-export__andreas-klein-jazz-drums_edited/one_shot/Drums/Snare/RT_Jazz_Drums_Jazz_Kit_Snare_ff_Drums_Andreas_Klein_one_shot.wav",
    },
    "clap": {
        "source": "packs/Smoke Dreams Soul Tapes/One_Shots/Drums/Single/Claps/SO_SM_clap_soft.wav",
    },
    "crossStick": {
        "source": "packs/Iconic Modern/Iconic_Modern/Modern_Percussion/ESM_Iconic_Click_2_Wood_Organic_Acoustic_Drum_Stick.wav",
        "note": "Closest available rim-click substitute. No explicit cross-stick was present.",
    },
    "closedHat": {
        "source": "packs/Andreas Klein - Jazz Drums/splice-export__andreas-klein-jazz-drums_edited/one_shot/Drums/Hat/RT_Jazz_Drums_Jazz_Kit_HH_Stick_Tip_2_Drums_Andreas_Klein_one_shot.wav",
    },
    "openHat": {
        "source": "packs/New School - Alternative R&B/New_School_-_Alternative_R&B/One-Shots/Drum_One-Shots/Hi-HatsToms/SOULSURPLUS_newschool_one_shot_open_hat_dry.wav",
    },
    "hiHatFoot": {
        "source": "packs/Andreas Klein - Jazz Drums/splice-export__andreas-klein-jazz-drums_edited/one_shot/Drums/Hat/RT_Jazz_Drums_Jazz_Kit_HH_Foot_2_Drums_Andreas_Klein_one_shot.wav",
    },
    "ride": {
        "source": "packs/Cloud Forest/Cloud_Forest/One_Shots/Cymbals/ru_XX_cymbal_ride_tip.wav",
    },
    "brushTap": {
        "source": "packs/Shapes Avant Garde Jazz/Signature_-_Shapes_Avant_Garde/One_Shots/Drum_One_Shots/Snare/SIG_SAG_snare_brush_tap_medium.wav",
    },
    "brushSweep": {
        "source": "packs/Rhythm Selections/Signature_-_Rhythm_Selections/One_Shots/Drum_One_Shots/Snares/SIG_RS_drum_snare_brush_open_sweep_fast.wav",
    },
    "shaker": {
        "source": "packs/REIMAGINED 2000s RNB (James Penley)/REIMAGINED_2000s_RNB/One_Shots/Drum_One_Shots/shaker_one_shots/JJP_R2000SRNB_shaker_one_shot_settle.wav",
    },
    "maraca": {
        "source": "packs/Latin Percussion/SM_Studio_-_Latin_Percussion_-_Wav/sampler_instruments/kits/classico/classico_Samples/lp_maracas_shake.wav",
    },
    "guache": {
        "source": "packs/Latin Pop Trends/Decliped_Samples_-_Latin_Pop_Trends/One_Shots/Percussion_One_Shots/Shakers/DS_LPT_percussion_shaker_pure.wav",
        "note": "Closest available substitute. No true guache or cabasa was present.",
    },
    "clave": {
        "source": "packs/Rhythmic Origins/Rhythmic_Origins/one_shots/wood/claves/bamboo_slit_stick/si_origins_percussion_wood_clave_bamboo_slit_stick_loud_intrigue.wav",
    },
    "agogo": {
        "source": "packs/Latin Percussion/SM_Studio_-_Latin_Percussion_-_Wav/sampler_instruments/hit_type_patches/kontakt/agogo_Samples/lp_agogo_high.wav",
    },
    "tambora": {
        "source": "packs/Ritmo Latin Percussion/SO_RLP_Ritmo/One_Shots/Tambora/SO_RLP_tambora_hit_soledad.wav",
    },
    "llamador": {
        "source": "packs/Suena Latino/One_Shots/percussion/SC_SL_llamador_hit.wav",
    },
    "alegre": {
        "source": "packs/Colombian Percussion/One_Shots/Alegre/SO_COL_alegre_mid.wav",
    },
    "surdo": {
        "source": "packs/Batteria Campeon by Basement Freaks/One_Shots/Surdo_One_Shots/BOS_BC_Low_Surdo_One_Shot_White.wav",
    },
    "pandeiro": {
        "source": "packs/Brazilian Carnival Percussion/One_Shots/Pandeiro/SO_BC_pandeiro_hit_simple.wav",
    },
    "tamborim": {
        "source": "packs/Batteria Campeon by Basement Freaks/One_Shots/Tamborim_One_Shots/BOS_BC_Tambo_One_Shot_Teal.wav",
    },
    "caixa": {
        "source": "packs/Hybrid Beats Favela Trap Vol 2/Soundsmiths_Hybrid_Beats_Favela_Trap_Vol_2/One_shots/Percussion_one_shots/SS_FT2_Perc_Caixa_Linda.wav",
    },
    "congaLow": {
        "source": "packs/Dirty Disco Vol. 3/TS_DIRTY_DISCO_VOLUME_3/one_shots/congas/TS_DD_VOL3_conga_low_open_slap.wav",
    },
}


def build_manifest() -> dict:
    voices = {}

    for voice, config in VOICE_MAP.items():
        source_path = SPLICE_ROOT / config["source"]
        if not source_path.exists():
            raise FileNotFoundError(f"Missing source sample for {voice}: {source_path}")

        destination_name = f"world-{voice}{source_path.suffix.lower()}"
        destination_path = WORLD_ROOT / destination_name
        shutil.copy2(source_path, destination_path)

        voice_entry = {
            "source_url": None,
            "preview_url": None,
            "license": "Splice",
            "license_url": None,
            "credit": source_path.name,
            "resource_subdirectory": "Samples/world",
            "resource_filename": destination_name,
            "bundle_path": str(destination_path.relative_to(ROOT)),
            "source_path": str(source_path.relative_to(SPLICE_ROOT)),
        }
        if "note" in config:
            voice_entry["mapping_note"] = config["note"]

        voices[voice] = voice_entry

    return {
        "packs": [
            {
                "id": "world",
                "name": "World",
                "subtitle": "Curated Splice one-shots for acoustic kit and world percussion",
                "voices": voices,
            }
        ]
    }


def reset_world_directory() -> None:
    if WORLD_ROOT.exists():
        shutil.rmtree(WORLD_ROOT)
    WORLD_ROOT.mkdir(parents=True, exist_ok=True)


def write_manifest(path: Path, manifest: dict) -> None:
    path.write_text(json.dumps(manifest, indent=2) + "\n")


def main() -> None:
    reset_world_directory()
    manifest = build_manifest()
    write_manifest(APP_MANIFEST_PATH, manifest)
    write_manifest(DOCS_MANIFEST_PATH, manifest)

    print("Synced Splice sample pack:")
    for voice, config in VOICE_MAP.items():
        note = config.get("note")
        if note:
            print(f"- {voice}: {config['source']} ({note})")
        else:
            print(f"- {voice}: {config['source']}")


if __name__ == "__main__":
    main()
