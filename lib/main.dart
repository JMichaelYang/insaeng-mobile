import 'package:go_router/go_router.dart';
import 'package:insaeng/app.dart';
import 'package:insaeng/bootstrap.dart';
import 'package:insaeng/config/dependencies.dart';

Future<void> main() => bootstrap(() => App(router: getIt<GoRouter>()));
