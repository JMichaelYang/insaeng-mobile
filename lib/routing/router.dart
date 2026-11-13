import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:insaeng/routing/routes.dart';
import 'package:insaeng/ui/generic/view_models/generic_cubit.dart';
import 'package:insaeng/ui/generic/widgets/generic_screen.dart';
import 'package:material_ui/material_ui.dart';

GoRouter router(GetIt getIt) {
  Widget genericScreen(String pageId, GoRouterState state) => BlocProvider(
    key: ValueKey(state.uri),
    create: (_) {
      final cubit = GenericCubit(getIt(), pageId: pageId, params: state.uri.queryParameters);
      unawaited(cubit.load());
      return cubit;
    },
    child: const GenericScreen(),
  );

  return GoRouter(
    initialLocation: Routes.home,
    routes: [
      GoRoute(path: Routes.home, builder: (context, state) => genericScreen(Routes.homePageId, state)),
      GoRoute(
        path: Routes.page,
        builder: (context, state) => genericScreen(state.pathParameters[Routes.pageIdParameter]!, state),
      ),
    ],
  );
}
