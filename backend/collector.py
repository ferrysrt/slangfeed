"""
SlangFeed Pipeline — Collector
FIX #6 (v2): query pakai bulan + tahun DINAMIS dari tanggal run
(contoh: "latest internet slang September 2026") — mempersempit hasil
ke tren terkini. Timezone UTC = zona waktu runner GitHub Actions.
Firecrawl search API (REST langsung, tanpa SDK — lebih stabil antar versi)
-> dapat 10 URL + konten markdown (scrapeOptions) -> fallback scrape per-URL.
"""
import time
import os

import requests

API_URL = "https://api.firecrawl.dev"
SEARCH_QUERY_TEMPLATE = "latest internet slang {month} {year} -site:youtube.com -site:tiktok.com"
MAX_URLS = 10
DELAY_SEC = 1.0


def get_search_query() -> str:
    from datetime import datetime, timezone
    now = datetime.now(timezone.utc)
    return SEARCH_QUERY_TEMPLATE.format(month=now.strftime("%B"), year=now.year)


def _headers(api_key: str) -> dict:
    return {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }


def collect() -> list[str]:
    """Return list of raw markdown/text scraped from up to MAX_URLS pages."""
    api_key = os.getenv("FIRECRAWL_API_KEY")
    if not api_key:
        raise RuntimeError("FIRECRAWL_API_KEY tidak tersedia")

    query = get_search_query()
    print(f"[COLLECTOR] Query: {query}")

    # ---- Step 1: search sekaligus scrape (v1 search + scrapeOptions) ----
    resp = requests.post(
        "https://api.firecrawl.dev/v1/search",
        headers=_headers(api_key),
        json={
            "query": get_search_query(),
            "limit": MAX_URLS,
            "scrapeOptions": {"formats": ["markdown"]},
        },
        timeout=60,
    )

    texts: list[str] = []
    urls: list[str] = []

    if resp.status_code == 200:
        data = resp.json().get("data", [])
        for item in data:
            md = (item.get("markdown") or "")[:20000]
            url = item.get("url", "?")
            if md.strip():
                texts.append(md)
                urls.append(url)
        print(f"[COLLECTOR] search+scrape langsung: {len(texts)} halaman")
    else:
        print(f"[COLLECTOR] search gagal (HTTP {resp.status_code}): {resp.text[:300]}")

    # ---- Fallback: kalau search-with-scrape gak menghasilkan markdown,
    #      scrape manual satu per satu ----
    if not texts:
        from datetime import datetime
        query = get_search_query()
        print(f"[COLLECTOR] Query: {query}")
        search = requests.post(
            "https://api.firecrawl.dev/v1/search",
            headers=_headers(api_key),
            json={"query": query, "limit": MAX_URLS},
            timeout=60,
        )
        search.raise_for_status()
        results = search.json().get("data", [])
        urls = [r.get("url") for r in results if r.get("url")]
        print(f"[COLLECTOR] Dapat {len(urls)} URL dari search (tanpa konten)")

        for i, url in enumerate(urls[:MAX_URLS]):
            try:
                result = requests.post(
                    "https://api.firecrawl.dev/v1/scrape",
                    headers=_headers(api_key),
                    json={"url": url, "formats": ["markdown"]},
                    timeout=60,
                )
                result.raise_for_status()
                md = (result.json().get("data", {}).get("markdown") or "")[:20000]
                if md.strip():
                    texts.append(md)
                    print(f"[COLLECTOR] [{i+1}/{len(urls)}] OK {url} ({len(md)} chars)")
            except Exception as e:
                print(f"[COLLECTOR] [{i+1}/{len(urls)}] GAGAL {url}: {e}")
            time.sleep(DELAY_SEC)

    for i, u in enumerate(urls):
        print(f"[COLLECTOR] [{i+1}] {u}")
    print(f"[COLLECTOR] Total halaman valid: {len(texts)}")
    return texts
