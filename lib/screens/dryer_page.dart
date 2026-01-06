import '../services/notification_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'payment_screen.dart';
import 'feedback_rating_page.dart';

// -------------------- MODELS --------------------

class DryingMachine {
  final String id;
  final String name;
  DateTime? endTime;
  String? currentRemark;

  DryingMachine({
    required this.id,
    required this.name,
    this.endTime,
    this.currentRemark,
  });

  factory DryingMachine.fromFirestore(Map<String, dynamic> data, String id) {
    return DryingMachine(
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
  final String type;
  bool isConfirmed;
  bool isPaid;

  Booking({
    required this.id,
    required this.machineId,
    required this.machineName,
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

  Future<void> _seedDryers() async {
    final dryerCollection = _firestore.collection('dryers');
    final snapshot = await dryerCollection.get();
    if (snapshot.docs.isEmpty) {
      for (int i = 1; i <= 5; i++) {
        await dryerCollection.doc(i.toString()).set({
          'name': 'Dryer $i',
          'endTime': '',
          'currentRemark': '',
        });
      }
    }
  }

  void _startAutoCancelCheck() {
    // Increased interval to 30s and window to 5 mins to prevent accidental deletions during testing
    _cleanupTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!mounted) return;
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('bookings')
          .where('type', isEqualTo: 'Dryer')
          .where('isConfirmed', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        final startTimeString = doc.data()['startTime'];
        if (startTimeString != null) {
          final startTime = DateTime.parse(startTimeString);
          // Give user 5 minutes to confirm before auto-canceling
          if (now.isAfter(startTime.add(const Duration(minutes: 5)))) {
            await _firestore.collection('bookings').doc(doc.id).delete();
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
    final bookingRef = _firestore.collection('bookings');

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _firestore.runTransaction((transaction) async {
        // Verification query inside transaction
        QuerySnapshot existing = await bookingRef
            .where('machineId', isEqualTo: newBooking.machineId)
            .where('startTime', isEqualTo: newBooking.startTime.toIso8601String())
            .get();

        if (existing.docs.isNotEmpty) {
          throw Exception("Slot already reserved!");
        }

        // Generate a new unique document ID
        DocumentReference newDoc = bookingRef.doc();

        transaction.set(newDoc, {
          'machineId': newBooking.machineId,
          'machineName': newBooking.machineName,
          'userName': "You",
          'type': 'Dryer',
          'startTime': newBooking.startTime.toIso8601String(),
          'endTime': newBooking.endTime.toIso8601String(),
          'isConfirmed': false,
          'isPaid': false,
          'createdAt': FieldValue.serverTimestamp(), // Useful for sorting in Console
        });
      });

      print("DEBUG: Dryer booking successfully saved to Firestore.");

      if (mounted) {
        Navigator.pop(context); // Pop Loading
        Navigator.pop(context); // Pop Modal
        _showSuccessPopup(newBooking);
      }
    } catch (e) {
      print("DEBUG ERROR: $e");
      if (mounted) {
        Navigator.pop(context); // Pop Loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
  }

  void _showSuccessPopup(Booking booking) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(child: Icon(Icons.check_circle, color: Colors.green, size: 60)),
        content: Text(
          "Reserved ${booking.machineName}\nfor ${DateFormat('h:mm a').format(booking.startTime)}",
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK"),
            ),
          )
        ],
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
    _shownPopups.remove(booking.id);
    final bool? success = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaymentScreen()),
    );
    if (success == true) {
      DateTime dryEndTime = DateTime.now().add(const Duration(minutes: 30));
      await _firestore.collection('bookings').doc(booking.id).update({'isPaid': true});
      await _firestore.collection('dryers').doc(booking.machineId).update({
        'endTime': dryEndTime.toIso8601String(),
        'currentRemark': "In Use",
      });
    }
  }

  void _showRateUsPopup(String machineName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(child: Icon(Icons.check_circle, color: Colors.green, size: 50)),
        content: Text(
          "$machineName finished! Please collect your items and rate us.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Later", style: TextStyle(color: Colors.grey)),
          ),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("WashSync - Dryer",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFFB97AD9),
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3E5F5), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('dryers').snapshots(),
          builder: (context, dryerSnapshot) {
            if (!dryerSnapshot.hasData) return const Center(child: CircularProgressIndicator());
            final machines = dryerSnapshot.data!.docs
                .map((doc) => DryingMachine.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
                .toList();

            return StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('bookings')
                  .where('type', isEqualTo: 'Dryer')
                  .snapshots(),
              builder: (context, bookingSnapshot) {
                final allBookings = bookingSnapshot.hasData
                    ? bookingSnapshot.data!.docs
                        .map((doc) => Booking.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
                        .toList()
                    : <Booking>[];

                DateTime now = DateTime.now();
                Set<String> displayedMachineIds = {};

                final myActiveBookings = allBookings.where((b) {
                  if (b.userName != "You") return false;
                  if (displayedMachineIds.contains(b.machineId)) return false;

                  final machine = machines.firstWhereOrNull((m) => m.id == b.machineId);
                  if (machine == null) return false;

                  bool isRunning = b.isPaid && machine.endTime != null && now.isBefore(machine.endTime!);
                  bool isUpcoming = !b.isPaid && now.isBefore(b.startTime.add(const Duration(minutes: 5)));

                  bool shouldDisplay = isRunning || isUpcoming;
                  if (shouldDisplay) displayedMachineIds.add(b.machineId);

                  return shouldDisplay;
                }).toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (myActiveBookings.isNotEmpty) ...[
                      const Text("My Dryer Bookings",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF6A1B9A))),
                      const SizedBox(height: 12),
                      ...myActiveBookings.map((b) {
                        DryingMachine machine = machines.firstWhere((m) => m.id == b.machineId);
                        return _buildMyBookingCard(b, machine);
                      }),
                      const SizedBox(height: 24),
                    ],
                    const Text("All Dryers",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF6A1B9A))),
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
    bool isConfirmWindow = now.isAfter(booking.startTime.subtract(const Duration(minutes: 5))) &&
        now.isBefore(booking.startTime.add(const Duration(minutes: 5)));

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
                if (!booking.isPaid)
                  IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _handleCancelBooking(booking.id))
                else
                  const Icon(Icons.verified, color: Colors.blue, size: 20)
              ],
            ),
            const Divider(),
            if (isCycleRunning) ...[
              const Text("Drying Cycle In Progress",
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: 1 - (machine.endTime!.difference(now).inSeconds / 1800),
                backgroundColor: Colors.blue.withOpacity(0.1),
                color: Colors.blue,
              ),
              const SizedBox(height: 12),
              Text("Time Remaining: ${_formatDuration(machine.endTime!.difference(now))}",
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue, fontFamily: 'monospace')),
            ] else if (isBeforeSlot && !isConfirmWindow) ...[
              Text("Starts at ${DateFormat('h:mm a').format(booking.startTime)}",
                  style: const TextStyle(fontSize: 16, color: Colors.grey)),
            ] else if (isConfirmWindow && !booking.isConfirmed) ...[
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                      icon: const Icon(Icons.location_on),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                      onPressed: () => _handleConfirm(booking.id),
                      label: const Text("CONFIRM ARRIVAL"))),
            ] else if (booking.isConfirmed && !booking.isPaid) ...[
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB97AD9), foregroundColor: Colors.white),
                      onPressed: () => _handlePayAndStart(booking),
                      child: const Text("PAY NOW & START"))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDryerCard(DryingMachine machine, List<Booking> allBookings) {
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
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purple.withOpacity(0.1), width: 1.5)),
        child: Row(
          children: [
            const Icon(Icons.dry, color: Colors.purple, size: 28),
            const SizedBox(width: 16),
            Expanded(child: Text(machine.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          ],
        ),
      ),
    );
  }
}

// -------------------- BOOKING MODAL --------------------

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
      DateTime slotStart = runner;
      DateTime slotEnd = runner.add(Duration(minutes: _slotDuration));

      if (slotEnd.isBefore(now)) {
        runner = runner.add(Duration(minutes: _slotDuration));
        continue;
      }

      bool isTaken = widget.existingBookings.any((booking) {
        if (booking.machineId != widget.machine.id) return false;
        bool overlaps = slotStart.isBefore(booking.endTime) && slotEnd.isAfter(booking.startTime);
        return overlaps;
      });

      _slots.add({'date': runner, 'isTaken': isTaken});
      runner = runner.add(Duration(minutes: _slotDuration));
    }

    final firstAvailable = _slots.firstWhereOrNull((s) => !s['isTaken']);
    if (firstAvailable != null) _selectedSlot = firstAvailable['date'];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Select Slot: ${widget.machine.name}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                      color: isTaken
                          ? Colors.grey[100]
                          : (isSelected ? const Color(0xFFB97AD9).withOpacity(0.1) : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isSelected ? const Color(0xFFB97AD9) : Colors.grey[300]!, width: isSelected ? 2 : 1),
                    ),
                    child: Row(children: [
                      Icon(
                          isTaken
                              ? Icons.block
                              : (isSelected ? Icons.check_circle : Icons.radio_button_unchecked),
                          color: isSelected ? const Color(0xFFB97AD9) : Colors.grey),
                      const SizedBox(width: 12),
                      Text(DateFormat('h:mm a').format(slot['date']),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (isTaken) ...[
                        const Spacer(),
                        const Text("Reserved", style: TextStyle(color: Colors.red, fontSize: 12)),
                      ]
                    ]),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedSlot == null
                  ? null
                  : () {
                      final booking = Booking(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        machineId: widget.machine.id,
                        machineName: widget.machine.name,
                        userName: "You",
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