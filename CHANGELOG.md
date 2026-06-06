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