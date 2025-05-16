import 'package:opengraph/src/models/open_graph_entity.dart';
import 'package:opengraph/src/parsers/base_parser.dart';

/// Adapter to convert between OpengraphMetadata and OpenGraphEntity
class OpengraphMetadataAdapter {
  /// Convert OpengraphMetadata to OpenGraphEntity
  static OpenGraphEntity toOpenGraphEntity(OpengraphMetadata metadata) {
    return OpenGraphEntity(
      title: metadata.title ?? '',
      description: metadata.description ?? '',
      image: metadata.image ?? '',
      url: metadata.url ?? '',
      locale: metadata.locale ?? 'en_US',
      type: metadata.type ?? 'website',
      siteName: metadata.siteName ?? '',
    );
  }

  /// Convert OpenGraphEntity to OpengraphMetadata
  static OpengraphMetadata fromOpenGraphEntity(OpenGraphEntity entity) {
    final metadata = OpengraphMetadata();
    metadata.title = entity.title;
    metadata.description = entity.description;
    metadata.image = entity.image;
    metadata.url = entity.url;
    metadata.locale = entity.locale;
    metadata.type = entity.type;
    metadata.siteName = entity.siteName;
    return metadata;
  }
}
