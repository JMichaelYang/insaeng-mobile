import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insaeng/design_system/theme/dimens.dart';
import 'package:insaeng/ui/home/view_models/home_cubit.dart';
import 'package:insaeng/utils/context_extensions.dart';
import 'package:material_ui/material_ui.dart';

class HomeScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.strings.homeTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Dimens.spaceMd),
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) =>
                Text('${state.count}', style: context.textTheme.displayMedium),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: context.read<HomeCubit>().increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
