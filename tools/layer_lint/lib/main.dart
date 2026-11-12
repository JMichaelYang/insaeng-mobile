import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:layer_lint/src/layer_boundary_rule.dart';

final plugin = LayerLintPlugin();

class LayerLintPlugin extends Plugin {
  @override
  String get name => 'layer_lint';

  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(LayerBoundaryRule());
  }
}
