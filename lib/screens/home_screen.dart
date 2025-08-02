import 'package:employee_management_app/utils/color_constant.dart';
import 'package:employee_management_app/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../providers/employee_provider.dart';
import '../models/employee.dart';
import '../widgets/generic_data_table.dart';
import 'add_employee_screen.dart';
import 'edit_employee_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee'),
        actions: [
          Consumer<EmployeeProvider>(builder: (context, provider, _) {
            return IconButton(
              icon: provider.isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cloud_sync,
                      size: 30, color: LOGIN_CONTAINER_BLUE),
              tooltip: 'Sync with server',
              onPressed: provider.isSyncing
                  ? null
                  : () async {
                      //Check internet first
                      final connectivityResult =
                          await Connectivity().checkConnectivity();
                      if (connectivityResult == ConnectivityResult.none) {
                        showDialog(
                          context: context,
                          builder: (_) => noInternetDialog(context),
                        );
                        return;
                      }

                      //Now check if any unsynced operations exist
                      final hasPendingOps =
                          await provider.hasPendingOperations();
                      if (!hasPendingOps) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                "No data available in DB, please add data then sync"),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      //Confirm Sync
                      final shouldSync = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => buildSyncConfirmationDialog(context),
                      );
                      if (shouldSync == true) {
                        final success = await provider.syncWithServer();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Successfully synced to the server'
                                : 'Failed to sync with server'),
                            backgroundColor:
                                success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
            );
          }),
        ],
      ),
      body: ColoredBox(
        color: backgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: backgroundLight,
                  border: Border.all(color: lightGrey, width: 1.0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Consumer<EmployeeProvider>(
                            builder: (context, provider, _) {
                              return CustomButton(
                                buttonColor: LOGIN_CONTAINER_BLUE,
                                buttonHeight: 40,
                                buttonWidth: 120,
                                textColor: Colors.white,
                                buttonText: '+ Add New',
                                topRightRadius: 8,
                                topLeftRadius: 8,
                                bottomRightRadius: 8,
                                bottomLeftRadius: 8,
                                onButtonPress: () async {
                                  showGeneralDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    barrierLabel: 'Dialog',
                                    barrierColor: Colors.black.withOpacity(0.2),
                                    transitionDuration:
                                        const Duration(milliseconds: 200),
                                    transitionBuilder:
                                        (context, anim1, anim2, child) {
                                      return FadeTransition(
                                        opacity: anim1,
                                        child: child,
                                      );
                                    },
                                    pageBuilder: (context, anim1, anim2) {
                                      return Center(
                                        child: Material(
                                          color: Colors.transparent,
                                          child: ChangeNotifierProvider.value(
                                            value:
                                                Provider.of<EmployeeProvider>(
                                                    context,
                                                    listen: false),
                                            child: const AddEmployeeScreen(),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: Consumer<EmployeeProvider>(
                          builder: (context, provider, _) {
                            if (provider.isLoading) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (provider.error != null) {
                              return Center(child: Text(provider.error!));
                            }
                            if (provider.employees.isEmpty) {
                              return const Center(
                                  child: Text('No employees found.'));
                            }
                            final tableData =
                                employeesToTableData(provider.employees);
                            return GenericDataTable(
                              data: tableData,
                              editableFields: const [],
                              ignoredFields: [],
                              onRowUpdate: (updatedRows) {},
                              editCallBack: (row) =>
                                  employeeDataEdit(context, row, provider),
                              deleteCallBack: (row) =>
                                  employeeDataDelete(context, row, provider),
                              onRowActionMenuClicked: (value, row, index) {
                                if (value == EmployeeMenu.activity) {
                                  employeesToTableData(provider.employees);
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void employeeDataEdit(BuildContext context, Map<String, dynamic> row,
      EmployeeProvider provider) {
    final employee = provider.employees.firstWhere((e) => e.id == row['id']);
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Dialog',
      barrierColor: Colors.black.withOpacity(0.2),
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: child,
        );
      },
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ChangeNotifierProvider.value(
              value: Provider.of<EmployeeProvider>(context, listen: false),
              child: EditEmployeeScreen(employee: employee),
            ),
          ),
        );
      },
    );
  }

  void employeeDataDelete(BuildContext context, Map<String, dynamic> row,
      EmployeeProvider provider) {
    showDeleteDialog(context, row, provider);
  }
}

List<Map<String, dynamic>> employeesToTableData(List<Employee> employees) {
  return employees
      .map((e) => {
            'id': e.id,
            'first_name': e.name,
            'last_name': e.lastName,
            'email': e.email,
            'salary': e.salary,
            'age': e.age,
          })
      .toList();
}

Future<void> showDeleteDialog(
  BuildContext context,
  Map<String, dynamic> row,
  EmployeeProvider provider,
) async {
  final int? employeeId =
      row['id'] is int ? row['id'] : int.tryParse(row['id'].toString());
  final String employeeName = row['first_name']?.toString() ?? 'Employee';

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete $employeeName?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                if (employeeId != null) {
                  await provider.deleteEmployee(employeeId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('$employeeName deleted successfully'),
                        backgroundColor: Colors.green),
                  );
                } else {
                  throw Exception('Invalid Employee ID');
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete employee')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}

Widget noInternetDialog(BuildContext context) {
  return Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 12,
    insetPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.redAccent, size: 32),
                SizedBox(width: 12),
                Text(
                  "No Internet",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "You are not connected to the internet.\n\nPlease connect to the internet!",
              style: TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    "OK",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildSyncConfirmationDialog(BuildContext context) {
  return Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_upload_rounded,
              size: 48, color: LOGIN_CONTAINER_BLUE),
          const SizedBox(height: 16),
          const Text("Sync Employee Data",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text(
            "Do you want to sync the data?\nAll saved Employee data will be uploaded to the server.",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel")),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: LOGIN_CONTAINER_BLUE,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 3,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Sync Now",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
