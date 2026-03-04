import 'package:dart_console/dart_console.dart';
import 'package:interact_cli/interact_cli.dart';
// ignore: implementation_imports
import 'package:interact_cli/src/framework/framework.dart';

/// A [Select] variant that also accepts ESC to go back.
///
/// Returns the selected index, or `-1` if the user pressed ESC.
class SelectOrBack extends Component<int> {
  SelectOrBack({
    required this.prompt,
    required this.options,
    this.initialIndex = 0,
  }) : theme = Theme.defaultTheme;

  final Theme theme;
  final String prompt;
  final int initialIndex;
  final List<String> options;

  @override
  _SelectOrBackState createState() => _SelectOrBackState();
}

class _SelectOrBackState extends State<SelectOrBack> {
  int index = 0;

  String _formatPrompt() {
    final buf = StringBuffer();
    buf.write(component.theme.inputPrefix);
    buf.write(component.theme.messageStyle(component.prompt));
    buf.write(component.theme.hintStyle(' (ESC to go back)'));
    buf.write(component.theme.inputSuffix);
    buf.write(' ');
    return buf.toString();
  }

  @override
  void init() {
    super.init();

    if (component.options.isEmpty) {
      throw Exception("Options can't be empty");
    }

    if (component.options.length - 1 < component.initialIndex) {
      throw Exception("Default value is out of options' range");
    } else {
      index = component.initialIndex;
    }

    context.writeln(_formatPrompt());
    context.hideCursor();
  }

  @override
  void dispose() {
    context.showCursor();
    super.dispose();
  }

  @override
  void render() {
    for (var i = 0; i < component.options.length; i++) {
      final option = component.options[i];
      final line = StringBuffer();

      if (i == index) {
        line.write(component.theme.activeItemPrefix);
        line.write(' ');
        line.write(component.theme.activeItemStyle(option));
      } else {
        line.write(component.theme.inactiveItemPrefix);
        line.write(' ');
        line.write(component.theme.inactiveItemStyle(option));
      }
      context.writeln(line.toString());
    }
  }

  @override
  int interact() {
    while (true) {
      final key = context.readKey();

      switch (key.controlChar) {
        case ControlCharacter.arrowUp:
          setState(() {
            index = (index - 1) % component.options.length;
          });
        case ControlCharacter.arrowDown:
          setState(() {
            index = (index + 1) % component.options.length;
          });
        case ControlCharacter.enter:
          return index;
        case ControlCharacter.escape:
          return -1;
        default:
          break;
      }
    }
  }
}
