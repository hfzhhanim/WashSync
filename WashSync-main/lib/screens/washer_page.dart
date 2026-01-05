import '../services/notification_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'payment_screen.dart';

// -------------------- MODELS --------------------

class WashingMachine {
  final String id;
  final String name;
  DateTime? endTime;
  String? currentRemark;

  WashingMachine({
    required this.id,
    required this.name,
    this.endTime,
    this.currentRemark,
  });

  factory WashingMachine.fromFirestore(Map<String, dynamic> data, String id) {
    return WashingMachine(
      id: id,
      name: data['name'] ?? '',
      currentRemark: data['currentRemark'] ?? '',
      endTime: (data['endTime'] != null && data['endTime'] != "")
          ? DateTime.parse(data['endTime'])
          : null,
    );
  }
}

class Booking {
  final String id;
  final String machineId;
  final String machineName;
  final String userName;
  final DateTime startTime;
  final DateTime endTime;
  final String remark;
  bool isConfirmed;
  bool isPaid;

  Booking({
    required this.id,
    required this.machineId,
    required this.machineName,
    required this.userName,
    required this.startTime,
    required this.endTime,
    required this.remark,
    this.isConfirmed = false,
    this.isPaid = false,
  });

  factory Booking.fromFirestore(Map<String, dynamic> data, String id) {
    return Booking(
      id: id,
      machineId: data['machineId'] ?? '',
      machineName: data['machineName'] ?? '',
      userName: data['userName'] ?? '',
      startTime: DateTime.parse(data['startTime']),
      endTime: DateTime.parse(data['endTime']),
      remark: data['remark'] ?? '',
      isConfirmed: data['isConfirmed'] ?? false,
      isPaid: data['isPaid'] ?? false,
    );
  }
}

// -------------------- MAIN SCREEN --------------------

class WasherPage extends StatefulWidget {
  const WasherPage({super.key});

  @override
  State<WasherPage> createState() => _WasherPageState();
}

class _WasherPageState extends State<WasherPage> {
  Timer? _timer;
  Timer? _cleanupTimer;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _seedWashers();
    _startAutoCancelCheck();
    // This timer triggers a rebuild every second to update the countdown text
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _seedWashers() async {
    final washerCollection = _firestore.collection('washers');
    final snapshot = await washerCollection.get();
    if (snapshot.docs.isEmpty) {
      for (int i = 1; i <= 5; i++) {
        await washerCollection.doc(i.toString()).set({
          'name': 'Washer $i',
          'endTime': '',
          'currentRemark': '',
        });
      }
    }
  }

  void _startAutoCancelCheck() {
    _cleanupTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!mounted) return;
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('bookings')
          .where('isConfirmed', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        final startTime = DateTime.parse(doc.data()['startTime']);
        if (now.isAfter(startTime.add(const Duration(minutes: 1)))) {
          await _firestore.collection('bookings').doc(doc.id).delete();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cleanupTimer?.cancel();
    super.dispose();
  }

  // --- ACTIONS ---

  void _handleSaveBooking(Booking newBooking) async {
    final bookingRef = _firestore.collection('bookings');
    try {
      await _firestore.runTransaction((transaction) async {
        QuerySnapshot existing = await bookingRef
            .where('machineId', isEqualTo: newBooking.machineId)
            .where('startTime', isEqualTo: newBooking.startTime.toIso8601String())
            .get();

        if (existing.docs.isNotEmpty) {
          throw Exception("Slot taken!");
        }

        transaction.set(bookingRef.doc(), {
          'machineId': newBooking.machineId,
          'machineName': newBooking.machineName,
          'userName': "You",
          'startTime': newBooking.startTime.toIso8601String(),
          'endTime': newBooking.endTime.toIso8601String(),
          'remark': newBooking.remark,
          'isConfirmed': false,
          'isPaid': false,
        });
      });

      int notifId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await NotificationService.scheduleBookingReminder(
        notifId,
        "Get Ready!",
        "Your turn for ${newBooking.machineName} starts in 5 minutes!",
        newBooking.startTime.subtract(const Duration(minutes: 5)),
      );

      if (mounted) {
        Navigator.of(context).pop(); 
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _showSuccessPopup(newBooking);
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _showSuccessPopup(Booking booking) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(child: Icon(Icons.check_circle, color: Colors.green, size: 60)),
        content: Text("Reserved ${booking.machineName}\nfor ${DateFormat('h:mm a').format(booking.startTime)}", textAlign: TextAlign.center),
        actions: [Center(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")))],
      ),
    );
  }

  void _handleCancelBooking(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).delete();
  }

  void _handleConfirm(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).update({'isConfirmed': true});
  }

  Future<void> _handlePayAndStart(Booking booking) async {
    final bool? success = await Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentScreen()));
    
    if (success == true) {
      DateTime washEndTime = DateTime.now().add(const Duration(minutes: 30));
      
      // Update Booking
      await _firestore.collection('bookings').doc(booking.id).update({'isPaid': true});
      
      // Update Machine status
      await _firestore.collection('washers').doc(booking.machineId).update({
        'endTime': washEndTime.toIso8601String(),
        'currentRemark': "In Use",
      });

      int finishNotifId = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 10;
      await NotificationService.scheduleBookingReminder(
        finishNotifId,
        "Laundry Almost Done! 🧺",
        "Your machine will finish in 5 minutes, please pick it up.",
        washEndTime.subtract(const Duration(minutes: 5)),
      );
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    if (d.isNegative) return "00:00:00";
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("WashSync", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), 
        backgroundColor: const Color(0xFFB97AD9), 
        centerTitle: true
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFF3E5F5), Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter)
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('washers').snapshots(),
          builder: (context, washerSnapshot) {
            if (!washerSnapshot.hasData) return const Center(child: CircularProgressIndicator());
            final machines = washerSnapshot.data!.docs.map((doc) => WashingMachine.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();

            return StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('bookings').snapshots(),
              builder: (context, bookingSnapshot) {
                final allBookings = bookingSnapshot.hasData
                    ? bookingSnapshot.data!.docs.map((doc) => Booking.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList()
                    : <Booking>[];
                
                final myBookings = allBookings.where((b) {
                  bool isUser = b.userName == "You";
                  bool isStillValid = DateTime.now().isBefore(b.startTime.add(const Duration(minutes: 1)));
                  return isUser && (isStillValid || b.isPaid);
                }).toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (myBookings.isNotEmpty) ...[
                      const Text("My Bookings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF6A1B9A))),
                      const SizedBox(height: 12),
                      ...myBookings.map((b) {
                        WashingMachine machine = machines.firstWhere((m) => m.id == b.machineId);
                        return _buildMyBookingCard(b, machine);
                      }),
                      const SizedBox(height: 24),
                    ],
                    const Text("All Washers", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF6A1B9A))),
                    const SizedBox(height: 12),
                    ...machines.map((m) => _buildWasherCard(m, allBookings)),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMyBookingCard(Booking booking, WashingMachine machine) {
    DateTime now = DateTime.now();
    
    // Check if THIS specific booking's machine is currently running the wash cycle
    bool isCycleRunning = booking.isPaid && machine.endTime != null && now.isBefore(machine.endTime!);
    bool isBeforeSlot = now.isBefore(booking.startTime);
    bool isConfirmWindow = now.isAfter(booking.startTime.subtract(const Duration(minutes: 5))) && 
                           now.isBefore(booking.startTime.add(const Duration(minutes: 1)));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(booking.machineName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                if (!booking.isPaid) 
                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _handleCancelBooking(booking.id))
                else
                  const Icon(Icons.verified, color: Colors.blue, size: 20)
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            if (isCycleRunning) ...[
              const Text("Wash Cycle In Progress", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              // Simple Progress bar based on 30 min duration
              LinearProgressIndicator(
                value: machine.endTime!.difference(now).inSeconds / 1800, // 1800s = 30m
                backgroundColor: Colors.blue.withOpacity(0.1),
                color: Colors.blue,
              ),
              const SizedBox(height: 12),
              Text(
                "Time Remaining: ${_formatDuration(machine.endTime!.difference(now))}",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue, fontFamily: 'monospace'),
              ),
            ] else if (booking.isPaid && !isCycleRunning) ...[
              const Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 40),
                  Text("Wash Completed!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ] else if (isBeforeSlot && !isConfirmWindow) ...[
              Text("Starts at ${DateFormat('h:mm a').format(booking.startTime)}", style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
            ] else if (isConfirmWindow && !booking.isConfirmed) ...[
               Column(
                children: [
                  SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.location_on), style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white), onPressed: () => _handleConfirm(booking.id), label: const Text("CONFIRM ARRIVAL"))),
                  Text("Expires in: ${_formatDuration(booking.startTime.add(const Duration(minutes: 1)).difference(now).abs())}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
            ] else if (booking.isConfirmed && !booking.isPaid) ...[
               SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB97AD9), foregroundColor: Colors.white), onPressed: () => _handlePayAndStart(booking), child: const Text("PAY NOW & START"))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWasherCard(WashingMachine machine, List<Booking> allBookings) {
    DateTime now = DateTime.now();
    bool isRunning = machine.endTime != null && now.isBefore(machine.endTime!);
    Color statusColor = isRunning ? Colors.blue : Colors.green;

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (c) => BookingModal(
          machine: machine,
          existingBookings: allBookings, 
          onSave: _handleSaveBooking,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5)),
        child: Row(
          children: [
            Icon(isRunning ? Icons.local_laundry_service : Icons.check_circle_outline, color: statusColor, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(machine.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(isRunning ? "Status: Busy" : "Status: Available", style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.bold)),
              ]),
            ),
            if (isRunning) Text(_formatDuration(machine.endTime!.difference(now)), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }
}

// -------------------- BOOKING MODAL (Time Slot Selection) --------------------

class BookingModal extends StatefulWidget {
  final WashingMachine machine;
  final List<Booking> existingBookings;
  final Function(Booking) onSave;

  const BookingModal({super.key, required this.machine, required this.existingBookings, required this.onSave});

  @override
  State<BookingModal> createState() => _BookingModalState();
}

class _BookingModalState extends State<BookingModal> {
  DateTime? _selectedSlot;
  List<Map<String, dynamic>> _slots = [];
  final int _slotDuration = 35;

  @override
  void initState() {
    super.initState();
    _generateSlots();
  }

  void _generateSlots() {
    _slots.clear();
    DateTime now = DateTime.now();
    DateTime runner = DateTime(now.year, now.month, now.day, 0, 0);
    DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59);

    while (runner.isBefore(endOfDay)) {
      if (runner.isBefore(now)) { runner = runner.add(Duration(minutes: _slotDuration)); continue; }
      DateTime slotStart = runner;
      DateTime slotEnd = runner.add(Duration(minutes: _slotDuration));
      bool isTaken = widget.existingBookings.any((booking) {
        bool overlaps = slotStart.isBefore(booking.endTime) && slotEnd.isAfter(booking.startTime);
        bool isValid = booking.isPaid || DateTime.now().isBefore(booking.startTime.add(const Duration(minutes: 1)));
        return overlaps && isValid && booking.machineId == widget.machine.id;
      });
      _slots.add({'date': runner, 'isTaken': isTaken});
      runner = runner.add(Duration(minutes: _slotDuration));
    }
    final firstAvailable = _slots.firstWhere((s) => s['isTaken'] == false, orElse: () => {});
    if (firstAvailable.isNotEmpty) _selectedSlot = firstAvailable['date'];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("Select Slot: ${widget.machine.name}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
          ]),
          const Divider(),
          Expanded(
            child: ListView.separated(
              itemCount: _slots.length,
              separatorBuilder: (c, i) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final slot = _slots[index];
                final bool isTaken = slot['isTaken'];
                final bool isSelected = _selectedSlot == slot['date'];
                return GestureDetector(
                  onTap: isTaken ? null : () => setState(() => _selectedSlot = slot['date']),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isTaken ? Colors.grey[100] : (isSelected ? const Color(0xFFB97AD9).withOpacity(0.1) : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? const Color(0xFFB97AD9) : Colors.grey[300]!, width: isSelected ? 2 : 1),
                    ),
                    child: Row(children: [
                      Icon(isTaken ? Icons.block : (isSelected ? Icons.check_circle : Icons.radio_button_unchecked), color: isSelected ? const Color(0xFFB97AD9) : Colors.grey),
                      const SizedBox(width: 12),
                      Text(DateFormat('h:mm a').format(slot['date']), style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (isTaken) ...[const Spacer(), const Text("Reserved", style: TextStyle(color: Colors.red, fontSize: 12))]
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedSlot == null ? null : () {
                final booking = Booking(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  machineId: widget.machine.id,
                  machineName: widget.machine.name,
                  userName: "You",
                  startTime: _selectedSlot!,
                  endTime: _selectedSlot!.add(Duration(minutes: _slotDuration)),
                  remark: "",
                );
                widget.onSave(booking);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB97AD9), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text("Confirm Reservation"),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}