import 'package:flutter/material.dart';
import 'package:habit_tracker/models/app_settings.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class HabitDatabase extends ChangeNotifier {
  static late Isar isar;
  // INITIALIZATION
  // Initialize the database
  static Future<void> initialize() async {
    final dir = await getApplicationCacheDirectory();
    isar =
        await Isar.open([HabitSchema, AppSettingSchema], directory: dir.path);
  }

  // Save first date of app startup (for heatmap)
  Future<void> saveFirstLaunchDate() async {
    final existingSetting = await isar.appSettings.where().findFirst();
    if (existingSetting == null) {
      final settings = AppSetting()..firstLaunchDate = DateTime.now();
      await isar.writeTxn(() => isar.appSettings.put(settings));
    }
  }

  // Get First date of app startup (for heatmap)
  Future<DateTime?> getFirstLaunchDate() async {
    final settings = await isar.appSettings.where().findFirst();
    return settings?.firstLaunchDate;
  }

  // CRUD Operations
  final List<Habit> currentHabits = [];

  // Create a new habit
  Future<void> addHabit(String habitName) async {
    final newHabit = Habit()..name = habitName;
    await isar.writeTxn(() => isar.habits.put(newHabit));
    await readHabits();
  }

  // Read Habit
  Future<void> readHabits() async {
    final List<Habit> habits = await isar.habits.where().findAll();
    currentHabits.clear();
    currentHabits.addAll(habits);

    // update ui
    notifyListeners();
  }

  // Update Habit Completion
  Future<void> updateHabitCompletion(int id, bool isCompleted) async {
    final habit = await isar.habits.get(id);

    if (habit != null) {
      await isar.writeTxn(() async {
        // if habit is completed -> add the current date to the completeDays list
        if (isCompleted && !habit.completedDays.contains(DateTime.now())) {
          // today
          final today = DateTime.now();
          habit.completedDays.add(DateTime(today.year, today.month, today.day));
        }
        // if habit is not completed -> remote the current date from the list
        else {
          // remove the current date if the habit is market as not completed
          habit.completedDays.removeWhere(
            (date) =>
                date.year == DateTime.now().year &&
                date.month == DateTime.now().month &&
                date.day == DateTime.now().day,
          );
        }
        // save the updated habits back to the db
        await isar.habits.put(habit);
      });
    }
    // read read databse
    await readHabits();
  }

  // edit habit name
  Future<void> updateHabitName(int id, String newName)async {
    final habit = await isar.habits.get(id);

    // update habit name
    if(habit != null ){
      await isar.writeTxn(() async {
        habit.name = newName;
        await isar.habits.put(habit);
      });
    }
    // re-read from db
    readHabits();
  }

  // Delete habit
  Future<void> deleteHabit(int id) async {
    await isar.writeTxn(()async {
      await isar.habits.delete(id);
    });
  }
}
