import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF173252),
      appBar: AppBar(
        centerTitle: true, // Add this line
        title: Text(
          'Contact Us',
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
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    // Add this Align widget to position the logo
                    alignment: Alignment(0,
                        -0.6), // Adjust the y-axis value to position at 1st quarter
                    child: Image.asset(
                      'assets/logo2.png', // Placeholder for logo image
                      width: 150,
                      height: 150,
                    ),
                  ),
                  SizedBox(height: 30),
                  _buildContactInfoTile(
                      Icons.email, "Email", "objectdetectionglasses@gmail.com",
                      () {
                    _sendEmail("objectdetectionglasses@gmail.com");
                  }),
                  _buildContactInfoTile(Icons.phone, "Phone", "+201009337523",
                      () {
                    _callPhoneNumber("+201009337523");
                  }),
                  _buildContactInfoTile(
                      Icons.location_on, "Location", "Alexandria, Egypt", null),
                  _buildContactInfoTile(
                      Icons.public, "Website", "sightsense.com", () {
                    _launchUrl(
                        "https://google.com"); //https://sightsense.com\news
                  },
                      description:
                          "Check our website for our latest updates, \nand new features added to our product.")
                ],
              ),
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
                GestureDetector(
                  onTap: onTap != null
                      ? () {
                          onTap();
                        }
                      : null,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: info,
                          style: TextStyle(
                            color: onTap != null ? Colors.blue : Colors.white,
                            fontSize: 16,
                            decoration: onTap != null
                                ? TextDecoration.underline
                                : TextDecoration.none,
                          ),
                        ),
                        if (description != null)
                          TextSpan(
                            text: '\n$description',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                      ],
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

  void _sendEmail(String email) async {
    final Uri params = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Feedback from App',
        'body': '',
      },
    );
    await launchUrl(params);
  }

  void _callPhoneNumber(String phoneNumber) async {
    final Uri params = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(params);
  }

  void _launchUrl(String url) async {
    await launchUrl(Uri.parse(url));
  }
}
