import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:playfantasy/lobby/addcash.dart';
import 'package:playfantasy/modal/profile.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/commonwidgets/changepassword.dart';

class MyProfile extends StatefulWidget {
  @override
  MyProfileState createState() => MyProfileState();
}

class MyProfileState extends State<MyProfile> {
  String cookie;
  int _gender = -1;
  bool bIsDatePicked = false;
  bool bIsInfoUpdated = false;
  Profile _userProfile = Profile();
  Map<String, dynamic> _selectedState;
  static int currentYear = DateTime.now().year;
  DateTime _date = new DateTime(currentYear - 18);
  TextEditingController _teamNameController = TextEditingController();
  TextEditingController _cityController = TextEditingController();
  TextEditingController _fNameController = TextEditingController();
  TextEditingController _lNameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _streetController = TextEditingController();
  TextEditingController _pincodeController = TextEditingController();
  TextEditingController _landmarkController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _getProfileData();
  }

  _getProfileData() async {
    http.Request req = http.Request(
      "GET",
      Uri.parse(
        BaseUrl.apiUrl + ApiUtil.GET_USER_PROFILE,
      ),
    );
    return HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          Map<String, dynamic> response = json.decode(res.body);
          setState(() {
            _userProfile = Profile.fromJson(response);
            _cityController.text = _userProfile.city;
            _fNameController.text = _userProfile.fname;
            _lNameController.text = _userProfile.lname;
            _phoneController.text = _userProfile.mobile;
            _emailController.text = _userProfile.email;
            _streetController.text = _userProfile.address1;
            _landmarkController.text = _userProfile.address2;
            _pincodeController.text = _userProfile.pincode == null
                ? ""
                : _userProfile.pincode.toString();
            _gender = _userProfile.gender == null
                ? -1
                : (_userProfile.gender == "MALE") ? 1 : 2;
            setSelectedState();
          });
        } else if (res.statusCode == 401) {
          Map<String, dynamic> response = json.decode(res.body);
          if (response["error"]["reasons"].length > 0) {}
        }
      },
    );
  }

  setSelectedState() {
    _userProfile.states.forEach((dynamic state) {
      if (_userProfile.state == state["code"]) {
        _selectedState = state;
      }
    });
  }

  _showMessage(String msg) {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: Duration(seconds: 3),
      ),
    );
  }

  _showChangePasswordDialog() async {
    String result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return ChangePassword();
      },
    );

    if (result != null) {
      _showMessage(result);
    }
  }

  _showChangeTeamNameDialog() {
    final _formKey = GlobalKey<FormState>();
    final FocusNode focusNode = FocusNode();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Team name"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      "You are allowed to change team name once.",
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Row(
                  children: <Widget>[
                    Form(
                      key: _formKey,
                      child: Expanded(
                        child: TextFormField(
                          controller: _teamNameController,
                          decoration: InputDecoration(
                            labelText: "Team name",
                            contentPadding: EdgeInsets.all(8.0),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black38,
                              ),
                            ),
                            errorMaxLines: 2,
                          ),
                          focusNode: focusNode,
                          validator: (value) {
                            if (value.isEmpty || value.length < 4) {
                              return "Minimum 4 characters required.";
                            } else if (value.length > 12) {
                              return "Maximum 12 characters allowed.";
                            } else if (value.contains(
                                    RegExp('[@#\$?(),!/:{}><;`*~%^&+=]')) ==
                                true) {
                              return "Name must contains characters, numbers, '.', '-', and '_' symbols only";
                            } else if (value.indexOf(" ") != -1) {
                              return "Name should not contain space";
                            } else if (!value.startsWith(RegExp('[A-Za-z]'))) {
                              return "Name must starts with character.";
                            }
                          },
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
            FlatButton(
              child: Text('CHANGE'),
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  _changeTeamName();
                }
              },
            ),
          ],
        );
      },
    );
    FocusScope.of(context).requestFocus(focusNode);
  }

  _changeTeamName() {
    http.Request req = http.Request(
      "PUT",
      Uri.parse(
        BaseUrl.apiUrl + ApiUtil.CHANGE_TEAM_NAME,
      ),
    );
    req.body = json.encode({
      "username": _teamNameController.text,
    });
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        _showMessage("Team name changed successfully.");
        _userProfile.isUserNameChangeAllowed = false;
        _userProfile.teamName = _teamNameController.text;
        Navigator.of(context).pop();
      } else if (res.statusCode >= 400 && res.statusCode <= 499) {
        Map<String, dynamic> response = json.decode(res.body);
        if (response["error"] != null) {
          Navigator.of(context).pop();
          _showMessage(response["error"]["erroMessage"]);
        }
      }
    });
  }

  _launchAddCash() async {
    if (cookie == null) {
      Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
      await futureCookie.then((value) {
        setState(() {
          cookie = value;
        });
      });
    }

    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => AddCash(),
        fullscreenDialog: true,
      ),
    );
  }

  _showChangeValueDialog(TextEditingController _controller, String label,
      {TextInputType keyboardType = TextInputType.text, int maxLength}) async {
    final _formKey = GlobalKey<FormState>();
    FocusNode focus = FocusNode();
    String defaultText = _controller.text;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Enter " + label),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TextFormField(
                          controller: _controller,
                          decoration: InputDecoration(
                            labelText: label,
                            contentPadding: EdgeInsets.all(8.0),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black38,
                              ),
                            ),
                          ),
                          keyboardType: keyboardType,
                          focusNode: focus,
                          validator: (value) {
                            if (value.isEmpty) {
                              return "Please enter " + label + ".";
                            } else if (maxLength != null &&
                                value.length > maxLength) {
                              return "Maximum " +
                                  maxLength.toString() +
                                  " characters allowed for " +
                                  label;
                            }
                          },
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('CANCEL'),
              onPressed: () {
                _controller.text = defaultText;
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text('OK'),
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  Navigator.of(context).pop();
                  bIsInfoUpdated = true;
                }
              },
            ),
          ],
        );
      },
    );
    FocusScope.of(context).requestFocus(focus);
  }

  showSelectionGenderPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          children: <Widget>[
            Column(
              children: <Widget>[
                FlatButton(
                  onPressed: () {
                    setState(() {
                      _gender = 1;
                      bIsInfoUpdated = true;
                    });
                    Navigator.of(context).pop();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text("MALE"),
                      _gender == 1
                          ? Icon(
                              Icons.check,
                              color: Colors.black,
                            )
                          : Container()
                    ],
                  ),
                ),
                FlatButton(
                  onPressed: () {
                    setState(() {
                      _gender = 2;
                      bIsInfoUpdated = true;
                    });
                    Navigator.of(context).pop();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text("FEMALE"),
                      _gender == 2
                          ? Icon(
                              Icons.check,
                              color: Colors.black,
                            )
                          : Container()
                    ],
                  ),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  _showStateSelection() {
    List<Widget> lstStates = [];
    for (int i = 0; i < _userProfile.states.length; i++) {
      lstStates.add(
        FlatButton(
          onPressed: () {
            setState(() {
              _selectedState = _userProfile.states[i];
              bIsInfoUpdated = true;
            });
            Navigator.of(context).pop();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                _userProfile.states[i]["value"],
              ),
              _selectedState != null &&
                      _selectedState["code"] == _userProfile.states[i]["code"]
                  ? Icon(Icons.check)
                  : Container(),
            ],
          ),
        ),
      );
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          children: <Widget>[
            Column(
              children: lstStates,
            )
          ],
        );
      },
    );
  }

  Future<Null> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1947),
      lastDate: DateTime(currentYear),
    );

    if (picked != null) {
      setState(() {
        _date = picked;
        bIsDatePicked = true;
        bIsInfoUpdated = true;
      });
    }
  }

  getDate() {
    return (_date.year.toString() +
        "-" +
        (_date.month >= 10
            ? _date.month.toString()
            : ("0" + _date.month.toString())) +
        "-" +
        (_date.day >= 10
            ? _date.day.toString()
            : ("0" + _date.day.toString())));
  }

  Map<String, dynamic> getUserProfileObject() {
    Map<String, dynamic> payload = {
      "address": {
        "first_name":
            _fNameController.text != "" ? _fNameController.text : null,
        "last_name": _lNameController.text != "" ? _lNameController.text : null,
        "add_line_1":
            _streetController.text != "" ? _streetController.text : null,
        "add_line_2":
            _landmarkController.text != "" ? _landmarkController.text : null,
        "city": _cityController.text != "" ? _cityController.text : null,
        "pin": _pincodeController.text != "" ? _pincodeController.text : null,
      },
      "info": {
        "email": _emailController.text != "" ? _emailController.text : null,
        "phone": _phoneController.text != "" ? _phoneController.text : null,
        "gender": _gender == -1 ? null : _gender == 1 ? "Male" : "Female",
        "dob": bIsDatePicked ? getDate() : null,
        "state": _selectedState == null ? "" : _selectedState["code"],
      },
    };

    return payload;
  }

  onSaveProfile() {
    if (_pincodeController.text.indexOf(".") != -1 ||
        _pincodeController.text.indexOf(" ") != -1 ||
        _pincodeController.text.indexOf(",") != -1 ||
        _pincodeController.text.indexOf("-") != -1) {
      _showMessage("Invalid pincode entered");
      return null;
    }
    http.Request req = http.Request(
      "PUT",
      Uri.parse(
        BaseUrl.apiUrl + ApiUtil.UPDATE_USER_PROFILE,
      ),
    );
    req.body = json.encode(getUserProfileObject());
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        _updateProfileObject(json.decode(res.body));
        _showMessage("Profile updated successfully.");
        setState(() {
          bIsInfoUpdated = false;
        });
      } else if (res.statusCode == 400) {
        Map<String, dynamic> response = json.decode(res.body);
        if (response["error"] != null) {
          _showMessage(response["error"]["erroMessage"]);
        }
      }
    });
  }

  _updateProfileObject(Map<String, dynamic> response) {
    Map<String, dynamic> addressReaponse = response["addressResponse"];
    setState(() {
      _userProfile.fname = addressReaponse["first_name"] == null
          ? _userProfile.fname
          : addressReaponse["first_name"];
      _userProfile.lname = addressReaponse["last_name"] == null
          ? _userProfile.lname
          : addressReaponse["last_name"];
      _userProfile.city = addressReaponse["city"] == null
          ? _userProfile.city
          : addressReaponse["city"];
      _userProfile.pincode = addressReaponse["pincode"] == null
          ? _userProfile.pincode
          : addressReaponse["pincode"];
      _userProfile.address1 = addressReaponse["add_line_1"] == null
          ? _userProfile.address1
          : addressReaponse["add_line_1"];
      _userProfile.address2 = addressReaponse["add_line_2"] == null
          ? _userProfile.address2
          : addressReaponse["add_line_2"];
      _userProfile.state = _selectedState == null ? "" : _selectedState["code"];
      _userProfile.gender =
          _gender == null ? "" : (_gender == 1 ? "MALE" : "FEMALE");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("MY PROFILE"),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(bottom: 80.0),
          color: Colors.blueGrey.shade50,
          child: Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Card(
                  elevation: 0.0,
                  margin: EdgeInsets.all(0.0),
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(0.0),
                  ),
                  child: Column(
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.only(
                            left: 32.0, right: 16.0, top: 8.0, bottom: 8.0),
                        child: Row(
                          children: <Widget>[
                            Text(
                              "ACCOUNT",
                              style: TextStyle(
                                  fontSize: Theme.of(context)
                                      .primaryTextTheme
                                      .subhead
                                      .fontSize,
                                  color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 32.0),
                        child: Divider(
                          color: Colors.black12,
                          height: 2.0,
                        ),
                      ),
                      Container(
                        height: 40.0,
                        child: FlatButton(
                          padding: EdgeInsets.all(0.0),
                          onPressed: () {
                            if (_userProfile.isUserNameChangeAllowed) {
                              _showChangeTeamNameDialog();
                            } else {
                              _showMessage(
                                  "Team name can not be changed again!!!");
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.only(left: 32.0, right: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  "Team name",
                                  style: TextStyle(
                                      fontSize: Theme.of(context)
                                          .primaryTextTheme
                                          .body2
                                          .fontSize,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black87),
                                ),
                                Row(
                                  children: <Widget>[
                                    Text(
                                      _userProfile.teamName == null
                                          ? "None"
                                          : _userProfile.teamName,
                                      style: TextStyle(
                                          fontSize: Theme.of(context)
                                              .primaryTextTheme
                                              .body2
                                              .fontSize,
                                          color: Colors.black54),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.black38,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 32.0),
                        child: Divider(
                          color: Colors.black12,
                          height: 2.0,
                        ),
                      ),
                      Container(
                        height: 40.0,
                        child: FlatButton(
                          padding: EdgeInsets.all(0.0),
                          onPressed: () {
                            if (_userProfile.hasPassword) {
                              _showChangePasswordDialog();
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.only(left: 32.0, right: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  "Password",
                                  style: TextStyle(
                                      fontSize: Theme.of(context)
                                          .primaryTextTheme
                                          .body2
                                          .fontSize,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black87),
                                ),
                                Row(
                                  children: <Widget>[
                                    Text(
                                      _userProfile.hasPassword
                                          ? "********"
                                          : "None",
                                      style: TextStyle(
                                          fontSize: Theme.of(context)
                                              .primaryTextTheme
                                              .body2
                                              .fontSize,
                                          color: Colors.black54),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.black38,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 32.0),
                        child: Divider(
                          color: Colors.black12,
                          height: 2.0,
                        ),
                      ),
                      Container(
                        height: 40.0,
                        child: FlatButton(
                          padding: EdgeInsets.all(0.0),
                          onPressed: () {
                            _launchAddCash();
                          },
                          child: Container(
                            padding: EdgeInsets.only(left: 32.0, right: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  "Balance",
                                  style: TextStyle(
                                      fontSize: Theme.of(context)
                                          .primaryTextTheme
                                          .body2
                                          .fontSize,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black87),
                                ),
                                Row(
                                  children: <Widget>[
                                    Text(
                                      strings.rupee +
                                          _userProfile.balance
                                              .toStringAsFixed(2),
                                      style: TextStyle(
                                          fontSize: Theme.of(context)
                                              .primaryTextTheme
                                              .body2
                                              .fontSize,
                                          color: Colors.black54),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.black38,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Card(
                  elevation: 0.0,
                  margin: EdgeInsets.all(0.0),
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(0.0),
                  ),
                  child: Column(
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.only(
                            left: 32.0, right: 16.0, top: 8.0, bottom: 8.0),
                        child: Row(
                          children: <Widget>[
                            Text(
                              "PERSONAL INFO",
                              style: TextStyle(
                                  fontSize: Theme.of(context)
                                      .primaryTextTheme
                                      .subhead
                                      .fontSize,
                                  color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 32.0),
                        child: Divider(
                          color: Colors.black12,
                          height: 2.0,
                        ),
                      ),
                      Container(
                        height: 40.0,
                        child: FlatButton(
                          padding: EdgeInsets.all(0.0),
                          onPressed: _userProfile.fname == null ||
                                  _userProfile.fname == ""
                              ? () {
                                  _showChangeValueDialog(
                                    _fNameController,
                                    "First name",
                                  );
                                }
                              : null,
                          child: Container(
                            padding: EdgeInsets.only(left: 32.0, right: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  "Name",
                                  style: TextStyle(
                                      fontSize: Theme.of(context)
                                          .primaryTextTheme
                                          .body2
                                          .fontSize,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black87),
                                ),
                                Row(
                                  children: <Widget>[
                                    Text(
                                      _fNameController.text == null ||
                                              _fNameController.text == ""
                                          ? "None"
                                          : _fNameController.text,
                                      style: TextStyle(
                                          fontSize: Theme.of(context)
                                              .primaryTextTheme
                                              .body2
                                              .fontSize,
                                          color: Colors.black54),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.black38,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 32.0),
                        child: Divider(
                          color: Colors.black12,
                          height: 2.0,
                        ),
                      ),
                      Container(
                        height: 40.0,
                        child: FlatButton(
                          padding: EdgeInsets.all(0.0),
                          onPressed: _userProfile.lname == null ||
                                  _userProfile.lname == ""
                              ? () {
                                  _showChangeValueDialog(
                                    _lNameController,
                                    "Last name",
                                  );
                                }
                              : null,
                          child: Container(
                            padding: EdgeInsets.only(left: 32.0, right: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  "Lastname",
                                  style: TextStyle(
                                      fontSize: Theme.of(context)
                                          .primaryTextTheme
                                          .body2
                                          .fontSize,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black87),
                                ),
                                Row(
                                  children: <Widget>[
                                    Text(
                                      _lNameController.text == null ||
                                              _lNameController.text == ""
                                          ? "None"
                                          : _lNameController.text,
                                      style: TextStyle(
                                          fontSize: Theme.of(context)
                                              .primaryTextTheme
                                              .body2
                                              .fontSize,
                                          color: Colors.black54),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.black38,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 32.0),
                        child: Divider(
                          color: Colors.black12,
                          height: 2.0,
                        ),
                      ),
                      Container(
                        height: 40.0,
                        child: FlatButton(
                          padding: EdgeInsets.all(0.0),
                          onPressed: _userProfile.gender == null ||
                                  _userProfile.gender == ""
                              ? () {
                                  showSelectionGenderPopup();
                                }
                              : null,
                          child: Container(
                            padding: EdgeInsets.only(left: 32.0, right: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  "Gender",
                                  style: TextStyle(
                                      fontSize: Theme.of(context)
                                          .primaryTextTheme
                                          .body2
                                          .fontSize,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black87),
                                ),
                                Row(
                                  children: <Widget>[
                                    Text(
                                      _gender == -1
                                          ? "None"
                                          : _gender == 1 ? "MALE" : "FEMALE",
                                      style: TextStyle(
                                          fontSize: Theme.of(context)
                                              .primaryTextTheme
                                              .body2
                                              .fontSize,
                                          color: Colors.black54),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.black38,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 32.0),
                        child: Divider(
                          color: Colors.black12,
                          height: 2.0,
                        ),
                      ),
                      Container(
                        height: 40.0,
                        child: FlatButton(
                          padding: EdgeInsets.all(0.0),
                          onPressed: () {
                            if (_userProfile.dob == null) {
                              _selectDate(context);
                            } else {
                              _showMessage(
                                "Please contact support to change this filed.",
                              );
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.only(left: 32.0, right: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  "Birthday",
                                  style: TextStyle(
                                      fontSize: Theme.of(context)
                                          .primaryTextTheme
                                          .body2
                                          .fontSize,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black87),
                                ),
                                Row(
                                  children: <Widget>[
                                    Text(
                                      _userProfile.dob == null && _date == null
                                          ? "None"
                                          : (bIsDatePicked
                                              ? getDate()
                                              : _userProfile.dob == null
                                                  ? "None"
                                                  : _userProfile.dob),
                                      style: TextStyle(
                                          fontSize: Theme.of(context)
                                              .primaryTextTheme
                                              .body2
                                              .fontSize,
                                          color: Colors.black54),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.black38,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Card(
                  elevation: 0.0,
                  margin: EdgeInsets.all(0.0),
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(0.0),
                  ),
                  child: Column(
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.only(
                            left: 32.0, right: 16.0, top: 8.0, bottom: 8.0),
                        child: Row(
                          children: <Widget>[
                            Text(
                              "PHONE & EMAIL",
                              style: TextStyle(
                                  fontSize: Theme.of(context)
                                      .primaryTextTheme
                                      .subhead
                                      .fontSize,
                                  color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 32.0),
                        child: Divider(
                          color: Colors.black12,
                          height: 2.0,
                        ),
                      ),
                      Container(
                        height: 40.0,
                        child: FlatButton(
                          padding: EdgeInsets.all(0.0),
                          onPressed: _userProfile.mobileVerification == null ||
                                  _userProfile.mobileVerification == false
                              ? () {
                                  _showChangeValueDialog(
                                    _phoneController,
                                    "Phone number",
                                    keyboardType: TextInputType.phone,
                                  );
                                }
                              : null,
                          child: Container(
                            padding: EdgeInsets.only(left: 32.0, right: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  "Phone",
                                  style: TextStyle(
                                      fontSize: Theme.of(context)
                                          .primaryTextTheme
                                          .body2
                                          .fontSize,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black87),
                                ),
                                Row(
                                  children: <Widget>[
                                    Text(
                                      _phoneController.text == null ||
                                              _phoneController.text == ""
                                          ? "None"
                                          : _phoneController.text,
                                      style: TextStyle(
                                          fontSize: Theme.of(context)
                                              .primaryTextTheme
                                              .body2
                                              .fontSize,
                                          color: Colors.black54),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.black38,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 32.0),
                        child: Divider(
                          color: Colors.black12,
                          height: 2.0,
                        ),
                      ),
                      Container(
                        height: 40.0,
                        child: FlatButton(
                          padding: EdgeInsets.all(0.0),
                          onPressed: _userProfile.emailVerification == null ||
                                  _userProfile.emailVerification == false
                              ? () {
                                  _showChangeValueDialog(
                                    _emailController,
                                    "Email address",
                                    keyboardType: TextInputType.emailAddress,
                                  );
                                }
                              : null,
                          child: Container(
                            padding: EdgeInsets.only(left: 32.0, right: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  "Email",
                                  style: TextStyle(
                                      fontSize: Theme.of(context)
                                          .primaryTextTheme
                                          .body2
                                          .fontSize,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black87),
                                ),
                                Row(
                                  children: <Widget>[
                                    Text(
                                      _emailController.text == null ||
                                              _emailController.text == ""
                                          ? "None"
                                          : _emailController.text,
                                      style: TextStyle(
                                          fontSize: Theme.of(context)
                                              .primaryTextTheme
                                              .body2
                                              .fontSize,
                                          color: Colors.black54),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.black38,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Card(
                  elevation: 0.0,
                  margin: EdgeInsets.all(0.0),
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(0.0),
                  ),
                  child: Column(
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.only(
                            left: 32.0, right: 16.0, top: 8.0, bottom: 8.0),
                        child: Row(
                          children: <Widget>[
                            Text(
                              "ADDRESS",
                              style: TextStyle(
                                  fontSize: Theme.of(context)
                                      .primaryTextTheme
                                      .subhead
                                      .fontSize,
                                  color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 32.0),
                        child: Divider(
                          color: Colors.black12,
                          height: 2.0,
                        ),
                      ),
                      Container(
                        height: 40.0,
                        child: FlatButton(
                          padding: EdgeInsets.all(0.0),
                          onPressed: _userProfile.address1 == null ||
                                  _userProfile.address1 == ""
                              ? () {
                                  _showChangeValueDialog(
                                    _streetController,
                                    "Area & street",
                                  );
                                }
                              : null,
                          child: Container(
                            padding: EdgeInsets.only(left: 32.0, right: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  "Area & street",
                                  style: TextStyle(
                                      fontSize: Theme.of(context)
                                          .primaryTextTheme
                                          .body2
                                          .fontSize,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black87),
                                ),
                                Row(
                                  children: <Widget>[
                                    Text(
                                      _streetController.text == null ||
                                              _streetController.text == ""
                                          ? "None"
                                          : _streetController.text,
                                      style: TextStyle(
                                          fontSize: Theme.of(context)
                                              .primaryTextTheme
                                              .body2
                                              .fontSize,
                                          color: Colors.black54),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.black38,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 32.0),
                        child: Divider(
                          color: Colors.black12,
                          height: 2.0,
                        ),
                      ),
                      Container(
                        height: 40.0,
                        child: FlatButton(
                          padding: EdgeInsets.all(0.0),
                          onPressed: _userProfile.address2 == null ||
                                  _userProfile.address2 == ""
                              ? () {
                                  _showChangeValueDialog(
                                    _landmarkController,
                                    "Landmark",
                                  );
                                }
                              : null,
                          child: Container(
                            padding: EdgeInsets.only(left: 32.0, right: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  "Landmark",
                                  style: TextStyle(
                                      fontSize: Theme.of(context)
                                          .primaryTextTheme
                                          .body2
                                          .fontSize,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black87),
                                ),
                                Row(
                                  children: <Widget>[
                                    Text(
                                      _landmarkController.text == null ||
                                              _landmarkController.text == ""
                                          ? "None"
                                          : _landmarkController.text,
                                      style: TextStyle(
                                          fontSize: Theme.of(context)
                                              .primaryTextTheme
                                              .body2
                                              .fontSize,
                                          color: Colors.black54),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.black38,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 32.0),
                        child: Divider(
                          color: Colors.black12,
                          height: 2.0,
                        ),
                      ),
                      Container(
                        height: 40.0,
                        child: FlatButton(
                          padding: EdgeInsets.all(0.0),
                          onPressed: _userProfile.pincode == null ||
                                  _userProfile.pincode == 0
                              ? () {
                                  _showChangeValueDialog(
                                    _pincodeController,
                                    "Pincode",
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                  );
                                }
                              : null,
                          child: Container(
                            padding: EdgeInsets.only(left: 32.0, right: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  "Pincode",
                                  style: TextStyle(
                                      fontSize: Theme.of(context)
                                          .primaryTextTheme
                                          .body2
                                          .fontSize,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black87),
                                ),
                                Row(
                                  children: <Widget>[
                                    Text(
                                      _pincodeController.text == null ||
                                              _pincodeController.text == ""
                                          ? "None"
                                          : _pincodeController.text,
                                      style: TextStyle(
                                          fontSize: Theme.of(context)
                                              .primaryTextTheme
                                              .body2
                                              .fontSize,
                                          color: Colors.black54),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.black38,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 32.0),
                        child: Divider(
                          color: Colors.black12,
                          height: 2.0,
                        ),
                      ),
                      Container(
                        height: 40.0,
                        child: FlatButton(
                          padding: EdgeInsets.all(0.0),
                          onPressed: _userProfile.city == null ||
                                  _userProfile.city == ""
                              ? () {
                                  _showChangeValueDialog(
                                    _cityController,
                                    "City",
                                  );
                                }
                              : null,
                          child: Container(
                            padding: EdgeInsets.only(left: 32.0, right: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  "City",
                                  style: TextStyle(
                                      fontSize: Theme.of(context)
                                          .primaryTextTheme
                                          .body2
                                          .fontSize,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black87),
                                ),
                                Row(
                                  children: <Widget>[
                                    Text(
                                      _cityController.text == null ||
                                              _cityController.text == ""
                                          ? "None"
                                          : _cityController.text,
                                      style: TextStyle(
                                          fontSize: Theme.of(context)
                                              .primaryTextTheme
                                              .body2
                                              .fontSize,
                                          color: Colors.black54),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.black38,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 32.0),
                        child: Divider(
                          color: Colors.black12,
                          height: 2.0,
                        ),
                      ),
                      Container(
                        height: 40.0,
                        child: FlatButton(
                          padding: EdgeInsets.all(0.0),
                          onPressed: _userProfile.state == null ||
                                  _userProfile.state == ""
                              ? () {
                                  _showStateSelection();
                                }
                              : null,
                          child: Container(
                            padding: EdgeInsets.only(left: 32.0, right: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  "State",
                                  style: TextStyle(
                                      fontSize: Theme.of(context)
                                          .primaryTextTheme
                                          .body2
                                          .fontSize,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black87),
                                ),
                                Row(
                                  children: <Widget>[
                                    Text(
                                      _selectedState == null
                                          ? "None"
                                          : _selectedState["value"],
                                      style: TextStyle(
                                          fontSize: Theme.of(context)
                                              .primaryTextTheme
                                              .body2
                                              .fontSize,
                                          color: Colors.black54),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.black38,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: bIsInfoUpdated
          ? FloatingActionButton(
              onPressed: () {
                onSaveProfile();
              },
              child: Text(
                "SAVE",
                style: Theme.of(context)
                    .primaryTextTheme
                    .button
                    .copyWith(color: Colors.white70),
              ),
            )
          : null,
    );
  }
}
