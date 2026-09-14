---
name: web-search-cn
description: Use when WebSearch returns US-only or poor Chinese results, the user asks to search the Chinese web or "搜一下/查一下" something whose content lives on the Chinese internet, or needs China-local content (domestic companies, policies, Chinese blogs/communities such as 知乎/微博/小红书/贴吧, weather, local news) that English web does not cover, or technical/international search where the built-in WebSearch is insufficient.
---

# Web Search (China)

## Overview
Search the web when the built-in `WebSearch` won't do — its backend is US-only and covers Chinese content poorly. Drive real search engines through the Playwright MCP instead: **Baidu** for China-local content (Chinese query, as-is), **Google** for technical/international content (Chinese query auto-translated to English first). No API keys, no new deps.

**Network constraints:** Bing (all domains) is blocked on the user's company network — never use Bing. If Google is unreachable (company network may block it), fall back to **Sogou** (国内可达, no key), then **Baidu** for the technical query as a last resort. Baidu is always reachable.

## When to Use
- User asks to search and the content lives on the Chinese internet.
- `WebSearch` gives US-centric or empty results for a China-related query.
- Need domestic companies, policies, Chinese community content, local weather/events.
- Technical search where English web has better coverage (libs, frameworks, papers, APIs).

## Engine Selection

| Query intent | Engine | Query language |
|---|---|---|
| China-local (国内公司/政策/中文社区/天气/本地新闻) | Baidu | Chinese, as-is |
| Technical/international (编程/库/框架/论文/国际新闻) | Google | English — translate first |
| Unclear or mixed | BOTH, then merge | per-engine |

When unsure, run BOTH and merge — the cost is one extra navigate + snapshot.

## Workflow
1. Classify intent (table above). If unclear → search both.
2. Build the URL (URL-encode the query):
   - Baidu: `https://www.baidu.com/s?wd=<encoded Chinese query>`
   - Google: `https://www.google.com/search?q=<encoded English query>&hl=en-US`
   - Sogou fallback (if Google unreachable): `https://www.sogou.com/web?query=<encoded English or Chinese query>`
3. `browser_navigate` to the URL. Detect block: if `document.title` is empty / generic / an error page, or `looksBlocked` (see **Reachability check** below), treat as unreachable and fall through.
4. Run the extractor via `browser_evaluate` — pick by engine (see **Extraction** below) → ~8 results as compact JSON. Falls back to `browser_snapshot` only if the extractor returns empty.
5. For a result needing full content: `WebFetch` the URL, or `browser_navigate` to it + `browser_snapshot`.
6. **Fallback chain for technical/international queries:** Google → Sogou → Baidu (with the English query; Baidu's English-tech coverage is weak but non-zero). Stop at the first engine that returns ≥3 results. China-local queries stay on Baidu (always reachable).
7. Synthesize results, cite titles + URLs.

## Reachability check

After `browser_navigate`, run this before extracting. If `blocked` is true (or `results` < 3), fall through to the next engine in the chain.

```js
() => ({
  title: document.title,
  h3: document.querySelectorAll('h3').length,
  externalLinks: [...document.querySelectorAll('a[href^="http"]')].filter(a => !/baidu\.com|google\.|sogou\.com|bing\.com/.test(a.host)).length,
  blocked: /can't be reached|err_|refused|timed out|无法访问|连接被重置|forbidden|ERR_/.test((document.body && document.body.innerText) || '') || !document.title || document.title.length < 3
})
```

## Extraction

Pick the extractor by current engine (based on the URL you navigated to). Both verified working.

### Baidu + Google (unified `h3` extractor)

Baidu: link is inside `h3` (`h3 a`). Google: link is an ancestor of `h3` (`h3.closest('a')`). The `||` covers both. Skips Baidu ads (`baidu.php`) and Google self-links. Returns `{title, url, snippet}`.

```js
() => {
  const out = [];
  document.querySelectorAll('h3').forEach(h3 => {
    const a = h3.querySelector('a') || h3.closest('a');
    if (!a) return;
    const title = (h3.innerText || '').trim();
    if (!title) return;
    let box = h3.parentElement;
    for (let i = 0; i < 4 && box; i++) { if ((box.innerText||'').length > title.length + 20) break; box = box.parentElement; }
    const snippet = box ? (box.innerText || '').replace(title, '').trim().slice(0, 160) : '';
    out.push({ title: title.slice(0, 120), url: a.href, snippet });
  });
  const seen = new Set(), res = [];
  for (const r of out) {
    if (!r.title || !r.url || seen.has(r.url)) continue;
    if (/baidu\.php|google\.com\/search|^https:\/\/www\.google\./.test(r.url)) continue;
    seen.add(r.url); res.push(r);
    if (res.length >= 8) break;
  }
  return res;
}
```

### Sogou fallback extractor (title + url only)

Sogou result blocks (`div.vrwrap`) mostly lack `h3`, and the title link's ancestor container holds the whole numbered result list — so snippets can't be cleanly extracted. Take **title + url only**; `WebFetch` for content. Title text includes a trailing source line (e.g. `\n博客园`); keep only the first line.

```js
() => {
  const links = [...document.querySelectorAll('a[href^="http"]')];
  const seen = new Set(), res = [];
  for (const a of links) {
    const raw = (a.innerText || '').trim();
    if (raw.length < 8) continue;
    if (/sogou\.com|yuanbao\.tencent|tencent\.com\/evt|qq\.com\/evt/.test(a.href)) continue;
    const title = raw.split('\n').map(s => s.trim()).filter(Boolean)[0] || raw;
    if (!title || seen.has(a.href)) continue;
    seen.add(a.href);
    res.push({ title: title.replace(/^\d+\.\s*/, '').slice(0, 100), url: a.href, snippet: '' });
    if (res.length >= 8) break;
  }
  return res;
}
```

- Baidu result URLs are redirect-wrapped: `baidu.com/link?url=` is organic, `baidu.php?url=` is an ad (ads are filtered). Following a `link?url=` URL via `browser_navigate` lands on the real page.
- Sogou URLs are direct (no redirect wrap) for non-WeChat sources; WeChat (`mp.weixin.qq.com`) links carry query params but work.
- Google/Sogou snippets are weak — `WebFetch` the URL for full content.

## Query Translation (Google path)
Translate the Chinese query to a concise **keyword** query in English — not a full sentence. Drop filler. Keep proper nouns.
- `Python asyncio 怎么做并发` → `python asyncio concurrency`
- `华为鸿蒙系统架构` → `huawei harmonyos architecture`

## Cleanup
After the search session, close the browser and remove Playwright temp files (CLAUDE.md browser-cleanup rule):
```bash
rm -f crg-*.png page-*.png && rm -rf .playwright-mcp
```

## Common Mistakes
- **Using Bing** — blocked on the user's company network (all bing domains). Never use Bing as a fallback; use Sogou then Baidu.
- **Sending a China-local query to Google translated** — "华为Mate70国内首发渠道" has no English-web coverage; keep it on Baidu.
- **Sending a technical query to Baidu in Chinese** — English docs/Stack Overflow/GitHub have better coverage; translate and use Google (fall back to Sogou if Google is blocked).
- **Skipping translation for Google** — a Chinese query on Google.com returns mostly Chinese-translated pages and misses the rich English web.
- **Forgetting to URL-encode** — spaces/CJK in the URL can break navigation; encode the query.
- **Expecting Sogou snippets** — Sogou extractor returns title+url only; `WebFetch` for content instead of trusting a snippet.
- **Leaving the browser open** — cleanup per CLAUDE.md.
