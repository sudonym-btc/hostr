import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

import 'relay_list_item.dart';

class RelayListWidget extends StatefulWidget {
  const RelayListWidget({super.key});

  @override
  RelayListWidgetState createState() => RelayListWidgetState();
}

class RelayListWidgetState extends State<RelayListWidget> {
  @override
  Widget build(BuildContext context) {
    final hostr = getIt<Hostr>();
    final bootstrapRelays = hostr.config.bootstrapRelays;

    return Column(
      children: [
        Gap.vertical.md(),
        FutureBuilder<List<String>>(
          future: hostr.relays.relayStorage.get(),
          builder: (context, storedSnapshot) {
            final storedRelays = storedSnapshot.data ?? [];

            return StreamBuilder(
              stream: hostr.relays.connectivity(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return CustomPadding.md(
                    child: Text(
                      AppLocalizations.of(
                        context,
                      )!.errorWithDetails(snapshot.error.toString()),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const SizedBox();
                }

                // Deduplicate by URL
                final seen = <String>{};
                final deduplicated = snapshot.data!.values.where((c) {
                  return seen.add(c.url);
                }).toList();

                return Column(
                  children: deduplicated.map((connectivity) {
                    final url = connectivity.url;
                    final isBootstrap = bootstrapRelays.contains(url);
                    final isStored = storedRelays.contains(url);
                    final canRemove = isStored && !isBootstrap;

                    return RelayListItemWidget(
                      relay: connectivity.relayInfo,
                      connectivity: connectivity,
                      canRemove: canRemove,
                    );
                  }).toList(),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
