import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'authentication.dart';
import 'chatroom.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthenticationService.currentUserID;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const Center(child: CircularProgressIndicator());
        final userData = userSnap.data!.data() as Map<String, dynamic>;
        final isTutor = userData['isTutor'] ?? false;
        final query = isTutor
            ? FirebaseFirestore.instance
                .collection('teachCourses')
                .where('teacherId', isEqualTo: currentUserId)
            : FirebaseFirestore.instance
                .collection('teachCourses')
                .where('enrolledStudents', arrayContains: currentUserId);

        return StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, courseSnap) {
            if (!courseSnap.hasData) return const Center(child: CircularProgressIndicator());
            if (courseSnap.data!.docs.isEmpty) {
              return Center(
                  child: Text(isTutor
                      ? "ยังไม่มีนักเรียนสมัครคอร์สของคุณ"
                      : "คุณยังไม่ได้ลงคอร์สเรียน"));
            }

            List<Widget> chatItems = [];

            for (var doc in courseSnap.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final subject = data['subject'] ?? '';
              final category = data['category'] ?? '';

              if (isTutor) {
                final List<dynamic> students = data['enrolledStudents'] ?? [];
                for (var studentId in students) {
                  chatItems.add(_buildChatTile(
                    context: context,
                    otherUserId: studentId,
                    subject: subject,
                    category: category,
                    isTutor: isTutor,
                  ));
                }
              } else {
                final teacherId = data['teacherId'];
                chatItems.add(_buildChatTile(
                  context: context,
                  otherUserId: teacherId,
                  subject: subject,
                  category: category,
                  isTutor: isTutor,
                ));
              }
            }

            return ListView(children: chatItems);
          },
        );
      },
    );
  }

  Widget _buildChatTile({
    required BuildContext context,
    required String otherUserId,
    required String subject,
    required String category,
    required bool isTutor,
  }) {
    return Column(
      children: [
        SizedBox(height: 10,),
        FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage(userData['profileImage']),
              ),
              title: Text(userData['name']),
              subtitle: Text("หมวด: $category | วิชา: $subject"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                final currentUserId = AuthenticationService.currentUserID;
                final chatId = isTutor
                    ? "${currentUserId}_$otherUserId"
                    : "${otherUserId}_$currentUserId";
        
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatRoomPage(
                      chatId: chatId,
                      otherUserId: otherUserId,
                      otherUserName: userData['name'],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
