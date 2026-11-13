import 'package:dart_mappable/dart_mappable.dart';
import 'package:insaeng/domain/models/sdui/bindable.dart';
import 'package:insaeng/domain/models/sdui/screen_values.dart';

part 'layout_action.mapper.dart';

@MappableEnum(caseStyle: CaseStyle.upperCase)
enum RequestMethod { get, post, put, patch, delete }

@MappableClass(discriminatorKey: 'type')
sealed class LayoutAction with LayoutActionMappable {
  const new();
}

@MappableClass(discriminatorValue: 'updateState')
final class UpdateStateAction extends LayoutAction with UpdateStateActionMappable {
  const new({required this.path, this.op = const Literal(UpdateOp.set), this.value});

  final String path;

  @MappableField(hook: BindableHook<UpdateOp>())
  final Bindable<UpdateOp> op;

  @MappableField(hook: BindableHook<Object>())
  final Bindable<Object>? value;
}

@MappableClass(discriminatorValue: 'navigate')
final class NavigateAction extends LayoutAction with NavigateActionMappable {
  const new({required this.screenId, this.params = const Literal({}), this.replace = const Literal(false)});

  @MappableField(hook: BindableHook<String>())
  final Bindable<String> screenId;

  @MappableField(hook: BindableHook<Map<String, String>>())
  final Bindable<Map<String, String>> params;

  @MappableField(hook: BindableHook<bool>())
  final Bindable<bool> replace;
}

@MappableClass(discriminatorValue: 'back')
final class BackAction extends LayoutAction with BackActionMappable {
  const new();
}

@MappableClass(discriminatorValue: 'reload')
final class ReloadAction extends LayoutAction with ReloadActionMappable {
  const new();
}

@MappableClass(discriminatorValue: 'showMessage')
final class ShowMessageAction extends LayoutAction with ShowMessageActionMappable {
  const new({required this.text});

  @MappableField(hook: BindableHook<String>())
  final Bindable<String> text;
}

@MappableClass(discriminatorValue: 'request')
final class RequestAction extends LayoutAction with RequestActionMappable {
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
final class UnknownAction extends LayoutAction with UnknownActionMappable {
  const new();
}
