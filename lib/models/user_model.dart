class AppUser {
  final String uid;
  final String email;
  final String name;
  final String role; // 'blind' or 'caretaker'
  final String? caretakerId; // only for blind users
  final List<String>? blindUserIds; // only for caretakers

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.caretakerId,
    this.blindUserIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      if (caretakerId != null) 'caretakerId': caretakerId,
      if (blindUserIds != null) 'blindUserIds': blindUserIds,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'],
      email: map['email'],
      name: map['name'] ?? '',
      role: map['role'],
      caretakerId: map['caretakerId'],
      blindUserIds: map['blindUserIds'] != null 
          ? List<String>.from(map['blindUserIds']) 
          : null,
    );
  }
}
