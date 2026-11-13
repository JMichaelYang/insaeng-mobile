import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/divider_item.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group(DividerItem, () {
    testWidgets('renders a full-width themed divider', (tester) async {
      await tester.pumpApp(
        const Scaffold(
          body: Column(
            children: [DividerItem(node: DividerNode(id: 'divider'))],
          ),
        ),
      );

      expect(find.byType(Divider), findsOneWidget);
      expect(tester.getSize(find.byType(DividerItem)).width, tester.getSize(find.byType(Scaffold)).width);
    });
  });
}
