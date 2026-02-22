import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';

class ModeToggleWidget extends StatelessWidget {
  const ModeToggleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ModeCubit, ModeCubitState>(
      builder: (context, state) {
        return CustomPadding(
          child: Center(
            child: ToggleButtons(
              fillColor: Theme.of(context).colorScheme.primary,
              selectedBorderColor: Theme.of(context).colorScheme.primary,
              borderColor: Theme.of(context).colorScheme.primary,
              selectedColor: Theme.of(context).colorScheme.onPrimary,
              borderWidth: 1.5,
              borderRadius: BorderRadius.circular(50.0),
              isSelected: [state is HostMode, state is GuestMode],
              onPressed: (int index) {
                if (index == 0) {
                  BlocProvider.of<ModeCubit>(context).setHost();
                } else {
                  BlocProvider.of<ModeCubit>(context).setGuest();
                }
              },
              textStyle: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    AppLocalizations.of(context)!.hostMode,
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    AppLocalizations.of(context)!.guestMode,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
