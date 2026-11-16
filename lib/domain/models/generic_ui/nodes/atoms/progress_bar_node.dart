part of '../generic_node.dart';

@MappableClass(discriminatorValue: 'progressBar')
final class ProgressBarNode extends GenericNode with ProgressBarNodeMappable {
  const new({required super.id, required this.value, required this.max});

  @MappableField(hook: BindableHook<int>())
  final Bindable<int> value;

  @MappableField(hook: BindableHook<int>())
  final Bindable<int> max;
}
