import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget? child;
  const SplashScreen({Key? key, this.child}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration(seconds: 3),
      () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => widget.child!),
          (route) => false,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Blue background layer
          Container(
            color: Color(0xFF173252), // Dark blue color
          ),
          // Red box with rounded bottom corners
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.5149, // Adjust the height as needed
              decoration: BoxDecoration(
                color: Color(0xFFC63C3F), // Dark red color
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(45), // Adjust the radius as needed
                  bottomRight: Radius.circular(45), // Adjust the radius as needed
                ),
              ),
            ),
          ),
          // Logo in the center
          Center(
            child: Container(
              width: 200, // Adjust width as needed
              height: 200, // Adjust height as needed
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/logo2.png'), // Assuming logo.png is located in the assets folder
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
