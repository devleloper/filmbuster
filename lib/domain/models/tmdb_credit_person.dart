import 'package:equatable/equatable.dart';

/// A cast or crew credit.
class TmdbCreditPerson extends Equatable {
  const TmdbCreditPerson({
    required this.id,
    required this.name,
    this.profilePath,
    this.character,
    this.job,
    this.department,
  });

  final int id;
  final String name;
  final String? profilePath;
  final String? character;
  final String? job;
  final String? department;

  factory TmdbCreditPerson.fromJson(Map<String, dynamic> json) {
    return TmdbCreditPerson(
      id: json['id'] as int,
      name: json['name'] as String,
      profilePath: json['profilePath'] as String?,
      character: json['character'] as String?,
      job: json['job'] as String?,
      department: json['department'] as String?,
    );
  }

  /// The character for cast, the job for crew.
  String get role => character ?? job ?? '';

  @override
  List<Object?> get props => [
    id,
    name,
    profilePath,
    character,
    job,
    department,
  ];
}
