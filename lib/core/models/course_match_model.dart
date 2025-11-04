import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'course_match_model.g.dart';

@JsonSerializable()
class CourseMatchModel extends Equatable {
  final String id;
  final UserModel matchedUser;
  final List<String> commonCourses;
  final double compatibilityScore;
  final String status; // 'pending', 'accepted', 'declined'
  final DateTime createdAt;

  const CourseMatchModel({
    required this.id,
    required this.matchedUser,
    required this.commonCourses,
    required this.compatibilityScore,
    required this.status,
    required this.createdAt,
  });

  factory CourseMatchModel.fromJson(Map<String, dynamic> json) =>
      _$CourseMatchModelFromJson(json);

  Map<String, dynamic> toJson() => _$CourseMatchModelToJson(this);

  CourseMatchModel copyWith({
    String? id,
    UserModel? matchedUser,
    List<String>? commonCourses,
    double? compatibilityScore,
    String? status,
    DateTime? createdAt,
  }) {
    return CourseMatchModel(
      id: id ?? this.id,
      matchedUser: matchedUser ?? this.matchedUser,
      commonCourses: commonCourses ?? this.commonCourses,
      compatibilityScore: compatibilityScore ?? this.compatibilityScore,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        matchedUser,
        commonCourses,
        compatibilityScore,
        status,
        createdAt,
      ];
}

@JsonSerializable()
class CourseModel extends Equatable {
  final String id;
  final String code;
  final String name;
  final String department;
  final int credits;
  final String? professor;

  const CourseModel({
    required this.id,
    required this.code,
    required this.name,
    required this.department,
    required this.credits,
    this.professor,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) =>
      _$CourseModelFromJson(json);

  Map<String, dynamic> toJson() => _$CourseModelToJson(this);

  @override
  List<Object?> get props => [id, code, name, department, credits, professor];
}
