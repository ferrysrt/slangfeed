"""
SlangFeed Pipeline — Toxicity Filter (FIX #2A)
Detoxify (RoBERTa) threshold 0.3: skor > 0.3 -> TOLAK.
Konsisten dengan proposal: "skor toksisitas di atas 0,3 dihapus otomatis".
"""
import os

THRESHOLD = 0.3

_model = None
_tokenizer = None


def _load_model():
    global _model, _tokenizer
    if _model is None:
        from transformers import AutoModelForSequenceClassification, AutoTokenizer
        import torch

        model_name = "unitary/toxic-bert"  # Detoxify original weights (RoBERTa-based)
        _tokenizer = AutoTokenizer.from_pretrained(model_name)
        _model = AutoModelForSequenceClassification.from_pretrained(model_name)
        _model.eval()
        if torch.cuda.is_available():
            _model.cuda()
    return _model, _tokenizer


def filter_entries(entries: list[dict]) -> tuple[list[dict], int]:
    """Return (entries_lolos, jumlah_ditolak)."""
    try:
        model, tokenizer = _load_model()
    except Exception as e:
        print(f"[FILTER] Model Detoxify gagal dimuat ({e}) — FAIL-SAFE: tolak semua kandidat baru")
        return [], len(entries)

    import torch

    kept, rejected = [], 0
    for e in entries:
        text = f"{e.get('slang', '')} {e.get('definition', '')} {e.get('origin_context', '')}"
        inputs = tokenizer(text, return_tensors="pt", truncation=True, max_length=512)
        if torch.cuda.is_available():
            inputs = {k: v.cuda() for k, v in inputs.items()}
        with torch.no_grad():
            outputs = model(**inputs)
        scores = outputs.logits.sigmoid().squeeze().tolist()
        toxicity = max(scores) if isinstance(scores, list) else float(scores)
        if toxicity > THRESHOLD:
            rejected += 1
            print(f"[FILTER] TOLAK '{e.get('slang', '')}' (toxicity={toxicity:.3f})")
        else:
            kept.append(e)
    print(f"[FILTER] Lolos: {len(kept)}, ditolak: {rejected}")
    return kept, rejected
