import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';

enum _ThreadReplyStatus { initial, loading, success, error }

class ThreadReplyView extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final String? errorText;
  final String? label;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  const ThreadReplyView({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.errorText,
    required this.label,
    required this.onChanged,
    required this.onSend,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = controller.text.trim().isEmpty;
    final isEnabled = !isLoading && !isEmpty;
    final theme = Theme.of(context);

    return TextField(
      onChanged: onChanged,
      controller: controller,
      maxLines: 3,
      minLines: 1,
      autofocus: false,
      decoration: InputDecoration(
        hintText: hintText,
        label: label != null
            ? Text(label!, style: Theme.of(context).textTheme.bodySmall)
            : null,
        errorText: errorText,
        contentPadding: const EdgeInsets.only(
          left: 16,
          top: 12,
          bottom: 12,
          right: 64,
        ),
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: IconButton.filled(
          onPressed: isEnabled ? onSend : null,
          icon: Icon(
            Icons.send_rounded,
            size: 16,
            color: isEnabled
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
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

    String? label;
    final counterpartyCubits = context.read<ThreadCubit>().counterpartyCubits;

    if (counterpartyCubits.length > 1) {
      label =
          "Sending to ${counterpartyCubits.values.map((e) => e.state.data?.metadata.getName() ?? 'Loading').join(', ')}";
    }

    return ThreadReplyView(
      controller: _replyController,
      isLoading: isLoading,
      errorText: _status == _ThreadReplyStatus.error ? _error : null,
      label: label,
      hintText: AppLocalizations.of(context)!.typeAMessage,
      onChanged: (_) {
        setState(() {});
      },
      onSend: _sendReply,
    );
  }
}
