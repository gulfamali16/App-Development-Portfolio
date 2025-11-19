import 'package:flutter/material.dart';

void main() {
  runApp(ProfilePage());
}

class ProfilePage extends StatelessWidget {
  final String name = 'Gulfam Ali';
  final String email = 'gulfamoffi62@gmail.com';
  final String phone = '+923280130155';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Stack Widget - Profile Image with badge
              Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('images/gulfam2.jpeg'),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Column Widget - Basic Info
              Column(
                children: [
                  Text(
                    name,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    email,
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    phone,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Row Widget - Labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('Email'),
                  Text('Phone'),
                  Text('Address'),
                ],
              ),

              // Row Widget - Values
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('gulfamoffi62@gmail.com'),
                  Text('+923280130155'),
                  Text('Thigi Vehari'),
                ],
              ),
              SizedBox(height: 20),

              // ListView Widget - Skills
              Container(
                height: 150,
                child: ListView(
                  children: [
                    Text('Flutter Development'),
                    Text('Mobile App Development'),
                    Text('Web Development'),
                    Text('Database Management'),
                    Text('UI/UX Design'),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
