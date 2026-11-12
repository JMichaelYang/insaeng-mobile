import 'package:dart_mappable/dart_mappable.dart';

part 'home_state.mapper.dart';

@MappableClass()
class HomeState with HomeStateMappable {
  const new({this.count = 0});

  final int count;
}
