import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'registerService.dart';
import 'authentication.dart' as auth;

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  final TextEditingController _nameController = TextEditingController();
  bool _isEditingName = false;
  final userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection(UserModel.collectionName)
              .doc(
                auth.AuthenticationService.currentUserID,
              )
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("ไม่พบข้อมูลผู้ใช้"));
        }

        UserModel user = UserModel.fromJson(
          snapshot.data!.data() as Map<String, dynamic>,
          id: snapshot.data!.id,
        );

        _nameController.text = user.name;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage(user.profileImage),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child:
                        _isEditingName
                            ? Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _nameController,
                                    keyboardType: TextInputType.text,
                                    decoration: const InputDecoration(
                                      hintText: 'ชื่อผู้ใช้',
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.check),
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection(UserModel.collectionName)
                                        .doc(user.referenceId)
                                        .update({'name': _nameController.text});
                                    setState(() {
                                      _isEditingName = false;
                                    });
                                  },
                                ),
                              ],
                            )
                            : Row(
                              children: [
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    setState(() {
                                      _isEditingName = true;
                                    });
                                  },
                                ),
                              ],
                            ),
                  ),
                ],
              ),
              const Divider(height: 32, color: Colors.brown),
              Text(
                "Email: ${user.email}",
                style: const TextStyle(fontSize: 16),
              ),
              const Divider(height: 32, color: Colors.brown),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Status: ${user.isTutor ? "ติวเตอร์" : "นักเรียน"}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      bool? confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text("ยืนยันการเปลี่ยนสถานะ"),
                              content: Text(
                                user.isTutor
                                    ? "คุณต้องการยกเลิกสถานะติวเตอร์หรือไม่?"
                                    : "คุณต้องการสมัครเป็นติวเตอร์หรือไม่?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: const Text("ยกเลิก"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("ตกลง"),
                                ),
                              ],
                            ),
                      );
                      if (confirm == true) {
                        await FirebaseFirestore.instance
                            .collection(UserModel.collectionName)
                            .doc(user.referenceId)
                            .update({'isTutor': !user.isTutor});
                      }
                    },
                    child: Text(
                      user.isTutor ? "ยกเลิกติวเตอร์" : "สมัครเป็นติวเตอร์",
                    ),
                  ),
                ],
              ),
              const Divider(height: 32, color: Colors.brown),
              Text(
                "Enrolled Courses:",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.brown[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('teachCourses')
                        .where('enrolledStudents', arrayContains: userId)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const CircularProgressIndicator();

                  final enrolledDocs = snapshot.data!.docs;

                  if (enrolledDocs.isEmpty)
                    return const Text("ยังไม่มีคอร์สที่เรียน");

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        enrolledDocs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          int enrolledCount =
                              (data['enrolledStudents'] as List<dynamic>?)
                                  ?.length ??
                              0;
                          return ListTile(
                            title: Text(data['subject'] ?? ''),
                            subtitle: Text(
                              "หมวด: ${data['category'] ?? ''} | จำนวนคน: $enrolledCount/${data['quota']}",
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                bool? confirm = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text("ถอนคอร์ส"),
                                        content: Text(
                                          "คุณต้องการถอนคอร์ส '${data['subject'] ?? ''}' หรือไม่?",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                            child: const Text("ยกเลิก"),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                            child: const Text("ตกลง"),
                                          ),
                                        ],
                                      ),
                                );

                                if (confirm == true) {
                                  final userRef = FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(userId);

                                  final courseRef = FirebaseFirestore.instance
                                      .collection('teachCourses')
                                      .doc(doc.id);
                                  await userRef.update({
                                    'enrolledCourses': FieldValue.arrayRemove([
                                      doc.id,
                                    ]),
                                  });
                                  await courseRef.update({
                                    'enrolledStudents': FieldValue.arrayRemove([
                                      userId,
                                    ]),
                                  });
                                }
                              },
                            ),
                          );
                        }).toList(),
                  );
                },
              ),
              const Divider(height: 32, color: Colors.brown),
              if (user.isTutor) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Teaching Courses:",
                      style: TextStyle(fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.brown),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            final TextEditingController subjectController =
                                TextEditingController();
                            final TextEditingController priceController =
                                TextEditingController();
                            final TextEditingController quotaController =
                                TextEditingController();

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
                            String? selectedCategory;

                            return StatefulBuilder(
                              builder: (context, setStateDialog) {
                                return AlertDialog(
                                  title: const Text("สร้างคอร์สใหม่"),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        DropdownButtonFormField<String>(
                                          decoration: const InputDecoration(
                                            labelText: "หมวดวิชา",
                                          ),
                                          value: selectedCategory,
                                          items:
                                              categories.map((cat) {
                                                return DropdownMenuItem(
                                                  value: cat,
                                                  child: Text(cat),
                                                );
                                              }).toList(),
                                          onChanged: (value) {
                                            setStateDialog(() {
                                              selectedCategory = value;
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: subjectController,
                                          decoration: const InputDecoration(
                                            labelText: "หัวข้อคอร์ส",
                                          ),
                                        ),
                                        TextField(
                                          controller: priceController,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: "ราคา",
                                          ),
                                        ),
                                        TextField(
                                          controller: quotaController,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: "จำนวนคนที่ลงได้",
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(dialogContext),
                                      child: const Text("ยกเลิก"),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        if (selectedCategory == null ||
                                            subjectController.text.isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "กรุณาเลือกหมวดวิชาและกรอกหัวข้อคอร์ส",
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        int quota =
                                            int.tryParse(
                                              quotaController.text,
                                            ) ??
                                            0;
                                        await FirebaseFirestore.instance
                                            .collection('teachCourses')
                                            .add({
                                              'category': selectedCategory,
                                              'subject': subjectController.text,
                                              'price':
                                                  double.tryParse(
                                                    priceController.text,
                                                  ) ??
                                                  0,
                                              'teacherName': user.name,
                                              'teacherId': user.referenceId,
                                              'quota': quota,
                                              'enrolledStudents': [],
                                            });

                                        Navigator.pop(dialogContext);
                                      },
                                      child: const Text("สร้าง"),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('teachCourses')
                          .where('teacherId', isEqualTo: user.referenceId)
                          .snapshots(),
                  builder: (context, courseSnap) {
                    if (!courseSnap.hasData || courseSnap.data!.docs.isEmpty) {
                      return const Text("ยังไม่มีคอร์สที่เปิดสอน");
                    }

                    return Column(
                      children:
                          courseSnap.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;

                            return ListTile(
                              title: Text(data['subject'] ?? ''),
                              subtitle: Text(
                                "${data['category'] ?? ''} | ราคา: ${data['price'] ?? 0} | "
                                "จำนวนคน: ${data['enrolledStudents'].length}/${data['quota']}",
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.brown,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext dialogContext) {
                                          final TextEditingController
                                          subjectController =
                                              TextEditingController(
                                                text: data['subject'],
                                              );
                                          final TextEditingController
                                          priceController =
                                              TextEditingController(
                                                text: data['price'].toString(),
                                              );
                                          final TextEditingController
                                          quotaController =
                                              TextEditingController(
                                                text: data['quota'].toString(),
                                              );

                                          String? selectedCategory =
                                              data['category'];
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
                                          return StatefulBuilder(
                                            builder: (context, setStateDialog) {
                                              return AlertDialog(
                                                title: const Text("แก้ไขคอร์ส"),
                                                content: SingleChildScrollView(
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      DropdownButtonFormField<
                                                        String
                                                      >(
                                                        decoration:
                                                            const InputDecoration(
                                                              labelText:
                                                                  "หมวดวิชา",
                                                            ),
                                                        value: selectedCategory,
                                                        items:
                                                            categories.map((
                                                              cat,
                                                            ) {
                                                              return DropdownMenuItem(
                                                                value: cat,
                                                                child: Text(
                                                                  cat,
                                                                ),
                                                              );
                                                            }).toList(),
                                                        onChanged: (value) {
                                                          setStateDialog(() {
                                                            selectedCategory =
                                                                value;
                                                          });
                                                        },
                                                      ),
                                                      const SizedBox(height: 8),
                                                      TextField(
                                                        controller:
                                                            subjectController,
                                                        decoration:
                                                            const InputDecoration(
                                                              labelText:
                                                                  "หัวข้อคอร์ส",
                                                            ),
                                                      ),
                                                      TextField(
                                                        controller:
                                                            priceController,
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        decoration:
                                                            const InputDecoration(
                                                              labelText: "ราคา",
                                                            ),
                                                      ),
                                                      TextField(
                                                        controller:
                                                            quotaController,
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        decoration:
                                                            const InputDecoration(
                                                              labelText:
                                                                  "จำนวนคนที่ลงได้",
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          dialogContext,
                                                        ),
                                                    child: const Text("ยกเลิก"),
                                                  ),
                                                  TextButton(
                                                    onPressed: () async {
                                                      if (selectedCategory ==
                                                              null ||
                                                          subjectController
                                                              .text
                                                              .isEmpty) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              "กรุณากรอกข้อมูลให้ครบถ้วน",
                                                            ),
                                                          ),
                                                        );
                                                        return;
                                                      }
                                                      int quota =
                                                          int.tryParse(
                                                            quotaController
                                                                .text,
                                                          ) ??
                                                          0;
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection(
                                                            'teachCourses',
                                                          )
                                                          .doc(doc.id)
                                                          .update({
                                                            'category':
                                                                selectedCategory,
                                                            'subject':
                                                                subjectController
                                                                    .text,
                                                            'price':
                                                                double.tryParse(
                                                                  priceController
                                                                      .text,
                                                                ) ??
                                                                0,
                                                            'quota': quota,
                                                          });

                                                      Navigator.pop(
                                                        dialogContext,
                                                      );
                                                    },
                                                    child: const Text("บันทึก"),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      bool?
                                      confirmDelete = await showDialog<bool>(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              title: const Text("ลบคอร์ส"),
                                              content: const Text(
                                                "คุณต้องการลบคอร์สนี้หรือไม่?",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text("ยกเลิก"),
                                                ),
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: const Text("ลบ"),
                                                ),
                                              ],
                                            ),
                                      );
                                      if (confirmDelete == true) {
                                        await FirebaseFirestore.instance
                                            .collection('teachCourses')
                                            .doc(doc.id)
                                            .delete();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    );
                  },
                ),

                const Divider(height: 32, color: Colors.brown),
              ],
            ],
          ),
        );
      },
    );
  }
}
