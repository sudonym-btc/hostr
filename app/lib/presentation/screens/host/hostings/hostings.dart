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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomPadding.horizontal.lg(
                child: Row(
                  children: [
                    Text(
                      'Hosting ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    FutureBuilder(
                      future: getIt<Hostr>()
                          .trade(pair.tradeId)
                          .resolveGuestPubkey(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return const Icon(Icons.error);
                        }
                        final guestPubkey = snapshot.data;
                        if (guestPubkey == null) {
                          return const SizedBox.shrink();
                        }
                        return ProfileChipWidget(id: guestPubkey);
                      },
                    ),
                  ],
                ),
              ),
              CustomPadding.only(
                left: 25,
                child: TradeHeader(
                  tradeId: pair.tradeId,
                  showActions: false,
                  onTap: () => AutoRouter.of(
                    context,
                  ).push(ThreadRoute(anchor: pair.tradeId)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
