import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/employee.dart';
import 'database_helper.dart';

class ApiService {
  static const String BASE_URL = 'https://reqres.in/api';
  static const String token = 'reqres-free-v1';
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<bool> isOnline() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  static Future<Map<String, String>> getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
      'x-api-key': token,
    };
    debugPrint('Token: $token');
    debugPrint('Headers JSON: ${jsonEncode(headers)}');
    return headers;
  }

  Future<List<Employee>> getAllEmployees() async {
    List<Employee> localEmployees = await _dbHelper.getEmployees();

    if (await isOnline()) {
      try {
        String url = '$BASE_URL/users';
        final response =
            await http.get(Uri.parse(url), headers: await getHeaders());

        if (response.statusCode == 200) {
          final List data = json.decode(response.body)['data'];
          List<Employee> apiEmployees =
              data.map((e) => Employee.fromJsonReqRes(e)).toList();

          //Sync API data with local DB without duplicates
          for (var employee in apiEmployees) {
            await _dbHelper.insertOrUpdateEmployee(employee);
          }

          //Refresh local employees list
          localEmployees = await _dbHelper.getEmployees();
        }
      } catch (e) {
        debugPrint('Error fetching from API: $e');
      }
    }
    return localEmployees;
  }

  Future<void> createEmployee(Employee employee) async {
    int localId = await _dbHelper.insertEmployee(employee, 'CREATE');
    await _dbHelper.addPendingOperation(
        localId, 'CREATE', jsonEncode(employee.toJson()));
  }

  Future<void> updateEmployee(int id, Employee employee) async {
    await _dbHelper.updateEmployee(employee, 'UPDATE');
    await _dbHelper.addPendingOperation(
        id, 'UPDATE', jsonEncode(employee.toJson()));
  }

  Future<void> deleteEmployee(int id) async {
    await _dbHelper.deleteEmployee(id);
  }

  Future<bool> syncWithServer({int maxRetries = 3}) async {
    if (!await isOnline()) {
      debugPrint('Device is offline. Sync aborted.');
      return false;
    }

    bool success = true;
    List<Map<String, dynamic>> pendingOps =
        await _dbHelper.getPendingOperations();
    debugPrint('Pending operations count: ${pendingOps.length}');

    for (var op in pendingOps) {
      int retries = 0;
      bool operationDone = false;

      while (!operationDone && retries < maxRetries) {
        try {
          retries++;
          int employeeId = op['employee_id'];
          String operation = op['operation'];
          String data = op['data'];
          final headers = await getHeaders();

          debugPrint('\nAttempt $retries for operation: $operation');

          switch (operation) {
            case 'CREATE':
              final url = '$BASE_URL/users';
              debugPrint('[CREATE] URL: $url\nHeaders: $headers\nBody: $data');

              final res =
                  await http.post(Uri.parse(url), headers: headers, body: data);
              debugPrint('Response: ${res.statusCode} -> ${res.body}');

              if (res.statusCode == 201) {
                await _dbHelper.markEmployeeAsSynced(employeeId);
                await _dbHelper.removePendingOperation(op['id']);
                debugPrint('Employee $employeeId synced');
                operationDone = true;
              }
              break;
            case 'UPDATE':
              final url = '$BASE_URL/users/$employeeId';
              debugPrint('[UPDATE] URL: $url\nHeaders: $headers\nBody: $data');

              final body = jsonDecode(data); // Convert JSON string to Map
              final res = await http.put(Uri.parse(url),
                  headers: headers, body: jsonEncode(body));

              debugPrint('Response: ${res.statusCode} -> ${res.body}');

              if (res.statusCode == 200) {
                await _dbHelper.markEmployeeAsSynced(employeeId);
                await _dbHelper.removePendingOperation(op['id']);
                debugPrint('Employee $employeeId synced ✅');
                operationDone = true;
              }
              break;
            case 'DELETE':
              final url = '$BASE_URL/users/$employeeId';
              debugPrint('[DELETE] URL: $url\nHeaders: $headers');

              final res = await http.delete(Uri.parse(url), headers: headers);
              debugPrint('Response: ${res.statusCode}');

              if (res.statusCode == 204 || res.statusCode == 200) {
                await _dbHelper.markEmployeeAsDeleted(employeeId); //Soft delete
                await _dbHelper.removePendingOperation(op['id']);
                debugPrint('Employee ID $employeeId marked as deleted (soft)');
                operationDone = true;
              }
              break;
          }
        } catch (e) {
          debugPrint('Retry $retries failed: $e');
        }
      }

      if (!operationDone) {
        success = false;
        debugPrint('Operation failed after $maxRetries retries.');
      }
    }

    debugPrint(success ? 'Sync completed successfully!' : 'Sync failed.');
    return success;
  }
}
