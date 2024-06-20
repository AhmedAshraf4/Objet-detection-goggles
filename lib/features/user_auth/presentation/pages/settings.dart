import 'package:flutter/material.dart';
import 'login_page.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:aws_s3_upload/aws_s3_upload.dart';
import 'contact.dart';
import 'support.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late File? _image;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _image = null; // Initialize as nullable
  }

  void _logout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _navigateToContactUs(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ContactUsPage()),
    );
  }

  void _navigateToSupport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SupportPage()),
    );
  }

  Future<void> _uploadImageToS3() async {
    if (_image == null) {
      print("No image selected.");
      return;
    }

    setState(() {
      _uploading = true; // Show progress bar
    });

    try {
      final response = await AwsS3.uploadFile(
        file: _image!,
        bucket: 'objectdetectiongoggles',
        region: "eu-north-1",
        accessKey: 'AKIA6GBMC726P4UMJAJJ',
        secretKey: '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',
        metadata: {"description": "My uploaded image"},
      );

      print("Image upload result: $response");

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Upload successful'),
      ));

      setState(() {
        _image = null;
      });
    } catch (e) {
      print("Error uploading image: $e");

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Upload failed'),
      ));
    } finally {
      setState(() {
        _uploading = false; // Hide progress bar
      });
    }
  }

  Future<void> _getImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF173252),
      appBar: AppBar(
        centerTitle: true, // Add this line
        title: Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 25,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        backgroundColor: Color(0xFF173252),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildImageBox(),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildActionBox(
                      'assets/import_image.png', 'Import Image', _getImage),
                ),
                SizedBox(width: 10),
                Expanded(
                  child:
                      _buildActionBox('assets/upload.png', 'Upload Image', () {
                    if (!_uploading) _uploadImageToS3();
                  }),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child:
                      _buildActionBox('assets/contact.png', 'Contact Us', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ContactUsPage()),
                    );
                  }),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _buildActionBox('assets/support.png', 'Support',
                      () => _navigateToSupport(context)),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildLogoutBox(context),
          ],
        ),
      ),
    );
  }

  Widget _buildImageBox() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _image != null ? null : Color(0xFFeef1f9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFF173252), width: 5.0),
      ),
      child: _image != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(_image!, fit: BoxFit.cover),
            )
          : Center(
              child: Text(
                'No Image Selected',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
            ),
    );
  }

  Widget _buildActionBox(String imagePath, String text, Function() onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: imagePath.contains('upload') && _image == null
              ? Color.fromARGB(255, 125, 124, 124)
              : Color(0xFFeef1f9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFF173252), width: 5.0),
        ),
        child: _uploading && imagePath.contains('upload') && _image != null
            ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(imagePath, height: 50),
                  SizedBox(height: 8),
                  Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLogoutBox(BuildContext context) {
    return InkWell(
      onTap: () => _logout(context),
      child: Container(
        height: 100,
        padding: EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Color(0xFFeef1f9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFF173252), width: 5.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logout.png',
                height: 50), // Add your logout icon here
            SizedBox(width: 10),
            Text(
              'Log Out',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 28,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _navigateToSupport(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => SupportPage()),
  );
}
