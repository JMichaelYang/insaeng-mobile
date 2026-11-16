import 'package:insaeng/config/dependencies.dart';
import 'package:insaeng/config/flavor.dart';
import 'package:insaeng/data/repositories/my_day_page_mapper.dart';
import 'package:insaeng/domain/use_cases/refresh_home_widget_use_case.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void widgetRefreshDispatcher() => Workmanager().executeTask(runWidgetRefreshTask);

Future<bool> runWidgetRefreshTask(String task, Map<String, dynamic>? inputData) {
  if (!getIt.isRegistered<Flavor>()) {
    configureDependencies(Flavor.values.asNameMap()[inputData?[WidgetRefreshScheduler.flavorKey]] ?? Flavor.prod);
  }
  return getIt<WidgetRefreshScheduler>().run(task);
}

class WidgetRefreshScheduler {
  new(this._workmanager, this._refresh, this._flavor, {this._now = DateTime.now});

  final Workmanager _workmanager;
  final RefreshHomeWidgetUseCase _refresh;
  final Flavor _flavor;
  final DateTime Function() _now;

  static const periodicTask = 'com.jae.insaeng.widgetRefresh.periodic';
  static const midnightTask = 'com.jae.insaeng.widgetRefresh.midnight';
  static const flavorKey = 'flavor';
  static const frequency = Duration(minutes: 15);
  static const afterMidnight = Duration(minutes: 1);

  Map<String, dynamic> get _inputData => {flavorKey: _flavor.name};

  Constraints get _constraints => Constraints(networkType: NetworkType.connected);

  Future<void> start() async {
    await _workmanager.initialize(widgetRefreshDispatcher);
    await _workmanager.registerPeriodicTask(
      periodicTask,
      periodicTask,
      frequency: frequency,
      inputData: _inputData,
      constraints: _constraints,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
    await _scheduleMidnight(ExistingWorkPolicy.replace);
  }

  Future<bool> run(String task) async {
    await _refresh(MyDayPageMapper.widgetPageId);
    if (task == periodicTask) await _scheduleMidnight(ExistingWorkPolicy.keep);
    return true;
  }

  static Duration untilAfterMidnight(DateTime now) =>
      DateTime(now.year, now.month, now.day + 1).add(afterMidnight).difference(now);

  Future<void> _scheduleMidnight(ExistingWorkPolicy policy) => _workmanager.registerOneOffTask(
    midnightTask,
    midnightTask,
    initialDelay: untilAfterMidnight(_now()),
    inputData: _inputData,
    constraints: _constraints,
    existingWorkPolicy: policy,
  );
}
