import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info/package_info.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';
import 'package:playfantasy/landingpage/landingpage.dart';
import 'package:playfantasy/lobby/lobby.dart';
import 'package:flutter/services.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/authcheck.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/commonwidgets/update.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';

class SplashScreen extends StatefulWidget {
  final String channelId;
  final String apiBaseUrl;
  final String analyticsUrl;
  final String fcmSubscribeId;

  SplashScreen({
    this.apiBaseUrl,
    this.fcmSubscribeId,
    this.analyticsUrl,
    this.channelId,
  });

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  String analyticsUrl;
  String maintenanceMsg = "";
  double loadingPercent = 0.0;
  bool bUnderMaintenence = false;
  static const firebase_fcm_platform =
      const MethodChannel('com.algorin.pf.fcm');

  @override
  void initState() {
    getRequiredData();
    super.initState();
    initFirebaseConfiguration();

     _getFirebaseToken();
    _subscribeToFirebaseTopic(widget.fcmSubscribeId);
  }

  getRequiredData() async {
    setLoadingPercentage(0.0);
    await updateStringTable();
    setLoadingPercentage(30.0);
    final initData = await getInitData();

    await setInitData(initData);
    setLoadingPercentage(60.0);
    final result = await AuthCheck().checkStatus(widget.apiBaseUrl);
    setLoadingPercentage(90.0);

    if (initData["update"]) {
      await _showUpdatingAppDialog(
        initData["updateUrl"],
        logs: initData["updateLogs"],
        isForceUpdate: initData["isForceUpdate"],
      );
    }

    if (result) {
      final wsCookie = json.decode(await setWSCookie());
      if (wsCookie != null && wsCookie != "") {
        final result =
            await SharedPrefHelper().saveWSCookieToStorage(wsCookie["cookie"]);
        print(result);
      }
      print("here");

      setLoadingPercentage(99.0);
      Navigator.of(context).pushReplacement(
        FantasyPageRoute(
          pageBuilder: (context) => Lobby(),
        ),
      );
    } else {
      setLoadingPercentage(99.0);
      Navigator.of(context).pushReplacement(
        FantasyPageRoute(
          pageBuilder: (context) => LandingPage(),
        ),
      );
    }
  }

  setWSCookie() async {
    http.Request req = http.Request(
        "POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.GET_COOKIE_URL));
    req.body = json.encode({});
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) async {
      return res.body;
    });
  }

  setLoadingPercentage(double percent) {
    setState(() {
      loadingPercent = percent;
    });
  }

  initFirebaseConfiguration() async {
    // FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();
    // await _firebaseMessaging.getToken().then((token) {
    //   print("Token is .........................");
    //   print(token);
    //   SharedPrefHelper.internal()
    //       .saveToSharedPref(ApiUtil.SHARED_PREFERENCE_FIREBASE_TOKEN, token);
    // });

    // _firebaseMessaging.configure(
    //   onMessage: (Map<String, dynamic> message) {
    //     print('on message $message');
    //   },
    //   onResume: (Map<String, dynamic> message) {
    //     print('on resume $message');
    //   },
    //   onLaunch: (Map<String, dynamic> message) {
    //     print('on launch $message');
    //   },
    // );
    // _firebaseMessaging.subscribeToTopic('news');
    // _firebaseMessaging.subscribeToTopic(widget.fcmSubscribeId);
  }


  Future<String> _getFirebaseToken() async {
    String value;
    try {
      value = await firebase_fcm_platform.invokeMethod('_getFirebaseToken');
      SharedPrefHelper.internal()
          .saveToSharedPref(ApiUtil.SHARED_PREFERENCE_FIREBASE_TOKEN, value);
          print("@@@@@@@@@@@@@@@@@@@@FCM 1@@@@@@@@@@@@@@@@@@@@@@@@@@@");
      print("Firebase token in splashscreen");
      print(value);
    } catch (e) {
       print("@@@@@@@@@@@@@@@@@@@@FCM 1@@@@@@@@@@@@@@@@@@@@@@@@@@@");
      print(e);
    }
    return value;
  }

  Future<String> _subscribeToFirebaseTopic(String topicName) async {
    String result;
    try {
      result = await firebase_fcm_platform.invokeMethod(
          '_subscribeToFirebaseTopic', topicName);
           print("@@@@@@@@@@@@@@@@@@@@FCM 1@@@@@@@@@@@@@@@@@@@@@@@@@@@");
      print("Subscribed to topic");
      print(result);
    } catch (e) {
       print("@@@@@@@@@@@@@@@@@@@@FCM 1@@@@@@@@@@@@@@@@@@@@@@@@@@@");
      print(e);
    }
    return result;
  }

  updateStringTable() async {
    String table;
    await SharedPrefHelper().getLanguageTable().then((value) {
      table = value;
    });

    Map<String, dynamic> stringTable =
        json.decode(table == null ? "{}" : table);

    http.Request req = http.Request(
        "POST", Uri.parse(widget.apiBaseUrl + ApiUtil.UPDATE_LANGUAGE_TABLE));
    req.body = json.encode({
      "version": stringTable["version"],
      "language": stringTable["language"] == null ? 1 : stringTable["language"],
    });
    await HttpManager(http.Client()).sendRequest(req).then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        Map<String, dynamic> response = json.decode(res.body);
        if (response["update"]) {
          strings.set(
            language: response["language"],
            table: response["table"],
          );
          SharedPrefHelper().saveLanguageTable(
              version: response["version"],
              lang: response["language"],
              table: response["table"]);
        } else {
          strings.set(
            language: stringTable["language"],
            table: stringTable["table"],
          );
        }
      } else {
        strings.set(
          language: stringTable["language"],
          table: stringTable["table"],
        );
      }
    });
  }

  getInitData() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    http.Request req =
        http.Request("POST", Uri.parse(widget.apiBaseUrl + ApiUtil.INIT_DATA));
    req.body = json.encode({
      "version": double.parse(packageInfo.version),
      "channelId": widget.channelId,
    });
    return await HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        return json.decode(res.body);
      }
    });
  }

  setInitData(Map<String, dynamic> initData) async {
    analyticsUrl = initData["strClickStreamURL"];
    BaseUrl().setApiUrl(widget.apiBaseUrl);
    BaseUrl().setWebSocketUrl(initData["websocketUrl"]);
    BaseUrl().setContestShareUrl(initData["contestShareUrl"]);
    BaseUrl().setStaticPageUrl(initData["staticPageUrls"]);

    SharedPrefHelper()
        .saveToSharedPref(ApiUtil.KEY_INIT_DATA, json.encode(initData));
    HttpManager.channelId = widget.channelId;
  }

  _showUpdatingAppDialog(String url,
      {bool isForceUpdate, List<dynamic> logs}) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return DownloadAPK(
          url: url,
          logs: logs,
          isForceUpdate: isForceUpdate,
        );
      },
      barrierDismissible: !isForceUpdate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            decoration: AppConfig.of(context).channelId == '3'
                ? BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromRGBO(198, 57, 39, 1),
                        Color.fromRGBO(26, 43, 93, 1)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  )
                : null,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.of(context).size.height * 0.50,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5.0),
                                child: Image.asset(
                                  "images/logo.png",
                                  height:
                                      MediaQuery.of(context).devicePixelRatio *
                                          80.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppConfig.of(context).channelId == '3'
              ? Padding(
                  padding: EdgeInsets.only(bottom: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.all(4.0),
                            child: Image.asset("images/pci.png"),
                            height: 40.0,
                          ),
                          Container(
                            padding: EdgeInsets.all(4.0),
                            child: Image.asset("images/paytm.png"),
                            height: 40.0,
                          ),
                          Container(
                            padding: EdgeInsets.all(4.0),
                            child: Image.asset("images/visa.png"),
                            height: 40.0,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.all(4.0),
                            child: Image.asset("images/master.png"),
                            height: 40.0,
                          ),
                          Container(
                            padding: EdgeInsets.all(4.0),
                            child: Image.asset("images/amex.png"),
                            height: 40.0,
                          ),
                          Container(
                            padding: EdgeInsets.all(4.0),
                            child: Image.asset("images/cashfree.png"),
                            height: 40.0,
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : Container(),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(bottom: 4.0, left: 8.0, right: 8.0),
                child: Text(
                  "LOADING..." + loadingPercent.toStringAsFixed(0) + "%",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: LinearProgressIndicator(
                      value: loadingPercent / 100,
                      backgroundColor: Colors.white12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
