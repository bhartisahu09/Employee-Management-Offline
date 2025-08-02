import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../models/employee.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';

class EmployeeProvider extends ChangeNotifier {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController salaryController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

  String? selectedFirstName;
  List<String> filteredLastNames = [];

  final ApiService employeeApiService = ApiService();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Employee> _employees = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _error;
  int _nextLocalId = 1000;

  // Getters
  List<Employee> get employees => _employees;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get error => _error;

  // Dropdown Lists
  List<String> get firstNames => employees
      .map((e) => e.name)
      .where((name) => name.isNotEmpty)
      .toSet()
      .toList();

  //Validation Methods
  String? validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter first name';
    if (value.trim().length < 2)
      return 'First name must be at least 2 characters';
    return null;
  }

  String? validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter last name';
    if (value.trim().length < 2)
      return 'Last name must be at least 2 characters';
    return null;
  }

  String? validateEmployeeEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter email';
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value))
      return 'Please enter a valid email address';
    return null;
  }

  String? validateSalary(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter salary';
    final salary = int.tryParse(value);
    if (salary == null) return 'Please enter a valid number';
    if (salary <= 0) return 'Salary must be greater than 0';
    return null;
  }

  String? validateAge(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter age';
    final age = int.tryParse(value);
    if (age == null) return 'Please enter a valid number';
    if (age < 18 || age > 100) return 'Age must be between 18 and 100';
    return null;
  }

  // Fetch all employees from API
  Future<void> fetchEmployees() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      debugPrint('Fetching employees...');
      _employees = await employeeApiService.getAllEmployees();
      debugPrint('Fetched ${_employees.length} employees from DB.');
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching employees: $_error');
    }
    _isLoading = false;
    notifyListeners();
  }

  //Fetch all employees from local DB
  Future<void> fetchEmployeeses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Loading employees from local DB...');
      _employees = await _dbHelper.getEmployees();
      debugPrint('Employees in DB (non-deleted): ${_employees.length}');
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading employees: $_error');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Add new employee
  Future<void> addEmployee(Employee employee) async {
    _isLoading = true;
    notifyListeners();
    try {
      final newEmployee = Employee(
        id: _nextLocalId++, // Assign unique local ID
        name: employee.name,
        lastName: employee.lastName,
        email: employee.email,
        salary: employee.salary,
        age: employee.age,
      );

      debugPrint('Adding new employee in local db: ${newEmployee.toJson()}');
      await employeeApiService.createEmployee(newEmployee);
      _error = null;

      await fetchEmployees();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding employee: $_error');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateEmployee(int id, Employee employee) async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('Updating employee ID $id: ${employee.toJson()}');

      //Update local DB immediately (soft update)
      await _dbHelper.updateEmployee(employee, 'UPDATE');

      await _dbHelper.addPendingOperation(
        id,
        'UPDATE',
        jsonEncode(employee.toJson()),
      );
      final index = _employees.indexWhere((e) => e.id == id);
      if (index != -1) {
        _employees[index] = employee;
      }

      _error = null;
      notifyListeners();
      debugPrint('Employee $id updated locally and added to pending sync.');
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating employee: $_error');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteEmployee(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _dbHelper.softDeleteEmployee(id); // Soft delete
      _employees.removeWhere((e) => e.id == id); // Update UI immediately
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting employee: $_error');
    }
    _isLoading = false;
    notifyListeners();
  }

  //Sync pending operations with server
  Future<bool> syncWithServer() async {
    _isSyncing = true;
    notifyListeners();

    bool success = false;

    try {
      final pendingOps = await _dbHelper.getPendingOperations();
      debugPrint('Pending operations count: ${pendingOps.length}');

      if (pendingOps.isEmpty) {
        debugPrint('No pending operations to sync.');
        _isSyncing = false;
        notifyListeners();
        return false;
      }

      success = await employeeApiService.syncWithServer();
      if (success) {
        debugPrint('Sync successful, refreshing employee list...');
        //await fetchEmployees();
        await fetchEmployeeses();
      } else {
        debugPrint('Sync failed.');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error during sync: $_error');
      success = false;
    }

    _isSyncing = false;
    notifyListeners();
    return success;
  }

  //Check if there are any pending operations
  Future<bool> hasPendingOperations() async {
    final pendingOps = await _dbHelper.getPendingOperations();
    return pendingOps.isNotEmpty;
  }

  //Check if all data is synced
  Future<bool> isAllDataSynced() async {
    final db = await _dbHelper.database;
    final result = await db
        .rawQuery('SELECT COUNT(*) as count FROM employees WHERE synced = 0');
    final unsyncedCount = Sqflite.firstIntValue(result) ?? 0;
    debugPrint('Unsynced employee count: $unsyncedCount');
    return unsyncedCount == 0;
  }

  //Clear form fields
  void clearFormFields() {
    firstNameController.clear();
    lastNameController.clear();
    emailController.clear();
    salaryController.clear();
    ageController.clear();
    selectedFirstName = null;
    filteredLastNames = [];
  }
}
