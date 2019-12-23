import 'package:flutter/foundation.dart';

class User extends ChangeNotifier {
  int userId;
  String mobile;
  String emailId;
  bool isNewUser;
  String userName;
  bool isEmailVerified;
  bool isMobileVerified;
  double withdrawable;
  double nonWithdrawable;
  double depositedAmount;
  double playableBonus;
  double bonusBalance;

  User({
    this.userId,
    this.mobile,
    this.emailId,
    this.userName,
    this.isNewUser,
    this.isEmailVerified,
    this.isMobileVerified,
    this.withdrawable = 0.0,
    this.depositedAmount = 0.0,
    this.nonWithdrawable = 0.0,
    this.playableBonus = 0.0,
    this.bonusBalance = 0.0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json["user_id"],
      mobile: json["mobile"],
      emailId: json["email_id"],
      userName: json["login_name"],
      isNewUser: json["isNewUser"],
      isMobileVerified: json["mobile_marked_verified"],
      isEmailVerified: json["verificationStatus"] == null
          ? null
          : json["verificationStatus"]["email_verification"] == true,
      withdrawable: json["withdrawable"],
      depositedAmount: json["depositBucket"],
      nonWithdrawable: json["nonWithdrawable"],
      playableBonus: json["playableBonus"],
    );
  }

  setUserFromJson(Map<String, dynamic> json) {
    this.userId = json["user_id"];
    this.mobile = json["mobile"];
    this.emailId = json["email_id"];
    this.userName = json["login_name"];
    this.isNewUser = json["isNewUser"];
    this.isMobileVerified = json["mobile_marked_verified"];
    this.isEmailVerified = json["verificationStatus"] == null
        ? null
        : (json["verificationStatus"]["email_verification"] == true);
    this.withdrawable = json["withdrawable"] == null
        ? 0.0
        : double.tryParse(json["withdrawable"].toString());
    this.depositedAmount = json["depositBucket"] == null
        ? 0.0
        : double.tryParse(json["depositBucket"].toString());
    this.nonWithdrawable = json["nonWithdrawable"] == null
        ? 0.0
        : double.tryParse(json["nonWithdrawable"].toString());

    notifyListeners();
  }

  updateWithdrawable(double amount) {
    this.withdrawable = amount;

    notifyListeners();
  }

  updateDepositBucket(double amount) {
    this.depositedAmount = amount;

    notifyListeners();
  }

  updatePlayableBonus(double bonus) {
    this.playableBonus = bonus;

    notifyListeners();
  }

  updateBonus(double bonus) {
    this.bonusBalance = bonus;

    notifyListeners();
  }
}
