import 'package:dart_mappable/dart_mappable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_page.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/result.dart';

part 'generic_state.mapper.dart';

@MappableEnum()
enum GenericStatus { loading, success, failure }

@MappableClass()
class GenericState with GenericStateMappable {
  const new({this.status = GenericStatus.loading, this.page, this.values = GenericValues.empty, this.failure});

  final GenericStatus status;
  final GenericPage? page;

  @MappableField(hook: GenericValuesHook())
  final GenericValues values;

  final Failure? failure;
}
