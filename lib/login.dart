import 'package:final_project_classup/home.dart';
import 'package:final_project_classup/register.dart';
import 'package:flutter/material.dart';
import 'authentication.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String email = '';
  String password = '';

  final Color mainColor = Colors.brown;
  final Color bgColor = const Color(0xFFFFCD9E);

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'CLASS - UP',
          style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: mainColor,
        centerTitle: true,
        toolbarHeight: 80,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 40),
              Icon(Icons.school, size: 170, color: mainColor),
              const SizedBox(height: 48),
          
              TextFormField(
                onChanged: (value) => email = value,
                validator: (value) => value!.isEmpty ? "กรุณากรอกอีเมลล์" : null,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 35),
          
              TextFormField(
                onChanged: (value) => password = value,
                validator: (value) => value!.isEmpty ? "กรุณากรอกรหัสผ่าน" : null,
                obscureText: true,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 60),
          
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      AuthenticationService()
                          .login(email, password)
                          .then((success) {
                        if (success) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('อีเมลล์หรือรหัสผ่านผิดพลาด')),
                          );
                        }
                      });
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
                    'Login',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
          
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                },
                child: Text(
                  'Register',
                  style: TextStyle(color: mainColor, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
