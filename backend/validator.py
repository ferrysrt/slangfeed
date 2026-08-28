"""
SlangFeed Pipeline — Validator (FIX #3)
Validasi skema + dedup + garansi comma-free (FIX #9) + log reject per run.
"""
import csv
import json
import os
import re
from datetime import datetime

DATASET_PATH = os.path.join(os.path.dirname(__file__), "..", "data", "slang_dataset.csv")
LOGS_DIR = os.path.join(os.path.dirname(__file__), "..", "logs")
MAX_ENTRIES = 200  # SRS FR-A10


def load_existing() -> tuple[list[dict], set[str]]:
    existing = []
    seen = set()
    if os.path.exists(DATASET_PATH):
        with open(DATASET_PATH, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                slang = (row.get("slang") or "").strip()
                if slang:
                    existing.append({
                        "slang": slang,
                        "definition": (row.get("definition") or "").strip(),
                        "origin_context": (row.get("origin_context") or "").strip(),
                    })
                    seen.add(slang.lower())
    return existing, seen


def validate_and_merge(candidates: list[dict], existing: list[dict], seen: set[str]) -> dict:
    stats = {"masuk": len(candidates), "ditolak_skema": 0, "duplikat": 0, "ditambahkan": 0}
    merged = list(existing)
    for c in candidates:
        slang = c.get("slang", "").strip()
        definition = c.get("definition", "").strip()
        origin = c.get("origin_context", "").strip()
        # Skema: kolom wajib terisi, definition >= 5 kata (SRS FR-A6)
        if not slang or not definition or len(definition.split()) < 5:
            stats["ditolak_skema"] += 1
            continue
        # Garansi comma-free (FIX #9 — kalau normalizer kelewat)
        slang = _sanitize(slang)
        definition = _sanitize(definition)
        origin = _sanitize(origin)
        # Dedup case-insensitive (SRS FR-A7)
        if slang.lower() in seen:
            stats["duplikat"] += 1
            continue
        seen.add(slang.lower())
        merged.append({"slang": slang, "definition": definition, "origin_context": origin})
        stats["ditambahkan"] += 1

    # Cap 200 entri (rotasi: entri terlama diganti — SRS FR-A10)
    if len(merged) > MAX_ENTRIES:
        merged = merged[-MAX_ENTRIES:]
    stats["final"] = len(merged)
    return {"merged": merged, "stats": stats}


def save_dataset(merged: list[dict]) -> str:
    os.makedirs(os.path.dirname(DATASET_PATH), exist_ok=True)
    with open(DATASET_PATH, "w", encoding="utf-8", newline="\n") as f:
        f.write("slang,definition,origin_context\n")
        for r in merged:
            f.write(f"{r['slang']},{r['definition']},{r['origin_context']}\n")
    return os.path.abspath(DATASET_PATH)


def save_log(stats: dict, extra: dict | None = None) -> str:
    os.makedirs(LOGS_DIR, exist_ok=True)
    today = datetime.now().strftime("%Y-%m-%d")
    payload = {"run_date": today, **stats}
    if extra:
        payload.update(extra)
    path = os.path.join(LOGS_DIR, f"run_{today}.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2, ensure_ascii=False)
    return path


def _sanitize(s: str) -> str:
    s = s.replace('"', "").replace(",", " ").replace("\r", " ").replace("\n", " ")
    return re.sub(r"\s+", " ", s).strip()
