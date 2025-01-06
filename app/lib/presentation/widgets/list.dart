import 'package:auto_animated/auto_animated.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/logic/main.dart';

class ListWidget<T extends Event> extends StatefulWidget {
  final String? emptyText;
  final ListCubit<T, BaseRepository<T>> Function() list;
  final Widget Function(dynamic el) builder;
  final Widget? appendItem;

  const ListWidget(
      {this.emptyText,
      required this.list,
      required this.builder,
      this.appendItem,
      super.key});

  @override
  State<StatefulWidget> createState() => _ListWidgetState();
}

class _ListWidgetState extends State<ListWidget> with TickerProviderStateMixin {
  late ListCubit c;

  @override
  void initState() {
    super.initState();
    c = widget.list();
    c.list();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ListCubit>(
        create: (_) => c,
        child: BlocBuilder<ListCubit, ListCubitState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...(state.data.isEmpty && widget.emptyText != null)
                    ? [
                        AnimatedContainer(
                            duration: const Duration(milliseconds: 50),
                            child: Text(widget.emptyText!))
                      ]
                    : [],
                state.data.isNotEmpty
                    ? AnimatedContainer(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        duration: Duration(milliseconds: 5000),
                        child: Expanded(
                            child: LiveList(
                          showItemInterval: const Duration(milliseconds: 50),
                          showItemDuration: const Duration(milliseconds: 50),
                          shrinkWrap: true,
                          // controller: controller,
                          itemBuilder: (context, index, animation) =>
                              FadeTransition(
                                  opacity: animation,
                                  child: widget.builder(state.data[index])),
                          itemCount: state.data.length,
                        )),
                      )
                    : Container(),
                ...(widget.appendItem != null ? [widget.appendItem!] : [])
              ],
            );
          },
        ));
  }
}
