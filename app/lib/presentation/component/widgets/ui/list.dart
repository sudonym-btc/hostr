import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/core/util/main.dart';
import 'package:hostr/logic/main.dart';
import 'package:models/main.dart';

class ListWidget<T extends Event> extends StatefulWidget {
  final Widget Function(dynamic) builder;
  const ListWidget({super.key, required this.builder});

  @override
  ListWidgetState createState() => ListWidgetState<T>();
}

class ListWidgetState<T extends Event> extends State<ListWidget<T>> {
  final ScrollController _scrollController = ScrollController();
  final CustomLogger logger = CustomLogger();

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
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      logger.d('Scrolling up');
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      logger.d('Scrolling down');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ListCubit<T>, ListCubitState>(
      builder: (context, state) {
        return ListView.builder(
            padding: EdgeInsets.only(bottom: DEFAULT_PADDING.toDouble()),
            controller: _scrollController,
            itemCount: state.results.length,
            itemBuilder: (context, index) {
              return KeyedSubtree(
                key: ValueKey(state.results[index].nip01Event
                    .id), // Ensure each item has a unique key
                child: widget.builder(state.results[index]),
              );
            });
      },
    );
  }
}
