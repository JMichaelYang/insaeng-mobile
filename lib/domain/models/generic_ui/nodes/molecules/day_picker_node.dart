part of '../generic_node.dart';

@MappableClass(discriminatorValue: 'dayPicker')
final class DayPickerNode extends GenericNode with DayPickerNodeMappable {
  const new({
    required super.id,
    required this.label,
    required this.previousLabel,
    required this.nextLabel,
    this.onPrevious = const [],
    this.onNext = const [],
    this.labelTapHint,
    this.onLabelTap = const [],
  });

  @MappableField(hook: BindableHook<String>())
  final Bindable<String> label;

  @MappableField(hook: BindableHook<String>())
  final Bindable<String> previousLabel;

  @MappableField(hook: BindableHook<String>())
  final Bindable<String> nextLabel;

  @MappableField(hook: BindableHook<String>())
  final Bindable<String>? labelTapHint;

  final List<GenericAction> onPrevious;

  final List<GenericAction> onNext;

  final List<GenericAction> onLabelTap;

  @override
  List<GenericAction> get actions => [...onPrevious, ...onNext, ...onLabelTap];
}
