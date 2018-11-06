import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/modal/prizestructure.dart';
import 'package:playfantasy/lobby/tabs/leaguecard.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/leaguedetail/createteam.dart';
import 'package:playfantasy/commonwidgets/joincontest.dart';
import 'package:playfantasy/lobby/createprizestructure.dart';

class CreateContest extends StatefulWidget {
  final L1 l1data;
  final League league;
  final List<MyTeam> myTeams;

  CreateContest({this.league, this.l1data, this.myTeams});

  @override
  State<StatefulWidget> createState() => CreateContestState();
}

class CreateContestState extends State<CreateContest> {
  int _entryFee;
  String cookie;
  int _prizeType;
  int _numberOfPrize = 0;
  double _totalPrize = 0.0;
  int _numberOfParticipants;
  bool _bIsMultyEntry = false;
  bool _bAllowMultiEntryChange = false;

  bool bShowJoinContest = false;
  bool bWaitingForTeamCreation = false;

  List<PrizeStructure> prizeStructure;
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _nameController = new TextEditingController();
  final TextEditingController _entryFeeController = new TextEditingController();
  final TextEditingController _participantsController =
      new TextEditingController();

  L1 _l1Data;
  List<MyTeam> _myTeams;

  List<dynamic> allowedContestType;

  @override
  initState() {
    super.initState();
    sockets.register(_onWsMsg);

    prizeStructure = [];
    _l1Data = widget.l1data;
    _myTeams = widget.myTeams;
    allowedContestType = _l1Data.league.allowedContestTypes;

    _entryFeeController.addListener(() {
      if (_entryFeeController.text != "" &&
          _entryFee != int.parse(_entryFeeController.text)) {
        _entryFee = int.parse(_entryFeeController.text);
        if ((_entryFee > 0 && _entryFee <= 10000) &&
            (_numberOfParticipants != null &&
                _numberOfParticipants > 1 &&
                _numberOfParticipants <= 100)) {
          _updateSuggestedPrizeStructure();
        }
      }
    });

    _participantsController.addListener(() {
      if (_participantsController.text != "" &&
          _numberOfParticipants != int.parse(_participantsController.text)) {
        _numberOfParticipants = int.parse(_participantsController.text);
        if (_numberOfParticipants <= 5) {
          setState(() {
            _bIsMultyEntry = false;
            _bAllowMultiEntryChange = false;
          });
        } else {
          setState(() {
            _bAllowMultiEntryChange = true;
          });
        }
        if ((_entryFee != null && _entryFee > 0 && _entryFee < 10000) &&
            (_numberOfParticipants > 1 && _numberOfParticipants < 100)) {
          _updateSuggestedPrizeStructure();
        }
      }
    });
  }

  _onWsMsg(onData) {
    Map<String, dynamic> _response = json.decode(onData);

    if (_response["iType"] == RequestType.GET_ALL_L1 &&
        _response["bSuccessful"] == true) {
      setState(() {
        _l1Data = L1.fromJson(_response["data"]["l1"]);
        _myTeams = (_response["data"]["myteams"] as List)
            .map((i) => MyTeam.fromJson(i))
            .toList();
      });
    } else if (_response["iType"] == RequestType.L1_DATA_REFRESHED &&
        _response["bSuccessful"] == true) {
      _applyL1DataUpdate(_response["diffData"]["ld"]);
    } else if (_response["iType"] == RequestType.MY_TEAMS_ADDED &&
        _response["bSuccessful"] == true) {
      MyTeam teamAdded = MyTeam.fromJson(_response["data"]);
      setState(() {
        bool bFound = false;
        for (MyTeam _myTeam in _myTeams) {
          if (_myTeam.id == teamAdded.id) {
            bFound = true;
          }
        }
        if (!bFound) {
          _myTeams.add(teamAdded);
        }
        if (bShowJoinContest) {
          _onCreateContest();
        }
        bWaitingForTeamCreation = false;
      });
    }
  }

  _applyL1DataUpdate(Map<String, dynamic> _data) {
    if (_data["lstAdded"] != null && _data["lstAdded"].length > 0) {
      List<Contest> _addedContests =
          (_data["lstAdded"] as List).map((i) => Contest.fromJson(i)).toList();
      setState(() {
        for (Contest _contest in _addedContests) {
          bool bFound = false;
          for (Contest _curContest in _l1Data.contests) {
            if (_curContest.id == _contest.id) {
              bFound = true;
            }
          }
          if (!bFound && _l1Data.league.id == _contest.leagueId) {
            _l1Data.contests.add(_contest);
          }
        }
      });
    }
    if (_data["lstModified"] != null && _data["lstModified"].length > 0) {
      List<dynamic> _modifiedContests = _data["lstModified"];
      for (Map<String, dynamic> _changedContest in _modifiedContests) {
        for (Contest _contest in _l1Data.contests) {
          if (_contest.id == _changedContest["id"]) {
            setState(() {
              _contest.joined = _changedContest["joined"];
            });
          }
        }
      }
    }
  }

  _onCreateContest() async {
    if (_formKey.currentState.validate()) {
      Map<String, dynamic> payload = {
        "entryFee": _entryFee,
        "fanTeamId": 0,
        "inningsId": _l1Data.league.inningsId,
        "leagueId": _l1Data.league.id,
        "name": _nameController.text,
        "prizeType": _prizeType,
        "size": _numberOfParticipants,
        "teamsAllowed": _bIsMultyEntry ? 6 : 1,
        "totalPrizeAmount": getTotalPrizeAmount(prizeStructure),
        "prizeStructure": getPrizeList(prizeStructure),
        "context": {
          "channel_id": 3,
        }
      };

      final result = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return JoinContest(
            l1Data: _l1Data,
            myTeams: _myTeams,
            onCreateTeam: _onCreateTeam,
            createContestPayload: payload,
          );
        },
      );

      if (result != null) {
        Navigator.of(context).pop(result);
      }
    }
  }

  void _onCreateTeam(BuildContext context, Contest contest,
      {Map<String, dynamic> createContestPayload}) async {
    final curContest = contest == null ? createContestPayload : contest;

    bWaitingForTeamCreation = true;

    Navigator.of(context).pop();
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateTeam(
              league: widget.league,
              l1Data: _l1Data,
            ),
      ),
    );

    if (result != null) {
      _scaffoldKey.currentState
          .showSnackBar(SnackBar(content: Text("$result")));
      if (curContest != null) {
        if (bWaitingForTeamCreation) {
          bShowJoinContest = true;
        } else {
          _onCreateContest();
        }
      }
      Navigator.of(context).pop();
    }
    bWaitingForTeamCreation = false;
  }

  getTotalPrizeAmount(List<PrizeStructure> _suggestedPrizes) {
    double _totalPrize = 0.0;
    _suggestedPrizes.forEach((PrizeStructure prizeStructure) {
      _totalPrize += prizeStructure.amount;
    });

    return _totalPrize;
  }

  List<double> getPrizeList(List<PrizeStructure> _suggestedPrizes) {
    List<double> prizes = [];
    _suggestedPrizes.forEach((PrizeStructure prize) {
      prizes.add(prize.amount);
    });

    return prizes;
  }

  _updateSuggestedPrizeStructure() async {
    if (cookie == null) {
      Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
      await futureCookie.then((value) {
        setState(() {
          cookie = value;
        });
      });
    }

    http.Client().get(
      ApiUtil.RECOMMENDED_PRIZE_STRUCTURE +
          _numberOfParticipants.toString() +
          "/" +
          _entryFee.toString(),
      headers: {'Content-type': 'application/json', "cookie": cookie},
    ).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          List<PrizeStructureRange> prizeStructureRange =
              (json.decode(res.body) as List)
                  .map((i) => PrizeStructureRange.fromJson(i))
                  .toList();
          prizeStructure = getPrizeStructureFromRange(prizeStructureRange);
          setState(() {
            _totalPrize = getTotalPrizeAmount(prizeStructure);
            _numberOfPrize = prizeStructure.length;
          });
        }
      },
    );
  }

  getPrizeStructureFromRange(List<PrizeStructureRange> range) {
    List<PrizeStructure> prizeStructure = [];
    range.forEach((PrizeStructureRange prizeRange) {
      if (prizeRange.rank.indexOf("-") == -1) {
        prizeStructure.add(PrizeStructure(
            rank: int.parse(prizeRange.rank), amount: prizeRange.amount));
      } else {
        int startRange = int.parse(prizeRange.rank.split("-")[0]);
        int endRange = int.parse(prizeRange.rank.split("-")[1]);
        for (int i = startRange; i <= endRange; i++) {
          prizeStructure
              .add(PrizeStructure(rank: i, amount: prizeRange.amount));
        }
      }
    });
    return prizeStructure;
  }

  _onCustomPrizeStructure(final List<PrizeStructure> _prizeStructure) {
    prizeStructure = _prizeStructure;
    setState(() {
      _numberOfPrize = prizeStructure.length;
    });
  }

  _onEditPrize() async {
    FocusScope.of(context).requestFocus(FocusNode());
    _scaffoldKey.currentState.showBottomSheet((context) {
      return Container(
        decoration: new BoxDecoration(
          color: Colors.white,
          boxShadow: [
            new BoxShadow(
              color: Colors.black,
              blurRadius: 20.0,
            ),
          ],
        ),
        height: 550.0,
        child: CreatePrizeStructure(
          suggestedPrizes: prizeStructure,
          scaffoldKey: _scaffoldKey,
          totalPrize: _totalPrize,
          onClose: (List<PrizeStructure> prizeStructure) {
            _onCustomPrizeStructure(prizeStructure);
          },
        ),
      );
    });
  }

  bool isNumeric(String s) {
    if (s == null) {
      return false;
    }
    return int.parse(s, onError: (e) => null) != null;
  }

  @override
  void dispose() {
    sockets.unRegister(_onWsMsg);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          strings.get("CREATE_CONTEST"),
        ),
      ),
      body: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: LeagueCard(
                    widget.league,
                    clickable: false,
                  ),
                ),
              ),
            ],
          ),
          Divider(
            height: 2.0,
            color: Colors.black12,
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                children: <Widget>[
                  ListTile(
                    leading: TextFormField(
                      decoration: InputDecoration(
                        labelText: strings.get("CONTEST_NAME"),
                      ),
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  ListTile(
                    leading: Row(
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: Text(
                            strings.get("TYPE"),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: ContestTypeRadio(
                            defaultValue:
                                allowedContestType.indexOf(2) == -1 ? 1 : 2,
                            allowedContestType: allowedContestType,
                            onValueChanged: (int value) {
                              _prizeType = value;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: strings.get("ENTRY_FEE"),
                        hintText: '1 - 10,000',
                        prefix: Padding(
                          padding: const EdgeInsets.only(left: 2.0, right: 4.0),
                          child: Text(strings.rupee),
                        ),
                      ),
                      controller: _entryFeeController,
                      validator: (value) {
                        if (isNumeric(value)) {
                          final int entryFee = int.parse(value);
                          if (value.isEmpty ||
                              entryFee <= 0 ||
                              entryFee > 10000) {
                            return strings.get("ENTRY_FEE_LIMIT");
                          }
                        } else {
                          return strings.get("ENTRY_FEE_NUMBER_ERROR");
                        }
                      },
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  ListTile(
                    leading: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: strings.get("PARTICIPANTS"),
                        hintText: '2-100',
                      ),
                      controller: _participantsController,
                      validator: (value) {
                        if (isNumeric(value)) {
                          final int noOfParticipants = int.parse(value);
                          if (value.isEmpty ||
                              noOfParticipants <= 1 ||
                              noOfParticipants > 100) {
                            return strings.get("PARTICIPANTS_LIMIT");
                          }
                        } else {
                          return strings.get("PARTICIPANTS_NUMBER_ERROR");
                        }
                      },
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  ListTile(
                    leading: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          strings.get("MULTY_ENTRY"),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Switch(
                          onChanged: _bAllowMultiEntryChange
                              ? (bool value) {
                                  setState(() {
                                    _bIsMultyEntry = value;
                                  });
                                }
                              : null,
                          value: _bIsMultyEntry,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                    child: ListTile(
                      leading: Row(
                        children: <Widget>[
                          Expanded(
                            flex: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    width: 1.0, color: Colors.black26),
                              ),
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    color: Theme.of(context).primaryColor,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            strings.get("TOTAL_PRIZE"),
                                            style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: Theme.of(context)
                                                    .primaryTextTheme
                                                    .subhead
                                                    .fontSize),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Align(
                                        alignment: Alignment.center,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(strings.rupee +
                                              " " +
                                              _totalPrize.toString()),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    width: 1.0, color: Colors.black26),
                              ),
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    color: Theme.of(context).primaryColor,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            strings.get("NUMBER_OF_PRIZE"),
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: Theme.of(context)
                                                  .primaryTextTheme
                                                  .subhead
                                                  .fontSize,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Stack(
                                    children: <Widget>[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              _numberOfPrize.toString(),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: <Widget>[
                                          Container(
                                            height: 28.0,
                                            child: IconButton(
                                              padding: EdgeInsets.all(0.0),
                                              icon: Icon(Icons.edit),
                                              iconSize: 16.0,
                                              onPressed: () {
                                                _onEditPrize();
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Tooltip(
                      message: strings.get("CREATE_CONTEST_TOOLTIP"),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 32.0),
                        child: RaisedButton(
                          color: Theme.of(context).primaryColorDark,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.add,
                                color: Colors.white70,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  strings.get("CREATE").toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                          onPressed: () {
                            _onCreateContest();
                          },
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ContestTypeRadio extends StatefulWidget {
  final Function onValueChanged;
  final int defaultValue;
  final List<dynamic> allowedContestType;
  ContestTypeRadio(
      {this.defaultValue, this.onValueChanged, this.allowedContestType});

  @override
  State<StatefulWidget> createState() => ContestTypeRadioState();
}

class ContestTypeRadioState extends State<ContestTypeRadio> {
  int _radioValue;

  @override
  void initState() {
    super.initState();
    _radioValue = widget.defaultValue == null ? 2 : widget.defaultValue;
  }

  _handleRadioValueChange(value) {
    setState(() {
      _radioValue = value;
      widget.onValueChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              Radio(
                value: 2,
                groupValue: _radioValue,
                onChanged: (int value) {
                  if (widget.allowedContestType.indexOf(2) != -1) {
                    _handleRadioValueChange(value);
                  }
                },
              ),
              Text(strings.get("CASH")),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: <Widget>[
              Radio(
                value: 1,
                groupValue: _radioValue,
                onChanged: (int value) {
                  if (widget.allowedContestType.indexOf(1) != -1) {
                    _handleRadioValueChange(value);
                  }
                },
              ),
              Text(strings.get("PRACTICE")),
            ],
          ),
        )
      ],
    );
  }
}
