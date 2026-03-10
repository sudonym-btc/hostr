import 'dart:io';
import 'dart:math' as math;

import 'package:dart_console/dart_console.dart';
import 'package:interact_cli/interact_cli.dart';
// ignore: implementation_imports
import 'package:interact_cli/src/framework/framework.dart';

/// Blocks until the user presses any key.
///
/// Useful after displaying non-interactive output to prevent the main loop
/// from immediately clearing the screen.
void pressAnyKey() {
  stdout.write('  Press any key to continue…');
  final console = Console();
  console.readKey();
  print('');
}

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

  int get _terminalLines {
    try {
      return stdout.hasTerminal ? stdout.terminalLines : 24;
    } catch (_) {
      return 24;
    }
  }

  int get _terminalColumns {
    try {
      return stdout.hasTerminal ? stdout.terminalColumns : 80;
    } catch (_) {
      return 80;
    }
  }

  int get _visibleOptionCount {
    // Keep some room for the prompt, overflow markers and shell prompt.
    final maxVisible = _terminalLines - 6;
    return math.max(5, math.min(component.options.length, maxVisible));
  }

  ({int start, int end}) get _window {
    final visibleCount = _visibleOptionCount;
    if (component.options.length <= visibleCount) {
      return (start: 0, end: component.options.length);
    }

    final half = visibleCount ~/ 2;
    var start = index - half;
    start = math.max(0, start);
    start = math.min(start, component.options.length - visibleCount);
    final end = math.min(component.options.length, start + visibleCount);
    return (start: start, end: end);
  }

  String _truncateOption(String option) {
    final maxWidth = math.max(20, _terminalColumns - 6);
    if (option.length <= maxWidth) return option;
    return '${option.substring(0, maxWidth - 1)}…';
  }

  String _formatPrompt() {
    final buf = StringBuffer();
    buf.write(component.theme.inputPrefix);
    buf.write(component.theme.messageStyle(component.prompt));
    buf.write(component.theme.hintStyle(' (↑/↓ move, q back)'));
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
    final window = _window;
    final hiddenAbove = window.start;
    final hiddenBelow = component.options.length - window.end;

    if (component.options.length > _visibleOptionCount) {
      context.writeln(
        component.theme.hintStyle(
          'Showing ${window.start + 1}-${window.end} of ${component.options.length}',
        ),
      );
    }

    if (hiddenAbove > 0) {
      context.writeln(
        component.theme.hintStyle('  ↑ $hiddenAbove more'),
      );
    }

    for (var i = window.start; i < window.end; i++) {
      final option = component.options[i];
      final line = StringBuffer();
      final display = _truncateOption(option);

      if (i == index) {
        line.write(component.theme.activeItemPrefix);
        line.write(' ');
        line.write(component.theme.activeItemStyle(display));
      } else {
        line.write(component.theme.inactiveItemPrefix);
        line.write(' ');
        line.write(component.theme.inactiveItemStyle(display));
      }
      context.writeln(line.toString());
    }

    if (hiddenBelow > 0) {
      context.writeln(
        component.theme.hintStyle('  ↓ $hiddenBelow more'),
      );
    }
  }

  @override
  int interact() {
    while (true) {
      final key = context.readKey();

      // Check for 'q' as a back key (reliable in Docker PTY where
      // ESC byte timing causes dart_console to misread escape sequences).
      if (!key.isControl && key.char == 'q') return -1;

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
