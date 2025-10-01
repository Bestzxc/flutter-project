import 'courseModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseHelperCourse {
  final CollectionReference collection =
      FirebaseFirestore.instance.collection(CourseModel.collectionName);

  Stream<QuerySnapshot> getStreamCourses() {
    return collection.snapshots();
  }
}

class DatabaseHelperTeachCourse {
  final CollectionReference collection =
      FirebaseFirestore.instance.collection('teachCourses');

  Stream<QuerySnapshot> getStreamCourses() {
    return collection.snapshots();
  }

  Stream<QuerySnapshot> getStreamCoursesByTeacher(String teacherId) {
    return collection.where('teacherId', isEqualTo: teacherId).snapshots();
  }

  Future<void> addCourse({
    required String category,
    required String subject,
    required double price,
    required String teacherName,
    required String teacherId,
    required int quota,
  }) async {
    await collection.add({
      'category': category,
      'subject': subject,
      'price': price,
      'teacherName': teacherName,
      'teacherId': teacherId,
      'quota': quota,
      'enrolledStudents': [teacherId],
    });
  }
}
