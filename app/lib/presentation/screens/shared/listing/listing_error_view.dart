import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/export.dart';
import 'package:models/main.dart';

/// Error state scaffold shown when the listing fails to load.
class ListingErrorView extends StatelessWidget {
  final Object? error;

  const ListingErrorView({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: CustomPadding.horizontal.lg(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: kIconHero,
                color: Theme.of(context).colorScheme.error,
              ),
              Gap.vertical.md(),
              Text(
                '$error',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Gap.vertical.custom(kSpace5),
              FilledButton.icon(
                onPressed: () =>
                    context.read<EntityCubit<Listing>>().get(),
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context)!.retryButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
