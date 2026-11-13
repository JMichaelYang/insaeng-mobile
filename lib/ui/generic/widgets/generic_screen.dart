import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insaeng/design_system/atoms/app_button.dart';
import 'package:insaeng/design_system/theme/dimens.dart';
import 'package:insaeng/routing/routes.dart';
import 'package:insaeng/ui/generic/items/node_view.dart';
import 'package:insaeng/ui/generic/view_models/generic_cubit.dart';
import 'package:insaeng/utils/context_extensions.dart';
import 'package:insaeng/utils/navigation_extensions.dart';
import 'package:material_ui/material_ui.dart';

class GenericScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return _GenericEffectListener(
      child: Scaffold(
        body: BlocBuilder<GenericCubit, GenericState>(
          buildWhen: (previous, current) => previous.status != current.status || previous.page != current.page,
          builder: (context, state) => switch (state) {
            GenericState(status: GenericStatus.failure) => const _GenericError(),
            GenericState(:final page?) => NodeView(node: page.root),
            GenericState() => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }
}

class _GenericError extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimens.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: Dimens.spaceMd,
          children: [
            Text(context.strings.genericPageError, textAlign: TextAlign.center),
            AppButton(label: context.strings.retry, onPressed: context.read<GenericCubit>().retry),
          ],
        ),
      ),
    );
  }
}

class _GenericEffectListener extends StatefulWidget {
  const new({required this.child});

  final Widget child;

  @override
  State<_GenericEffectListener> createState() => _GenericEffectListenerState();
}

class _GenericEffectListenerState extends State<_GenericEffectListener> {
  late final StreamSubscription<GenericEffect> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = context.read<GenericCubit>().effects.listen(_handle);
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }

  void _handle(GenericEffect effect) {
    if (!mounted) return;
    switch (effect) {
      case NavigateEffect(:final pageId, :final params, replace: true):
        unawaited(context.replaceWith(Routes.pageLocation(pageId, params)));
      case NavigateEffect(:final pageId, :final params):
        unawaited(context.pushTo(Routes.pageLocation(pageId, params)));
      case BackEffect():
        if (context.canGoBack) context.back();
      case ShowMessageEffect(:final text):
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
