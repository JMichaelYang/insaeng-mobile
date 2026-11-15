import 'package:dart_mappable/dart_mappable.dart';

part 'generic_effect.mapper.dart';

@MappableClass()
sealed class GenericEffect with GenericEffectMappable {
  const new();
}

@MappableClass()
final class NavigateEffect extends GenericEffect with NavigateEffectMappable {
  const new({required this.pageId, this.params = const {}, this.replace = false});

  final String pageId;
  final Map<String, String> params;
  final bool replace;
}

@MappableClass()
final class BackEffect extends GenericEffect with BackEffectMappable {
  const new();
}

@MappableClass()
final class ShowMessageEffect extends GenericEffect with ShowMessageEffectMappable {
  const new({required this.text});

  final String text;
}
