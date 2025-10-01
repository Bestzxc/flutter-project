import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'authentication.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;

  const ChatRoomPage({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _controller = TextEditingController();

  /// ดึง profileImage ของผู้ใช้จาก Firestore
  Future<String> getProfileImage(String userId) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists) {
      final data = doc.data()!;
      return data['profileImage'] ?? 'assets/profiles/default.png';
    }
    return 'assets/profiles/default.png';
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthenticationService.currentUserID;

    return Scaffold(
      backgroundColor: const Color(0xFFFFCD9E),
      appBar: AppBar(
        title: Text(
          "Chat with ${widget.otherUserName}",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.brown,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('chats')
                      .doc(widget.chatId)
                      .collection('messages')
                      .orderBy('timestamp')
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;

                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children:
                      docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final isMe = data['senderId'] == currentUserId;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment:
                                isMe
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                            children: [
                              // ถ้าไม่ใช่ตัวเอง ให้แสดง Avatar ของอีกฝ่าย
                              if (!isMe)
                                FutureBuilder<String>(
                                  future: getProfileImage(data['senderId']),
                                  builder: (context, snapshotImage) {
                                    final imagePath =
                                        snapshotImage.data ??
                                        'assets/profiles/default.png';
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: CircleAvatar(
                                        radius: 20,
                                        backgroundImage: AssetImage(imagePath),
                                      ),
                                    );
                                  },
                                ),
                              // ข้อความ
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      isMe
                                          ? Colors.brown[200]
                                          : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(data['text'] ?? ''),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                );
              },
            ),
          ),
          const Divider(color: Colors.brown),
          Padding(
            padding: const EdgeInsets.all(5),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'พิมพ์ข้อความ...',
                      contentPadding: EdgeInsets.all(8),
                      fillColor: Colors.white,
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.brown, width: 2),
                      ),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.brown),
                  onPressed: () async {
                    final text = _controller.text.trim();
                    if (text.isEmpty) return;
                    await FirebaseFirestore.instance
                        .collection('chats')
                        .doc(widget.chatId)
                        .collection('messages')
                        .add({
                          'senderId': currentUserId,
                          'text': text,
                          'timestamp': FieldValue.serverTimestamp(),
                        });
                    _controller.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
