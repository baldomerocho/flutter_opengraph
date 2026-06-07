## 1.5.0 (2026-06-06)
* **Persistent cache**: new pluggable `OpengraphCache.store` (`OpengraphCacheStore` interface: read/write/delete/clear + serializable `OpengraphCacheEntry`), so previews survive app restarts. Memory stays the source of truth: fetches write through fire-and-forget, memory misses are answered from the store (validated against TTL/`maxAge`) before hitting the network, stale persisted entries are deleted, and store errors are swallowed — a broken store never breaks fetching. No storage dependency is imposed: bring your own backend (shared_preferences/hive/file; README includes a copy-paste implementation)
* Store reads are bounded by `OpengraphCache.storeTimeout` (default 5s): a hanging store falls through to the network instead of freezing the fetch
* A late store read never overwrites a fresher entry that landed in memory while it was in flight; corrupt persisted JSON decodes to a stale entry and gets dropped instead of throwing
* `OpengraphCache.clear(memoryOnly: true)` frees memory without wiping the persisted entries
* **Per-call timeout**: `opengraph_fetch(url, timeout: ...)` / `OpengraphFetch.extract(url, timeout: ...)` override the global `OpengraphFetch.timeout` for a single request
* Test coverage: 99.9% (208 tests)

## 1.4.0 (2026-06-06)
* **Rich OpenGraph model**: `OpenGraphEntity` now exposes every structured object — `images` (`List<OgImage>` with width/height/alt/secureUrl/type), `videos` (`List<OgVideo>`), `audios` (`List<OgAudio>`) and `structuredTags` (`article:*`, `book:*`, `profile:*`, `music:*`, `video:*` accumulated in document order). `images.first` always carries the preview image
* **Favicon fallback**: `<link rel="icon">`/`apple-touch-icon` is parsed (`FaviconParser`), exposed as `entity.faviconUrl` and used as the last-resort image when no metadata format provides one
* **JSON-LD `@graph`**: the parser now reads every `application/ld+json` script (head and body), traverses `@graph` containers and prefers Article/Product/WebSite-like nodes; invalid scripts are skipped
* **CORS proxy for Flutter Web**: `OpengraphFetch.proxyUrl` routes requests through a proxy (`{url}` template or plain prefix); relative images keep resolving against the target site
* **Widget customization**: `titleStyle`/`descriptionStyle`/`hostStyle` (merged over the defaults), `titleMaxLines`/`descriptionMaxLines`, `overlayColor`, `imageFit`, `onTap` and a new `layout: OpenGraphLayout.horizontal` variant (side image + texts)
* **Lazy loading**: `lazyLoad: true` defers the fetch until the preview enters the viewport (`visibilityThreshold` configurable) — long lists no longer fire every request at once
* Test coverage: 99.9% (178 tests)

## 1.3.0 (2026-06-06)
* **URL normalization**: scheme-less URLs (`www.example.com`, `example.com/page`) are now prepended with `https://` and fetched, instead of always failing with "No host specified" (`normalizeUrl`)
* **Charset detection**: response bodies are decoded from the charset declared in the Content-Type header or `<meta charset>` (latin1, ISO-8859-1, windows-1252…) instead of always assuming UTF-8; malformed bytes no longer lose the page
* **Controlled redirects**: redirects (301/302/303/307/308) are followed manually with a configurable limit (`OpengraphFetch.maxRedirects`, default 7), and relative images are now resolved against the **final** URL after redirects — fixes broken images behind link shorteners. On the web (where the browser follows redirects itself) the final URL is picked up from the response when the platform exposes it. Sensitive headers (Authorization, Cookie) are dropped on cross-origin hops
* **Cache TTL**: cached entries now expire (`OpengraphCache.ttl`, default 24h; set to null for session-long entries) and `opengraph_fetch` accepts a per-call `maxAge` override (e.g. `Duration.zero` to force a refetch)
* `OpengraphCache.get/put/evict` normalize their keys, so `evict("www.example.com")` and `evict("https://www.example.com")` address the same entry
* **Per-call headers**: `opengraph_fetch(url, headers: {...})` and `OpengraphFetch.extract(url, headers: {...})` merge custom headers over `requestHeaders` for a single request (auth, Accept-Language…)
* `OpengraphFetch.clientFactory` is injectable for testing (e.g. with `MockClient`)
* Legacy `OpenGraphRequest.fetch` now sends the configured request headers (it previously sent none, so sites that block the default Dart user agent returned errors), decodes non-UTF-8 charsets, and correctly caches pages without a description
* **Deprecated**: `OpenGraphRequest`, `OpenGraphRequestInterface` and `OpenGraphConfiguration` — use `opengraph_fetch` / `OpengraphCache`; removal planned for 2.0.0
* Fixed an unhandled-error report when a fetch failed before `FutureBuilder` subscribed (e.g. retry with an instantly-failing connection)
* Inputs with explicit non-web schemes (`mailto:`, `tel:`, `data:`…) are rejected instead of being fetched as bogus https URLs
* Requires `http: ^1.2.0`
* Test coverage: 99.8% (134 tests)

## 1.2.0 (2026-06-06)
* **Web support**: migrated the legacy `OpenGraphRequest` from `dart:io` to `package:http` — the package now supports all 6 platforms (Android, iOS, Web, Windows, macOS, Linux)
* `OpenGraphRequest.client` is now injectable for testing (e.g. with `MockClient` from `package:http/testing.dart`)
* Test coverage raised from 90.3% to 99.6% (98 tests)
* pub.dev score: fixed all static analysis findings, shortened package description, added topics and screenshots metadata (160/160 pana points)
* README: badges, simplified setup docs (no initialization required), updated best practices
* Example app: new "Options" tab showcasing `hideOnError`, `childError`, `showReloadButton`, `fallbackImage`, `enableBlur` and list usage
* Removed dead code (`SalveObjects`)

## 1.1.0 (2026-06-06)
* Added in-memory cache (`OpengraphCache`) for `opengraph_fetch`: repeated calls for the same URL no longer refetch, and concurrent requests are deduplicated (#1)
* `OpengraphPreview` memoizes its fetch: rebuilds inside scrollable lists no longer trigger new network requests (#1)
* Support `data:` URI images (base64) rendered with `Image.memory`; broken image URLs now fall back gracefully instead of crashing (#3)
* New `hideOnError` option to render nothing when the fetch fails (#2)
* `childError`, `childPreview`, `showReloadButton` and `refresh` are now functional: custom error widget, custom loading widget and a retry button that invalidates the cache (#2)
* New `fallbackImage` option to replace the default image when there is no og:image (#2)
* New `enableBlur` option to disable the expensive `BackdropFilter` in long lists (#2)
* Network images are decoded at display size (`cacheWidth`) to reduce jank while scrolling (#2)
* Configurable request timeout (`OpengraphFetch.timeout`, default 10s) and request headers/User-Agent (`OpengraphFetch.requestHeaders`)

## 1.0.0 (2025-05-15)
* Migrated code from old structure while maintaining compatibility
* Added new `OpengraphPreview` widget to replace `OpenGraphPreview`
* Added `opengraph_fetch` function for direct metadata extraction
* Created adapter between old and new metadata structures
* Updated documentation and examples

## 0.0.1 (2021-07-01)

* First release

## 0.0.004 (2024-03-09)

* Fixed a bug in the `foo` function

## 0.0.6 (2024-03-09)

* Published to pub.dev

## 0.0.7 (2024-03-09)

* Published to pub.dev with the correct version
* Fixed expose the library

## 0.0.9 (2024-03-09)

* Published to pub.dev with the correct version
* Fixed expose the library

## 0.0.10 (2024-03-09)

* Add Documentation and example

## 0.0.11 (2024-03-09)

* Add Documentation api

## 0.0.12 (2024-03-11)

* Update Documentation api

## 0.0.13 (2024-03-11)

* Update Documentation api

## 0.0.14 (2024-03-11)

* Update Documentation api

## 0.0.15 (2024-03-11)

* Add Screenshots example

## 0.1.0 (2024-03-29)
* Add http dependency, and remove http request to server