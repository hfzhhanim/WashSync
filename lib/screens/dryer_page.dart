import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collection/collection.dart';
import '../services/notification_service.dart';
import 'payment_screen.dart';
import 'feedback_rating_page.dart';

// -------------------- MODELS --------------------

class DryingMachine {
  final String id;
  final String name;
  DateTime? endTime;
  String? currentRemark;
  String? status; // Added to match Admin App logic
  String? maintenanceUntil;

  DryingMachine({
    required this.id,
    required this.name,
    this.endTime,
    this.currentRemark,
    this.status,
    this.maintenanceUntil,
  });

  factory DryingMachine.fromFirestore(Map<String, dynamic> data, String id) {
    return DryingMachine(
      id: id,
      name: data['name'] ?? '',
      currentRemark: data['currentRemark'] ?? '',
      status: data['status'] ?? 'Available', //
      maintenanceUntil: data['maintenanceUntil'],
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
      type: data['type'] ?? 'Dryer',
      isConfirmed: data['isConfirmed'] ?? false,
      isPaid: data['isPaid'] ?? false,
    );
  }
}

// -------------------- MAIN SCREEN --------------------

class DryerPage extends StatefulWidget {
  const DryerPage({super.key});

  @override
  State<DryerPage> createState() => _DryerPageState();
}

class _DryerPageState extends State<DryerPage> {
  Timer? _timer;
  Timer? _cleanupTimer;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Set<String> _shownPopups = {};

  @override
  void initState() {
    super.initState();
    _seedDryers();
    _startAutoCancelCheck();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  // --- LOGIC TO AUTO-RELEASE MACHINES ---
  void _autoReleaseExpiredMachines(List<DryingMachine> machines) {
    DateTime now = DateTime.now();
    for (var machine in machines) {
      if (machine.currentRemark == "In Use" && machine.endTime != null && now.isAfter(machine.endTime!)) {
        _firestore.collection('dryers').doc(machine.id).update({
          'currentRemark': "",
          'status': "Available",
          'endTime': "",
        });
      }
    }
  }

  // --- UPDATED CARD LOGIC: ONLY LOCK IF MAINTENANCE ---
  Widget _buildDryerCard(DryingMachine machine, List<Booking> allBookings) {
    bool isUnderMaintenance = machine.status == 'Maintenance'; 
    bool isInUse = machine.currentRemark == "In Use";

    return GestureDetector(
      onTap: isUnderMaintenance
          ? () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Dryer under maintenance. Please choose another.")))
          : () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (c) => BookingModal(machine: machine, existingBookings: allBookings, onSave: _handleSaveBooking),
              ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: isUnderMaintenance ? Colors.grey[100] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isUnderMaintenance ? Colors.orange : (isInUse ? Colors.blue : Colors.purple.withOpacity(0.1)), 
                width: 1.5)),
        child: Row(
          children: [
            Icon(
              isUnderMaintenance ? Icons.build_circle : Icons.dry, 
              color: isUnderMaintenance ? Colors.orange : (isInUse ? Colors.blue : Colors.purple), 
              size: 28
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(machine.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isUnderMaintenance ? Colors.grey[600] : Colors.black)),
                  if (isUnderMaintenance) const Text("Offline: Maintenance", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                  if (isInUse) const Text("Book for another slot ", style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            if (isUnderMaintenance) const Badge(label: Text("OFFLINE"), backgroundColor: Colors.orange),
            if (isInUse) const Badge(label: Text("IN USE"), backgroundColor: Colors.blue),
          ],
        ),
      ),
    );
  }

  Future<void> _seedDryers() async {
    final dryerCollection = _firestore.collection('dryers');
    final snapshot = await dryerCollection.get();
    if (snapshot.docs.isEmpty) {
      for (int i = 1; i <= 5; i++) {
        await dryerCollection.doc(i.toString()).set({
          'name': 'Dryer $i',
          'endTime': '',
          'currentRemark': '',
          'status': 'Available', //
          'maintenanceUntil': '',
        });
      }
    }
  }

  void _startAutoCancelCheck() {
    _cleanupTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!mounted) return;
      final now = DateTime.now();
      final snapshot = await _firestore.collection('bookings')
          .where('type', isEqualTo: 'Dryer')
          .where('isConfirmed', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        final startTimeString = doc.data()['startTime'];
        if (startTimeString != null) {
          final startTime = DateTime.parse(startTimeString);
          if (now.isAfter(startTime.add(const Duration(minutes: 5)))) {
            await _firestore.collection('bookings').doc(doc.id).delete();
            NotificationService.cancelNotification(doc.id.hashCode);
          }
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

  void _handleSaveBooking(Booking newBooking) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final bookingRef = _firestore.collection('bookings');
    try {
      await _firestore.runTransaction((transaction) async {
        QuerySnapshot existing = await bookingRef
            .where('machineId', isEqualTo: newBooking.machineId)
            .where('startTime', isEqualTo: newBooking.startTime.toIso8601String())
            .get();

        if (existing.docs.isNotEmpty) throw Exception("Slot taken!");

        transaction.set(bookingRef.doc(newBooking.id), {
          'machineId': newBooking.machineId,
          'machineName': newBooking.machineName,
          'userId': user.uid,
          'userName': user.displayName ?? "User",
          'type': 'Dryer',
          'startTime': newBooking.startTime.toIso8601String(),
          'endTime': newBooking.endTime.toIso8601String(),
          'isConfirmed': false,
          'isPaid': false,
        });
      });

      DateTime reminderTime = newBooking.startTime.subtract(const Duration(minutes: 5));
      NotificationService.scheduleNotification(
        id: newBooking.id.hashCode,
        title: "Dryer Turn Soon!",
        body: "Your turn for ${newBooking.machineName} starts in 5 minutes.",
        scheduledTime: reminderTime,
      );

      if (mounted) {
        Navigator.of(context).pop();
        _showSuccessPopup(newBooking);
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
    NotificationService.cancelNotification(bookingId.hashCode);
  }

  void _handleConfirm(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).update({'isConfirmed': true});
  }

  Future<void> _handlePayAndStart(Booking booking) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.uid != booking.userId) return;

    String machineNumber = booking.machineName.replaceAll(RegExp(r'[^0-9]'), '');

    final bool? success = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PaymentScreen(
                  machineType: "Dryer",
                  machineNo: machineNumber,
                )));

    if (success == true) {
      DateTime dryEndTime = DateTime.now().add(const Duration(minutes: 30));

      WriteBatch batch = _firestore.batch();
      DocumentReference bookingDoc = _firestore.collection('bookings').doc(booking.id);
      DocumentReference machineDoc = _firestore.collection('dryers').doc(booking.machineId);

      batch.update(bookingDoc, {'isPaid': true});
      // UPDATED: Sync both fields for Admin App
      batch.update(machineDoc, {
        'endTime': dryEndTime.toIso8601String(),
        'currentRemark': "In Use",
        'status': "In Use", 
      });

      await batch.commit();

      NotificationService.scheduleNotification(
        id: booking.id.hashCode + 1,
        title: "Dryer Almost Done!",
        body: "Your laundry will be ready in 5 minutes.",
        scheduledTime: DateTime.now().add(const Duration(minutes: 25)),
      );

      NotificationService.scheduleNotification(
        id: booking.id.hashCode + 2,
        title: "Dryer Finished!",
        body: "Your laundry is done. Please collect it now!",
        scheduledTime: DateTime.now().add(const Duration(minutes: 30)),
      );
    }
  }

  void _showRateUsPopup(String machineName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(child: Icon(Icons.stars_rounded, color: Colors.orange, size: 60)),
        content: Text("$machineName finished! Please collect items and rate us.", textAlign: TextAlign.center),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Later")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB97AD9)),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackRatingPage()));
            },
            child: const Text("Rate Now", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
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
      appBar: AppBar(title: const Text("WashSync - Dryer", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: const Color(0xFFB97AD9), centerTitle: true),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF3E5F5), Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('dryers').snapshots(),
          builder: (context, dryerSnapshot) {
            if (!dryerSnapshot.hasData) return const Center(child: CircularProgressIndicator());
            final machines = dryerSnapshot.data!.docs.map((doc) => DryingMachine.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();

            _autoReleaseExpiredMachines(machines);

            return StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('bookings').where('type', isEqualTo: 'Dryer').snapshots(),
              builder: (context, bookingSnapshot) {
                final allBookings = bookingSnapshot.hasData ? bookingSnapshot.data!.docs.map((doc) => Booking.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList() : <Booking>[];

                DateTime now = DateTime.now();
                Set<String> displayedMachineIds = {};

                final myActiveBookings = allBookings.where((b) {
                  if (b.userId != currentUid) return false;
                  if (displayedMachineIds.contains(b.machineId)) return false;
                  final machine = machines.firstWhereOrNull((m) => m.id == b.machineId);
                  if (machine == null) return false;

                  bool isRunning = b.isPaid && machine.endTime != null && now.isBefore(machine.endTime!);
                  bool isUpcoming = !b.isPaid && now.isBefore(b.startTime.add(const Duration(minutes: 5)));

                  if (isRunning || isUpcoming) displayedMachineIds.add(b.machineId);
                  return isRunning || isUpcoming;
                }).toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (myActiveBookings.isNotEmpty) ...[
                      const Text("My Dryer Bookings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF6A1B9A))),
                      const SizedBox(height: 12),
                      ...myActiveBookings.map((b) => _buildMyBookingCard(b, machines.firstWhere((m) => m.id == b.machineId))),
                      const SizedBox(height: 24),
                    ],
                    const Text("All Dryers", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF6A1B9A))),
                    const SizedBox(height: 12),
                    ...machines.map((m) => _buildDryerCard(m, allBookings)),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMyBookingCard(Booking booking, DryingMachine machine) {
    DateTime now = DateTime.now();
    bool isCycleRunning = booking.isPaid && machine.endTime != null && now.isBefore(machine.endTime!);
    bool isBeforeSlot = now.isBefore(booking.startTime);
    bool isConfirmWindow = now.isAfter(booking.startTime.subtract(const Duration(minutes: 5))) && now.isBefore(booking.startTime.add(const Duration(minutes: 5)));

    if (booking.isPaid && machine.endTime != null && now.isAfter(machine.endTime!)) {
      if (!_shownPopups.contains(booking.id)) {
        _shownPopups.add(booking.id);
        WidgetsBinding.instance.addPostFrameCallback((_) => _showRateUsPopup(booking.machineName));
      }
    }

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
                if (!booking.isPaid) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _handleCancelBooking(booking.id)) else const Icon(Icons.verified, color: Colors.blue, size: 20)
              ],
            ),
            const Divider(),
            if (isCycleRunning) ...[
              const Text("Dry Cycle In Progress", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: 1 - (machine.endTime!.difference(now).inSeconds / 1800),
                backgroundColor: Colors.blue.withOpacity(0.1),
                color: Colors.blue,
              ),
              const SizedBox(height: 12),
              Text("Time Remaining: ${_formatDuration(machine.endTime!.difference(now))}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue, fontFamily: 'monospace')),
            ] else if (isBeforeSlot && !isConfirmWindow) ...[
              Text("Starts at ${DateFormat('h:mm a').format(booking.startTime)}", style: const TextStyle(fontSize: 16, color: Colors.grey)),
            ] else if (isConfirmWindow && !booking.isConfirmed) ...[
              SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.location_on), style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white), onPressed: () => _handleConfirm(booking.id), label: const Text("CONFIRM ARRIVAL"))),
            ] else if (booking.isConfirmed && !booking.isPaid) ...[
              SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB97AD9), foregroundColor: Colors.white), onPressed: () => _handlePayAndStart(booking), child: const Text("PAY NOW & START"))),
            ],
          ],
        ),
      ),
    );
  }
}

// -------------------- BOOKING MODAL (UPDATED SLOTS) --------------------
class BookingModal extends StatefulWidget {
  final DryingMachine machine;
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
  final int _stepMinutes = 10;

  @override
  void initState() {
    super.initState();
    _generateSlots();
  }

  // --- UPDATED: ALSO BLOCK SLOTS IF MACHINE IS CURRENTLY RUNNING ---
  void _generateSlots() {
    _slots.clear();
    DateTime now = DateTime.now();
    int roundedMinutes = (now.minute / 5).ceil() * 5;
    DateTime runner = DateTime(now.year, now.month, now.day, now.hour, roundedMinutes);
    DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59);

    while (runner.isBefore(endOfDay)) {
      DateTime slotStart = runner;
      DateTime slotEnd = runner.add(Duration(minutes: _slotDuration));

      if (slotStart.isBefore(now)) {
        runner = runner.add(Duration(minutes: _stepMinutes));
        continue;
      }

      // Check against existing bookings AND the machine's current running time
      bool isTaken = widget.existingBookings.any((booking) {
        if (booking.machineId != widget.machine.id) return false;
        return slotStart.isBefore(booking.endTime) && slotEnd.isAfter(booking.startTime);
      }) || (widget.machine.endTime != null && slotStart.isBefore(widget.machine.endTime!)); 

      _slots.add({'date': runner, 'isTaken': isTaken});
      runner = runner.add(Duration(minutes: _stepMinutes));
    }
    final firstAvailable = _slots.firstWhereOrNull((s) => !s['isTaken']);
    if (firstAvailable != null) _selectedSlot = firstAvailable['date'];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Select Slot: ${widget.machine.name}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedSlot == null ? null : () {
                final user = FirebaseAuth.instance.currentUser;
                final booking = Booking(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  machineId: widget.machine.id,
                  machineName: widget.machine.name,
                  userId: user?.uid ?? 'unknown',
                  userName: user?.displayName ?? 'User',
                  startTime: _selectedSlot!,
                  endTime: _selectedSlot!.add(Duration(minutes: _slotDuration)),
                  type: 'Dryer',
                );
                widget.onSave(booking);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB97AD9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Confirm Reservation", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}