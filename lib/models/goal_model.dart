class GoalModel {
  late String name;
  late DateTime date;
  late int tasksNum;
  late int progress;
  late bool visibility;

  GoalModel({required this.name,required this.date,required this.tasksNum,required this.progress,required this.visibility,});

  factory GoalModel.fromJson({required Map<String,dynamic> json})=> GoalModel(name: json['name'],date: DateTime.parse(json['date']),tasksNum: json['notasks'],progress: json['progress'].toInt(),visibility: json['visibility']);

  Map<String,dynamic> toJson()=> {
    "name" : name,
    "notasks" : tasksNum,
    "progress" : progress,
    "visibility" : visibility,
    "date" : date,
  };

}