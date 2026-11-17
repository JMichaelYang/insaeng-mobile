import 'package:insaeng/design_system/molecules/app_day_picker.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/generic_item_extensions.dart';
import 'package:material_ui/material_ui.dart';

class DayPickerItem extends StatelessWidget {
  const new({required this.node, super.key});

  final DayPickerNode node;

  @override
  Widget build(BuildContext context) {
    return AppDayPicker(
      label: context.watchBindable(node.label) ?? '',
      previousLabel: context.watchBindable(node.previousLabel) ?? '',
      nextLabel: context.watchBindable(node.nextLabel) ?? '',
      onPrevious: () => context.dispatch(node.onPrevious),
      onNext: () => context.dispatch(node.onNext),
    );
  }
}
