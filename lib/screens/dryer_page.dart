import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'payment_screen.dart';

// -------------------- GLOBAL DATA STORAGE --------------------
class DryerData {
  static List<DryerMachine> machines = [];
  static List<Booking> bookings = [];
  static bool isInitialized = false;
}

// -------------------- MODELS --------------------

class DryerMachine {
  final int id;
  final String name;
  DateTime? endTime; 
  String? currentRemark; 

  DryerMachine({required this.id, required this.name, this.endTime, this.currentRemark});
}

class Booking {
  final int id;
  final int machineId;
  final String machineName;
  final String userName;
  final DateTime startTime;
  final DateTime endTime; 
  final String remark;
  bool isConfirmed; 
  bool isPaid;      

  Booking({required this.id, required this.machineId, required this.machineName, required this.userName, required this.startTime, required this.endTime, required this.remark, this.isConfirmed = false, this.isPaid = false});
}

// -------------------- MAIN SCREEN --------------------

class DryerPage extends StatefulWidget {
  const DryerPage({super.key});

  @override
  State<DryerPage> createState() => _DryerPageState();
}

class _DryerPageState extends State<DryerPage> {
  final int _runTime = 30;    
  final int _cycleTime = 35; 

  Timer? _timer;
  Set<int> _notifiedBookings = {}; 

  @override
  void initState() {
    super.initState();
    _initializeDataOnce();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) { setState(() {}); _checkTimeBasedLogic(); }
    });
  }

  void _initializeDataOnce() {
    if (DryerData.isInitialized) return;

    DateTime now = DateTime.now();
    DryerData.machines = [
      DryerMachine(id: 1, name: 'Dryer 1'),
      DryerMachine(id: 2, name: 'Dryer 2'),
      // Dryer 3 Running (Persistent)
      DryerMachine(id: 3, name: 'Dryer 3', endTime: now.add(const Duration(minutes: 24, seconds: 12)), currentRemark: "Jeans"),
      DryerMachine(id: 4, name: 'Dryer 4'),
      DryerMachine(id: 5, name: 'Dryer 5'),
    ];
    DryerData.isInitialized = true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _checkTimeBasedLogic() {
    DateTime now = DateTime.now();
    DryerData.bookings.removeWhere((b) {
      DateTime confirmDeadline = b.startTime.add(const Duration(minutes: 5));
      if (now.isAfter(confirmDeadline) && !b.isPaid && b.userName == "You") {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking cancelled: You missed the 5-minute start window."), backgroundColor: Colors.red));
        return true; 
      }
      return false;
    });

    for (var b in DryerData.bookings) {
      if (b.userName == "You" && !_notifiedBookings.contains(b.id)) {
        DateTime notifyStart = b.startTime.subtract(const Duration(minutes: 5));
        if (now.isAfter(notifyStart) && now.isBefore(b.startTime) && !b.isConfirmed) {
          _showPopup("Ready?", "Your slot for ${b.machineName} starts in < 5 mins! Please confirm.");
          _notifiedBookings.add(b.id);
        }
      }
    }
  }

  void _showPopup(String title, String message) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: Text(title), content: Text(message), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))]));
  }

  void _handleSaveBooking(Booking newBooking) { setState(() { DryerData.bookings.add(newBooking); }); Navigator.pop(context); }
  void _handleCancelBooking(int bookingId) { setState(() { DryerData.bookings.removeWhere((b) => b.id == bookingId); }); }
  void _handleConfirm(Booking booking) { setState(() { booking.isConfirmed = true; }); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Confirmed! Pay when ready to start."), backgroundColor: Colors.green)); }

  Future<void> _handlePayAndStart(Booking booking) async {
    final bool? success = await Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentScreen()));
    if (success == true) {
      setState(() {
        booking.isPaid = true;
        final index = DryerData.machines.indexWhere((m) => m.id == booking.machineId);
        if (index != -1) {
          DryerData.machines[index].endTime = DateTime.now().add(const Duration(minutes: 30));
          DryerData.machines[index].currentRemark = booking.remark;
        }
      });
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final myBookings = DryerData.bookings.where((b) => b.userName == "You").toList();
    return Scaffold(
      appBar: AppBar(title: const Text("Select Dryer", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFFB97AD9), elevation: 0, centerTitle: true),
      body: Container(
         decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF3E5F5), Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: ListView(padding: const EdgeInsets.all(16), children: [
            if (myBookings.isNotEmpty) ...[const Text("My Bookings", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)), const SizedBox(height: 12), ...myBookings.map((b) => _buildMyBookingCard(b)), const SizedBox(height: 24)],
            const Text("All Dryers", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)), const SizedBox(height: 12), ...DryerData.machines.map((m) => _buildDryerCard(m))
        ]),
      ),
    );
  }

  Widget _buildMyBookingCard(Booking booking) {
    DateTime now = DateTime.now();
    bool isTomorrow = booking.startTime.day != now.day;
    String dayPrefix = isTomorrow ? "Tomorrow, " : "";
    
    // --- TIMING LOGIC UPDATE ---
    // 1. Confirm Window: 5 mins BEFORE start time
    bool isConfirmWindow = now.isAfter(booking.startTime.subtract(const Duration(minutes: 5))) && now.isBefore(booking.startTime);
    
    // 2. Pay Window: Starts 2 mins BEFORE start time, ends 5 mins AFTER start time
    bool isPayWindow = now.isAfter(booking.startTime.subtract(const Duration(minutes: 2))) && 
                       now.isBefore(booking.startTime.add(const Duration(minutes: 5)));

    String statusLabel = "Reserved"; Color statusColor = Colors.orange;
    if (booking.isPaid) { statusLabel = "Running"; statusColor = Colors.green; }
    else if (booking.isConfirmed) { statusLabel = "Confirmed"; statusColor = Colors.blue; }
    else if (isConfirmWindow) { statusLabel = "Action Needed"; statusColor = Colors.redAccent; }

    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.purple.shade100), boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(children: [
          Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Text(booking.machineName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)))]),
                  const SizedBox(height: 8), Text("$dayPrefix${DateFormat('h:mm a').format(booking.startTime)} - ${DateFormat('h:mm a').format(booking.endTime)}", style: TextStyle(color: Colors.grey.shade600, fontSize: 14))
              ])),
              if (!booking.isPaid) GestureDetector(onTap: () => _handleCancelBooking(booking.id), child: const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.delete_outline, color: Colors.red)))
          ]),
          const SizedBox(height: 16),
          if (booking.isPaid) Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)), child: const Center(child: Text("Cycle in Progress ⏳", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))))
          else if (isPayWindow) SizedBox(width: double.infinity, child: ElevatedButton(onPressed: booking.isConfirmed ? () => _handlePayAndStart(booking) : null, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB97AD9), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: Text(booking.isConfirmed ? "PAY NOW & START" : "Missed Confirmation!", style: const TextStyle(fontWeight: FontWeight.bold))))
          else if (isConfirmWindow && !booking.isConfirmed) SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => _handleConfirm(booking), icon: const Icon(Icons.thumb_up_alt_outlined, size: 18), label: const Text("Confirm I'm Here", style: TextStyle(fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))))
          else Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)), child: const Center(child: Text("Waiting for slot time...", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))))
      ]),
    );
  }

  Widget _buildDryerCard(DryerMachine machine) {
    DateTime now = DateTime.now();
    bool isRunning = machine.endTime != null && now.isBefore(machine.endTime!);
    List<Booking> futureBookings = DryerData.bookings.where((b) => b.machineId == machine.id && b.startTime.isAfter(now)).toList();
    futureBookings.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    String statusText = "Available"; Color statusColor = Colors.green; IconData statusIcon = Icons.check_circle_outline; String? subText;
    if (isRunning) { statusText = "Running"; statusColor = Colors.blue; statusIcon = Icons.local_laundry_service; if (machine.currentRemark != null) subText = "Note: ${machine.currentRemark}"; }
    else if (futureBookings.isNotEmpty) { Booking next = futureBookings.first; String start = DateFormat('h:mm').format(next.startTime); String end = DateFormat('h:mm a').format(next.endTime); statusText = "Booked ($start - $end)"; statusColor = Colors.orange; statusIcon = Icons.schedule; }

    String timeRemaining = "";
    if (isRunning) { final diff = machine.endTime!.difference(now); timeRemaining = _formatDuration(diff); }

    return GestureDetector(
      onTap: () { showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (c) => BookingModal(machine: machine, existingBookings: DryerData.bookings.where((b) => b.machineId == machine.id).toList(), onSave: _handleSaveBooking)); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))], border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5)),
        child: Column(children: [
            Row(children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(statusIcon, color: statusColor, size: 28)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(machine.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 4), Text(statusText, style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.bold)), if (subText != null) Text(subText!, style: const TextStyle(color: Colors.grey, fontSize: 11))])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFB97AD9), borderRadius: BorderRadius.circular(20)), child: const Text("Select Slot", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))
            ]),
            if (timeRemaining.isNotEmpty) ...[const SizedBox(height: 12), Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(8)), child: Center(child: Text(timeRemaining, style: const TextStyle(color: Colors.blue, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Courier'))))]
        ]),
      ),
    );
  }
}

class BookingModal extends StatefulWidget {
  final DryerMachine machine;
  final List<Booking> existingBookings; 
  final Function(Booking) onSave;

  const BookingModal({super.key, required this.machine, required this.existingBookings, required this.onSave});

  @override
  State<BookingModal> createState() => _BookingModalState();
}

class _BookingModalState extends State<BookingModal> {
  DateTime? _selectedSlot;
  final TextEditingController _remarkController = TextEditingController();
  List<Map<String, dynamic>> _slots = [];
  final int _slotDuration = 35; 
  bool _showingTomorrow = false;

  @override
  void initState() {
    super.initState();
    _generateSlots();
    _remarkController.text = ""; 
  }

  void _generateSlots() {
    _slots.clear();
    _showingTomorrow = false;
    DateTime now = DateTime.now();
    _generateSlotsForDay(now, "Today");
    if (_slots.length < 2) {
      _showingTomorrow = true;
      DateTime tomorrow = now.add(const Duration(days: 1));
      _generateSlotsForDay(tomorrow, "Tomorrow");
    }
    final firstAvailable = _slots.firstWhere((s) => s['isTaken'] == false, orElse: () => {});
    if (firstAvailable.isNotEmpty) _selectedSlot = firstAvailable['date'];
  }

  void _generateSlotsForDay(DateTime date, String label) {
    DateTime runner = DateTime(date.year, date.month, date.day, 0, 0);
    DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59);

    while (runner.isBefore(endOfDay)) {
      if (runner.isBefore(DateTime.now())) { runner = runner.add(Duration(minutes: _slotDuration)); continue; }
      
      DateTime slotStart = runner;
      DateTime slotEnd = runner.add(Duration(minutes: _slotDuration));
      bool isTaken = widget.existingBookings.any((booking) => slotStart.isBefore(booking.endTime) && slotEnd.isAfter(booking.startTime));

      _slots.add({'date': runner, 'label': label, 'isTaken': isTaken});
      runner = runner.add(Duration(minutes: _slotDuration));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Book ${widget.machine.name}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              if (widget.machine.currentRemark != null) Text("Note: ${widget.machine.currentRemark}", style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
            ]),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
          ]),
          const Divider(),
          const SizedBox(height: 10),
          Row(children: [const Text("Select Time Slot", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)), if (_showingTomorrow) Container(margin: const EdgeInsets.only(left: 10), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4)), child: const Text("Displaying Next Day", style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)))]),
          const SizedBox(height: 10),
          Expanded(child: _slots.isEmpty ? const Center(child: Text("No slots available.")) : ListView.separated(itemCount: _slots.length, separatorBuilder: (c, i) => const SizedBox(height: 10), itemBuilder: (context, index) {
            final slotData = _slots[index];
            final DateTime slotTime = slotData['date'];
            final bool isTaken = slotData['isTaken'];
            final isSelected = _selectedSlot == slotTime;
            Color bgColor = isTaken ? Colors.grey.shade100 : (isSelected ? const Color(0xFFB97AD9).withOpacity(0.1) : Colors.white);
            Color borderColor = isTaken ? Colors.transparent : (isSelected ? const Color(0xFFB97AD9) : Colors.grey.shade300);
            Color textColor = isTaken ? Colors.grey.shade400 : (isSelected ? const Color(0xFFB97AD9) : Colors.black87);
            return GestureDetector(onTap: isTaken ? null : () => setState(() => _selectedSlot = slotTime), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor, width: isSelected ? 2 : 1)), child: Row(children: [Icon(isTaken ? Icons.block : (isSelected ? Icons.check_circle : Icons.radio_button_unchecked), size: 18, color: textColor), const SizedBox(width: 12), Text(DateFormat('h:mm a').format(slotTime), style: TextStyle(fontWeight: FontWeight.bold, color: textColor)), if (isTaken) const Spacer(), if (isTaken) const Text("Unavailable", style: TextStyle(fontSize: 12, color: Colors.grey))])));
          })),
          const SizedBox(height: 20),
          const Text("Note for next user (Optional)", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 8),
          TextField(controller: _remarkController, decoration: InputDecoration(hintText: "e.g. Please take out my clothes", filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _selectedSlot == null ? null : () {
            final booking = Booking(id: DateTime.now().millisecondsSinceEpoch, machineId: widget.machine.id, machineName: widget.machine.name, userName: "You", startTime: _selectedSlot!, endTime: _selectedSlot!.add(Duration(minutes: _slotDuration)), remark: _remarkController.text.isEmpty ? "Reserved" : _remarkController.text);
            widget.onSave(booking);
          }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB97AD9), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Confirm Reservation (Free)", style: TextStyle(fontWeight: FontWeight.bold)))),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}