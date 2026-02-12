import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// OOP class for Calculator
class Calculator {
  double add(double a, double b) => a + b;
  double sub(double a, double b) => a - b;
  double mul(double a, double b) => a * b;
  double div(double a, double b) => b != 0 ? a / b : double.infinity;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Calculator App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Simple Calculator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController num1Controller = TextEditingController();
  final TextEditingController num2Controller = TextEditingController();
  String result = "";

  final Calculator calc = Calculator(); // Using OOP object

  void calculate(String operation) {
    double n1 = double.tryParse(num1Controller.text) ?? 0;
    double n2 = double.tryParse(num2Controller.text) ?? 0;

    double res = 0;
    if (operation == "add") {
      res = calc.add(n1, n2);
    } else if (operation == "sub") {
      res = calc.sub(n1, n2);
    } else if (operation == "mul") {
      res = calc.mul(n1, n2);
    } else if (operation == "div") {
      res = calc.div(n1, n2);
    }

    setState(() {
      result = res.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text(widget.title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: num1Controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Enter first number",
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: num2Controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Enter second number",
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 30),

            // Floating Buttons in center
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  backgroundColor: Colors.green,
                  heroTag: "addBtn",
                  onPressed: () => calculate("add"),
                  child: const Text("+", style: TextStyle(fontSize: 24, color: Colors.white)),
                ),
                const SizedBox(width: 20),
                FloatingActionButton(
                  backgroundColor: Colors.red,
                  heroTag: "subBtn",
                  onPressed: () => calculate("sub"),
                  child: const Text("-", style: TextStyle(fontSize: 24, color: Colors.white)),
                ),
                const SizedBox(width: 20),
                FloatingActionButton(
                  backgroundColor: Colors.blue,
                  heroTag: "mulBtn",
                  onPressed: () => calculate("mul"),
                  child: const Text("×", style: TextStyle(fontSize: 24, color: Colors.white)),
                ),
                const SizedBox(width: 20),
                FloatingActionButton(
                  backgroundColor: Colors.orange,
                  heroTag: "divBtn",
                  onPressed: () => calculate("div"),
                  child: const Text("÷", style: TextStyle(fontSize: 24, color: Colors.white)),
                ),
              ],
            ),

            const SizedBox(height: 40),
            Text(
              "Result: $result",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),

            const SizedBox(height: 60),

            // Footer Text
            const Text(
              "Made by Gulfam Ali\nFA23-BSE-030",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
