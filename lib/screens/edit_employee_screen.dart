import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/employee.dart';
import '../providers/employee_provider.dart';
import 'package:employee_management_app/utils/color_constant.dart';

class EditEmployeeScreen extends StatefulWidget {
  final Employee employee;
  const EditEmployeeScreen({Key? key, required this.employee})
      : super(key: key);

  @override
  State<EditEmployeeScreen> createState() => _EditEmployeeScreenState();
}

class _EditEmployeeScreenState extends State<EditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final provider = context.read<EmployeeProvider>();

    provider.selectedFirstName = widget.employee.name;
    provider.firstNameController.text = widget.employee.name;
    provider.lastNameController.text = widget.employee.lastName ?? '';
    provider.emailController.text = widget.employee.email;
    provider.salaryController.text = widget.employee.salary.toString();
    provider.ageController.text = widget.employee.age.toString();

    provider.filteredLastNames = provider.employees
        .where((e) => e.name == widget.employee.name)
        .map((e) => e.lastName ?? '')
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Employee',
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
                DropdownButtonFormField<String>(
                  value:
                      provider.firstNames.contains(provider.selectedFirstName)
                          ? provider.selectedFirstName
                          : null,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.blue.shade50.withOpacity(0.15),
                  ),
                  items: provider.firstNames
                      .map((name) =>
                          DropdownMenuItem(value: name, child: Text(name)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      provider.selectedFirstName = value;
                      provider.firstNameController.text = value ?? '';
                      provider.filteredLastNames = provider.employees
                          .where((e) => e.name == value)
                          .map((e) => e.lastName ?? '')
                          .where((name) => name.isNotEmpty)
                          .toSet()
                          .toList();

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
                  value: provider.filteredLastNames
                          .contains(provider.lastNameController.text)
                      ? provider.lastNameController.text
                      : null,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.blue.shade50.withOpacity(0.15),
                  ),
                  items: provider.filteredLastNames
                      .map((name) =>
                          DropdownMenuItem(value: name, child: Text(name)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      provider.lastNameController.text = value ?? '';
                    });
                  },
                  validator: provider.validateLastName,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: provider.emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.blue.shade50.withOpacity(0.15),
                  ),
                  validator: provider.validateEmployeeEmail,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: provider.salaryController,
                  decoration: InputDecoration(
                    labelText: 'Salary',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.blue.shade50.withOpacity(0.15),
                  ),
                  keyboardType: TextInputType.number,
                  validator: provider.validateSalary,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: provider.ageController,
                  decoration: InputDecoration(
                    labelText: 'Age',
                    prefixIcon: const Icon(Icons.cake_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.blue.shade50.withOpacity(0.15),
                  ),
                  keyboardType: TextInputType.number,
                  validator: provider.validateAge,
                ),
                const SizedBox(height: 20),
                //Update Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              final updatedEmployee = Employee(
                                id: widget.employee.id,
                                name: provider.firstNameController.text.trim(),
                                lastName:
                                    provider.lastNameController.text.trim(),
                                email: provider.emailController.text.trim(),
                                salary:
                                    int.parse(provider.salaryController.text),
                                age: int.parse(provider.ageController.text),
                              );
                              await provider.updateEmployee(
                                  widget.employee.id, updatedEmployee);
                              if (provider.error == null && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Employee updated successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: LOGIN_CONTAINER_BLUE,
                              foregroundColor: Colors.white),
                          child: const Text('Update Employee'),
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
