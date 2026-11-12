import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insaeng/l10n/l10n.dart';
import 'package:insaeng/ui/core/theme/dimens.dart';
import 'package:insaeng/ui/home/view_models/home_cubit.dart';
import 'package:material_ui/material_ui.dart';

class HomeScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Dimens.spaceMd),
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) => Text(
              '${state.count}',
              style: Theme.of(context).textTheme.displayMedium,
            ),
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
