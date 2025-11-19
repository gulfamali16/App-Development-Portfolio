import 'dart:convert';
import 'dart:io';

// Student class
class Student {
  String name;
  int age;
  String city;
  List<String> hobbies;
  Set<String> subjects;

  Student(this.name, this.age, this.city, this.hobbies, this.subjects);

  // Method to convert student to Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'city': city,
      'hobbies': hobbies,
      'subjects': subjects.toList(),
    };
  }
}

void main() {
  List<Student> students = [];

  while (true) {
    print("\n=== Student Menu ===");
    print("1. Add Student");
    print("2. Show Data");
    print("3. Search by Name");
    print("4. Filter Subjects or Hobbies");
    print("5. Export Data as JSON");
    print("6. Exit");
    stdout.write("Choose an option: ");
    String? choice = stdin.readLineSync();

    if (choice == "1") {
      // Add student
      stdout.write("Enter name: ");
      String name = stdin.readLineSync() ?? "";

      int age = 0;
      try {
        stdout.write("Enter age: ");
        age = int.parse(stdin.readLineSync() ?? "0");
      } catch (e) {
        print("Invalid age! Defaulting to 0.");
      }

      stdout.write("Enter city: ");
      String city = stdin.readLineSync() ?? "";

      stdout.write("Enter hobbies (comma separated): ");
      List<String> hobbies = (stdin.readLineSync() ?? "")
          .split(",")
          .map((e) => e.trim())
          .toList();

      stdout.write("Enter subjects (comma separated): ");
      Set<String> subjects =
      (stdin.readLineSync() ?? "").split(",").map((e) => e.trim()).toSet();

      students.add(Student(name, age, city, hobbies, subjects));
      print("Student added successfully!");

    } else if (choice == "2") {
      // Show all students
      if (students.isEmpty) {
        print("No students added yet.");
      } else {
        for (var s in students) {
          print("Name: ${s.name}, Age: ${s.age}, City: ${s.city}");
          print("  Hobbies: ${s.hobbies}");
          print("  Subjects: ${s.subjects}\n");
        }
      }

    } else if (choice == "3") {
      // Search student by name
      stdout.write("Enter name to search: ");
      String searchName = stdin.readLineSync() ?? "";
      var result =
      students.where((s) => s.name.toLowerCase() == searchName.toLowerCase());
      if (result.isEmpty) {
        print("No student found with that name.");
      } else {
        for (var s in result) {
          print("Found -> ${s.toMap()}");
        }
      }

    } else if (choice == "4") {
      // Filter hobbies/subjects
      stdout.write("Enter hobby or subject to filter: ");
      String filter = stdin.readLineSync() ?? "";
      var filtered = students.where((s) =>
      s.hobbies.contains(filter) || s.subjects.contains(filter));
      if (filtered.isEmpty) {
        print("No student matches this filter.");
      } else {
        for (var s in filtered) {
          print("Match -> ${s.toMap()}");
        }
      }

    } else if (choice == "5") {
      // Export as JSON
      List<Map<String, dynamic>> data =
      students.map((s) => s.toMap()).toList();
      String jsonString = jsonEncode(data);
      print("JSON Export:\n$jsonString");

    } else if (choice == "6") {
      print("Exiting program...");
      break;
    } else {
      print("Invalid choice, try again.");
    }
  }
}
