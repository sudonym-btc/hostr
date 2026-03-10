import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr/presentation/component/widgets/reservation/trade_header.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';

@RoutePage()
class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  late final StreamWithStatus<Validation<ReservationPairStatus>> _tripsStream;
  late final Stream<(List<Validation<ReservationPairStatus>>, StreamStatus)>
  _combined;

  @override
  void initState() {
    super.initState();
    _tripsStream = getIt<Hostr>().userSubscriptions.myTrips$;
    _combined = Rx.combineLatest2(
      _tripsStream.list,
      _tripsStream.status,
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
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.trips)),
      body:
          StreamBuilder<
            (List<Validation<ReservationPairStatus>>, StreamStatus)
          >(
            stream: _combined,
            builder: (context, snapshot) {
              final data = snapshot.data;
              if (data == null) {
                return const Center(child: AppLoadingIndicator.large());
              }

              final (validations, status) = data;
              if (status is StreamStatusIdle ||
                  status is StreamStatusQuerying) {
                return const Center(child: AppLoadingIndicator.large());
              }

              final pairs = validations
                  .whereType<Valid<ReservationPairStatus>>()
                  .map((v) => v.event)
                  .toList();

              if (pairs.isEmpty) {
                return SafeArea(
                  child: CustomPadding(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.noTripsYet,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Gap.vertical.xs(),
                        Text(
                          'Head over to explore some listings to get started!',
                        ),
                        Gap.vertical.lg(),
                        FilledButton(onPressed: () {}, child: Text('Search')),
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
                  return TradeHeader(
                    tradeId: pairs[index].tradeId,
                    showActions: false,
                    onTap: () => AutoRouter.of(
                      context,
                    ).push(ThreadRoute(anchor: pairs[index].tradeId)),
                  );
                },
              );
            },
          ),
    );
  }
}
