import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

Widget buildFrame({
  required String path,
  required Widget placeholder,
  required VoidCallback onNext,
  required VoidCallback onPrevious,
}) => HtmlElementView.fromTagName(
  tagName: 'iframe',
  onElementCreated: (Object element) {
    final frame = element as web.HTMLIFrameElement;
    frame
      ..src = '${web.window.location.origin}$path'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = '#F4EEE4';
    frame.onload = ((web.Event _) {
      // Mismo origen: la charla puede escuchar el teclado de la app.
      frame.contentWindow?.addEventListener(
        'keydown',
        ((web.KeyboardEvent event) {
          if (event.key == 'PageDown') onNext();
          if (event.key == 'PageUp') onPrevious();
        }).toJS,
      );
    }).toJS;
  },
);
