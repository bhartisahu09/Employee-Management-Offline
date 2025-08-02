import 'package:employee_management_app/utils/color_constant.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/employee.dart';
import '../providers/employee_provider.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({Key? key}) : super(key: key);

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    final provider = context.read<EmployeeProvider>();
    //Clear previous values
    provider.firstNameController.clear();
    provider.lastNameController.clear();
    provider.emailController.clear();
    provider.salaryController.clear();
    provider.ageController.clear();

    provider.selectedFirstName = null;
    provider.filteredLastNames = [];
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EmployeeProvider>(context);

    return Center(
      child: SingleChildScrollView(
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add Employee',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: LOGIN_CONTAINER_BLUE,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black54),
                      onPressed: () =>
                          Navigator.of(context, rootNavigator: true).pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // TextFormField(
                //   controller: _firstNameController,
                //   decoration: InputDecoration(
                //     labelText: 'First Name',
                //     prefixIcon: const Icon(Icons.person_outline),
                //     border: OutlineInputBorder(
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //     filled: true,
                //     fillColor: Colors.blue.shade50.withOpacity(0.15),
                //   ),
                //   validator: _validateFirstName,
                //   textCapitalization: TextCapitalization.words,
                // ),
                DropdownButtonFormField<String>(
                  value: provider.selectedFirstName,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.blue.shade50.withOpacity(0.15),
                  ),
                  items: provider.firstNames
                      .map((name) => DropdownMenuItem(
                            value: name,
                            child: Text(name),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      provider.selectedFirstName = value;
                      provider.firstNameController.text = value ?? '';
                      // Filter last names for selected first name
                      provider.filteredLastNames = provider.employees
                          .where((e) => e.name == value)
                          .map((e) => e.lastName ?? '')
                          .where((name) => name.isNotEmpty)
                          .toSet()
                          .toList();
                      // Reset last name controller if not in filtered list
                      if (!provider.filteredLastNames
                          .contains(provider.lastNameController.text)) {
                        provider.lastNameController.text = '';
                      }
                    });
                  },
                  validator: provider.validateFirstName,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: provider.lastNameController.text.isNotEmpty
                      ? provider.lastNameController.text
                      : null,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.blue.shade50.withOpacity(0.15),
                  ),
                  items: provider.filteredLastNames
                      .map((name) => DropdownMenuItem(
                            value: name,
                            child: Text(name),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      provider.lastNameController.text = value ?? '';
                    });
                  },
                  validator: provider.validateLastName,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: provider.emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.blue.shade50.withOpacity(0.15),
                  ),
                  keyboardType: TextInputType.number,
                  validator: provider.validateEmployeeEmail,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: provider.salaryController,
                  decoration: InputDecoration(
                    labelText: 'Salary',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.blue.shade50.withOpacity(0.15),
                  ),
                  keyboardType: TextInputType.number,
                  validator: provider.validateSalary,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: provider.ageController,
                  decoration: InputDecoration(
                    labelText: 'Age',
                    prefixIcon: const Icon(Icons.cake_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.blue.shade50.withOpacity(0.15),
                  ),
                  keyboardType: TextInputType.number,
                  validator: provider.validateAge,
                ),
                const SizedBox(height: 18),
                if (provider.error != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            provider.error!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (provider.error != null) const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: provider.isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              final employee = Employee(
                                id: 0,
                                name: provider.firstNameController.text.trim(),
                                lastName:
                                    provider.lastNameController.text.trim(),
                                email: provider.emailController.text.trim(),
                                salary:
                                    int.parse(provider.salaryController.text),
                                age: int.parse(provider.ageController.text),
                              );
                              await provider.addEmployee(employee);
                              if (provider.error == null) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Employee added successfully!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  Navigator.of(context, rootNavigator: true)
                                      .pop();
                                }
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LOGIN_CONTAINER_BLUE,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
