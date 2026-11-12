import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:insaeng/routing/routes.dart';
import 'package:insaeng/ui/home/view_models/home_cubit.dart';
import 'package:insaeng/ui/home/widgets/home_screen.dart';

/// Builds the app router. Each route provides its screen's view model,
/// resolved from [getIt].
GoRouter router(GetIt getIt) => GoRouter(
  initialLocation: Routes.home,
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<HomeCubit>(),
        child: const HomeScreen(),
      ),
    ),
  ],
);
