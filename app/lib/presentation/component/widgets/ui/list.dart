import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:ndk/ndk.dart';

class ListWidget<T extends Nip01Event> extends StatefulWidget {
  final Widget Function(dynamic) builder;
  final bool loadNextOnBottom;
  final double loadNextThreshold;
  final bool reserveBottomNavigationBarSpace;

  const ListWidget({
    super.key,
    required this.builder,
    this.loadNextOnBottom = false,
    this.loadNextThreshold = 200,
    this.reserveBottomNavigationBarSpace = false,
  });

  @override
  ListWidgetState createState() => ListWidgetState<T>();
}

class ListWidgetState<T extends Nip01Event> extends State<ListWidget<T>> {
  final ScrollController _scrollController = ScrollController();
  final CustomLogger logger = CustomLogger();
  bool _loadingNextPage = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (widget.loadNextOnBottom &&
        _scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent -
                widget.loadNextThreshold) {
      _loadNext();
    }

    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      // logger.d('Scrolling up');
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      // logger.d('Scrolling down');
    }
  }

  Future<void> _loadNext() async {
    if (_loadingNextPage || !mounted) return;

    final cubit = context.read<ListCubit<T>>();
    final state = cubit.state;
    if (state.fetching || state.synching || state.hasMore == false) {
      return;
    }

    _loadingNextPage = true;
    try {
      await cubit.next();
    } finally {
      _loadingNextPage = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ListCubit<T>, ListCubitState>(
      builder: (context, state) {
        // Only show centered loading if we have no results yet
        if ((state.synching || state.fetching) && state.results.isEmpty) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        if (state.results.isEmpty) {
          return const Center(child: Text('No items'));
        }

        final isLoading = state.synching || state.fetching;
        final itemCount = state.results.length + (isLoading ? 1 : 0);
        final bottomInset = widget.reserveBottomNavigationBarSpace
            ? MediaQuery.paddingOf(context).bottom + kBottomNavigationBarHeight
            : 0.0;

        return ListView.builder(
          padding: EdgeInsets.only(
            bottom: kDefaultPadding.toDouble() + bottomInset,
          ),
          controller: _scrollController,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            // Show loading indicator at the bottom
            if (index == state.results.length) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator.adaptive()),
              );
            }

            return KeyedSubtree(
              key: ValueKey(
                state.results[index].id,
              ), // Ensure each item has a unique key
              child: widget.builder(state.results[index]),
            );
          },
        );
      },
    );
  }
}
