import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

typedef LayerPolicy = ({
  Set<String>? onlyLayers,
  Set<String> forbiddenLayers,
  Set<String> forbiddenPackages,
});

const Map<String, LayerPolicy> layerPolicies = {
  'domain': (
    onlyLayers: {'domain'},
    forbiddenLayers: {},
    forbiddenPackages: {'dart:ui', 'flutter', 'material_ui', 'cupertino_ui'},
  ),
  'design_system': (
    onlyLayers: {'design_system'},
    forbiddenLayers: {},
    forbiddenPackages: {'flutter_bloc', 'get_it', 'go_router'},
  ),
  'data': (
    onlyLayers: null,
    forbiddenLayers: {
      'ui',
      'design_system',
      'routing',
      'config',
      'app.dart',
      'bootstrap.dart',
      'main_dev.dart',
      'main_prod.dart',
    },
    forbiddenPackages: {},
  ),
  'ui': (
    onlyLayers: null,
    forbiddenLayers: {'data', 'config'},
    forbiddenPackages: {'go_router'},
  ),
  'utils': (
    onlyLayers: {'utils', 'l10n'},
    forbiddenLayers: {},
    forbiddenPackages: {},
  ),
};

String? violation({required Uri library, required Uri target}) {
  if (library.scheme != 'package' || library.pathSegments.length < 2) {
    return null;
  }
  final package = library.pathSegments.first;
  final policy = layerPolicies[library.pathSegments[1]];
  if (policy == null) return null;

  if (target.scheme == 'dart') {
    return policy.forbiddenPackages.contains('dart:${target.path}')
        ? 'dart:${target.path}'
        : null;
  }
  if (target.scheme != 'package' || target.pathSegments.isEmpty) return null;

  final targetPackage = target.pathSegments.first;
  if (targetPackage != package) {
    return policy.forbiddenPackages.contains(targetPackage)
        ? 'package:$targetPackage'
        : null;
  }

  if (target.pathSegments.length < 2) return null;
  final targetLayer = target.pathSegments[1];
  final allowed =
      (policy.onlyLayers?.contains(targetLayer) ?? true) &&
      !policy.forbiddenLayers.contains(targetLayer);
  return allowed ? null : targetLayer;
}

class LayerBoundaryRule extends AnalysisRule {
  new()
    : super(
        name: 'layer_boundary',
        description:
            'Enforces layer boundaries: ui and data depend on domain, never '
            'on each other, domain stays pure Dart, and design_system imports '
            'nothing else from the app.',
      );

  static const LintCode code = LintCode(
    'layer_boundary',
    "The '{0}' layer can't import '{1}'.",
    correctionMessage:
        'Depend on domain/ instead; only config/ wires implementations.',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, context);
    registry
      ..addImportDirective(this, visitor)
      ..addExportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  new(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitImportDirective(ImportDirective node) => _check(node);

  @override
  void visitExportDirective(ExportDirective node) => _check(node);

  void _check(NamespaceDirective node) {
    final library = context.libraryElement?.uri;
    final uri = node.uri.stringValue;
    if (library == null || uri == null) return;

    final target = library.resolve(uri);
    final forbidden = violation(library: library, target: target);
    if (forbidden != null) {
      rule.reportAtNode(
        node.uri,
        arguments: [library.pathSegments[1], forbidden],
      );
    }
  }
}
