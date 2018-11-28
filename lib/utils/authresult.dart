import 'dart:convert';
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/lobby/lobby.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';

class AuthResult {
  Response response;
  GlobalKey<ScaffoldState> scaffoldKey;
  AuthResult(this.response, this.scaffoldKey);

  setWSCookie() async {
    Request req =
        Request("POST", Uri.parse(BaseUrl.apiUrl + ApiUtil.GET_COOKIE_URL));
    req.body = json.encode({});
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        SharedPrefHelper()
            .saveWSCookieToStorage(json.decode(res.body)["cookie"]);
      }
    });
  }

  processResult(Function done) async {
    if (response.statusCode >= 200 && response.statusCode <= 299) {
      SharedPrefHelper.internal()
          .saveCookieToStorage(response.headers["set-cookie"]);
      SharedPrefHelper.internal()
          .saveToSharedPref(ApiUtil.SHARED_PREFERENCE_USER_KEY, response.body);
      await setWSCookie();
      Navigator.of(scaffoldKey.currentContext).pushReplacement(
        MaterialPageRoute(
          builder: (context) => Lobby(),
        ),
      );
      done();
    }
  }
}
