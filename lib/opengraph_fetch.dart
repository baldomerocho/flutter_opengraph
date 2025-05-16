/// This library provides metadata parsers and utility functions for retrieving and parsing documents from a URL.
///
/// [OpengraphParser] and [HtmlMetaParser] are metadata parsers that take in a [dom.Document]
/// Utility functions [opengraph_fetch] and [opengraph_fetch_raw] help retrieving and decoding documents.
library opengraph_fetch;

export 'src/opengraph_fetch_base.dart';
export 'src/parsers/parsers.dart';
export 'src/adapters/opengraph_metadata_adapter.dart';
export 'src/opengraph_fetch_functions.dart';
