class EmployeeModel {
  int? id;
  String name;
  String profileImagePath;
  List<String> calibrationImages;
  DateTime createdAt;

  EmployeeModel({
    this.id,
    required this.name,
    required this.profileImagePath,
    required this.calibrationImages,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'profileImagePath': profileImagePath,
      'calibrationImages': calibrationImages.join(','),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EmployeeModel.fromMap(Map<String, dynamic> map) {
    return EmployeeModel(
      id: map['id'],
      name: map['name'],
      profileImagePath: map['profileImagePath'],
      calibrationImages: (map['calibrationImages'] as String).split(','), // نرجعهم كـ List
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  @override
  String toString() {
    return 'Employee(id: $id, name: $name, profileImage: $profileImagePath, calibrationImages: ${calibrationImages.length})';
  }

  EmployeeModel copyWith({
    int? id,
    String? name,
    String? profileImagePath,
    List<String>? calibrationImages,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      calibrationImages: calibrationImages ?? this.calibrationImages,
    );
  }
}