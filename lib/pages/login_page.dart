import 'dart:async';
import 'package:farmer/util/server_wakeup.dart';
import 'dart:convert';
import 'package:farmer/pages/register_page.dart';
import 'package:farmer/util/ipfile.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../util/bottom_navigation_bar_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _checkLogin() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    Map<String, dynamic> checkLogin = {
      "email": _emailController.text.trim(),
      "password": _passwordController.text,
    };

    try {
      final response = await http
          .post(
            Uri.parse(loginUrl),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(checkLogin),
          )
          .waitForServer();

      print('******************Login********************');
      print(response.body);

      if (response.statusCode != 200 || response.body.trim().isEmpty) {
        _showMessage("Invalid Credentials");
        return;
      }

      final responseData = json.decode(response.body);
      if (responseData is! Map || responseData['id'] == null) {
        _showMessage("Invalid Credentials");
        return;
      }

      final int exUserId = int.parse(responseData['id'].toString());
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('loggedUserID', exUserId);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BottomNavigationBarPage(userId: exUserId),
        ),
      );
    } on TimeoutException {
      _showMessage("Server is not responding. Check the IP in ipfile.dart.");
    } catch (error) {
      print('Error: $error');
      _showMessage("Could not connect to server. Check the IP in ipfile.dart.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _register() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.0),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'Please enter your email'
                        : null,
                  ),
                  SizedBox(height: 16.0),
                  TextFormField(
                    controller: _passwordController,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _isLoading ? null : _checkLogin(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    obscureText: true,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter your password'
                        : null,
                  ),
                  SizedBox(height: 24.0),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _checkLogin,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('Login'),
                    ),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text("Don't have an account?"),
                      TextButton(
                        onPressed: _register,
                        child: Text("Register"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
