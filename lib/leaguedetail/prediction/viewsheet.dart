import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:playfantasy/leaguedetail/prediction/createsheet.dart';
import 'package:playfantasy/leaguedetail/prediction/predictionsummarywidget.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/mysheet.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/modal/prediction.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';

const double TEAM_LOGO_HEIGHT = 24.0;

class ViewSheet extends StatefulWidget {
  final MySheet sheet;
  final League league;
  final Contest contest;
  final List<MySheet> mySheet;
  final Prediction predictionData;

  ViewSheet({
    this.sheet,
    this.league,
    this.mySheet,
    this.contest,
    this.predictionData,
  });

  @override
  ViewSheetState createState() => ViewSheetState();
}

class ViewSheetState extends State<ViewSheet> {
  Prediction predictionData;
  Map<String, dynamic> l1UpdatePackate = {};
  MyTeam _myTeamWithPlayers = MyTeam.fromJson({});
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    sockets.register(_onWsMsg);
    if (widget.predictionData == null) {
      _createL1WSObject();
    } else {
      predictionData = widget.predictionData;
    }
  }

  _createL1WSObject() async {
    l1UpdatePackate["bResAvail"] = true;
    l1UpdatePackate["withPrediction"] = true;
    l1UpdatePackate["id"] = widget.league.leagueId;
    l1UpdatePackate["iType"] = RequestType.GET_ALL_L1;
    l1UpdatePackate["sportsId"] = widget.league.teamA.sportType;
    _getL1Data();
  }

  _onWsMsg(onData) {
    Map<String, dynamic> _response = json.decode(onData);

    if (_response["bReady"] == 1) {
      // _showLoader(true);
      _getL1Data();
    } else if (_response["iType"] == RequestType.GET_ALL_L1 &&
        _response["bSuccessful"] == true) {
      setState(() {
        if (_response["data"]["prediction"] != null) {
          predictionData = Prediction.fromJson(_response["data"]["prediction"]);
        }
      });
    }
  }

  _getL1Data() {
    // _showLoader(true);
    sockets.sendMessage(l1UpdatePackate);
  }

  void _onEditSheet(BuildContext context) async {
    final result = await Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => CreateSheet(
              league: widget.league,
              selectedSheet: widget.sheet,
              mode: SheetCreationMode.EDIT_SHEET,
              predictionData: widget.predictionData,
            ),
      ),
    );

    if (result != null) {
      _scaffoldKey.currentState
          .showSnackBar(SnackBar(content: Text("$result")));
    }
  }

  void _onCloneSheet(BuildContext context) async {
    final result = await Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => CreateSheet(
              league: widget.league,
              selectedSheet: widget.sheet,
              mode: SheetCreationMode.CLONE_SHEET,
              predictionData: widget.predictionData,
            ),
      ),
    );
    if (result != null) {
      _scaffoldKey.currentState
          .showSnackBar(SnackBar(content: Text("$result")));
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<int, int> mapAnswers = {};
    int maxQuestionRules = 0;
    Quiz quiz =
        predictionData == null ? null : predictionData.quizSet.quiz["0"];
    if (quiz != null) {
      List<int>.generate(widget.sheet.answers.length, (index) {
        if (widget.sheet.answers[index] != -1) {
          mapAnswers[index] = widget.sheet.answers[index];
        }
      });
      maxQuestionRules =
          quiz.questions.length < predictionData.rules["0"]["qcount"]
              ? quiz.questions.length
              : predictionData.rules["0"]["qcount"];
    }
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.sheet.name),
        actions: <Widget>[
          widget.league.status == LeagueStatus.UPCOMING
              ? IconButton(
                  icon: Icon(Icons.content_copy),
                  onPressed: () {
                    _onCloneSheet(context);
                  },
                )
              : Container(),
          widget.league.status == LeagueStatus.UPCOMING
              ? IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    _onEditSheet(context);
                  },
                )
              : Container(),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: widget.league.status != LeagueStatus.UPCOMING
              ? EdgeInsets.only(bottom: 64.0)
              : EdgeInsets.only(),
          child: Card(
            elevation: 3.0,
            margin: EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                Container(
                  color: Colors.black.withAlpha(10),
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Prediction Summary",
                        style:
                            Theme.of(context).primaryTextTheme.subhead.copyWith(
                                  color: Colors.black54,
                                ),
                      ),
                      Text(
                        mapAnswers.keys.length.toString() +
                            "/" +
                            maxQuestionRules.toString(),
                        style:
                            Theme.of(context).primaryTextTheme.subhead.copyWith(
                                  color: Colors.black54,
                                ),
                      )
                    ],
                  ),
                ),
                PredictionSummaryWidget(
                  answers: mapAnswers,
                  xBooster: widget.sheet.boosterOne,
                  bPlusBooster: widget.sheet.boosterTwo,
                  predictionData: widget.predictionData,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomSheet: widget.league.status == LeagueStatus.LIVE
          ? Container(
              height: 64.0,
              color: Theme.of(context).primaryColorDark,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                "Rank",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: Theme.of(context)
                                        .primaryTextTheme
                                        .title
                                        .fontSize),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "Score",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: Theme.of(context)
                                        .primaryTextTheme
                                        .title
                                        .fontSize),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                _myTeamWithPlayers.rank.toString(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: Theme.of(context)
                                        .primaryTextTheme
                                        .title
                                        .fontSize),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _myTeamWithPlayers.score.toString(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: Theme.of(context)
                                        .primaryTextTheme
                                        .title
                                        .fontSize),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : widget.league.status == LeagueStatus.COMPLETED
              ? Container(
                  height: 64.0,
                  color: Theme.of(context).primaryColorDark,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "WINNINGS - ",
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: Theme.of(context)
                                .primaryTextTheme
                                .title
                                .fontSize),
                      ),
                      widget.contest.prizeType == 1
                          ? Image.asset(
                              strings.chips,
                              width: 16.0,
                              height: 12.0,
                              fit: BoxFit.contain,
                            )
                          : Text(
                              strings.rupee,
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: Theme.of(context)
                                      .primaryTextTheme
                                      .title
                                      .fontSize),
                            ),
                      Text(
                        _myTeamWithPlayers.prize.toStringAsFixed(2),
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: Theme.of(context)
                                .primaryTextTheme
                                .title
                                .fontSize),
                      )
                    ],
                  ),
                )
              : Container(
                  height: 0.0,
                ),
    );
  }

  @override
  void dispose() {
    sockets.unRegister(_onWsMsg);
    super.dispose();
  }
}
