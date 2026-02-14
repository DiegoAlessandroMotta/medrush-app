import 'dart:html' as html;

/// En web: true si la página se cargó por HTTPS (evita Mixed Content).
bool isWebPageHttps() =>
    html.window.location.protocol == 'https:';
