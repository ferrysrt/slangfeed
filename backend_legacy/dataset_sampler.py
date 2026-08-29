"""
Dataset Sampler — Random slang retrieval from curated dataset.

Architecture:
- Loads curated CSV dataset (457 SFW slangs)
- Filters NSFW entries at startup
- Provides random sampling with exclusion of already-used slangs
- Slang selection is theme-independent (theme applied by LLM in prompt)

This ensures slangs can appear in ANY context:
  e.g. "cook" in gaming, "AFK" in cooking, "ghosting" in work context
"""
import pandas as pd
import os
import time
from config import SLANG_SAMPLE_COUNT

# ============================================================
# Load & Filter Dataset
# ============================================================
_dataset_path = os.path.join(
    os.path.dirname(__file__), "data", "final_slang_with_nsfw_with_colab.csv"
)

print("[DATASET] Loading dataset...")
_dataset_raw = pd.read_csv(_dataset_path)
_dataset_raw.columns = [c.strip() for c in _dataset_raw.columns]
print(f"[DATASET] Dataset loaded: {len(_dataset_raw)} total slangs")

# Filter out NSFW slangs (labeled by LLM in label_nsfw.py)
if "is_nsfw" in _dataset_raw.columns:
    nsfw_mask = _dataset_raw["is_nsfw"].apply(lambda x: str(x).lower() == "true")
    nsfw_count = nsfw_mask.sum()
    _dataset = _dataset_raw[~nsfw_mask].copy()
    print(f"[DATASET] Filtered {nsfw_count} NSFW slangs → {len(_dataset)} safe slangs remaining")
else:
    _dataset = _dataset_raw.copy()
    print("[DATASET] No 'is_nsfw' column found — using all slangs")

print(f"[DATASET] Columns: {list(_dataset.columns)}")
print("[DATASET] ============ DATASET READY ============\n")


# ============================================================
# Random Sampling Function
# ============================================================
def sample_slangs(
    n: int = SLANG_SAMPLE_COUNT,
    exclude_list: list[str] | None = None,
) -> list[dict]:
    """
    Randomly sample slangs from the curated dataset.

    Args:
        n: Number of slangs to return
        exclude_list: Slangs already used in this session (won't be picked again)

    Returns:
        List of dicts with Slang, Definition, Origin/Context
    """
    sample_start = time.time()

    df = _dataset.copy()

    # Filter already-used slangs
    if exclude_list:
        exclude_lower = {s.lower().strip() for s in exclude_list}
        df = df[~df["Slang"].str.lower().str.strip().isin(exclude_lower)]

    # If all slangs exhausted, reset pool
    if len(df) == 0:
        print("[DATASET] All slangs exhausted — resetting pool")
        df = _dataset.copy()

    if len(df) < n:
        n = len(df)

    # Random sample
    sampled = df.sample(n=n)
    results = sampled.to_dict("records")

    elapsed = time.time() - sample_start
    print(f"[DATASET] Sampled {len(results)} slangs in {elapsed:.4f}s:")
    for r in results:
        print(f"[DATASET]   - {r['Slang']}")

    return results


# ============================================================
# Utility Functions
# ============================================================
def get_all_slangs() -> list[str]:
    """Return all available slang terms."""
    return _dataset["Slang"].tolist()


def get_dataset_stats() -> dict:
    """Return dataset statistics for health check."""
    return {
        "total_slangs": len(_dataset),
        "columns": list(_dataset.columns),
    }
