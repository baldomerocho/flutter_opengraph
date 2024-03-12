import 'package:opengraph/entities/open_graph_entity.dart';

/// SalveObjects class
/// This class is a helper to create a default OpenGraphEntity object
/// with the title "Not results" and empty description, image, url, locale, type and siteName
class SalveObjects {
  static OpenGraphEntity notResults = OpenGraphEntity(
      title: "Not results",
      description: "",
      image: "",
      url: "",
      locale: 'en_US',
      type: 'website',
      siteName: 'Not results');
}
