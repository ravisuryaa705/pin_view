import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info/package_info.dart';
import 'dart:io';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/createteam/sports.dart';
import 'package:playfantasy/lobby/lobby.dart';
import 'package:playfantasy/profilepages/update.dart';
import 'package:playfantasy/signup/signup.dart';
import 'package:playfantasy/utils/analytics.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/signin/signin.dart';
import 'package:playfantasy/utils/authcheck.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';
import 'package:permission/permission.dart';
import 'package:flutter_device_type/flutter_device_type.dart';

class SplashScreen extends StatefulWidget {
  final String channelId;
  final String apiBaseUrl;
  final String analyticsUrl;
  final String fcmSubscribeId;
  final bool disableBranchIOAttribution;

  SplashScreen(
      {this.apiBaseUrl,
      this.fcmSubscribeId,
      this.analyticsUrl,
      this.channelId,
      this.disableBranchIOAttribution});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  String analyticsUrl;
  String maintenanceMsg = "";
  double loadingPercent = 0.0;
  bool bUnderMaintenence = false;
  bool isTablet=false;
  static const firebase_fcm_platform =
      const MethodChannel('com.algorin.pf.fcm');
  static const branch_io_platform =
      const MethodChannel('com.algorin.pf.branch');
  static const utils_platform = const MethodChannel('com.algorin.pf.utils');
  PermissionStatus permissionStatus = PermissionStatus.allow;
  bool isIos = false;
  bool disableBranchIOAttribution = false;

  @override
  void initState() {
    getRequiredData();
    super.initState();
    if (Platform.isIOS) {
      isIos = true;
    }
    initServices();
    if (PrivateAttribution.disableBranchIOAttribution && !isIos) {
      AnalyticsManager.deleteInternalStorageFile(
          PrivateAttribution.getApkNameToDelete());
    }
  }

  getRequiredData() async {
    if (PrivateAttribution.disableBranchIOAttribution && !isIos) {
      await checkForPermission();
    }
    setLoadingPercentage(0.0);
    await updateStringTable();
    setLoadingPercentage(30.0);
    final initData = await getInitData();
    if (!isIos) {
      await _initBranchIoPlugin();
    }
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

      setLoadingPercentage(99.0);
      SharedPrefHelper().saveToSharedPref(ApiUtil.REGISTERED_USER, "1");
      Navigator.of(context).pushReplacement(
        FantasyPageRoute(
          pageBuilder: (context) => Lobby(),
        ),
      );
    } else {
      setLoadingPercentage(99.0);
      final result =
          await SharedPrefHelper().getFromSharedPref(ApiUtil.REGISTERED_USER);
      Navigator.of(context).pushReplacement(
        FantasyPageRoute(
          pageBuilder: (context) => result == null ? Signup() : SignInPage(),
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

  initServices() async {
    if( Device.get().isTablet ){
       isTablet=true;
    }
    await _getFirebaseToken();
    await _subscribeToFirebaseTopic(widget.fcmSubscribeId);
    if (isIos) {
      await _initBranchIoPlugin();
    }
  }

  _initBranchIoPlugin() async {
    Map<dynamic, dynamic> value = new Map();
    try {
      final value = await branch_io_platform
          .invokeMethod('_initBranchIoPlugin')
          .timeout(Duration(seconds: 10));
      SharedPrefHelper.internal().saveToSharedPref(
          ApiUtil.SHARED_PREFERENCE_INSTALLREFERRING_BRANCH,
          value["installReferring_link"]);
      SharedPrefHelper.internal().saveToSharedPref(
          ApiUtil.SHARED_PREFERENCE_REFCODE_BRANCH, value["refCodeFromBranch"]);
    } catch (e) {
      SharedPrefHelper.internal().saveToSharedPref(
          ApiUtil.SHARED_PREFERENCE_INSTALLREFERRING_BRANCH, "");
      SharedPrefHelper.internal()
          .saveToSharedPref(ApiUtil.SHARED_PREFERENCE_REFCODE_BRANCH, "");
    }
  }

  Future<String> _getFirebaseToken() async {
    String value;
    try {
      value = await firebase_fcm_platform
          .invokeMethod('_getFirebaseToken')
          .timeout(Duration(seconds: 10));
      print("####Firebase Token#######");
      print(value);
      SharedPrefHelper.internal()
          .saveToSharedPref(ApiUtil.SHARED_PREFERENCE_FIREBASE_TOKEN, value);
    } catch (e) {}
    return value;
  }

  Future<String> _subscribeToFirebaseTopic(String topicName) async {
    String result;
    try {
      result = await firebase_fcm_platform
          .invokeMethod('_subscribeToFirebaseTopic', topicName)
          .timeout(Duration(seconds: 10));
      print("####FCM Topic#######");
      print(result);
    } catch (e) {
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

  askForPermission() async {
    final result =
        await Permission.requestSinglePermission(PermissionName.WriteStorage);
    if (result != null) {
      setState(() {
        permissionStatus = result;
      });
    }
    return result;
  }

  checkForPermission() async {
    List<Permissions> permissions =
        await Permission.getPermissionsStatus([PermissionName.WriteStorage]);
    setState(() {
      permissionStatus = permissions[0].permissionStatus;
    });

    if (permissions[0].permissionStatus != PermissionStatus.allow) {
      final result = await askForPermission();
      if (result == PermissionStatus.allow) {}
    }
  }

  getInitData() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    double version = 0.0;
    bool isIos = false;
    if (Platform.isAndroid) {
      version = double.parse(packageInfo.version);
      isIos = false;
    }
    if (Platform.isIOS) {
      version = 3.73;
      isIos = true;
    }
    http.Request req =
        http.Request("POST", Uri.parse(widget.apiBaseUrl + ApiUtil.INIT_DATA));
    req.body = json.encode(
        {"version": version, "channelId": widget.channelId, "isIos": isIos});
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
    sports.mapSports = getMapSports(initData);
    sports.playingStyles = getMapPlayingStyle(initData);

    SharedPrefHelper()
        .saveToSharedPref(ApiUtil.KEY_INIT_DATA, json.encode(initData));
    HttpManager.channelId = widget.channelId;
  }

  getMapSports(Map<String, dynamic> initData) {
    Map<String, int> mapSports = {};
    (initData["sports"] as Map<String, dynamic>).keys.forEach((key) {
      mapSports[key] = initData["sports"][key];
    });

    return mapSports;
  }

  getMapPlayingStyle(Map<String, dynamic> initData) {
    Map<int, String> mapSports = {};
    (initData["playingStyleLabels"] as Map<String, dynamic>)
        .keys
        .forEach((key) {
      mapSports[int.parse(key)] = initData["playingStyleLabels"][key];
    });

    return mapSports;
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
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AppConfig.of(context).channelId == "10" || AppConfig.of(context).channelId == "13"
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white,
                image: DecorationImage(
                  image: AssetImage(!isTablet?"images/splashscreen.png":"images/SplashScreenTablet.png"),
                  fit: BoxFit.fitWidth,
                  
                  alignment: Alignment.topCenter,
                ),
              ),
              // child: Image.asset(
              //   "images/splashscreen.png",
              //   fit: BoxFit.fitWidth,
              //   alignment: Alignment.topCenter,
              // ),
            )
          : Stack(
              children: <Widget>[
                Container(
                  decoration: (AppConfig.of(context).channelId == "10"
                      ? BoxDecoration(color: Theme.of(context).primaryColor)
                      : (AppConfig.of(context).channelId == "9"
                          ? BoxDecoration(color: Theme.of(context).primaryColor)
                          : null)),
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
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.80,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(5.0),
                                      child: Image.asset(
                                        "images/logo_with_name.png",
                                        height: MediaQuery.of(context)
                                                .devicePixelRatio *
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
                      padding:
                          EdgeInsets.only(bottom: 4.0, left: 8.0, right: 8.0),
                      child: Text(
                        "LOADING...",
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
