// ignore_for_file: non_constant_identifier_names

import 'package:opengraph/src/models/open_graph_entity.dart';
import 'package:opengraph/src/adapters/opengraph_metadata_adapter.dart';
import 'package:opengraph/src/opengraph_fetch_base.dart';

/// Fetch OpenGraph data from a URL and return it as an [OpenGraphEntity]
///
/// This is the main entry point for the opengraph_fetch functionality
Future<OpenGraphEntity?> opengraph_fetch(String url) async {
  final metadata = await OpengraphFetch.extract(url);
  if (metadata == null) return null;
  return OpengraphMetadataAdapter.toOpenGraphEntity(metadata);
}

/// Fetch OpenGraph data from a URL and return the raw metadata
///
/// This is provided for compatibility with the old API
Future<dynamic> opengraph_fetch_raw(String url) async {
  return await OpengraphFetch.extract(url);
}
