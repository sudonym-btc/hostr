import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';

enum _ThreadReplyStatus { initial, loading, success, error }

class ThreadReplyView extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final String? errorText;
  final String sendLabel;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  const ThreadReplyView({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.errorText,
    required this.sendLabel,
    required this.onChanged,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = controller.text.trim().isEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            onChanged: onChanged,
            controller: controller,
            maxLines: 3,
            minLines: 1,
            autofocus: true,
            decoration: InputDecoration(
              labelText: sendLabel,
              errorText: errorText,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: isLoading || isEmpty ? null : onSend,
          child: Text(AppLocalizations.of(context)!.send),
        ),
      ],
    );
  }
}

class ThreadReplyWidget extends StatefulWidget {
  const ThreadReplyWidget({super.key});

  @override
  State<ThreadReplyWidget> createState() => _ThreadReplyWidgetState();
}

class _ThreadReplyWidgetState extends State<ThreadReplyWidget> {
  late TextEditingController _replyController;
  _ThreadReplyStatus _status = _ThreadReplyStatus.initial;
  String? _error;

  @override
  void initState() {
    super.initState();
    _replyController = TextEditingController();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;

    setState(() {
      _status = _ThreadReplyStatus.loading;
      _error = null;
    });

    try {
      final threadCubit = context.read<ThreadCubit>();
      await threadCubit.thread.replyText(_replyController.text);

      if (!mounted) return;
      setState(() {
        _status = _ThreadReplyStatus.success;
        _replyController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _ThreadReplyStatus.error;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _status == _ThreadReplyStatus.loading;

    String sendText = AppLocalizations.of(context)!.send;
    final counterpartyCubits = context.read<ThreadCubit>().counterpartyCubits;

    if (counterpartyCubits.length > 1) {
      sendText =
          "Sending to ${counterpartyCubits.values.map((e) => e.state.data?.metadata.getName() ?? 'Loading').join(', ')}";
    }

    return ThreadReplyView(
      controller: _replyController,
      isLoading: isLoading,
      errorText: _status == _ThreadReplyStatus.error ? _error : null,
      sendLabel: sendText,
      onChanged: (_) {
        setState(() {});
      },
      onSend: _sendReply,
    );
  }
}
