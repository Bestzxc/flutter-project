import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClassPage extends StatefulWidget {
  const ClassPage({super.key});

  @override
  State<ClassPage> createState() => _ClassPageState();
}

class _ClassPageState extends State<ClassPage> {
  final TextEditingController _searchController = TextEditingController();
  String? selectedCategory;
  List<String> categories = [
    'คณิตศาสตร์',
    'วิทยาศาสตร์',
    'ภาษาอังกฤษ',
    'ภาษาไทย',
    'ประวัติศาสตร์',
    'สังคมศึกษา',
    'ศิลปะ',
    'คอมพิวเตอร์',
  ];

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'หมวดวิชา',
              border: const OutlineInputBorder(),
              fillColor: Colors.white,
              filled: true,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.brown, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),

              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: const Color.fromARGB(255, 81, 49, 0),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            value: selectedCategory,
            items:
                categories
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
            onChanged: (value) {
              setState(() {
                selectedCategory = value;
              });
            },
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _searchController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              labelText: 'ค้นหาชื่อคอร์ส',
              border: const OutlineInputBorder(),
              fillColor: Colors.white,
              filled: true,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.brown, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: const Color.fromARGB(255, 81, 49, 0),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            onChanged: (_) {
              setState(() {});
            },
          ),
          const SizedBox(height: 35),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('teachCourses')
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                final filtered =
                    docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final subject = data['subject'] ?? '';
                      final category = data['category'] ?? '';
                      final matchesCategory =
                          selectedCategory == null ||
                          category == selectedCategory;
                      final matchesSearch =
                          _searchController.text.isEmpty ||
                          subject.toLowerCase().contains(
                            _searchController.text.toLowerCase(),
                          );
                      return matchesCategory && matchesSearch;
                    }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('ไม่พบคอร์สที่ค้นหา'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final data = filtered[index].data() as Map<String, dynamic>;
                    final docId = filtered[index].id;
                    final quota = data['quota'] ?? 0;
                    final enrolledStudents = List<String>.from(
                      data['enrolledStudents'] ?? [],
                    );
                    final teacherId = data['teacherId'] ?? '';
                    final isEnrolled =
                        enrolledStudents.contains(userId) ||
                        teacherId == userId;
                    final enrolledCountDisplay = enrolledStudents.length;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(data['subject'] ?? ''),
                        subtitle: Text(
                          'หมวด: ${data['category'] ?? ''} | รับ: $enrolledCountDisplay/$quota \n'
                          'ผู้สอน: ${data['teacherName'] ?? ''} | ราคา: ${data['price'] ?? 0} บาท',
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown,
                            foregroundColor: Colors.white,
                          ),
                          onPressed:
                              (enrolledCountDisplay >= quota || isEnrolled)
                                  ? null
                                  : () async {
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('teachCourses')
                                          .doc(docId)
                                          .update({
                                            'enrolledStudents':
                                                FieldValue.arrayUnion([userId]),
                                          });

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('สมัครเรียนสำเร็จ'),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('เกิดข้อผิดพลาด: $e'),
                                        ),
                                      );
                                    }
                                  },
                          child: Text(
                            teacherId == userId
                                ? 'คอร์สของคุณ'
                                : isEnrolled
                                ? 'สมัครแล้ว'
                                : enrolledCountDisplay >= quota
                                ? 'เต็มแล้ว'
                                : 'สมัครเรียน',
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
