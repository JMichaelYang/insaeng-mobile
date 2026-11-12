import 'package:layer_lint/src/layer_boundary_rule.dart';
import 'package:test/test.dart';

String? check(String library, String import) {
  final lib = Uri.parse(library);
  return violation(library: lib, target: lib.resolve(import));
}

void main() {
  const domain = 'package:app/domain/result.dart';
  const ui = 'package:app/ui/home/widgets/home_screen.dart';
  const data = 'package:app/data/repositories/entry/entry_repository_remote.dart';
  const utils = 'package:app/utils/context_extensions.dart';
  const config = 'package:app/config/dependencies.dart';

  test('domain imports only domain and pure Dart', () {
    expect(check(domain, 'package:app/domain/failure.dart'), isNull);
    expect(check(domain, 'failure.dart'), isNull);
    expect(check(domain, 'package:meta/meta.dart'), isNull);
    expect(check(domain, 'dart:async'), isNull);
    expect(check(domain, 'package:app/data/x.dart'), 'data');
    expect(check(domain, 'package:app/utils/x.dart'), 'utils');
    expect(check(domain, 'package:app/app.dart'), 'app.dart');
    expect(check(domain, 'package:flutter/foundation.dart'), 'package:flutter');
    expect(check(domain, 'package:material_ui/material_ui.dart'), 'package:material_ui');
    expect(check(domain, 'dart:ui'), 'dart:ui');
  });

  test('ui never imports data, config, or go_router', () {
    expect(check(ui, 'package:app/domain/result.dart'), isNull);
    expect(check(ui, 'package:flutter_bloc/flutter_bloc.dart'), isNull);
    expect(check(ui, 'package:app/utils/navigation_extensions.dart'), isNull);
    expect(check(ui, 'package:app/data/x.dart'), 'data');
    expect(check(ui, '../../../data/x.dart'), 'data');
    expect(check(ui, 'package:app/config/dependencies.dart'), 'config');
    expect(check(ui, 'package:go_router/go_router.dart'), 'package:go_router');
  });

  test('design_system imports only itself and outside packages', () {
    const ds = 'package:app/design_system/atoms/app_button.dart';
    expect(check(ds, 'package:app/design_system/theme/dimens.dart'), isNull);
    expect(check(ds, '../theme/dimens.dart'), isNull);
    expect(check(ds, 'package:material_ui/material_ui.dart'), isNull);
    expect(check(ds, 'package:app/ui/home/x.dart'), 'ui');
    expect(check(ds, 'package:app/domain/result.dart'), 'domain');
    expect(check(ds, 'package:app/l10n/l10n.dart'), 'l10n');
    expect(check(ds, 'package:app/utils/context_extensions.dart'), 'utils');
    expect(check(ds, 'package:app/routing/routes.dart'), 'routing');
    expect(check(ds, 'package:flutter_bloc/flutter_bloc.dart'), 'package:flutter_bloc');
    expect(check(ds, 'package:get_it/get_it.dart'), 'package:get_it');
    expect(check(ds, 'package:go_router/go_router.dart'), 'package:go_router');
  });

  test('only ui and app.dart use design_system', () {
    const routing = 'package:app/routing/router.dart';
    const theme = 'package:app/design_system/theme/theme.dart';
    expect(check(ui, theme), isNull);
    expect(check('package:app/app.dart', theme), isNull);
    expect(check(data, theme), 'design_system');
    expect(check(domain, theme), 'design_system');
    expect(check(utils, theme), 'design_system');
    expect(check(config, theme), 'design_system');
    expect(check(routing, theme), 'design_system');
    expect(check('package:app/bootstrap.dart', theme), 'design_system');
    expect(check('package:app/main_dev.dart', theme), 'design_system');
    expect(check('package:app/main_prod.dart', theme), 'design_system');
  });

  test('config and routing may import every other layer', () {
    const routing = 'package:app/routing/router.dart';
    expect(check(config, 'package:app/data/x.dart'), isNull);
    expect(check(config, 'package:app/routing/router.dart'), isNull);
    expect(check(routing, 'package:app/ui/home/x.dart'), isNull);
    expect(check(routing, 'package:go_router/go_router.dart'), isNull);
  });

  test('data never imports ui, routing, or config', () {
    expect(check(data, 'package:app/domain/result.dart'), isNull);
    expect(check(data, 'package:app/ui/x.dart'), 'ui');
    expect(check(data, 'package:app/routing/router.dart'), 'routing');
    expect(check(data, 'package:app/config/dependencies.dart'), 'config');
  });

  test('utils imports only utils, l10n, and packages', () {
    expect(check(utils, 'package:app/utils/x.dart'), isNull);
    expect(check(utils, 'package:app/l10n/l10n.dart'), isNull);
    expect(check(utils, 'package:go_router/go_router.dart'), isNull);
    expect(check(utils, 'package:app/domain/result.dart'), 'domain');
    expect(check(utils, 'package:app/ui/x.dart'), 'ui');
    expect(check(utils, 'package:app/data/x.dart'), 'data');
    expect(check(utils, 'package:app/app.dart'), 'app.dart');
  });

  test('unrestricted locations are ignored', () {
    expect(check('package:app/app.dart', 'package:app/ui/x.dart'), isNull);
    expect(check('file:///app/test/x_test.dart', '../lib/data/x.dart'), isNull);
  });
}
