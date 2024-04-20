import 'package:isar/isar.dart';

part 'habit.g.dart';

@Collection()
class Habit {
  // habit id
  Id id = Isar.autoIncrement;

  // habit name 
late String name;

  // completed days
  List<DateTime> completedDays = [
    // dateTime(year, month, day)
    // dateTime(2024, 4, 1)
  ];
}