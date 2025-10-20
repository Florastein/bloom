import 'package:hive/hive.dart';

part 'user.g.dart'; // <-- This tells Hive to generate this file

@HiveType(typeId: 1)
class User extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String ageRange;

  @HiveField(2)
  String gender;

  @HiveField(3)
  String about;

  User({
    required this.name,
    required this.ageRange,
    required this.gender,
    required this.about,
  });
}
