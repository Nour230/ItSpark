class EmployeeModel {
  int? id;
  String name;
  String profileImagePath; // الصورة الأساسية
  List<String> calibrationImages; // الـ 5 صور للتعرف على الوجه
  DateTime createdAt;

  EmployeeModel({
    this.id,
    required this.name,
    required this.profileImagePath,
    required this.calibrationImages,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // تحويل ال Object لـ Map عشان SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'profileImagePath': profileImagePath,
      'calibrationImages': calibrationImages.join(','), // نخزنهم كـ string مفصول بفاصلة
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // تحويل من Map لـ Object
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