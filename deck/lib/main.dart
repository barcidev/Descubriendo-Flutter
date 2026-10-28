import 'package:flutter/widgets.dart';

import 'app.dart';
import 'engine/browser.dart';

void main() => runApp(DeckApp(browser: Browser.current));
