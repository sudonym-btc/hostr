import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';

class ModeToggleWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ModeCubit, ModeCubitState>(builder: (context, state) {
      return CustomPadding(
        child: Center(
          child: ToggleButtons(
            fillColor: Theme.of(context).canvasColor,
            borderRadius: BorderRadius.circular(50.0),
            isSelected: [state is HostMode, state is GuestMode],
            onPressed: (int index) {
              if (index == 0) {
                BlocProvider.of<ModeCubit>(context).setHost();
              } else {
                BlocProvider.of<ModeCubit>(context).setGuest();
              }
            },
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(AppLocalizations.of(context)!.hostMode,
                    textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(AppLocalizations.of(context)!.guestMode,
                    textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      );
    });
  }
}
