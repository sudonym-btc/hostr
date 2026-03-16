import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/reservation/reservation_status_sections.dart';
import 'package:hostr/presentation/component/widgets/reservation/trade_header.dart';
import 'package:hostr/presentation/component/widgets/ui/status_stream_list.dart';
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

@RoutePage()
class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
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
    final layout = AppLayoutSpec.of(context);
    final content = StatusStreamListWidget(
      stream: getIt<Hostr>().userSubscriptions.myTrips$,
      sort: ReservationStatusSections.compare,
      sectionHeaderBuilder: ReservationStatusSections.buildHeader,
      emptyBuilder: () => StatusStreamListWidget.empty(
        context,
        title: AppLocalizations.of(context)!.noTripsYet,
        subtitle: 'Head over to explore some listings to get started!',
        action: FilledButton.tonal(
          onPressed: () {
            AutoRouter.of(context).navigate(const SearchRoute());
          },
          child: Text('Search'),
        ),
      ),
      builder: (item) {
        return TradeHeader(
          tradeId: item.event.tradeId,
          showActions: false,
          onTap: () => AutoRouter.of(
            context,
          ).push(ThreadRoute(anchor: item.event.tradeId)),
        );
      },
    );

    return Scaffold(
      appBar: layout.showsSidebarNavigation
          ? null
          : AppBar(title: Text(AppLocalizations.of(context)!.trips)),
      body: layout.showsSidebarNavigation
          ? AppSinglePanePage(
              maxWidth: kAppWideContentMaxWidth,
              usePanel: false,
              child: AppPanelScaffold(
                appBar: AppBar(
                  title: Text(AppLocalizations.of(context)!.trips),
                ),
                body: content,
              ),
            )
          : content,
    );
  }
}
