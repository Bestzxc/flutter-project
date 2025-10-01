import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String profileImage;
  final String name;
  final String email;
  final bool isTutor;
  final List<Map<String, dynamic>>? subjects;
  final List<String>? categories;
  final List<String> enrolledCourses;
  final String? referenceId;

  static const String collectionName = 'users';

  UserModel({
    required this.profileImage,
    required this.name,
    required this.email,
    required this.isTutor,
    this.subjects,
    this.categories,
    this.enrolledCourses = const [],
    this.referenceId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return UserModel(
      profileImage: json['profileImage'],
      name: json['name'],
      email: json['email'],
      isTutor: json['isTutor'] ?? false,
      subjects: (json['subjects'] != null)
          ? List<Map<String, dynamic>>.from(json['subjects'])
          : null,
      categories: (json['categories'] != null)
          ? List<String>.from(json['categories'])
          : null,
      enrolledCourses: (json['enrolledCourses'] != null)
          ? List<String>.from(json['enrolledCourses'])
          : [],
      referenceId: id,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profileImage': profileImage,
      'name': name,
      'email': email,
      'isTutor': isTutor,
      'subjects': subjects,
      'categories': categories,
      'enrolledCourses': enrolledCourses,
    };
  }
}
/////////////////////////////////////////////////////////////////////////////////

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      print("Login error: $e");
      return false;
    }
  }

  Future<bool> registerWithAvatar(
    String name,
    String email,
    String password,
    String avatarPath,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user == null) return false;
      UserModel newUser = UserModel(
        profileImage: avatarPath,
        name: name,
        email: email,
        isTutor: false,
        subjects: null,
        categories: null,
        enrolledCourses: [],
      );

      await FirebaseFirestore.instance
          .collection(UserModel.collectionName)
          .doc(user.uid)
          .set(newUser.toJson());

      return true;
    } catch (e) {
      print("Register error: $e");
      return false;
    }
  }
}


