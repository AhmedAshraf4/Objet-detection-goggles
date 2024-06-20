import 'package:flutter/material.dart';

class SupportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF173252),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Support',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 25,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        backgroundColor: Color(0xFFC63C3F),
      ),
      body: Stack(
        children: [
          Container(
            color: Color(0xFF173252),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.35,
              decoration: BoxDecoration(
                color: Color(0xFFC63C3F),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(45),
                  bottomRight: Radius.circular(45),
                ),
              ),
            ),
          ),
          Align( // Add this Align widget to position the logo
      alignment: Alignment(0, -0.60), // Adjust the y-axis value to position at top 3rd
      child: Image.asset(
        'assets/logo2.png', // Placeholder for logo image
        width: 150,
        height: 150,
      ),
    ),
        ],
      ),
    );
  }

  Widget _buildContactInfoTile(
      IconData icon, String title, String info, Function()? onTap,
      {String? description}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                description != null
                    ? Text(
                        description,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      )
                    : Container(),
                GestureDetector(
                  onTap: onTap != null
                      ? () {
                          onTap();
                        }
                      : null,
                  child: Text(
                    info,
                    style: TextStyle(
                      color: onTap != null ? Colors.blue : Colors.white,
                      fontSize: 16,
                      decoration: onTap != null
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
