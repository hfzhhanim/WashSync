import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Required for DateFormat

class AdminMaintenancePage extends StatefulWidget {
  const AdminMaintenancePage({super.key});

  @override
  State<AdminMaintenancePage> createState() => _AdminMaintenancePageState();
}

class _AdminMaintenancePageState extends State<AdminMaintenancePage> {
  // 1. DATA AND STATE
  int? _selectedMachineIndex; 
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String? _selectedIssue;

  // Initial Mock Data
  final List<Map<String, dynamic>> _machines = [
    {'type': 'Washer', 'no': 1, 'status': 'Available', 'next': '2025-01-10', 'issue': '', 'start': '', 'end': '', 'notes': ''},
    {'type': 'Dryer', 'no': 1, 'status': 'Maintenance', 'next': '2025-01-05', 'issue': 'Water leakage', 'start': '2025-01-01', 'end': '2025-01-06', 'notes': 'Replacing the main pipe.'},
    {'type': 'Washer', 'no': 2, 'status': 'Available', 'next': '2025-01-12', 'issue': '', 'start': '', 'end': '', 'notes': ''},
  ];

  final List<String> _issueTypes = [
    'Machine not turning on', 'Water leakage', 'Drum not spinning / drum stuck',
    'Excessive vibration during operation', 'Unusual or loud noise', 'Damaging or tearing clothes', 'Other'
  ];

  // FUNCTION TO OPEN CALENDAR POPUP
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024), 
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blueAccent, 
              onPrimary: Colors.white,    
              onSurface: Colors.black,    
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // Formats date to YYYY-MM-DD for consistency
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _handleAction(int index) {
    setState(() {
      _selectedMachineIndex = index;
      var machine = _machines[index];
      
      if (machine['status'] == 'Maintenance') {
        _selectedIssue = machine['issue'];
        _startDateController.text = machine['start'];
        _endDateController.text = machine['end'];
        _notesController.text = machine['notes'];
      } else {
        _selectedIssue = _issueTypes.first;
        _startDateController.clear();
        _endDateController.clear();
        _notesController.clear();
      }
    });
  }

  void _saveMaintenance() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        int index = _selectedMachineIndex!;
        
        _machines[index]['status'] = 'Maintenance';
        _machines[index]['issue'] = _selectedIssue;
        _machines[index]['start'] = _startDateController.text;
        _machines[index]['end'] = _endDateController.text;
        _machines[index]['notes'] = _notesController.text;
        
        // UPDATED: Set Next Maintenance to the Start Date
        _machines[index]['next'] = _startDateController.text;

        _selectedMachineIndex = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maintenance Updated Successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 47.0, vertical: 35.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Machine Management", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildMachineTable(),
          const SizedBox(height: 40),
          if (_selectedMachineIndex != null) _buildSchedulingForm(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildMachineTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SingleChildScrollView(
  scrollDirection: Axis.horizontal,
      child: DataTable(
          columns: const [
            DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('No.', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Next Maintenance', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _machines.asMap().entries.map((entry) {
            int idx = entry.key;
            var machine = entry.value;
            bool isMaint = machine['status'] == 'Maintenance';

            return DataRow(cells: [
              DataCell(Text(machine['type'])),
              DataCell(Text(machine['no'].toString())),
              DataCell(_buildStatusBadge(machine['status'])),
              DataCell(Text(machine['next'])),
              DataCell(
                SizedBox(
                  width: 120, // 👈 IMPORTANT
                  child: ElevatedButton(
                    onPressed: () => _handleAction(idx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isMaint ? Colors.orange[800] : Colors.blue[700],
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      isMaint ? 'Update' : 'Schedule',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSchedulingForm() {
    var machine = _machines[_selectedMachineIndex!];
    bool isUpdate = machine['status'] == 'Maintenance';

    return Container(
      width: 900,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isUpdate ? Colors.orange : Colors.blue, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${isUpdate ? 'Update' : 'Schedule'} Maintenance: ${machine['type']} ${machine['no']}", 
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Divider(height: 40),
            const Text('Issue Type', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              initialValue: _selectedIssue,
              items: _issueTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _selectedIssue = val),
              decoration: const InputDecoration(border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildDateField("Start Date", _startDateController),
                const SizedBox(width: 20),
                _buildDateField("End Date", _endDateController),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Enter maintenance details...', filled: true, fillColor: Colors.white),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _saveMaintenance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700], 
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20)
                  ),
                  child: Text(isUpdate ? 'Update Schedule' : 'Save Schedule'),
                ),
                const SizedBox(width: 15),
                OutlinedButton(
                  onPressed: () => setState(() => _selectedMachineIndex = null), 
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20)),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            readOnly: true, // Prevents manual typing
            onTap: () => _selectDate(context, controller), // Triggers calendar
            decoration: const InputDecoration(
              border: OutlineInputBorder(), 
              suffixIcon: Icon(Icons.calendar_month), 
              filled: true, 
              fillColor: Colors.white,
              hintText: 'Select Date',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'Maintenance' ? Colors.orange : (status == 'Available' ? Colors.green : Colors.blue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(10), 
        border: Border.all(color: color)
      ),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}