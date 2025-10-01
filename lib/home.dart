import 'package:final_project_classup/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'databaseHelper.dart';
import 'courseModel.dart';
import 'registerService.dart';
import 'chat.dart';
import 'class.dart';
import 'more.dart';
import 'authentication.dart' as auth;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<CourseModel> courses = [];
  String appTitle = 'ClassUp';
  Color mainColor = Colors.brown;
  Color bgColor = const Color(0xFFFFCD9E);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          toolbarHeight: 90,
          backgroundColor: mainColor,
          title: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              appTitle,
              style: const TextStyle(fontSize: 40, color: Colors.white),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.white, size: 40),
                onPressed: () async {
                  bool? confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text("ยืนยันการออกจากระบบ"),
                          content: const Text(
                            "คุณต้องการออกจากระบบใช่หรือไม่?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("ยกเลิก"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("ตกลง"),
                            ),
                          ],
                        ),
                  );

                  if (confirm != true) return;

                  try {
                    await auth.AuthenticationService().logout();

                    if (!mounted) return;

                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                      (route) => false,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Logout ล้มเหลว: $e")),
                    );
                  }
                },
              ),
            ),
          ],
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [contentHome(), const ClassPage(), ChatPage(), MorePage()],
        ),
        bottomNavigationBar: Container(
          color: mainColor,
          child: const TabBar(
            labelColor: Colors.white,
            indicator: BoxDecoration(
              color: Color(0xFFA26F4D),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            unselectedLabelColor: Color.fromARGB(255, 195, 195, 195),
            tabs: [
              Tab(icon: Icon(Icons.home_rounded), text: "Home"),
              Tab(icon: Icon(Icons.school), text: "Classes"),
              Tab(icon: Icon(Icons.chat_bubble), text: "Chat"),
              Tab(icon: Icon(Icons.density_medium), text: "More"),
            ],
          ),
        ),
      ),
    );
  }

  Widget contentHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Recommended Courses:',
            style: TextStyle(color: Colors.brown, fontSize: 16),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: StreamBuilder<QuerySnapshot>(
              stream: DatabaseHelperCourse().getStreamCourses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No courses found.'));
                }

                courses.clear();
                for (var doc in snapshot.data!.docs) {
                  courses.add(
                    CourseModel(
                      name: doc.get('name'),
                      image: doc.get('image'),
                      price: (doc.get('price') as num).toDouble(), 
                    ),
                  );
                }

                return CoursesCarousel(courses: courses);
              },
            ),
          ),
          const SizedBox(height: 30),
          StreamBuilder<DocumentSnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection(UserModel.collectionName)
                    .doc(FirebaseAuth.instance.currentUser!.uid)
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

              return profileSection(user);
            },
          ),
        ],
      ),
    );
  }

  Widget profileSection(UserModel user) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage(user.profileImage),
                  backgroundColor: Colors.grey[200],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Divider(height: 32, color: Colors.brown),
            const SizedBox(height: 15),
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
                if (!snapshot.hasData) return const CircularProgressIndicator();

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
                        );
                      }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              "Teaching Courses:",
              style: TextStyle(
                fontSize: 16,
                color: Colors.brown[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            (user.isTutor)
                ? StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('teachCourses')
                          .where('teacherId', isEqualTo: user.referenceId)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text("ยังไม่มีคอร์สที่สอน");
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          snapshot.data!.docs.map((doc) {
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
                            );
                          }).toList(),
                    );
                  },
                )
                : const Text("ยังไม่มีคอร์สที่สอน"),
          ],
        ),
      ),
    );
  }
}

class CoursesCarousel extends StatefulWidget {
  final List<CourseModel> courses;
  const CoursesCarousel({super.key, required this.courses});

  @override
  State<CoursesCarousel> createState() => _CoursesCarouselState();
}

class _CoursesCarouselState extends State<CoursesCarousel> {
  late PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.9);
  }

  void _nextPage() {
    if (_currentPage < widget.courses.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.courses.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final course = widget.courses[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  clipBehavior: Clip.antiAlias,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      course.image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            left: 0,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: _prevPage,
            ),
          ),
          Positioned(
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: _nextPage,
            ),
          ),
        ],
      ),
    );
  }
}
