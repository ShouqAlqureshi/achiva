class UserModel {
  late String fname;
  late String lname;
  late String email;
  late String gender;
  late String id; // TODO: get it from login or signUp
  late String? photo;
  late String phoneNumber;
/*
  int streak = 0;
  int productivity = 0;
*/

  UserModel({
    required this.id,
    required this.fname,
    required this.lname,
    required this.email,
    required this.gender,
    required this.photo,
    required this.phoneNumber,
/*    required this.streak,
    required this.productivity,*/
  });

  factory UserModel.fromJson({required Map<String, dynamic> json}) => UserModel(
      id: json['id'],
      fname: json['fname'],
      lname: json['lname'],
      email: json['email'],
      gender: json['gender'],
      photo: json['photo'],
      phoneNumber: json['phoneNumber'],
/*      streak: json['streak'],
      productivity: json['productivity']*/);

  Map<String, dynamic> toJson() => {
        "id": id,
        "fname": fname,
        "lname": lname,
        "email": email,
        "gender": gender,
        "photo": photo,
        "phoneNumber": phoneNumber,
/*        "streak": streak,
        "productivity": productivity,*/
      };
}
