import 'package:flutter/material.dart';

class ZapInput extends StatefulWidget {
  const ZapInput({super.key});

  @override
  State<StatefulWidget> createState() => ZapInputState();
}

class ZapInputState extends State<ZapInput> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Zap us'),
        MaterialButton(
          child: Text('Zap'),
          onPressed: () {
            // BlocProvider.of<SecureStorage>(context).set(
            //     'mode', !BlocProvider.of<SecureStorage>(context).state.mode);
          },
        )
      ],
    );
  }
}
