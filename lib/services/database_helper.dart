import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/employee.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'employee_management.db');
    debugPrint('DB Path: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('Creating tables...');
    await db.execute('''
      CREATE TABLE employees(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        lastName TEXT,
        email TEXT,
        salary INTEGER,
        age INTEGER,
        synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        operation TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_operations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER,
        operation TEXT,
        data TEXT,
        timestamp INTEGER
      )
    ''');
    debugPrint('Tables created successfully.');
  }

  /// Insert Employee
  Future<int> insertEmployee(Employee employee, String operation) async {
    Database db = await database;
    Map<String, dynamic> employeeMap = {
      'name': employee.name,
      'lastName': employee.lastName ?? '',
      'email': employee.email,
      'salary': employee.salary,
      'age': employee.age,
      'synced': 0,
      'operation': operation
    };

    int id = await db.insert('employees', employeeMap);
    debugPrint('Inserted Employee with ID: $id -> $employeeMap');
    return id;
  }

  Future<List<Employee>> getEmployees() async {
    Database db = await database;
    List<Map<String, dynamic>> maps =
        await db.query('employees', where: 'is_deleted = ?', whereArgs: [0]);
    debugPrint('Employees in DB Data: $maps');

    return List.generate(maps.length, (i) {
      return Employee(
        id: maps[i]['id'],
        name: maps[i]['name'],
        lastName: maps[i]['lastName'],
        email: maps[i]['email'],
        salary: maps[i]['salary'],
        age: maps[i]['age'],
      );
    });
  }

  Future<int> updateEmployee(Employee employee, String operation) async {
    Database db = await database;
    Map<String, dynamic> employeeMap = {
      'name': employee.name,
      'lastName': employee.lastName ?? '',
      'email': employee.email,
      'salary': employee.salary,
      'age': employee.age,
      'synced': 0,
      'operation': operation
    };

    int result = await db.update('employees', employeeMap,
        where: 'id = ?', whereArgs: [employee.id]);
    debugPrint('Updated Employee ID: ${employee.id} -> $employeeMap');
    return result;
  }

  Future<int> deleteEmployee(int id) async {
    Database db = await database;
    await db.insert('pending_operations', {
      'employee_id': id,
      'operation': 'DELETE',
      'data': '',
      'timestamp': DateTime.now().millisecondsSinceEpoch
    });

    int result = await db.delete('employees', where: 'id = ?', whereArgs: [id]);
    debugPrint('Deleted Employee ID: $id');
    return result;
  }

  //deleted from db
  Future<void> softDeleteEmployee(int id) async {
    Database db = await database;
    await db.update(
      'employees',
      {'is_deleted': 1, 'synced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    await db.insert('pending_operations', {
      'employee_id': id,
      'operation': 'DELETE',
      'data': '',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    debugPrint('Employee ID $id marked as deleted (soft delete).');
  }

  Future<void> removeEmployeePermanently(int id) async {
    Database db = await database;
    await db.delete('employees', where: 'id = ?', whereArgs: [id]);
    debugPrint('Employee ID $id permanently deleted from DB');
  }

  Future<void> addPendingOperation(
      int employeeId, String operation, String data) async {
    Database db = await database;
    await db.insert('pending_operations', {
      'employee_id': employeeId,
      'operation': operation,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch
    });
    debugPrint(
        'Pending operation added: $operation for Employee ID: $employeeId');
  }

  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    Database db = await database;
    List<Map<String, dynamic>> result =
        await db.query('pending_operations', orderBy: 'timestamp ASC');
    debugPrint('Pending operations: $result');
    return result;
  }

  Future<void> removePendingOperation(int id) async {
    Database db = await database;
    await db.delete('pending_operations', where: 'id = ?', whereArgs: [id]);
    debugPrint('Removed pending operation ID: $id');
  }

  Future<void> markEmployeeAsSynced(int id) async {
    Database db = await database;
    await db.update('employees', {'synced': 1},
        where: 'id = ?', whereArgs: [id]);
    debugPrint('Employee ID $id marked as synced ✅');
  }

  Future<void> markEmployeeAsDeleted(int id) async {
    Database db = await database;
    await db.update(
      'employees',
      {'is_deleted': 1, 'synced': 1}, // Mark as deleted and synced
      where: 'id = ?',
      whereArgs: [id],
    );
    debugPrint('Employee ID $id marked as deleted in DB');
  }

  Future<void> insertOrUpdateEmployee(Employee employee) async {
    Database db = await database;

    final existing = await db.query(
      'employees',
      where: 'id = ?',
      whereArgs: [employee.id],
    );

    if (existing.isNotEmpty) {
      await db.update(
          'employees',
          {
            'name': employee.name,
            'lastName': employee.lastName ?? '',
            'email': employee.email,
            'salary': employee.salary,
            'age': employee.age,
            'synced': 1,
            'operation': 'FETCH'
          },
          where: 'id = ?',
          whereArgs: [employee.id]);
      debugPrint('Updated employee ID: ${employee.id}');
    } else {
      await db.insert('employees', {
        'id': employee.id,
        'name': employee.name,
        'lastName': employee.lastName ?? '',
        'email': employee.email,
        'salary': employee.salary,
        'age': employee.age,
        'synced': 1,
        'operation': 'FETCH'
      });
      debugPrint('Inserted new employee ID: ${employee.id}');
    }
  }
}
