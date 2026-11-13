import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/spacer_item.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group(SpacerItem, () {
    testWidgets('takes no space on its own', (tester) async {
      await tester.pumpApp(
        const Scaffold(
          body: Center(
            child: SpacerItem(node: SpacerNode(id: 'gap')),
          ),
        ),
      );

      expect(tester.getSize(find.byType(SpacerItem)), Size.zero);
    });
  });
}
