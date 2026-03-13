import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr/presentation/component/widgets/reservation/reservation_status_sections.dart';
import 'package:hostr/presentation/component/widgets/reservation/trade_header.dart';
import 'package:hostr/presentation/component/widgets/ui/status_stream_list.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

@RoutePage()
class HostingsScreen extends StatefulWidget {
  const HostingsScreen({super.key});

  @override
  State<HostingsScreen> createState() => HostingsScreenState();
}

class HostingsScreenState extends State<HostingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bookings')),
      body: StatusStreamListWidget(
        stream: getIt<Hostr>().userSubscriptions.myHostings$,
        sort: ReservationStatusSections.compare,
        sectionHeaderBuilder: ReservationStatusSections.buildHeader,
        emptyBuilder: () => StatusStreamListWidget.empty(
          context,
          title: 'No bookings yet',
          subtitle: 'Head over to manage your listings!',
          action: FilledButton.tonal(
            onPressed: () {
              AutoRouter.of(context).navigate(const MyListingsRoute());
            },
            child: Text('Manage Listings'),
          ),
        ),
        builder: (item) {
          final pair = item.event;

          return CustomPadding.horizontal.lg(
            child: CustomPadding.vertical.md(
              child: FutureBuilder<String?>(
                future: getIt<Hostr>().trade(pair.tradeId).resolveGuestPubkey(),
                builder: (context, snapshot) {
                  final guestPubkey = snapshot.data;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          switch (snapshot.connectionState) {
                            ConnectionState.waiting => const Align(
                              alignment: Alignment.centerLeft,
                              child: AppLoadingIndicator.small(),
                            ),
                            _ when snapshot.hasError => const Align(
                              alignment: Alignment.centerLeft,
                              child: Icon(Icons.error_outline, size: 18),
                            ),
                            _ when guestPubkey == null =>
                              const SizedBox.shrink(),
                            _ => ProfileProvider(
                              pubkey: guestPubkey,
                              builder: (context, profileSnapshot) {
                                final guestName =
                                    profileSnapshot.data?.metadata.getName() ??
                                    guestPubkey.substring(0, 8);
                                return Text(
                                  guestName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                );
                              },
                            ),
                          },

                          Text(
                            ' hosted at ',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                      Gap.vertical.md(),
                      SizedBox(
                        width: double.infinity,
                        child: TradeHeader(
                          tradeId: pair.tradeId,
                          showActions: false,
                          showImages: true,
                          compact: true,
                          onTap: () => AutoRouter.of(
                            context,
                          ).push(ThreadRoute(anchor: pair.tradeId)),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
