import 'package:flutter/material.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/services/swap.dart';
import 'package:hostr/presentation/main.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

class EscrowSelectorWidget extends StatefulWidget {
  final Metadata counterparty;
  final ReservationRequest r;
  const EscrowSelectorWidget(
      {super.key, required this.counterparty, required this.r});

  createState() => _EscrowSelectorWidgetState();
}

class _EscrowSelectorWidgetState extends State<EscrowSelectorWidget> {
  String? _current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: CustomPadding(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
          Text(
              style: Theme.of(context).textTheme.titleLarge!,
              'Which escrow would you like to use to settle this transfer?'),
          CustomPadding(),
          Container(
            child: FutureBuilder(
              future: getIt<Ndk>().lists.getSingleNip51List(
                  NOSTR_KIND_ESCROW_TRUST,
                  Bip340EventSigner(
                      privateKey: getIt<KeyStorage>()
                          .getActiveKeyPairSync()!
                          .privateKey,
                      publicKey: getIt<KeyStorage>()
                          .getActiveKeyPairSync()!
                          .publicKey)),
              builder:
                  (BuildContext context, AsyncSnapshot<Nip51List?> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData) {
                    return DropdownButton<dynamic>(
                      value: _current,
                      isExpanded: true,
                      underline: Container(),
                      selectedItemBuilder: (BuildContext context) {
                        if (_current == null) {
                          return [Text('Select escrow')];
                        }
                        return [ProfileChipWidget(id: _current!)];
                      },
                      items: snapshot.data!
                          .byTag('p')
                          .map<DropdownMenuItem<dynamic>>(
                              (Nip51ListElement pubkey) {
                        return DropdownMenuItem(
                          value: pubkey.value,
                          child: Text(pubkey.value,
                              style: TextStyle(
                                  fontSize: 20,
                                  overflow: TextOverflow.ellipsis)),
                        );
                      }).toList(),
                      onChanged: (dynamic size) {
                        if (_current != size) {
                          setState(() {
                            _current = size!;
                          });
                        }
                      },
                    );
                    ;
                  } else {
                    return Text("No escrows trusted yet");
                  }
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
          ),
          CustomPadding(),
          Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                  key: ValueKey('select_escrow'),
                  onPressed: _current == null
                      ? null
                      : () async {
                          List<Escrow> l = await getIt<NostrService>()
                              .startRequestAsync<Escrow>(filters: [
                            Filter(
                                authors: [_current!],
                                kinds: [NOSTR_KIND_ESCROW])
                          ]);
                          Navigator.of(context).pop();
                          await getIt<SwapService>().escrow(
                              amount: widget.r.parsedContent.amount,
                              eventId: widget.r.nip01Event.id,
                              timelock: widget.r.parsedContent.end
                                  .difference(DateTime.now())
                                  .inMinutes,
                              escrowContractAddress:
                                  '0xE72544c0fa4dE04faecac9EAcC06c0790f168A5a',
                              sellerPubkey: widget.counterparty.pubKey,
                              escrowPubkey: MOCK_ESCROWS[0].nip01Event.pubKey);
                        },
                  child: Text('Select Escrow')))
        ])));
  }
}
