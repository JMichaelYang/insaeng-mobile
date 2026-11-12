import 'package:go_router/go_router.dart';
import 'package:insaeng/l10n/l10n.dart';
import 'package:insaeng/ui/core/theme/theme.dart';
import 'package:insaeng/utils/context_extensions.dart';
import 'package:material_ui/material_ui.dart';

class App extends StatelessWidget {
  const new({required this.router, super.key});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => context.strings.homeTitle,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      localizationsDelegates: localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
