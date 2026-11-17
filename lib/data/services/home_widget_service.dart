import 'package:home_widget/home_widget.dart';

class HomeWidgetService {
  const new();

  static const androidReceiver = 'com.jae.insaeng.GenericWidgetReceiver';

  Future<bool?> save(String key, String? value) => HomeWidget.saveWidgetData<String>(key, value);

  Future<String?> read(String key) => HomeWidget.getWidgetData<String>(key);

  Future<bool?> update() => HomeWidget.updateWidget(qualifiedAndroidName: androidReceiver);
}
