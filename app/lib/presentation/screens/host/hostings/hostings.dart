import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr/presentation/component/widgets/reservation/trade_header.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';

@RoutePage()
class HostingsScreen extends StatefulWidget {
  const HostingsScreen({super.key});

  @override
  State<HostingsScreen> createState() => HostingsScreenState();
}

class HostingsScreenState extends State<HostingsScreen> {
  late final StreamWithStatus<Validation<ReservationPairStatus>>
  _hostingsStream;
  late final Stream<(List<Validation<ReservationPairStatus>>, StreamStatus)>
  _combined;
  late final Threads _threads;

  @override
  void initState() {
    super.initState();
    _threads = getIt<Hostr>().messaging.threads;
    _hostingsStream = getIt<Hostr>().userSubscriptions.myHostings$;
    _combined = Rx.combineLatest2(
      _hostingsStream.list,
      _hostingsStream.status,
      (data, status) => (data, status),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bookings')),
      body: StreamBuilder<(List<Validation<ReservationPairStatus>>, StreamStatus)>(
        stream: _combined,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: AppLoadingIndicator.large());
          }

          final (validations, status) = snapshot.data!;
          final pairs = validations
              .whereType<Valid<ReservationPairStatus>>()
              .map((v) => v.event)
              .toList();

          if (pairs.isEmpty) {
            if (status is! StreamStatusLive) {
              return const Center(child: AppLoadingIndicator.large());
            }
            return SafeArea(
              child: CustomPadding(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No bookings for your location yet',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Gap.vertical.xs(),
                    Text('Head over to manage your listings!'),
                    Gap.vertical.lg(),
                    FilledButton(
                      onPressed: () {},
                      child: Text('Manage Listings'),
                    ),
                  ],
                ),
              ),
            );
          }
          pairs.sort(
            (a, b) => (b.start ?? DateTime.now()).compareTo(
              a.start ?? DateTime.now(),
            ),
          );

          return ListView.separated(
            addAutomaticKeepAlives: true,
            itemCount: pairs.length,
            separatorBuilder: (_, _) => Container(),
            itemBuilder: (context, index) {
              final pair = pairs[index];
              final guestPubkey = getIt<Hostr>()
                  .trade(pair.tradeId)
                  .resolveGuestPubkey();

              print(
                'Rendering hosting for trade ${pair.tradeId} with guestPubkey $guestPubkey',
              );

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
          );
        },
      ),
    );
  }
}
