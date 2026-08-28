"""
SlangFeed Pipeline — Orchestrator (main.py)
GitHub Actions mingguan: collect -> normalize -> filter -> validate -> store.
Run gagal total = TIDAK ada push (SRS FR-A11): exit code 1 tanpa mengubah dataset.
"""
import sys

import collector
import normalizer
import filter_toxicity
import validator


def main() -> int:
    print("=" * 60)
    print("[MAIN] SlangFeed dataset pipeline — start")
    print("=" * 60)

    # 1. Collect
    try:
        raw_texts = collector.collect()
    except Exception as e:
        print(f"[MAIN] FATAL collect: {e}")
        return 1
    if not raw_texts:
        print("[MAIN] Tidak ada halaman valid — batal tanpa push")
        return 1

    # 2. Normalize (LLM#1)
    try:
        candidates = normalizer.normalize(raw_texts)
    except Exception as e:
        print(f"[MAIN] FATAL normalize: {e}")
        return 1
    if not candidates:
        print("[MAIN] Tidak ada kandidat entri — batal tanpa push")
        return 1

    # 3. Filter toxicity (Detoxify > 0.3 -> tolak)
    kept, rejected_count = filter_toxicity.filter_entries(candidates)

    # 4. Validate + dedup + merge
    existing, seen = validator.load_existing()
    result = validator.validate_and_merge(kept, existing, seen)
    stats = result["stats"]
    stats["ditolak_filter"] = rejected_count

    if not result["merged"]:
        print("[MAIN] Dataset hasil kosong — batal tanpa push")
        return 1

    # 5. Store
    path = validator.save_dataset(result["merged"])
    log_path = validator.save_log(stats, {"scraped_pages": len(raw_texts)})
    print(f"[MAIN] Dataset tersimpan: {path} ({stats['final']} entri)")
    print(f"[MAIN] Log run: {log_path}")
    print("[MAIN] DONE — siap dipush oleh GitHub Actions")
    return 0


if __name__ == "__main__":
    sys.exit(main())
