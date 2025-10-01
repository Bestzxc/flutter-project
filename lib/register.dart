import 'package:final_project_classup/login.dart';
import 'package:flutter/material.dart';
import 'home.dart';
import 'registerService.dart' as reg;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '', email = '', password = '';
  String? selectedAvatar;
  final Color mainColor = Colors.brown;
  final Color bgColor = const Color(0xFFFFCD9E);

  final List<String> avatars = [
    'assets/profiles/archeologist.png',
    'assets/profiles/cat.png',
    'assets/profiles/costume.png',
    'assets/profiles/director.png',
    'assets/profiles/frog.png',
    'assets/profiles/frog2.png',
    'assets/profiles/kid.png',
    'assets/profiles/mime.png',
    'assets/profiles/ptah.png',
    'assets/profiles/punk.png',
    'assets/profiles/soldier.png',
    'assets/profiles/vampire.png',
    'assets/profiles/zombie.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Register",style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),),
        backgroundColor: mainColor,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => LoginScreen(),
                ),
              );
            },
            icon: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: const Icon(Icons.close, color: Colors.white,),
            ),
          ),
        ],
        toolbarHeight: 80,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text("เลือก Avatar"),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: GridView.count(
                              crossAxisCount: 3,
                              shrinkWrap: true,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              children:
                                  avatars.map((avatar) {
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedAvatar = avatar;
                                        });
                                        Navigator.of(context).pop();
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.asset(
                                          avatar,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ),
                  );
                },
                child: CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child:
                        selectedAvatar != null
                            ? Image.asset(
                              selectedAvatar!,
                              fit: BoxFit.cover,
                              width: 140,
                              height: 140,
                            )
                            : Icon(Icons.question_mark, color: mainColor, size: 70),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(alignment: Alignment.center, child: Text('Choose your Avartar.',style: TextStyle(color: Colors.brown, fontSize: 20),),),
              const SizedBox(height: 35),

              TextFormField(
                onChanged: (val) => name = val,
                validator: (val) => val!.isEmpty ? "กรุณากรอกชื่อ" : null,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: "ชื่อ",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                onChanged: (value) => email = value,
                validator: (value) => value!.isEmpty ? "กรุณากรอกอีเมล" : null,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: "อีเมล",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                onChanged: (value) => password = value,
                obscureText: true,
                keyboardType: TextInputType.text,
                validator:
                    (value) =>value!.length < 6 ? "รหัสผ่านต้อง 6 ตัวขึ้นไป" : null,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: "รหัสผ่าน",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate() && selectedAvatar != null) {
                    bool success = await reg.AuthenticationService()
                        .registerWithAvatar(
                          name,
                          email,
                          password,
                          selectedAvatar!,
                        );
                    if (success) {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()),);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("สมัครสมาชิกไม่สำเร็จ")),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("กรุณากรอกข้อมูลให้ครบถ้วน"),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "สมัครสมาชิก",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
