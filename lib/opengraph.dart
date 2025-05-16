///
/// @project  : opengraph
/// @author   : Baldomero (datogedon@gmail.com)
/// @link     : https://github.com/baldomerocho/flutter_opengraph/
/// @Disc     : a dart and flutter package to fetch and preview OpenGraph data
///
library opengraph;

// Export both the preview and fetch functionality
export 'src/fetch_opengraph.dart';
export 'opengraph_fetch.dart';
export 'src/parsers/parsers.dart';
export 'src/opengraph_fetch_functions.dart';

// Export the models
export 'src/models/open_graph_entity.dart';

// Export the widget components
export 'src/widget_opengraph.dart';
export 'src/opengraph_preview_widget.dart';
