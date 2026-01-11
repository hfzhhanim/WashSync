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
  
  bool _isLoading = false;

  // Local machine list structure
  final List<Map<String, dynamic>> _machines = [
    {'type': 'Washer', 'no': 1},
    {'type': 'Washer', 'no': 2},
    {'type': 'Washer', 'no': 3},
    {'type': 'Washer', 'no': 4},
    {'type': 'Washer', 'no': 5},
    {'type': 'Dryer', 'no': 1},
    {'type': 'Dryer', 'no': 2},
    {'type': 'Dryer', 'no': 3},
    {'type': 'Dryer', 'no': 4},
    {'type': 'Dryer', 'no': 5},
  ];

  // Helper to get collection names
  String _getCollection(String type) => type == 'Washer' ? 'washers' : 'dryers';

  // Save or update maintenance info
  void _saveMaintenance() async {
    if (_formKey.currentState!.validate() && _selectedMachineIndex != null) {
      var machine = _machines[_selectedMachineIndex!];
      String collection = _getCollection(machine['type']);
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
      String collection = _getCollection(machine['type']);
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
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: DataTable(
        headingRowHeight: 60,
        dataRowMaxHeight: 70,
        horizontalMargin: 20,
        columnSpacing: 0,
        columns: const [
          DataColumn(label: Expanded(child: Text('Machine Type', style: TextStyle(fontWeight: FontWeight.bold)))),
          DataColumn(label: Expanded(child: Text('No.', style: TextStyle(fontWeight: FontWeight.bold)))),
          DataColumn(label: Expanded(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)))),
          DataColumn(label: Expanded(child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold)))),
        ],
        rows: _machines.asMap().entries.map((e) {
          final machine = e.value;
          final docRef = FirebaseFirestore.instance
              .collection(_getCollection(machine['type']))
              .doc(machine['no'].toString());

          return DataRow(cells: [
            DataCell(Text(machine['type']?.toString() ?? '')),
            DataCell(Text(machine['no']?.toString() ?? '')),
            DataCell(
              StreamBuilder<DocumentSnapshot>(
                stream: docRef.snapshots(),
                builder: (context, snapshot) {
                  // Safe check to prevent "Bad State" error
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return _buildStatusBadge('Available');
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  String currentStatus = data['status'] ?? 'Available';

                  // Logic to check your current Firebase field 'currentRemark'
                  if (data['currentRemark'] == 'In Use') {
                    currentStatus = 'In Use';
                  }

                  return _buildStatusBadge(currentStatus);
                },
              ),
            ),
            DataCell(
              StreamBuilder<DocumentSnapshot>(
                stream: docRef.snapshots(),
                builder: (context, snapshot) {
                  String currentStatus = 'Available';
                  bool hasData = snapshot.hasData && snapshot.data!.exists;

                  if (hasData) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    currentStatus = data['status'] ?? 'Available';
                    if (data['currentRemark'] == 'In Use') currentStatus = 'In Use';
                  }

                  final bool isScheduled = currentStatus == 'Maintenance';
                  final bool isInUse = currentStatus == 'In Use';

                  return TextButton.icon(
                    icon: Icon(isInUse ? Icons.lock : (isScheduled ? Icons.edit_note : Icons.calendar_month), size: 18),
                    label: Text(isInUse ? "In Use" : (isScheduled ? "Update" : "Schedule")),
                    style: TextButton.styleFrom(
                      foregroundColor: isInUse ? Colors.blueGrey : (isScheduled ? Colors.orange[800] : Colors.purple),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: isInUse ? null : () async {
                      setState(() => _selectedMachineIndex = e.key);
                      if (isScheduled && hasData) {
                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        setState(() {
                          _startDateController.text = data['maintenanceStart'] ?? '';
                          _endDateController.text = data['maintenanceUntil'] ?? '';
                          _descriptionController.text = data['maintenanceDescription'] ?? '';
                        });
                      } else {
                        _clearForm();
                      }
                    },
                  );
                },
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    if (status == 'Maintenance') {
      badgeColor = Colors.orange;
    } else if (status == 'In Use') {
      badgeColor = Colors.blue;
    } else {
      badgeColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: badgeColor.withOpacity(0.9),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMaintenanceForm() {
    var machine = _machines[_selectedMachineIndex!];
    
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
                  label: const Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _saveMaintenance,
                ),
                const SizedBox(width: 15),
                // Only show "Mark as Available" if currently in maintenance
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(_getCollection(machine['type']))
                      .doc(machine['no'].toString())
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      if (data['status'] == 'Maintenance') {
                        return OutlinedButton.icon(
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Mark as Available'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green[700],
                            side: BorderSide(color: Colors.green.shade700),
                            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _completeMaintenanceEarly,
                        );
                      }
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2024),
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
}