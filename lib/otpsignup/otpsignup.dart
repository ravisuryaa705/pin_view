import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:device_info/device_info.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:package_info/package_info.dart';
import 'package:playfantasy/action_utils/action_util.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/commonwidgets/leadingbutton.dart';
import 'package:playfantasy/otpsignup/otpinput.dart';
import 'package:playfantasy/signin/signin.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/authresult.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/redux/actions/loader_actions.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';
import 'package:playfantasy/utils/analytics.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:location_permissions/location_permissions.dart';

class OTPSignup extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new OTPSignupState();
}

class OTPSignupState extends State<OTPSignup> {
  String _authName;
  String _deviceId;
  String _pfRefCode;
  String googleAddId = "";
  bool _obscureText = true;
  bool isIos = false;
  bool _bShowReferralInput = false;
  String _installReferringLink = "";
  Map<dynamic, dynamic> androidDeviceInfoMap;
  String chosenloginTypeByUser = "";
  String locationLongitude = "";
  String locationLatitude = "";

  bool showPromoInput = false;

  static const branch_io_platform =
      const MethodChannel('com.algorin.pf.branch');
  static const firebase_fcm_platform =
      const MethodChannel('com.algorin.pf.fcm');
  static const webengage_platform =
      const MethodChannel('com.algorin.pf.webengage');
  static const utils_platform = const MethodChannel('com.algorin.pf.utils');
  bool disableBranchIOAttribution = false;
  final formKey = new GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  final TextEditingController _referralCodeController = TextEditingController();

  static const _kFontFam = 'MyFlutterApp';
  static const IconData gplus_squared =
      const IconData(0xf0d4, fontFamily: _kFontFam);
  static const IconData facebook_squared =
      const IconData(0xf308, fontFamily: _kFontFam);

  @override
  void initState() {
    super.initState();
    initServices();
    if (Platform.isIOS) {
      isIos = true;
    }
    if (PrivateAttribution.disableBranchIOAttribution && !isIos) {
      AnalyticsManager.deleteInternalStorageFile(
          PrivateAttribution.getApkNameToDelete());
    }

    setLongLatValues();
  }

  initServices() async {
    await getLocalStorageValues();
    await getAndroidDeviceInfo();
    await _initBranchStuff();
  }

  getLocalStorageValues() {
    Future<dynamic> firebasedeviceid = SharedPrefHelper.internal()
        .getFromSharedPref(ApiUtil.SHARED_PREFERENCE_FIREBASE_TOKEN);
    firebasedeviceid.then((value) {
      if (value != null && value.length > 0) {
        _deviceId = value;
      } else {
        _getFirebaseToken();
      }
    });
    Future<dynamic> installReferringlinkFromBranch = SharedPrefHelper.internal()
        .getFromSharedPref(ApiUtil.SHARED_PREFERENCE_INSTALLREFERRING_BRANCH);
    installReferringlinkFromBranch.then((value) {
      if (value != null) {
        if (value.length > 3) {
          _installReferringLink = value;
        }
      } else {
        _getInstallReferringLink().then((String link) {
          if (value != null) {
            if (link.length > 3) {
              _installReferringLink = link;
            }
          }
        });
      }
    });
    Future<dynamic> pfRefCodeFromBranch = SharedPrefHelper.internal()
        .getFromSharedPref(ApiUtil.SHARED_PREFERENCE_REFCODE_BRANCH);
    pfRefCodeFromBranch.then((value) {
      if (value != null && value.length > 0) {
        bool disableBranchIOAttribution =
            PrivateAttribution.disableBranchIOAttribution;
        if (!disableBranchIOAttribution) {
          _pfRefCode = value;
          setState(() {
            _referralCodeController.text = _pfRefCode;
          });
        }
      } else {
        _getBranchRefCode().then((String refcode) {
          bool disableBranchIOAttribution =
              PrivateAttribution.disableBranchIOAttribution;
          if (!disableBranchIOAttribution) {
            _pfRefCode = refcode;
            setState(() {
              _referralCodeController.text = _pfRefCode;
            });
          }
        });
      }
    });
  }

  Future<String> _getFirebaseToken() async {
    String value;
    try {
      value = await firebase_fcm_platform.invokeMethod('_getFirebaseToken');
      _deviceId = value;
    } catch (e) {}
    return value;
  }

  _getFirebaseId() async {
    _deviceId = await SharedPrefHelper.internal()
        .getFromSharedPref(ApiUtil.SHARED_PREFERENCE_FIREBASE_TOKEN);
  }

  _initBranchStuff() async {
    _getInstallReferringLink().then((String value) {
      if (value.length > 2) {
        _installReferringLink = value;
      }
    });

    _getBranchRefCode().then((String refcode) {
      _pfRefCode = refcode;
      setState(() {
        _referralCodeController.text = _pfRefCode;
      });
    });
  }

  showLoader(bool bShow) {
    AppConfig.of(context)
        .store
        .dispatch(bShow ? LoaderShowAction() : LoaderHideAction());
  }

  Future<String> _getBranchRefCode() async {
    String value;
    try {
      value = await branch_io_platform.invokeMethod('_getBranchRefCode');
    } catch (e) {}
    return value;
  }

  Future<String> getAndroidDeviceInfo() async {
    Map<dynamic, dynamic> value;
    try {
      value = await branch_io_platform.invokeMethod('_getAndroidDeviceInfo');
      androidDeviceInfoMap = value;
    } catch (e) {}
    return "";
  }

  Future<String> _getInstallReferringLink() async {
    String value;
    try {
      value = await branch_io_platform.invokeMethod('_getInstallReferringLink');
    } catch (e) {}
    return value;
  }

  Future<String> setLongLatValues() async {
    await LocationPermissions().requestPermissions();
    Map<dynamic, dynamic> value;
    PermissionStatus permissionStatus =
        await LocationPermissions().checkPermissionStatus();
    if (permissionStatus.toString() == PermissionStatus.granted.toString()) {
      try {
        value = await utils_platform.invokeMethod('getLocationLongLat');
        print("^^^^^^^^^Inside the Geo location********");
        print(value);
        if (value["bAccessGiven"] != null) {
          if (value["bAccessGiven"] == "true") {
            locationLongitude = value["longitude"];
            locationLatitude = value["latitude"];
          }
        }
      } catch (e) {
        print("^^^^^^^^^Inside the Geo location error ********");
        print(e);
        value = null;
      }
    } else if (permissionStatus.toString() ==
        PermissionStatus.denied.toString()) {
      await showLocationPermissionInformationPopup();
    } else {
      await LocationPermissions().requestPermissions();
    }
    return "";
  }

  showLocationPermissionInformationPopup() async {
    return showDialog(
      context: context,
      builder: (context) => WillPopScope(
        onWillPop: () {},
        child: AlertDialog(
          contentPadding: EdgeInsets.all(0.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.0),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                height: 80.0,
                color: Theme.of(context).primaryColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SvgPicture.asset(
                      "images/logo_white.svg",
                      color: Colors.white,
                      width: 40.0,
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Image.asset(
                        "images/logo_name_white.png",
                        height: 20.0,
                      ),
                    )
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: RichText(
                        textAlign: TextAlign.justify,
                        text: TextSpan(
                          style: TextStyle(
                            color: Colors.black87,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  "Howzat needs access to your location.Please allow access to your location settings and restart app to move forward.",
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: FlatButton(
                child: Text("Settings"),
                onPressed: () {
                  openSettingForGrantingPermissions();
                },
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<bool> openSettingForGrantingPermissions() async {
    bool isOpened = await LocationPermissions().openAppSettings();
    PermissionStatus permissionStatus =
        await LocationPermissions().checkPermissionStatus();
    if (permissionStatus.toString() == PermissionStatus.granted.toString()) {
      print("We are inside granted permission");
      Navigator.of(context).pop();
    } else {
      print("We are outside granted permission");
    }
  }

  _showReferralInput() {
    setState(() {
      _bShowReferralInput = !_bShowReferralInput;
    });
  }

  _doSignUp({bool launchEnterOTP = true}) async {
    showLoader(true);
    Map<String, dynamic> _payload = {
      "mobile": _authName,
      "context": {
        "channelId": HttpManager.channelId,
      }
    };

    http.Request req =
        http.Request("POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.REQUEST_OTP));
    req.body = json.encode(_payload);
    await HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          if (launchEnterOTP) {
            showModalBottomSheet<void>(
              context: context,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.0),
                  topRight: Radius.circular(8.0),
                ),
              ),
              builder: (context) {
                return OtpInput(
                  onResend: () {
                    _doSignUp(launchEnterOTP: false);
                  },
                  onVerify: (String otp) {
                    print(otp);
                    authOTP(otp);
                  },
                );
              },
            );
          }
        } else {
          ActionUtil().showMsgOnTop("error", _scaffoldKey.currentContext);
        }
        showLoader(false);
      },
    ).whenComplete(() {
      showLoader(false);
    });
  }

  authOTP(String otp) async {
    showLoader(true);
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String appVersion = packageInfo.version;
    String model = "";
    String manufacturer = "";
    String serial = "";

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      model = androidInfo.model;
      manufacturer = androidInfo.manufacturer;
      serial = androidInfo.androidId;
    }
    if (Platform.isIOS) {
      await deviceInfo.iosInfo;
      try {
        model = androidDeviceInfoMap["model"];
      } catch (e) {}
      manufacturer = "Apple";
      serial = "";
    }

    Map<String, dynamic> _payload = {
      "value": {"mobile": _authName, "password": otp}
    };
    _payload["mobile"] = _authName;
    _payload["password"] = otp;
    chosenloginTypeByUser = "FORM_MOBILE";

    _payload["context"] = {
      "refCode": _referralCodeController.text,
      "channel_id": HttpManager.channelId,
      "deviceId": _deviceId,
      "model": model,
      "manufacturer": manufacturer,
      "serial": serial,
      "branchinstallReferringlink": _installReferringLink,
      "app_version_flutter": appVersion,
      "location_longitude": locationLongitude,
      "location_latitude": locationLatitude
    };

    bool disableBranchIOAttribution =
        PrivateAttribution.disableBranchIOAttribution;

    if (!disableBranchIOAttribution) {
      if (_installReferringLink.length > 0) {
        var uri = Uri.parse(_installReferringLink);
        uri.queryParameters.forEach((k, v) {
          try {
            _payload["context"][k] = v;
          } catch (e) {
            print(e);
          }
        });
        AnalyticsManager().setContext(_payload["context"]);
      }
    } else if (PrivateAttribution.getPrivateAttributionName() == "oppo") {
      _payload["context"]["utm_source"] = "Oppo";
      _payload["context"]["utm_medium"] = "Oppo Store";
      _payload["context"]["utm_campaign"] = "Oppo World Cup";
    } else if (PrivateAttribution.getPrivateAttributionName() == "xiaomi") {
      _payload["context"]["utm_source"] = "xiaomi";
      _payload["context"]["utm_medium"] = "xiaomi-store";
      _payload["context"]["utm_campaign"] = "xiaomi-World-Cup";
    }
    try {
      _payload["context"]["uid"] = androidDeviceInfoMap["uid"];
      _payload["context"]["googleaddid"] = androidDeviceInfoMap["googleaddid"];
      _payload["context"]["platformType"] = androidDeviceInfoMap["version"];
      _payload["context"]["network_operator"] =
          androidDeviceInfoMap["network_operator"];
      _payload["context"]["firstInstallTime"] =
          androidDeviceInfoMap["firstInstallTime"];
      _payload["context"]["lastUpdateTime"] =
          androidDeviceInfoMap["lastUpdateTime"];
      _payload["context"]["device_ip_"] = androidDeviceInfoMap["device_ip_"];
      _payload["context"]["network_type"] =
          androidDeviceInfoMap["network_type"];
      _payload["context"]["googleEmailList"] =
          json.encode(androidDeviceInfoMap["googleEmailList"]);
    } catch (e) {}

    http.Request req =
        http.Request("POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.OTP_SIGNUP));
    req.body = json.encode(_payload);
    await HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          onLoginAuthenticate(json.decode(res.body));
          AuthResult(res, _scaffoldKey).processResult(context, () {});
        } else {
          final dynamic response =
              json.decode(res.body).cast<String, dynamic>();
          String error = response['error']['erroMessage'];
          if (error == null && response['error']['errorCode'] != null) {
            error = strings.get(response['error']['errorCode']);
          } else if (error == null) {
            error = strings.get("INVALID_USERNAME_PASSWORD");
          }
          ActionUtil().showMsgOnTop(error, _scaffoldKey.currentContext);
        }
        showLoader(false);
      },
    ).whenComplete(() {
      showLoader(false);
    });
  }

  bool isMobileNumber(String input) {
    if (input.length == 10 && isNumeric(input)) {
      return true;
    }
    return false;
  }

  bool isNumeric(String s) {
    if (s == null) {
      return false;
    }
    return int.parse(s, onError: (e) => null) != null;
  }

  bool validateEmail(String value) {
    Pattern pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = new RegExp(pattern);
    if (!regex.hasMatch(value))
      return false;
    else
      return true;
  }

  _doGoogleLogin(BuildContext context) async {
    showLoader(true);
    GoogleSignIn _googleSignIn = new GoogleSignIn(
      scopes: [
        'email',
        'https://www.googleapis.com/auth/contacts.readonly',
      ],
    );

    _googleSignIn.signIn().then(
      (GoogleSignInAccount _googleSignInAccount) {
        _googleSignInAccount.authentication.then(
          (GoogleSignInAuthentication _googleSignInAuthentication) {
            _sendTokenToAuthenticate(
                _googleSignInAuthentication.accessToken, 1);
            chosenloginTypeByUser = "GOOGLE";
          },
        ).whenComplete(() {
          showLoader(false);
        });
      },
    ).whenComplete(() {
      showLoader(false);
    });
  }

  _doFacebookLogin(BuildContext context) async {
    showLoader(true);
    var facebookLogin = new FacebookLogin();
    facebookLogin.loginBehavior = FacebookLoginBehavior.webViewOnly;
    var result = await facebookLogin.logIn(['email', 'public_profile']);

    switch (result.status) {
      case FacebookLoginStatus.loggedIn:
        _sendTokenToAuthenticate(result.accessToken.token, 2);
        chosenloginTypeByUser = "FACEBOOK";
        break;
      case FacebookLoginStatus.cancelledByUser:
        showLoader(false);
        break;
      case FacebookLoginStatus.error:
        showLoader(false);
        break;
      default:
        showLoader(false);
    }
  }

  _sendTokenToAuthenticate(String token, int authFor) async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String app_version_flutter = packageInfo.version;
    String model = "";
    String manufacturer = "";
    String serial = "";
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      model = androidInfo.model;
      manufacturer = androidInfo.manufacturer;
      serial = androidInfo.androidId;
    }
    if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      try {
        model = androidDeviceInfoMap["model"];
      } catch (e) {}
      manufacturer = "Apple";
      serial = "";
    }
    Map<String, dynamic> _payload = {};
    _payload["accessToken"] = token;
    _payload["context"] = {
      "refCode": _pfRefCode,
      "channel_id": HttpManager.channelId,
      "deviceId": _deviceId,
      "uid": "",
      "model": model,
      "manufacturer": manufacturer,
      "serial": serial,
      "branchinstallReferringlink": _installReferringLink,
      "app_version_flutter": app_version_flutter,
      "location_longitude": locationLongitude,
      "location_latitude": locationLatitude
    };

    bool disableBranchIOAttribution =
        PrivateAttribution.disableBranchIOAttribution;

    if (!disableBranchIOAttribution) {
      if (_installReferringLink.length > 0) {
        var uri = Uri.parse(_installReferringLink);
        uri.queryParameters.forEach((k, v) {
          try {
            _payload["context"][k] = v;
          } catch (e) {
            print(e);
          }
        });
      }
    } else if (PrivateAttribution.getPrivateAttributionName() == "oppo") {
      _payload["context"]["utm_source"] = "Oppo";
      _payload["context"]["utm_medium"] = "Oppo Store";
      _payload["context"]["utm_campaign"] = "Oppo World Cup";
    } else if (PrivateAttribution.getPrivateAttributionName() == "xiaomi") {
      _payload["context"]["utm_source"] = "xiaomi";
      _payload["context"]["utm_medium"] = "xiaomi-store";
      _payload["context"]["utm_campaign"] = "xiaomi-World-Cup";
    }

    try {
      _payload["context"]["uid"] = androidDeviceInfoMap["uid"];
      _payload["context"]["googleaddid"] = androidDeviceInfoMap["googleaddid"];
      _payload["context"]["platformType"] = androidDeviceInfoMap["version"];
      _payload["context"]["network_operator"] =
          androidDeviceInfoMap["network_operator"];
      _payload["context"]["firstInstallTime"] =
          androidDeviceInfoMap["firstInstallTime"];
      _payload["context"]["lastUpdateTime"] =
          androidDeviceInfoMap["lastUpdateTime"];
      _payload["context"]["device_ip_"] = androidDeviceInfoMap["device_ip_"];
      _payload["context"]["network_type"] =
          androidDeviceInfoMap["network_type"];
      _payload["context"]["googleEmailList"] =
          json.encode(androidDeviceInfoMap["googleEmailList"]);
    } catch (e) {}

    http.Client()
        .post(
      BaseUrl().apiUrl +
          (authFor == 1
              ? ApiUtil.GOOGLE_LOGIN_URL
              : (authFor == 2
                  ? ApiUtil.FACEBOOK_LOGIN_URL
                  : ApiUtil.GOOGLE_LOGIN_URL)),
      headers: {'Content-type': 'application/json'},
      body: json.encode(_payload),
    )
        .then((http.Response res) {
      showLoader(false);
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        onLoginAuthenticate(json.decode(res.body));
        AuthResult(res, _scaffoldKey).processResult(context, () {});
      } else {
        final dynamic response = json.decode(res.body).cast<String, dynamic>();
        // setState(() {
        //   _scaffoldKey.currentState
        //       .showSnackBar(SnackBar(content: Text(response['error'])));
        // });
        ActionUtil()
            .showMsgOnTop(response['error'], _scaffoldKey.currentContext);
      }
    });
    showLoader(false);
  }

  onLoginAuthenticate(Map<String, dynamic> loginData) async {
    await webEngageUserLogin(loginData["user_id"].toString(), loginData);
    await trackAndSetBranchUserIdentity(loginData["user_id"].toString());
    await branchLifecycleEventSigniup(loginData);
    await webEngageEventSigniup(loginData);
  }

  Future<String> webEngageUserLogin(
      String userId, Map<String, dynamic> loginData) async {
    String result = "";
    Map<dynamic, dynamic> data = new Map();
    data["trackingType"] = "login";
    data["value"] = userId;
    try {
      result =
          await webengage_platform.invokeMethod('webengageTrackUser', data);
    } catch (e) {}
    return "";
  }

  Future<String> webEngageEventSigniup(Map<String, dynamic> loginData) async {
    Map<dynamic, dynamic> signupdata = new Map();
    signupdata["registrationID"] = loginData["user_id"].toString();
    signupdata["transactionID"] = loginData["user_id"].toString();
    signupdata["description"] =
        "CHANNEL" + loginData["channelId"].toString() + "SIGNUP";
    String phone = "";
    String email = "";
    if (isMobileNumber(_authName)) {
      phone = await AnalyticsManager.dosha256Encoding("+91" + _authName);
    } else {
      email = await AnalyticsManager.dosha256Encoding(_authName);
    }
    signupdata["phone"] = phone;
    signupdata["email"] = email;
    signupdata["chosenloginTypeByUser"] = chosenloginTypeByUser;
    signupdata["data"] = loginData;
    String trackValue;
    try {
      String trackValue = await webengage_platform.invokeMethod(
          'webEngageEventSigniup', signupdata);
    } catch (e) {}
    return trackValue;
  }

  Future<String> trackAndSetBranchUserIdentity(String userId) async {
    String value;
    try {
      value = await branch_io_platform.invokeMethod(
          'trackAndSetBranchUserIdentity', userId);
    } catch (e) {
      print(e);
    }
    return value;
  }

  Future<String> branchLifecycleEventSigniup(
      Map<String, dynamic> loginData) async {
    Map<dynamic, dynamic> signupdata = new Map();
    signupdata["registrationID"] = loginData["user_id"].toString();
    signupdata["transactionID"] = loginData["user_id"].toString();
    signupdata["description"] =
        "CHANNEL" + loginData["channelId"].toString() + "SIGNUP";
    signupdata["data"] = loginData;
    String trackValue;
    try {
      String trackValue = await branch_io_platform.invokeMethod(
          'branchLifecycleEventSigniup', signupdata);
    } catch (e) {}
    return trackValue;
  }

  openTermsAndConditionsPage() {
    String url = "";
    String title = "";
    title = "TERMS AND CONDITIONS";
    url = BaseUrl().staticPageUrls["TERMS"];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WebviewScaffold(
          url: isIos ? Uri.encodeFull(url) : url,
          appBar: AppBar(
            leading: LeadingButton(),
            title: Text(
              title.toUpperCase(),
            ),
            titleSpacing: 0.0,
          ),
        ),
      ),
    );
  }

  _launchSignIn() {
    Navigator.of(context).pushReplacement(FantasyPageRoute(
      pageBuilder: (context) => SignInPage(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      scaffoldKey: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0.0),
        child: Container(),
      ),
      backgroundColor: Color.fromRGBO(134, 16, 13, 1),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 8.0, right: 16.0, bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  FlatButton(
                    child: Text(
                      "LOGIN",
                      style: Theme.of(context).primaryTextTheme.title.copyWith(
                            color: Color.fromRGBO(216, 138, 4, 1),
                            decoration: TextDecoration.underline,
                          ),
                    ),
                    onPressed: () {
                      _launchSignIn();
                    },
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  "images/hzlogo.png",
                  width: MediaQuery.of(context).size.width * 0.4,
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(top: 32.0, left: 56.0, right: 56.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Form(
                          key: formKey,
                          child: Column(
                            children: <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(bottom: 16.0),
                                      child: TextFormField(
                                        onSaved: (val) => _authName = val,
                                        decoration: InputDecoration(
                                          labelText: "Enter Mobile",
                                          isDense: true,
                                          labelStyle: Theme.of(context)
                                              .primaryTextTheme
                                              .title
                                              .copyWith(
                                                color: Colors.white,
                                              ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: new BorderSide(
                                              color: Colors.white24,
                                            ),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: new BorderSide(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                        style: Theme.of(context)
                                            .primaryTextTheme
                                            .title
                                            .copyWith(
                                              color: Colors.white,
                                            ),
                                        validator: (value) {
                                          if (value.isEmpty) {
                                            return strings
                                                .get("EMAIL_OR_MOBILE_ERROR");
                                          } else if (!isMobileNumber(value)) {
                                            return "Please enter valid Mobile";
                                          }
                                          return null;
                                        },
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: <Widget>[
                                  showPromoInput
                                      ? Expanded(
                                          child: Padding(
                                            padding:
                                                EdgeInsets.only(bottom: 16.0),
                                            child: TextFormField(
                                              controller:
                                                  _referralCodeController,
                                              decoration: InputDecoration(
                                                labelText: strings
                                                    .get("REFERRAL_CODE"),
                                                labelStyle: Theme.of(context)
                                                    .primaryTextTheme
                                                    .title
                                                    .copyWith(
                                                      color: Colors.white,
                                                    ),
                                                enabledBorder:
                                                    UnderlineInputBorder(
                                                  borderSide: new BorderSide(
                                                    color: Colors.white24,
                                                  ),
                                                ),
                                                focusedBorder:
                                                    UnderlineInputBorder(
                                                  borderSide: new BorderSide(
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ),
                                              textCapitalization:
                                                  TextCapitalization.characters,
                                              style: Theme.of(context)
                                                  .primaryTextTheme
                                                  .title
                                                  .copyWith(
                                                    color: Colors.white,
                                                  ),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          padding: EdgeInsets.only(
                                              top: 16.0, bottom: 32.0),
                                          child: InkWell(
                                            child: Text(
                                              "Enter Invite Code",
                                              style: Theme.of(context)
                                                  .primaryTextTheme
                                                  .title
                                                  .copyWith(
                                                    color: Color.fromRGBO(
                                                        216, 138, 4, 1),
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                            ),
                                            onTap: () {
                                              setState(() {
                                                showPromoInput =
                                                    !showPromoInput;
                                              });
                                            },
                                          ),
                                        ),
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 16.0),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Container(
                                        height: 48.0,
                                        child: ColorButton(
                                          onPressed: () {
                                            if (formKey.currentState
                                                .validate()) {
                                              formKey.currentState.save();
                                              _doSignUp();
                                            }
                                          },
                                          child: Container(
                                            child: Text(
                                              "SIGNUP",
                                              style: Theme.of(context)
                                                  .primaryTextTheme
                                                  .title
                                                  .copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: 24.0, top: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "By registering you agree to our ",
              style: Theme.of(context).primaryTextTheme.subhead.copyWith(
                    color: Colors.white,
                  ),
              textAlign: TextAlign.center,
            ),
            InkWell(
              child: Padding(
                padding: EdgeInsets.only(right: 8.0, bottom: 8.0, top: 8.0),
                child: Text(
                  "Terms & Conditions",
                  style: Theme.of(context).primaryTextTheme.subhead.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        decoration: TextDecoration.underline,
                      ),
                ),
              ),
              onTap: () {
                openTermsAndConditionsPage();
              },
            )
          ],
        ),
      ),
    );
  }
}
