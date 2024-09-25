
class Goal {
  String name;
  DateTime date;
  bool visibility;
  List<String> tasks;

  Goal({
    required this.name,
    required this.date,
    required this.visibility,
    required this.tasks,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'date': date.toIso8601String(),
        'visibility': visibility,
        'tasks': tasks,
      };

  static Goal fromJson(Map<String, dynamic> json) => Goal(
        name: json['name'],
        date: DateTime.parse(json['date']),
        visibility: json['visibility'],
        tasks: List<String>.from(json['tasks']),
      );
}

