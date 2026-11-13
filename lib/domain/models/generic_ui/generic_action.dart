import 'package:dart_mappable/dart_mappable.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';

part 'generic_action.mapper.dart';

@MappableEnum(caseStyle: CaseStyle.upperCase)
enum RequestMethod { get, post, put, patch, delete }

@MappableClass(discriminatorKey: 'type')
sealed class GenericAction with GenericActionMappable {
  const new();
}

@MappableClass(discriminatorValue: 'updateState')
final class UpdateStateAction extends GenericAction with UpdateStateActionMappable {
  const new({required this.path, this.op = const Literal(UpdateOp.set), this.value});

  final String path;

  @MappableField(hook: BindableHook<UpdateOp>())
  final Bindable<UpdateOp> op;

  @MappableField(hook: BindableHook<Object>())
  final Bindable<Object>? value;
}

@MappableClass(discriminatorValue: 'navigate')
final class NavigateAction extends GenericAction with NavigateActionMappable {
  const new({required this.screenId, this.params = const Literal({}), this.replace = const Literal(false)});

  @MappableField(hook: BindableHook<String>())
  final Bindable<String> screenId;

  @MappableField(hook: BindableHook<Map<String, String>>())
  final Bindable<Map<String, String>> params;

  @MappableField(hook: BindableHook<bool>())
  final Bindable<bool> replace;
}

@MappableClass(discriminatorValue: 'back')
final class BackAction extends GenericAction with BackActionMappable {
  const new();
}

@MappableClass(discriminatorValue: 'reload')
final class ReloadAction extends GenericAction with ReloadActionMappable {
  const new();
}

@MappableClass(discriminatorValue: 'showMessage')
final class ShowMessageAction extends GenericAction with ShowMessageActionMappable {
  const new({required this.text});

  @MappableField(hook: BindableHook<String>())
  final Bindable<String> text;
}

@MappableClass(discriminatorValue: 'request')
final class RequestAction extends GenericAction with RequestActionMappable {
  const new({required this.endpoint, this.method = const Literal(RequestMethod.post), this.body, this.loadingPath});

  @MappableField(hook: BindableHook<RequestMethod>())
  final Bindable<RequestMethod> method;

  @MappableField(hook: BindableHook<String>())
  final Bindable<String> endpoint;

  @MappableField(hook: BindableHook<Map<String, Object?>>())
  final Bindable<Map<String, Object?>>? body;

  final String? loadingPath;
}

@MappableClass(discriminatorValue: MappableClass.useAsDefault)
final class UnknownAction extends GenericAction with UnknownActionMappable {
  const new();
}
