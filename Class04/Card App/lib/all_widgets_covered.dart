import 'package:flutter/material.dart';



class ProfileApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ProfilePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ProfilePage extends StatelessWidget {
  final String name = 'Gulfam ALi';
  final String email = 'gulfamoffi62e@gmail.com';
  final String phone = '+923280130155';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile App'),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('images/gulfam.jpg.png'),
              ),
              SizedBox(height: 16),
              Text(
                name,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,),
              ),
              SizedBox(height: 8),
              Text(
                email,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 4),
              Text(
                phone,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}






// import 'package:flutter/material.dart';
//
// void main() => runApp(ProfileApp());
//
// class ProfileApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: ProfilePage(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }
//
// class ProfilePage extends StatelessWidget {
//   final String name = 'Muhammad Abdullah';
//   final String email = 'abdullahwale@gmail.com';
//   final String phone = '+923046983794';
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Profile App'),
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: EdgeInsets.all(16.0),
//           child: Column(
//             children: [
//               // Stack Widget - Profile image with online status badge
//               Stack(
//                 children: [
//                   CircleAvatar(
//                     radius: 60,
//                     backgroundImage: AssetImage('images/abdullah.png'),
//                   ),
//                   Positioned(
//                     bottom: 0,
//                     right: 0,
//                     child: Container(
//                       width: 20,
//                       height: 20,
//                       decoration: BoxDecoration(
//                         color: Colors.green,
//                         shape: BoxShape.circle,
//                         border: Border.all(color: Colors.white, width: 2),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 20),
//
//               // Column Widget - User information
//               Column(
//                 children: [
//                   Text(
//                     name,
//                     style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     'Flutter Developer',
//                     style: TextStyle(fontSize: 16, color: Colors.grey[600]),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 20),
//
//               // Row Widget - Contact information with icons
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   _buildContactCard(Icons.email, email, 'Email'),
//                   _buildContactCard(Icons.phone, phone, 'Phone'),
//                 ],
//               ),
//               SizedBox(height: 20),
//
//               // Row Widget - Social media links
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   _buildSocialButton(Icons.facebook, Colors.blue),
//                   SizedBox(width: 15),
//                   _buildSocialButton(Icons.camera_alt, Colors.pink),
//                   SizedBox(width: 15),
//                   _buildSocialButton(Icons.link, Colors.orange),
//                 ],
//               ),
//               SizedBox(height: 30),
//
//               // ListView Widget - Skills and achievements
//               Container(
//                 height: 200,
//                 child: ListView(
//                   children: [
//                     _buildListItem('Flutter Development', Icons.code, Colors.blue),
//                     _buildListItem('UI/UX Design', Icons.design_services, Colors.purple),
//                     _buildListItem('Mobile App Development', Icons.phone_android, Colors.green),
//                     _buildListItem('Web Development', Icons.web, Colors.orange),
//                     _buildListItem('Database Management', Icons.storage, Colors.red),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildContactCard(IconData icon, String text, String label) {
//     return Container(
//       padding: EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.grey[100],
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Column(
//         children: [
//           Icon(icon, color: Colors.blue, size: 24),
//           SizedBox(height: 8),
//           Text(
//             label,
//             style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//           ),
//           SizedBox(height: 4),
//           Text(
//             text,
//             style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSocialButton(IconData icon, Color color) {
//     return Container(
//       width: 50,
//       height: 50,
//       decoration: BoxDecoration(
//         color: color,
//         shape: BoxShape.circle,
//       ),
//       child: Icon(icon, color: Colors.white, size: 24),
//     );
//   }
//
//   Widget _buildListItem(String title, IconData icon, Color color) {
//     return Container(
//       margin: EdgeInsets.symmetric(vertical: 4),
//       padding: EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 3,
//             offset: Offset(0, 1),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(icon, color: color, size: 20),
//           ),
//           SizedBox(width: 12),
//           Text(
//             title,
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//           ),
//         ],
//       ),
//     );
//   }
// }