import 'package:employee_management_app/utils/color_constant.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum EmployeeMenu {
  edit,
  delete,
  activity,
}

class GenericDataTable extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final List<String> editableFields;
  final List<String> dropdownFields;
  final Map<String, List<String>> dropdownOptions;
  final List<String> dateFields;
  final List<String> ignoredFields;
  final Function(List<Map<String, dynamic>>)? onRowUpdate;
  final Function(dynamic, dynamic, int)? onRowActionMenuClicked;
  final List<PopupMenuEntry<dynamic>> Function(Map<String, dynamic>)? rowActions;
  final GlobalKey<GenericDataTableState>? tableKey;
  final bool? parentEditable;
  final bool? parentDeletable;
  final bool? isSelectable;
  final bool? checkBoxValue;
  final Function(dynamic)? deleteCallBack;
  final Function(bool, dynamic)? checkBoxCallBack;
  final Function(dynamic)? editCallBack;
  final bool? isEditNot;
  final bool? isDeleteNot;

  const GenericDataTable({
    required this.data,
    required this.editableFields,
    this.dropdownFields = const [],
    this.dropdownOptions = const {},
    this.dateFields = const [],
    this.ignoredFields = const [],
    this.onRowUpdate,
    this.rowActions,
    this.onRowActionMenuClicked,
    this.tableKey,
    this.parentEditable,
    this.parentDeletable,
    this.isSelectable,
    this.deleteCallBack,
    this.editCallBack,
    this.checkBoxValue = false,
    this.checkBoxCallBack,
    this.isEditNot,
    this.isDeleteNot,
  }) : super(key: tableKey);

  @override
  GenericDataTableState createState() => GenericDataTableState();
}

class GenericDataTableState extends State<GenericDataTable> {
  late List<Map<String, dynamic>> data;
  bool isAllEditing = false;
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  late List<String> columnKeys;
  late Map<String, double> columnWidths;
  final double actionColumnWidth = 50.0;
  final double minColumnWidth = 50.0;
  bool selectAll = false;
  Map<String, bool> columnSelectAll = {};

  @override
  void initState() {
    super.initState();
    data = List.from(widget.data);
    for (var key in widget.dropdownFields) {
      columnSelectAll[key] = false;
    }
    // Use a consistent column key order for both columns and cells
    columnKeys = data.isNotEmpty
        ? data.first.keys.where((key) => !widget.ignoredFields.contains(key)).toList()
        : [];
    columnWidths = {
      "Actions": actionColumnWidth,
      for (var key in columnKeys) key: 100.0,
    };
  }

  void cancelEdit(int index) {
    setState(() {
      data[index]['isEditing'] = false;
    });
  }

  Future<void> _selectDate(BuildContext context, int index, String key) async {
    DateTime initialDate =
        DateTime.tryParse(data[index][key]?.toString() ?? '') ?? DateTime.now();

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        data[index][key] = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return '';
    DateTime? parsedDate = DateTime.tryParse(date);
    return parsedDate != null
        ? DateFormat('dd-MM-yyyy').format(parsedDate)
        : '';
  }

  // Custom menu item builder
  PopupMenuItem<EmployeeMenu> _buildMenuItem(
    String label,
    EmployeeMenu id, {
    bool disabled = false,
    IconData? icon,
  }) {
    debugPrint('_buildMenuItem called: $label, $id, disabled: $disabled');
    return PopupMenuItem<EmployeeMenu>(
      value: disabled ? null : id,
      enabled: !disabled,
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: icon != null ? Icon(icon, size: 20) : null,
        title: Text(
          label,
          style: TextStyle(
            color: disabled ? Colors.grey : Colors.black87,
            fontSize: 14,
          ),
        ),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  // Build menu items for a row
  List<PopupMenuEntry<EmployeeMenu>> _buildMenuItems(Map<String, dynamic> row) { 
    List<PopupMenuEntry<EmployeeMenu>> menuItems = [];

    // Always add Edit and Delete options
    menuItems.add(
      _buildMenuItem(
        'Edit',
        EmployeeMenu.edit,
        disabled: false,
        icon: Icons.edit,
      ),
    );
    
    menuItems.add(
      _buildMenuItem(
        'Delete',
        EmployeeMenu.delete,
        disabled: false,
        icon: Icons.delete,
      ),
    );
    return menuItems;
  }

  @override
  Widget build(BuildContext context) {
    data = List.from(widget.data);
    if (data.isEmpty) {
      return const Center(child: Text('No data available.'));
    }
    // Ensure columnKeys is always in sync with data
    columnKeys = data.first.keys.where((key) => !widget.ignoredFields.contains(key)).toList();
    return Column(
      children: [
        Expanded(
          child: Scrollbar(
            controller: _horizontalScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: Scrollbar(
                controller: _verticalScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _verticalScrollController,
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    headingRowColor: MaterialStateColor.resolveWith(
                      (states) => LOGIN_CONTAINER_BLUE,
                    ),
                    columns: [
                      DataColumn(
                        label: SizedBox(
                          width: actionColumnWidth,
                          child: const Text(
                            'Actions',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 14),
                          ),
                        ),
                      ),
                      ...columnKeys.map((key) {
                        return DataColumn(
                          label: Stack(
                            children: [
                              SizedBox(
                                width: columnWidths[key],
                                child: Text(
                                  camelCaseToTitleCase(key),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: -2,
                                top: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  onHorizontalDragUpdate: (details) {
                                    setState(() {
                                      columnWidths[key] = (columnWidths[key]! +
                                              details.primaryDelta!)
                                          .clamp(minColumnWidth, 400.0);
                                    });
                                  },
                                  // child: MouseRegion(
                                  //   cursor: SystemMouseCursors.resizeLeftRight,
                                  //   child: Icon(Icons.drag_indicator, color: Colors.white54),
                                  // ),
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.resizeLeftRight,
                                    child: Image.asset(
                                      'assets/resizer.png',
                                      color: backgroundLight,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                    rows: data.asMap().entries.map((entry) {
                      int index = entry.key;
                      var row = entry.value;
                      bool isEditing = row['isEditing'] ?? false;
                      bool isDisabled = row['disabled_view'] ?? false;
                      // Build cells: first Actions, then for each columnKey
                      List<DataCell> cells = [
                        DataCell(
                          widget.editableFields.isNotEmpty
                              ? (isDisabled
                                  ? IconButton(
                                      icon: const Icon(Icons.lock),
                                      onPressed: () {},
                                    )
                                  : isEditing
                                      ? Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.save),
                                              onPressed: () {},
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.close, color: Colors.red),
                                              onPressed: () => cancelEdit(index),
                                            ),
                                          ],
                                        )
                                      : IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () => setState(() {
                                            row['isEditing'] = true;
                                          }),
                                        ))
                              : PopupMenuButton<EmployeeMenu>(
                                  itemBuilder: (context) {
                                    debugPrint('PopupMenuButton itemBuilder called');
                                    return _buildMenuItems(row);
                                  },
                                  onSelected: (value) {
                                    debugPrint('PopupMenuButton onSelected: $value');
                                    if (value == EmployeeMenu.edit) {
                                      widget.editCallBack?.call(row);
                                    } else if (value == EmployeeMenu.delete) {
                                      widget.deleteCallBack?.call(row);
                                    }
                                    widget.onRowActionMenuClicked?.call(value, row, index);
                                  },
                                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 4,
                                ),
                        ),
                      ];
                      // Add a DataCell for each columnKey
                      cells.addAll(
                        columnKeys.map((key) {
                          if (widget.dateFields.contains(key)) {
                            return DataCell(
                              isEditing
                                  ? SizedBox(
                                      width: columnWidths[key],
                                      child: Row(
                                        children: [
                                          Text(formatDate(row[key]?.toString() ?? '')),
                                          IconButton(
                                            icon: const Icon(Icons.calendar_today),
                                            onPressed: () => _selectDate(context, index, key),
                                          ),
                                        ],
                                      ),
                                    )
                                  : SizedBox(
                                      width: columnWidths[key],
                                      child: Text(
                                        formatDate(row[key]?.toString() ?? ''),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        maxLines: 2,
                                      ),
                                    ),
                            );
                          }
                          if (widget.dropdownFields.contains(key)) {
                            String? dropdownValue = (row[key] ?? '').toString();
                            List<String>? options = widget.dropdownOptions[key];
                            return DataCell(
                              isEditing
                                  ? SizedBox(
                                      width: columnWidths[key],
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: options!.contains(dropdownValue) ? dropdownValue : null,
                                        onChanged: (newValue) {
                                          setState(() {
                                            row[key] = newValue;
                                          });
                                        },
                                        items: options.map((value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(
                                              value,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              maxLines: 2,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    )
                                  : SizedBox(
                                      width: columnWidths[key],
                                      child: Text(
                                        dropdownValue ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        maxLines: 2,
                                      ),
                                    ),
                            );
                          }
                          return DataCell(
                            isEditing && widget.editableFields.contains(key)
                                ? SizedBox(
                                    width: columnWidths[key],
                                    child: TextField(
                                      controller: TextEditingController(
                                        text: row[key]?.toString() ?? '',
                                      ),
                                      onChanged: (value) {
                                        data[index][key] = value;
                                      },
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      maxLines: null,
                                      decoration: const InputDecoration(
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.grey,
                                            width: 1.0,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.blue,
                                            width: 1.0,
                                          ),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(4),
                                          ),
                                        ),
                                        hintText: 'Enter text',
                                      ),
                                    ),
                                  )
                                : SizedBox(
                                    width: columnWidths[key],
                                    child: Tooltip(
                                      message: row[key]?.toString() ?? '',
                                      child: Text(
                                        row[key]?.toString() ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        maxLines: 2,
                                      ),
                                    ),
                                  ),
                          );
                        }),
                      );
                      return DataRow(
                        color: MaterialStateColor.resolveWith(
                          (states) => index % 2 == 0 ? Colors.grey[100]! : Colors.grey[200]!,
                        ),
                        cells: cells,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String camelCaseToTitleCase(String input) {
    String spaced = input.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (Match m) => ' ${m.group(0)}',
    );
    return spaced.trim().split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}