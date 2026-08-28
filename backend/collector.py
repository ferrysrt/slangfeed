"""
SlangFeed Pipeline — Collector
FIX #6: query pakai tahun dinamis dari tanggal run.
Firecrawl search -> scrape 10 URL (delay >= 1 detik).
"""
import time
import os

SEARCH_QUERY_TEMPLATE = "latest internet slang {year} -site:youtube.com -site:tiktok.com"
MAX_URLS = 10
DELAY_SEC = 1.0


def get_search_query() -> str:
    from datetime import datetime
    return SEARCH_QUERY_TEMPLATE.format(year=datetime.now().year)


def collect() -> list[str]:
    """Return list of raw markdown/text scraped from up to MAX_URLS pages."""
    from firecrawl import FirecrawlApp

    api_key = os.getenv("FIRECRAWL_API_KEY")
    if not api_key:
        raise RuntimeError("FIRECRAWL_API_KEY tidak tersedia")

    app = FirecrawlApp(api_key=api_key)
    query = get_search_query()
    print(f"[COLLECTOR] Query: {query}")

    search = app.search(query, limit=MAX_URLS)
    urls = [r.get("url") for r in search.get("data", []) if r.get("url")]
    print(f"[COLLECTOR] Dapat {len(urls)} URL")

    texts = []
    for i, url in enumerate(urls[:MAX_URLS]):
        try:
            result = app.scrape_url(url, params={"formats": ["markdown"]})
            md = (result.get("markdown") or "")[:20000]  # batasi ukuran per halaman
            if md.strip():
                texts.append(md)
                print(f"[COLLECTOR] [{i+1}/{len(urls)}] OK {url} ({len(md)} chars)")
        except Exception as e:
            print(f"[COLLECTOR] [{i+1}/{len(urls)}] GAGAL {url}: {e}")
        time.sleep(DELAY_SEC)

    print(f"[COLLECTOR] Total halaman valid: {len(texts)}")
    return texts
