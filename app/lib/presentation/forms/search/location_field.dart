import 'package:flutter/material.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:uuid/uuid.dart';

class LocationField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const LocationField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<StatefulWidget> createState() {
    return LocationFieldState();
  }
}

class LocationFieldState extends State<LocationField> {
  late TextEditingController _controller;
  var uuid = Uuid();
  String? _sessionToken;
  List<dynamic> _placeList = [];
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _controller.addListener(() {
      onChanged();
    });
  }

  onChanged() async {
    if (_sessionToken == null) {
      setState(() {
        _sessionToken = uuid.v4();
      });
    }
    var res = await getIt<GoogleMaps>()
        .getLocationResults(_controller.text, _sessionToken);
    setState(() {
      _placeList = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TextFormField(
        decoration: InputDecoration(
          hintText: "Where are you going?",
          labelText: 'Location',
          // prefixIcon: Icon(Icons.location_on),
          suffixIcon: IconButton(
            icon: Icon(Icons.cancel),
            onPressed: () {
              _controller.clear();
              setState(() {
                _placeList = [];
              });
            },
          ),
        ),
        controller: _controller,
        onChanged: widget.onChanged,
        validator: (value) {
          if (value?.isEmpty ?? true) {
            return 'Please enter a location';
          }
          return null;
        },
      ),
      ListView.builder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: _placeList.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_placeList[index]["text"]['text']),
            onTap: () => setState(() {
              _controller.text = _placeList[index]["text"]['text'];
              _placeList = [];
            }),
          );
        },
      )
    ]);
  }
}
