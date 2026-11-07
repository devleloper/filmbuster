import 'package:equatable/equatable.dart';

class TmdbPersonDetails extends Equatable {
  const TmdbPersonDetails({
    required this.id,
    required this.name,
    this.profilePath,
    this.biography,
    this.knownForDepartment,
  });

  final int id;
  final String name;
  final String? profilePath;
  final String? biography;
  final String? knownForDepartment;

  factory TmdbPersonDetails.fromJson(Map<String, dynamic> json) {
    return TmdbPersonDetails(
      id: json['id'] as int,
      name: json['name'] as String,
      profilePath: json['profilePath'] as String?,
      biography: json['biography'] as String?,
      knownForDepartment: json['knownForDepartment'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    profilePath,
    biography,
    knownForDepartment,
  ];
}
