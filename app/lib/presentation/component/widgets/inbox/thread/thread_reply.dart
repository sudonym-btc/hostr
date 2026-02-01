import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';

enum _ThreadReplyStatus { initial, loading, success, error }

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
    final isEmpty = _replyController.text.trim().isEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            onChanged: (text) {
              setState(() {}); // Trigger rebuild for button state
            },
            controller: _replyController,
            maxLines: 3,
            minLines: 1,
            autofocus: true,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.send,
              errorText: _status == _ThreadReplyStatus.error ? _error : null,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: isLoading || isEmpty ? null : _sendReply,
          child: Text(AppLocalizations.of(context)!.send),
        ),
      ],
    );
  }
}
