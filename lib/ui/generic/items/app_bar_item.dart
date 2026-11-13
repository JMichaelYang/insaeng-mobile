import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/generic_item_extensions.dart';
import 'package:material_ui/material_ui.dart';

class AppBarItem extends StatelessWidget {
  const new({required this.node, super.key});

  final AppBarNode node;

  @override
  Widget build(BuildContext context) {
    final title = switch (node.title) {
      final title? => context.watchBindable(title),
      null => null,
    };
    final leading = context.watchBindable(node.leading) ?? AppBarLeading.none;
    void back() => context.dispatch(const [BackAction()]);
    return AppBar(
      automaticallyImplyLeading: false,
      title: title == null ? null : Text(title),
      leading: switch (leading) {
        AppBarLeading.none => null,
        AppBarLeading.back => BackButton(onPressed: back),
        AppBarLeading.close => CloseButton(onPressed: back),
      },
    );
  }
}
