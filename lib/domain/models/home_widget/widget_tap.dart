import 'package:dart_mappable/dart_mappable.dart';

part 'widget_tap.mapper.dart';

@MappableClass(discriminatorKey: 'type')
sealed class WidgetTap with WidgetTapMappable {
  const new();
}

@MappableClass(discriminatorValue: 'openApp')
final class OpenAppTap extends WidgetTap with OpenAppTapMappable {
  const new();
}

@MappableClass(discriminatorValue: 'event')
final class EventTap extends WidgetTap with EventTapMappable {
  const new({required this.nodeId, required this.event});

  final String nodeId;

  final String event;
}
