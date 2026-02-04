import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/logic/main.dart';

class SearchBoxWidget extends StatelessWidget {
  const SearchBoxWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2.0, // Set the elevation
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(50), // Perfectly round border radius
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          50,
        ), // Perfectly round border radius
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // Blur effect
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor.withAlpha(
                50,
              ), // Semi-transparent background
              borderRadius: BorderRadius.circular(
                50,
              ), // Perfectly round border radius
            ),
            child: ListTile(
              leading: Icon(Icons.search),
              title: Text(
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
                AppLocalizations.of(context)!.where,
              ),
              subtitle: BlocBuilder<DateRangeCubit, DateRangeState>(
                builder: (context, state) => state.dateRange == null
                    ? Text(AppLocalizations.of(context)!.when)
                    : Text(
                        formatDateRangeShort(
                          state.dateRange!,
                          Localizations.localeOf(context),
                        ),
                      ),
              ),
              trailing: Icon(Icons.filter_list),
            ),
          ),
        ),
      ),
    );
  }
}
