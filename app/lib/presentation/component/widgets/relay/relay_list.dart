import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:ndk/entities.dart';
import 'package:rxdart/rxdart.dart';

import 'relay_list_item.dart';

class RelayListWidget extends StatefulWidget {
  const RelayListWidget({super.key});

  @override
  RelayListWidgetState createState() => RelayListWidgetState();
}

class RelayListWidgetState extends State<RelayListWidget> {
  late final Future<List<String>> _storedRelaysFuture;
  late final Stream<Map<String, RelayConnectivity>> _connectivity$;

  @override
  void initState() {
    super.initState();
    final hostr = getIt<Hostr>();
    _storedRelaysFuture = hostr.relays.relayStorage.get();

    // NDK fires relayConnectivityChanges on every relay event (connect,
    // disconnect, EOSE, request close, …). Debounce so the widget tree
    // rebuilds at most once per 500 ms instead of every few milliseconds.
    _connectivity$ = hostr.relays.connectivity().debounceTime(
      const Duration(milliseconds: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bootstrapRelays = getIt<Hostr>().config.bootstrapRelays;

    return Column(
      children: [
        FutureBuilder<List<String>>(
          future: _storedRelaysFuture,
          builder: (context, storedSnapshot) {
            final storedRelays = storedSnapshot.data ?? [];

            return StreamBuilder(
              stream: _connectivity$,
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
