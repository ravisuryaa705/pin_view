import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

class InitPay extends StatefulWidget {
  final String url;
  final bool waitForCookieset;
  final Function onTransactionComplete;
  InitPay({this.url, this.onTransactionComplete, this.waitForCookieset});

  @override
  InitPayState createState() => InitPayState();
}

class InitPayState extends State<InitPay> {
  String cookie = "";
  bool isWebviewLoaded = false;
  Map<String, String> depositResponse;
  FlutterWebviewPlugin flutterWebviewPlugin;

  @override
  void initState() {
    super.initState();
    flutterWebviewPlugin = FlutterWebviewPlugin();
    setWebview();
  }

  setWebview() async {
    flutterWebviewPlugin.onStateChanged.listen(
      (WebViewStateChanged state) {
        Uri uri = Uri.dataFromString(state.url);
        if (uri.path.indexOf(ApiUtil.PAYMENT_SUCCESS) != -1 && uri.hasQuery) {
          if (depositResponse == null) {
            depositResponse = uri.queryParameters;
            flutterWebviewPlugin.close();
            Navigator.of(context).pop(json.encode(depositResponse));
          }
        }
      },
    );

    cookie = HttpManager.cookie;
    if (cookie == null || cookie == "") {
      Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
      await futureCookie.then((value) {
        cookie = value;
      });
    }

    if (widget.waitForCookieset) {
      await flutterWebviewPlugin
          .evalJavascript("document.cookie='" + cookie + "'");
      Map<String, String> cookiesMap = await flutterWebviewPlugin.getCookies();
      Map<String, String> mapCookies = {};
      cookiesMap.keys.forEach((key) {
        mapCookies[key.trim().replaceAll("\"", "")] = cookiesMap[key];
      });
      if (mapCookies["pids"].length > 0) {
        setState(() {
          isWebviewLoaded = true;
        });
      }
    } else {
      isWebviewLoaded = true;
    }
  }

  @override
  void dispose() {
    flutterWebviewPlugin.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isWebviewLoaded
        ? WebviewScaffold(
            url: Uri.encodeFull(widget.url),
            withJavascript: true,
            enableAppScheme: true,
            withLocalStorage: true,
          )
        : Scaffold(
            body: Center(
              child: Text("Loading..."),
            ),
          );
  }
}
