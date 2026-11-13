import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

extension NavigationExtensions on BuildContext {
  void goTo(String location) => GoRouter.of(this).go(location);

  Future<T?> pushTo<T extends Object?>(String location) => GoRouter.of(this).push<T>(location);

  Future<T?> replaceWith<T extends Object?>(String location) => GoRouter.of(this).pushReplacement<T>(location);

  bool get canGoBack => GoRouter.of(this).canPop();

  void back<T extends Object?>([T? result]) => GoRouter.of(this).pop<T>(result);
}
