import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:playfantasy/routes.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/splashscreen.dart';
import 'package:playfantasy/utils/httpmanager.dart';

disableDeviceRotation() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

ThemeData _buildLightTheme() {
  const Color primaryColor = Color(0xFF0E4F87);
  const Color secondaryColor = Color(0xFF244f83);
  final ColorScheme colorScheme = const ColorScheme.light().copyWith(
    primary: primaryColor,
    secondary: secondaryColor,
  );
  final ThemeData base = ThemeData.light();
  return base.copyWith(
    colorScheme: colorScheme,
    primaryColor: primaryColor,
    primaryColorDark: secondaryColor,
    buttonColor: primaryColor,
    indicatorColor: Colors.white,
    splashColor: Colors.white24,
    splashFactory: InkRipple.splashFactory,
    accentColor: secondaryColor,
    canvasColor: Colors.white,
    scaffoldBackgroundColor: Colors.white,
    backgroundColor: Colors.white,
    errorColor: const Color(0xFFB00020),
  );
}

///
/// Bootstraping APP.
///
void main() async {
  String channelId = "3";
  const apiBaseUrl = "https://www.playfantasy.com";

  disableDeviceRotation();

  HttpManager.channelId = channelId;
  var configuredApp = AppConfig(
    appName: 'PlayFantasy',
    channelId: channelId,
    showBackground: true,
    apiBaseUrl: apiBaseUrl,
    child: MaterialApp(
      home: SplashScreen(
        apiBaseUrl: apiBaseUrl,
        channelId: channelId,
      ),
      routes: FantasyRoutes().getRoutes(),
      theme: _buildLightTheme(),
    ),
  );

  runApp(configuredApp);
}
