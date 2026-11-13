import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insaeng/design_system/theme/dimens.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/view_models/generic_cubit.dart';
import 'package:material_ui/material_ui.dart';

extension GenericItemContext on BuildContext {
  T? watchBindable<T extends Object>(Bindable<T> bindable) =>
      select<GenericCubit, T?>((cubit) => bindable.resolve(cubit.state.values));

  Future<void> dispatch(List<GenericAction> actions) => read<GenericCubit>().dispatch(actions);
}

extension TextStyleTokenStyle on TextStyleToken {
  TextStyle? resolve(TextTheme theme) => switch (this) {
    TextStyleToken.displayLarge => theme.displayLarge,
    TextStyleToken.displayMedium => theme.displayMedium,
    TextStyleToken.displaySmall => theme.displaySmall,
    TextStyleToken.headlineLarge => theme.headlineLarge,
    TextStyleToken.headlineMedium => theme.headlineMedium,
    TextStyleToken.headlineSmall => theme.headlineSmall,
    TextStyleToken.titleLarge => theme.titleLarge,
    TextStyleToken.titleMedium => theme.titleMedium,
    TextStyleToken.titleSmall => theme.titleSmall,
    TextStyleToken.bodyLarge => theme.bodyLarge,
    TextStyleToken.bodyMedium => theme.bodyMedium,
    TextStyleToken.bodySmall => theme.bodySmall,
    TextStyleToken.labelLarge => theme.labelLarge,
    TextStyleToken.labelMedium => theme.labelMedium,
    TextStyleToken.labelSmall => theme.labelSmall,
  };
}

extension SpacingTokenSize on SpacingToken {
  double get size => switch (this) {
    SpacingToken.none => 0,
    SpacingToken.xs => Dimens.spaceXs,
    SpacingToken.sm => Dimens.spaceSm,
    SpacingToken.md => Dimens.spaceMd,
    SpacingToken.lg => Dimens.spaceLg,
    SpacingToken.xl => Dimens.spaceXl,
  };
}

extension AlignmentTokenCrossAxis on AlignmentToken {
  CrossAxisAlignment get crossAxis => switch (this) {
    AlignmentToken.start => CrossAxisAlignment.start,
    AlignmentToken.center => CrossAxisAlignment.center,
    AlignmentToken.end => CrossAxisAlignment.end,
    AlignmentToken.stretch => CrossAxisAlignment.stretch,
  };
}

extension AlignmentTokenHorizontal on AlignmentToken {
  AlignmentGeometry? get horizontal => switch (this) {
    AlignmentToken.start => AlignmentDirectional.topStart,
    AlignmentToken.center => Alignment.topCenter,
    AlignmentToken.end => AlignmentDirectional.topEnd,
    AlignmentToken.stretch => null,
  };
}

extension GenericNodeFlex on GenericNode {
  bool expandsAlong(Axis axis) => switch (this) {
    SpacerNode() => true,
    ScrollNode() => axis == Axis.vertical,
    UnknownNode(:final fallback?) => fallback.expandsAlong(axis),
    _ => false,
  };
}
