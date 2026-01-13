import 'dart:async';
import 'dart:math'; 
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collection/collection.dart';
import '../services/notification_service.dart';
import 'payment_screen.dart';
import 'feedback_rating_page.dart';

// -------------------- MODELS --------------------

class WashingMachine {
  final String id;
  final String name;
  DateTime? endTime;
  String? currentRemark;
  String? status; 
  DateTime? maintenanceStart; 
  DateTime? maintenanceUntil; 

  WashingMachine({
    required this.id,
    required this.name,
    this.endTime,
    this.currentRemark,
    this.status,
    this.maintenanceStart,
    this.maintenanceUntil,
  });

  factory WashingMachine.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null || value == "") return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return WashingMachine(
      id: id,
      name: data['name'] ?? '',
      currentRemark: data['currentRemark'] ?? '',
      status: data['status'] ?? 'Available',
      maintenanceStart: parseDateTime(data['maintenanceStart']),
      maintenanceUntil: parseDateTime(data['maintenanceUntil']),
      endTime: parseDateTime(data['endTime']),
    );
  }
}

class Booking {
  final String id;
  final String machineId;
  final String machineName;
  final String userId;
  final String userName;
  final DateTime startTime;
  final DateTime endTime;
  final String type;
  bool isConfirmed;
  bool isPaid;

  Booking({
    required this.id,
    required this.machineId,
    required this.machineName,
    required this.userId,
    required this.userName,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.isConfirmed = false,
    this.isPaid = false,
  });

  factory Booking.fromFirestore(Map<String, dynamic> data, String id) {
    return Booking(
      id: id,
      machineId: data['machineId'] ?? '',
      machineName: data['machineName'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      startTime: DateTime.parse(data['startTime']),
      endTime: DateTime.parse(data['endTime']),
      type: data['type'] ?? 'Washer',
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Set<String> _shownPopups = {};

  @override
  void initState() {
    super.initState();
    _seedWashers();
    _startAutoCancelCheck();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  // --- AUTO CANCEL LOGIC: IF NOW > START TIME AND NOT CONFIRMED, DELETE ---
  void _startAutoCancelCheck() {
    _cleanupTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!mounted) return;
      final now = DateTime.now();
      
      final snapshot = await _firestore.collection('bookings')
          .where('type', isEqualTo: 'Washer')
          .where('isConfirmed', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        final startTimeString = doc.data()['startTime'];
        if (startTimeString != null) {
          final startTime = DateTime.parse(startTimeString);
          
          if (now.isAfter(startTime)) {
            await _firestore.collection('bookings').doc(doc.id).delete();
            NotificationService.cancelNotification(doc.id.hashCode);
          }
        }
      }
    });
  }

  void _autoReleaseExpiredMachines(List<WashingMachine> machines) {
    DateTime now = DateTime.now();
    for (var machine in machines) {
      if (machine.currentRemark == "In Use" && machine.endTime != null && now.isAfter(machine.endTime!)) {
        bool shouldBeInMaintenance = machine.maintenanceStart != null && now.isAfter(machine.maintenanceStart!);
        _firestore.collection('washers').doc(machine.id).update({
          'currentRemark': "",
          'status': shouldBeInMaintenance ? "Maintenance" : "Available",
          'endTime': "",
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cleanupTimer?.cancel();
    super.dispose();
  }

  void _handleSaveBooking(Booking newBooking) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore.runTransaction((transaction) async {
        QuerySnapshot existing = await _firestore.collection('bookings')
            .where('machineId', isEqualTo: newBooking.machineId)
            .where('startTime', isEqualTo: newBooking.startTime.toIso8601String())
            .get();
        if (existing.docs.isNotEmpty) throw Exception("Slot taken!");
        transaction.set(_firestore.collection('bookings').doc(newBooking.id), {
          'machineId': newBooking.machineId,
          'machineName': newBooking.machineName,
          'userId': user.uid,
          'userName': user.displayName ?? "User",
          'type': 'Washer',
          'startTime': newBooking.startTime.toIso8601String(),
          'endTime': newBooking.endTime.toIso8601String(),
          'isConfirmed': false,
          'isPaid': false,
        });
      });
      NotificationService.scheduleNotification(
        id: newBooking.id.hashCode,
        title: "Washer Turn Soon!",
        body: "Your turn for ${newBooking.machineName} starts in 5 minutes.",
        scheduledTime: newBooking.startTime.subtract(const Duration(minutes: 5)),
      );
      if (mounted) { Navigator.of(context).pop(); _showSuccessPopup(newBooking); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _handleCancelBooking(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).delete();
    NotificationService.cancelNotification(bookingId.hashCode);
  }

  void _handleConfirm(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).update({'isConfirmed': true});
  }

  Future<void> _handlePayAndStart(Booking booking) async {
    String machineNumber = booking.machineName.replaceAll(RegExp(r'[^0-9]'), '');
    final bool? success = await Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(machineType: "Washer", machineNo: machineNumber)));
    if (success == true) {
      DateTime washEndTime = DateTime.now().add(const Duration(minutes: 30));
      WriteBatch batch = _firestore.batch();
      batch.update(_firestore.collection('bookings').doc(booking.id), {'isPaid': true});
      batch.update(_firestore.collection('washers').doc(booking.machineId), {
        'endTime': washEndTime.toIso8601String(),
        'currentRemark': "In Use",
        'status': "In Use", 
      });
      await batch.commit();
    }
  }

  Future<void> _seedWashers() async {
    final washerCollection = _firestore.collection('washers');
    final snapshot = await washerCollection.get();
    if (snapshot.docs.isEmpty) {
      for (int i = 1; i <= 5; i++) {
        await washerCollection.doc(i.toString()).set({
          'name': 'Washer $i', 'endTime': '', 'currentRemark': '', 'status': 'Available', 'maintenanceStart': null, 'maintenanceUntil': null,
        });
      }
    }
  }

  void _showSuccessPopup(Booking booking) {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Center(child: Icon(Icons.check_circle, color: Colors.green, size: 60)),
      content: Text("Reserved ${booking.machineName}\nfor ${DateFormat('h:mm a').format(booking.startTime)}", textAlign: TextAlign.center),
      actions: [Center(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")))],
    ));
  }

  void _showRateUsPopup(String machineName) {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Center(child: Icon(Icons.stars_rounded, color: Colors.orange, size: 60)),
      content: Text("$machineName finished! Please collect items and rate us.", textAlign: TextAlign.center),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Later")),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB97AD9)), onPressed: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackRatingPage())); }, child: const Text("Rate Now", style: TextStyle(color: Colors.white)))
      ],
    ));
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    if (d.isNegative) return "00:00:00";
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUid = _auth.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text("WashSync - Washer", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: const Color(0xFFB97AD9), centerTitle: true),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF3E5F5), Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('washers').snapshots(),
          builder: (context, washerSnapshot) {
            if (!washerSnapshot.hasData) return const Center(child: CircularProgressIndicator());
            final machines = washerSnapshot.data!.docs.map((doc) => WashingMachine.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
            _autoReleaseExpiredMachines(machines);
            return StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('bookings').where('type', isEqualTo: 'Washer').snapshots(),
              builder: (context, bookingSnapshot) {
                final allBookings = bookingSnapshot.hasData ? bookingSnapshot.data!.docs.map((doc) => Booking.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList() : <Booking>[];
                DateTime now = DateTime.now();
                Set<String> displayedMachineIds = {};
                
                final myActiveBookings = allBookings.where((b) {
                  // FILTER: Only show bookings belonging to User B (logged in user)
                  if (b.userId != currentUid) return false;
                  
                  if (displayedMachineIds.contains(b.machineId)) return false;
                  final machine = machines.firstWhereOrNull((m) => m.id == b.machineId);
                  if (machine == null) return false;
                  
                  bool isRunning = b.isPaid && machine.endTime != null && now.isBefore(machine.endTime!);
                  bool isUpcoming = !b.isPaid && now.isBefore(b.startTime);
                  bool isRecentlyExpiredUnconfirmed = !b.isConfirmed && now.isBefore(b.startTime.add(const Duration(seconds: 10)));
                  
                  if (isRunning || isUpcoming || isRecentlyExpiredUnconfirmed) displayedMachineIds.add(b.machineId);
                  return isRunning || isUpcoming || isRecentlyExpiredUnconfirmed;
                }).toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (myActiveBookings.isNotEmpty) ...[
                      const Text("My Washer Bookings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF6A1B9A))),
                      const SizedBox(height: 12),
                      ...myActiveBookings.map((b) => _buildMyBookingCard(b, machines.firstWhere((m) => m.id == b.machineId))),
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

  Widget _buildWasherCard(WashingMachine machine, List<Booking> allBookings) {
    DateTime now = DateTime.now();
    bool isInUse = machine.currentRemark == "In Use";
    bool maintenanceScheduledReached = machine.maintenanceStart != null && now.isAfter(machine.maintenanceStart!);
    bool isUnderMaintenance = machine.status == 'Maintenance' || (maintenanceScheduledReached && !isInUse);
    return GestureDetector(
      onTap: isUnderMaintenance ? null : () => showModalBottomSheet(
        context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (c) => BookingModal(machine: machine, existingBookings: allBookings, onSave: _handleSaveBooking),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isUnderMaintenance ? Colors.grey[100] : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isUnderMaintenance ? Colors.red : (isInUse ? Colors.blue : Colors.purple.withOpacity(0.1)), width: 1.5)),
        child: Row(children: [
          Icon(isUnderMaintenance ? Icons.construction : Icons.local_laundry_service, color: isUnderMaintenance ? Colors.red : (isInUse ? Colors.blue : Colors.purple), size: 28),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(machine.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isUnderMaintenance ? Colors.grey[600] : Colors.black)),
            if (isUnderMaintenance) const Text("Offline: Maintenance", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
          ])),
          if (isInUse) const Badge(label: Text("IN USE"), backgroundColor: Colors.blue),
        ]),
      ),
    );
  }

  Widget _buildMyBookingCard(Booking booking, WashingMachine machine) {
    DateTime now = DateTime.now();
    bool isCycleRunning = booking.isPaid && machine.endTime != null && now.isBefore(machine.endTime!);
    bool isBeforeSlot = now.isBefore(booking.startTime.subtract(const Duration(minutes: 5)));
    
    // Logic: User must confirm within 5 minutes before the slot starts
    bool isConfirmWindow = now.isAfter(booking.startTime.subtract(const Duration(minutes: 5))) && now.isBefore(booking.startTime);

    if (booking.isPaid && machine.endTime != null && now.isAfter(machine.endTime!)) {
      if (!_shownPopups.contains(booking.id)) {
        _shownPopups.add(booking.id);
        WidgetsBinding.instance.addPostFrameCallback((_) => _showRateUsPopup(booking.machineName));
      }
    }

    return Card(
      elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), margin: const EdgeInsets.only(bottom: 12),
      child: Padding(padding: const EdgeInsets.all(16.0), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(booking.machineName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          if (!booking.isPaid) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _handleCancelBooking(booking.id)) else const Icon(Icons.verified, color: Colors.blue, size: 20)
        ]),
        const Divider(),
        if (isCycleRunning) ...[
          const Text("Wash Cycle In Progress", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: 1 - (machine.endTime!.difference(now).inSeconds / 1800), backgroundColor: Colors.blue.withOpacity(0.1), color: Colors.blue),
          const SizedBox(height: 12),
          Text(_formatDuration(machine.endTime!.difference(now)), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
        ] else if (isBeforeSlot && !isConfirmWindow) ...[
          Text("Confirm Window starts at ${DateFormat('h:mm a').format(booking.startTime.subtract(const Duration(minutes: 5)))}", style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ] else if (isConfirmWindow && !booking.isConfirmed) ...[
          // THE CONFIRMATION BUTTON UI
          Builder(builder: (context) {
            final timeUntilExpired = booking.startTime.difference(now);
            return Column(children: [
               Text("Slot starts in: ${timeUntilExpired.inMinutes}:${(timeUntilExpired.inSeconds % 60).toString().padLeft(2, '0')}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
               const SizedBox(height: 8),
               SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.location_on), style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white), onPressed: () => _handleConfirm(booking.id), label: const Text("CONFIRM ARRIVAL"))),
            ]);
          }),
        ] else if (booking.isConfirmed && !booking.isPaid) ...[
          SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB97AD9), foregroundColor: Colors.white), onPressed: () => _handlePayAndStart(booking), child: const Text("PAY NOW & START"))),
        ],
      ])),
    );
  }
}

// -------------------- BOOKING MODAL (Same Design) --------------------
class BookingModal extends StatefulWidget {
  final WashingMachine machine;
  final List<Booking> existingBookings;
  final Function(Booking) onSave;
  const BookingModal({super.key, required this.machine, required this.existingBookings, required this.onSave});
  @override State<BookingModal> createState() => _BookingModalState();
}

class _BookingModalState extends State<BookingModal> {
  DateTime? _selectedSlot;
  List<Map<String, dynamic>> _slots = [];
  final int _slotDuration = 35;
  final int _stepMinutes = 10;

  @override void initState() { super.initState(); _generateSlots(); }

  void _generateSlots() {
    _slots.clear();
    DateTime now = DateTime.now();
    DateTime runner = DateTime(now.year, now.month, now.day, now.hour, (now.minute / 5).ceil() * 5);
    DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59);
    while (runner.isBefore(endOfDay)) {
      DateTime slotStart = runner;
      DateTime slotEnd = runner.add(Duration(minutes: _slotDuration));
      if (slotStart.isBefore(now)) { runner = runner.add(Duration(minutes: _stepMinutes)); continue; }
      bool isTaken = widget.existingBookings.any((b) => b.machineId == widget.machine.id && slotStart.isBefore(b.endTime) && slotEnd.isAfter(b.startTime)) || (widget.machine.endTime != null && slotStart.isBefore(widget.machine.endTime!)); 
      _slots.add({'date': runner, 'isTaken': isTaken});
      runner = runner.add(Duration(minutes: _stepMinutes));
    }
    _selectedSlot = _slots.firstWhereOrNull((s) => !s['isTaken'])?['date'];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("Select Slot: ${widget.machine.name}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
        ]),
        const Divider(),
        Expanded(child: ListView.separated(
          itemCount: _slots.length,
          separatorBuilder: (c, i) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final slot = _slots[index];
            final bool isSelected = _selectedSlot == slot['date'];
            return GestureDetector(
              onTap: slot['isTaken'] ? null : () => setState(() => _selectedSlot = slot['date']),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: slot['isTaken'] ? Colors.grey[100] : (isSelected ? const Color(0xFFB97AD9).withOpacity(0.1) : Colors.white), borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? const Color(0xFFB97AD9) : Colors.grey[300]!, width: isSelected ? 2 : 1)),
                child: Row(children: [
                  Icon(slot['isTaken'] ? Icons.block : (isSelected ? Icons.check_circle : Icons.radio_button_unchecked), color: isSelected ? const Color(0xFFB97AD9) : Colors.grey),
                  const SizedBox(width: 12),
                  Text(DateFormat('h:mm a').format(slot['date']), style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (slot['isTaken']) ...[const Spacer(), const Text("Reserved", style: TextStyle(color: Colors.red, fontSize: 12))]
                ]),
              ),
            );
          },
        )),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _selectedSlot == null ? null : () {
          widget.onSave(Booking(
            id: DateTime.now().millisecondsSinceEpoch.toString(), machineId: widget.machine.id, machineName: widget.machine.name,
            userId: FirebaseAuth.instance.currentUser?.uid ?? 'unknown', userName: FirebaseAuth.instance.currentUser?.displayName ?? 'User',
            startTime: _selectedSlot!, endTime: _selectedSlot!.add(Duration(minutes: _slotDuration)), type: 'Washer',
          ));
        }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB97AD9), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Confirm Reservation", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
      ]),
    );
  }
}