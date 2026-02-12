import 'package:flutter/material.dart';

void main() => runApp(ProfileApp());

class ProfileApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ProfilePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final String name = 'Gulfam Ali';
  final String email = 'gulfsmali@gmail.com';
  final String phone = '+923280130155';
  final String tagline = 'AI Developer';

  int selectedTheme = 0; // 0: default, 1: modern, 2: creative

  final List<String> profileImages = [
    'images/gulfam.jpg',
    'images/gulfam2.jpeg',
    'images/gulfam3.jpg',
  ];

  int currentImageIndex = 0;

  void _switchProfileImage() {
    setState(() {
      currentImageIndex = (currentImageIndex + 1) % profileImages.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Professional CV'),
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Container(
        decoration: _getBackgroundDecoration(),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Theme Selection Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildGradientButton('Classic', [
                      Colors.blueGrey,
                      Colors.deepPurple,
                    ], 0),
                    _buildGradientButton('Modern', [
                      Colors.cyan,
                      Colors.indigo,
                      Colors.deepPurpleAccent,
                    ], 1),
                    _buildGradientButton('Creative', [
                      Colors.pinkAccent,
                      Colors.orangeAccent,
                      Colors.redAccent,
                    ], 2),
                  ],
                ),
                SizedBox(height: 20),

                _buildProfileCard(),
                SizedBox(height: 20),

                _buildAboutCard(),
                SizedBox(height: 20),

                _buildSkillsCard(),
                SizedBox(height: 20),

                _buildExperienceCard(),
                SizedBox(height: 20),

                _buildContactCard(),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _switchProfileImage,
        backgroundColor: Colors.deepPurpleAccent,
        child: Icon(Icons.switch_account, color: Colors.white),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.2),
            spreadRadius: 3,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: AssetImage(profileImages[currentImageIndex]),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Text(
            name,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurpleAccent,
            ),
          ),
          SizedBox(height: 5),
          Text(
            tagline,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.deepPurpleAccent, size: 24),
              SizedBox(width: 10),
              Text(
                'About Me',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurpleAccent,
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Text(
            'Passionate AI Developer with years of experience in building intelligent and innovative solutions. Specialized in Artificial Intelligence, Machine Learning, Flutter App Development, WordPress, and Python Development. I love turning complex problems into smart, beautiful, and intuitive solutions.',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsCard() {
    List<Map<String, dynamic>> skills = [
      {'name': 'AI Development', 'icon': Icons.psychology, 'color': Colors.purple},
      {'name': 'Flutter App Development', 'icon': Icons.phone_android, 'color': Colors.blue},
      {'name': 'WordPress', 'icon': Icons.web, 'color': Colors.green},
      {'name': 'Python Development', 'icon': Icons.code, 'color': Colors.orange},
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.deepPurpleAccent, size: 24),
              SizedBox(width: 10),
              Text(
                'Core Skills',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurpleAccent,
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Container(
            height: 200,
            child: ListView.builder(
              itemCount: skills.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 6),
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: skills[index]['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: skills[index]['color'].withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: skills[index]['color'],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          skills[index]['icon'],
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 15),
                      Text(
                        skills[index]['name'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.work, color: Colors.deepPurpleAccent, size: 24),
              SizedBox(width: 10),
              Text(
                'Experience',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurpleAccent,
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          _buildExperienceItem('Senior Flutter Developer', 'Devsinc Inc.', '2021 - Present'),
          _buildExperienceItem('AI Development Specialist', 'Microsoft Labs', '2021 - 2022'),
          _buildExperienceItem('WordPress Developer', 'AI Innovative Agency', '2020 - 2021'),
        ],
      ),
    );
  }

  Widget _buildExperienceItem(String title, String company, String period) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurpleAccent,
            ),
          ),
          Text(
            company,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Text(
            period,
            style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_mail, color: Colors.deepPurpleAccent, size: 24),
              SizedBox(width: 10),
              Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurpleAccent,
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildContactItem(Icons.email, email, 'Email'),
              _buildContactItem(Icons.phone, phone, 'Phone'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text, String label) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurpleAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.deepPurpleAccent, size: 24),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton(String text, List<Color> colors, int themeIndex) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTheme = themeIndex;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.4),
              blurRadius: 6,
              offset: Offset(2, 3),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  BoxDecoration _getBackgroundDecoration() {
    switch (selectedTheme) {
      case 1: // Modern
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.cyan, Colors.indigo, Colors.deepPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case 2: // Creative
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pinkAccent, Colors.orange, Colors.red],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );
      default: // Classic
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey.shade200, Colors.blueGrey.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );
    }
  }
}
