import 'package:equatable/equatable.dart';

class PlayerSource extends Equatable {
  const PlayerSource({required this.url, required this.label});

  final String url;

  /// The name shown in the quality picker.
  final String label;

  @override
  List<Object?> get props => [url, label];
}
