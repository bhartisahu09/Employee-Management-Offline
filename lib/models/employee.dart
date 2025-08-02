class Employee {
  final int id;
  final String name;
  final String? lastName;
  final String email;
  final int salary;
  final int age;

  Employee({
    required this.id,
    required this.name,
    this.lastName,
    required this.email,
    required this.salary,
    required this.age,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['employee_name'] ?? '',
      email: json['employee_email'] ?? '',
      salary: int.tryParse(json['employee_salary'].toString()) ?? 0,
      age: int.tryParse(json['employee_age'].toString()) ?? 0,
    );
  }

  // For ReqRes API
  factory Employee.fromJsonReqRes(Map<String, dynamic> json) {
    return Employee(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['first_name'] ?? '',
      lastName: json['last_name'],
      email: json['email'] ?? '',
      salary: 0, // ReqRes API doesn't provide salary
      age: 0, // ReqRes API doesn't provide age
    );
  }

  // Get full name for ReqRes employees
  String get fullName {
    if (lastName != null && lastName!.isNotEmpty) {
      return '$name $lastName';
    }
    return name;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'salary': salary.toString(),
      'email': email,
      'age': age.toString(),
    };
  }

  // For ReqRes API
  Map<String, dynamic> toReqResJson() {
    return {
      'first_name': name,
      'last_name': lastName ?? '',
      'email': '${name.toLowerCase()}.${lastName?.toLowerCase() ?? 'user'}@reqres.in',
    };
  }
} 