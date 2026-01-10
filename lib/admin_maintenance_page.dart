import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminMaintenancePage extends StatefulWidget {
  const AdminMaintenancePage({super.key});

  @override
  State<AdminMaintenancePage> createState() => _AdminMaintenancePageState();
}

class _AdminMaintenancePageState extends State<AdminMaintenancePage> {
  int? _selectedMachineIndex;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for the form fields
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  bool _isLoading = true;

  // Local machine list
  final List<Map<String, dynamic>> _machines = [
    {'type': 'Washer', 'no': 1, 'isScheduled': false},
    {'type': 'Washer', 'no': 2, 'isScheduled': false},
    {'type': 'Washer', 'no': 3, 'isScheduled': false},
    {'type': 'Washer', 'no': 4, 'isScheduled': false},
    {'type': 'Washer', 'no': 5, 'isScheduled': false},
    {'type': 'Dryer', 'no': 1, 'isScheduled': false},
    {'type': 'Dryer', 'no': 2, 'isScheduled': false},
    {'type': 'Dryer', 'no': 3, 'isScheduled': false},
    {'type': 'Dryer', 'no': 4, 'isScheduled': false},
    {'type': 'Dryer', 'no': 5, 'isScheduled': false},
  ];

  @override
  void initState() {
    super.initState();
    _syncWithFirestore();
  }

  // Syncs local list with Firestore on page load
  Future<void> _syncWithFirestore() async {
    try {
      for (var machine in _machines) {
        String collection = machine['type'] == 'Washer' ? 'washers' : 'dryers';
        String docId = machine['no'].toString();
        var doc = await FirebaseFirestore.instance.collection(collection).doc(docId).get();
        
        if (doc.exists) {
          final data = doc.data();
          if (data != null && data['status'] == 'Maintenance') {
            setState(() {
              machine['isScheduled'] = true;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Sync error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Save or update maintenance info
  void _saveMaintenance() async {
    if (_formKey.currentState!.validate() && _selectedMachineIndex != null) {
      var machine = _machines[_selectedMachineIndex!];
      String collection = machine['type'] == 'Washer' ? 'washers' : 'dryers';
      String docId = machine['no'].toString();

      try {
        await FirebaseFirestore.instance.collection(collection).doc(docId).set({
          'maintenanceStart': _startDateController.text,
          'maintenanceUntil': _endDateController.text,
          'maintenanceDescription': _descriptionController.text,
          'status': 'Maintenance',
        }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maintenance Details Saved!')),
        );

        setState(() {
          _machines[_selectedMachineIndex!]['isScheduled'] = true;
          _selectedMachineIndex = null;
          _clearForm();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _clearForm() {
    _startDateController.clear();
    _endDateController.clear();
    _descriptionController.clear();
  }

  // Set machine back to Available
  void _completeMaintenanceEarly() async {
    if (_selectedMachineIndex != null) {
      var machine = _machines[_selectedMachineIndex!];
      String collection = machine['type'] == 'Washer' ? 'washers' : 'dryers';
      String docId = machine['no'].toString();

      try {
        await FirebaseFirestore.instance.collection(collection).doc(docId).update({
          'maintenanceStart': FieldValue.delete(),
          'maintenanceUntil': FieldValue.delete(),
          'maintenanceDescription': FieldValue.delete(),
          'status': 'Available',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Machine is now Available!')),
        );

        setState(() {
          _machines[_selectedMachineIndex!]['isScheduled'] = false;
          _selectedMachineIndex = null;
          _clearForm();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Maintenance & Operations',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Set downtime periods and track machine issues.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 30),

                _buildTableContainer(),

                const SizedBox(height: 30),

                if (_selectedMachineIndex != null) _buildMaintenanceForm(),
              ],
            ),
          ),
    );
  }

  Widget _buildTableContainer() {
    return Container(
      width: double.infinity, // Ensures card fills horizontal space
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: DataTable(
        headingRowHeight: 60,
        dataRowMaxHeight: 70,
        horizontalMargin: 20, // Padding for the left side of table
        columnSpacing: 0, // We use Expanded in headers to spread columns
        columns: const [
          DataColumn(label: Expanded(child: Text('Machine Type', style: TextStyle(fontWeight: FontWeight.bold)))),
          DataColumn(label: Expanded(child: Text('No.', style: TextStyle(fontWeight: FontWeight.bold)))),
          DataColumn(label: Expanded(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)))),
          DataColumn(label: Expanded(child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold)))),
        ],
        rows: _machines.asMap().entries.map((e) {
          final machine = e.value;
          final bool isScheduled = machine['isScheduled'] ?? false;

          return DataRow(cells: [
            DataCell(Text(machine['type']?.toString() ?? '')), // Left aligned
            DataCell(Text(machine['no']?.toString() ?? '')),
            DataCell(_buildStatusBadge(isScheduled ? 'Maintenance' : 'Available')),
            DataCell(
              TextButton.icon(
                icon: Icon(isScheduled ? Icons.edit_note : Icons.calendar_month, size: 18),
                label: Text(isScheduled ? "Update" : "Schedule"),
                style: TextButton.styleFrom(
                  foregroundColor: isScheduled ? Colors.orange[800] : Colors.purple,
                  padding: EdgeInsets.zero,
                ),
                onPressed: () async {
                  setState(() => _selectedMachineIndex = e.key);
                  
                  if (isScheduled) {
                    // Fetch and fill the form with existing data when updating
                    var doc = await FirebaseFirestore.instance
                        .collection(machine['type'] == 'Washer' ? 'washers' : 'dryers')
                        .doc(machine['no'].toString())
                        .get();
                    
                    if (doc.exists) {
                      var data = doc.data()!;
                      setState(() {
                        _startDateController.text = data['maintenanceStart'] ?? '';
                        _endDateController.text = data['maintenanceUntil'] ?? '';
                        _descriptionController.text = data['maintenanceDescription'] ?? '';
                      });
                    }
                  } else {
                    _clearForm();
                  }
                },
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildMaintenanceForm() {
    var machine = _machines[_selectedMachineIndex!];
    bool isScheduled = machine['isScheduled'] ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.purple.shade100, width: 2),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Maintenance Form: ${machine['type']} #${machine['no']}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _selectedMachineIndex = null;
                    _clearForm();
                  }), 
                  icon: const Icon(Icons.close)
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(child: _buildDatePicker(controller: _startDateController, label: "Start Date")),
                const SizedBox(width: 20),
                Expanded(child: _buildDatePicker(controller: _endDateController, label: "Estimated End Date")),
              ],
            ),
            
            const SizedBox(height: 20),
            
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Description / Issues",
                hintText: "Enter details about the repair needed...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (val) => val == null || val.isEmpty ? 'Please enter a description' : null,
            ),
            
            const SizedBox(height: 30),
            
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(isScheduled ? 'Update Maintenance' : 'Confirm Schedule'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _saveMaintenance,
                ),
                if (isScheduled) ...[
                  const SizedBox(width: 15),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Mark as Available'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green[700],
                      side: BorderSide(color: Colors.green.shade700),
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _completeMaintenanceEarly,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Reusable DatePicker with Calendar Icon
  Widget _buildDatePicker({required TextEditingController controller, required String label}) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_month, color: Colors.purple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (val) => val == null || val.isEmpty ? 'Pick a date' : null,
      onTap: () async {
        DateTime now = DateTime.now();
        DateTime today = DateTime(now.year, now.month, now.day);

        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: today,
          firstDate: DateTime(today.year - 1),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          setState(() {
            controller.text = DateFormat('yyyy-MM-dd').format(picked);
          });
        }
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    bool isMaintenace = status == 'Maintenance';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isMaintenace ? Colors.orange[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isMaintenace ? Colors.orange : Colors.green),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: isMaintenace ? Colors.orange[800] : Colors.green[700],
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}