import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';

class ContestDetailsCard extends StatelessWidget {
  final League league;
  final Contest contest;
  final Function onJoinContest;
  final Function onShareContest;
  final Function onPrizeStructure;
  final List<MyTeam> contestTeams;
  ContestDetailsCard({
    this.league,
    this.contest,
    this.contestTeams,
    this.onJoinContest,
    this.onShareContest,
    this.onPrizeStructure,
  });

  @override
  Widget build(BuildContext context) {
    bool bIsContestFull =
        (contestTeams != null && contest.teamsAllowed <= contestTeams.length) ||
            contest.size == contest.joined ||
            league.status == LeagueStatus.LIVE ||
            league.status == LeagueStatus.COMPLETED;

    final formatCurrency = NumberFormat.currency(
      locale: "hi_IN",
      symbol: contest.prizeType == 1 ? "" : strings.rupee,
      decimalDigits: 0,
    );

    return Card(
      margin: EdgeInsets.all(12.0),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        children: <Widget>[
                          Text(
                            "Prize pool",
                            style: Theme.of(context)
                                .primaryTextTheme
                                .body1
                                .copyWith(
                                  color: Colors.grey.shade500,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        contest.prizeType == 1
                            ? Image.asset(
                                strings.chips,
                                width: 12.0,
                                height: 12.0,
                                fit: BoxFit.contain,
                              )
                            : Container(),
                        Text(
                          contest.prizeDetails != null
                              ? formatCurrency.format(
                                  contest.prizeDetails[0]["totalPrizeAmount"])
                              : 0.toString(),
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: Theme.of(context)
                                .primaryTextTheme
                                .headline
                                .fontSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    if (onPrizeStructure != null) {
                      onPrizeStructure();
                    }
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                "Winners",
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .body1
                                    .copyWith(
                                      color: Colors.grey.shade500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              contest.prizeDetails == null
                                  ? 0.toString()
                                  : contest.prizeDetails[0]["noOfPrizes"]
                                      .toString(),
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: Theme.of(context)
                                    .primaryTextTheme
                                    .title
                                    .fontSize,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        "Entry",
                        style:
                            Theme.of(context).primaryTextTheme.body1.copyWith(
                                  color: Colors.grey.shade500,
                                ),
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        contest.prizeType == 1 && contest.entryFee > 0
                            ? Image.asset(
                                strings.chips,
                                width: 12.0,
                                height: 12.0,
                                fit: BoxFit.contain,
                              )
                            : Container(),
                        Text(
                          contest.entryFee > 0
                              ? formatCurrency.format(contest.entryFee)
                              : "FREE",
                          style: TextStyle(
                            color: Color.fromRGBO(70, 165, 12, 1),
                            fontSize: Theme.of(context)
                                .primaryTextTheme
                                .title
                                .fontSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            league.status == LeagueStatus.COMPLETED
                ? Container()
                : Column(
                    children: <Widget>[
                      Divider(
                        color: Colors.grey.shade400,
                        height: 2.0,
                      ),
                      contest.guaranteed
                          ? Row(
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(
                                      top: 8.0,
                                      bottom: contest.bonusAllowed == 0 &&
                                              contest.teamsAllowed == 1
                                          ? 8.0
                                          : 0.0),
                                  child: Row(
                                    children: <Widget>[
                                      Container(
                                        width: 20.0,
                                        height: 20.0,
                                        child: Text(
                                          "G",
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontSize: Theme.of(context)
                                                .primaryTextTheme
                                                .caption
                                                .fontSize,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(5.0),
                                          border: Border.all(
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(left: 4.0),
                                        child: Text(
                                          "Confirmed Winnings even if contest remains unfilled",
                                          style: Theme.of(context)
                                              .primaryTextTheme
                                              .caption
                                              .copyWith(
                                                color: Colors.black38,
                                                fontSize: Theme.of(context)
                                                    .primaryTextTheme
                                                    .overline
                                                    .fontSize,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            )
                          : Container(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          contest.bonusAllowed == 0
                              ? Container()
                              : Row(
                                  children: <Widget>[
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 8.0),
                                      child: Container(
                                        width: 20.0,
                                        height: 20.0,
                                        child: Text(
                                          "B",
                                          style: Theme.of(context)
                                              .primaryTextTheme
                                              .caption
                                              .copyWith(
                                                color: Colors.blue,
                                              ),
                                        ),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(5.0),
                                          border: Border.all(
                                            color: Colors.blueAccent,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 4.0),
                                      child: Text(
                                        "Entry with bonus amount (" +
                                            contest.bonusAllowed.toString() +
                                            "%)",
                                        style: Theme.of(context)
                                            .primaryTextTheme
                                            .caption
                                            .copyWith(
                                              color: Colors.black38,
                                              fontSize: Theme.of(context)
                                                  .primaryTextTheme
                                                  .overline
                                                  .fontSize,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                          contest.teamsAllowed == 1
                              ? Container()
                              : Expanded(
                                  child: Row(
                                    mainAxisAlignment: contest.bonusAllowed == 0
                                        ? MainAxisAlignment.start
                                        : MainAxisAlignment.end,
                                    children: <Widget>[
                                      Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 8.0),
                                        child: Container(
                                          width: 20.0,
                                          height: 20.0,
                                          child: Text(
                                            "M",
                                            style: Theme.of(context)
                                                .primaryTextTheme
                                                .caption
                                                .copyWith(
                                                  color: Color.fromRGBO(
                                                      70, 165, 12, 1),
                                                ),
                                          ),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(5.0),
                                            border: Border.all(
                                              color: Color.fromRGBO(
                                                  70, 165, 12, 1),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(left: 4.0),
                                        child: Text(
                                          "Join with multiple teams (" +
                                              contest.teamsAllowed.toString() +
                                              ")",
                                          style: Theme.of(context)
                                              .primaryTextTheme
                                              .caption
                                              .copyWith(
                                                color: Colors.black38,
                                                fontSize: Theme.of(context)
                                                    .primaryTextTheme
                                                    .overline
                                                    .fontSize,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ],
                      ),
                      Container(
                        child: league.status == LeagueStatus.UPCOMING
                            ? Column(
                                children: <Widget>[
                                  Padding(
                                    padding: EdgeInsets.only(top: 4.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Container(
                                        color: Colors.black26,
                                        child: Row(
                                          children: <Widget>[
                                            Expanded(
                                              flex: contest.joined,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                                child: Container(
                                                  height: 6.0,
                                                  color: Color.fromRGBO(
                                                      70, 165, 12, 1),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex:
                                                  contest.size - contest.joined,
                                              child: Container(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsets.only(top: 4.0, bottom: 4.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Text(
                                              "Only " +
                                                  (contest.size -
                                                          contest.joined)
                                                      .toString() +
                                                  " seats left",
                                              style: Theme.of(context)
                                                  .primaryTextTheme
                                                  .subhead
                                                  .copyWith(
                                                    color: Colors.grey.shade500,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: <Widget>[
                                            Text(
                                              contest.size.toString(),
                                              style: TextStyle(
                                                color: Colors.black38,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            Text(
                                              " seats",
                                              style: Theme.of(context)
                                                  .primaryTextTheme
                                                  .subhead
                                                  .copyWith(
                                                    color: Colors.grey.shade500,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: <Widget>[
                                  Padding(
                                    padding: EdgeInsets.only(top: 4.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Container(
                                        color: Colors.black26,
                                        child: Row(
                                          children: <Widget>[
                                            Expanded(
                                              flex: contest.joined,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                                child: Container(
                                                  height: 6.0,
                                                  color: Color.fromRGBO(
                                                      70, 165, 12, 1),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(top: 4.0),
                                    child: Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            (contest.size - contest.joined)
                                                    .toString() +
                                                " seats",
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .primaryTextTheme
                                                .subhead
                                                .copyWith(
                                                  color: Colors.grey.shade500,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      bIsContestFull
                          ? Container()
                          : Padding(
                              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: ColorButton(
                                      onPressed: bIsContestFull
                                          ? null
                                          : () {
                                              onJoinContest(contest);
                                            },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 12.0),
                                        child: Text(
                                          "Join the contest".toUpperCase(),
                                          style: Theme.of(context)
                                              .primaryTextTheme
                                              .headline
                                              .copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
