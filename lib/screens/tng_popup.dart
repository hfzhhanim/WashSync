import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for FilteringTextInputFormatter
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class TngPopup extends StatefulWidget {
  final double amount;
  const TngPopup({super.key, required this.amount});

  @override
  State<TngPopup> createState() => _TngPopupState();
}

class _TngPopupState extends State<TngPopup> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  
  bool _isVerifyingPhone = true; 
  bool _isLoading = false;
  bool _isExpired = false;
  String? _validPin;
  
  Timer? _timer;
  int _secondsRemaining = 60; // 1 Minute

  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _isExpired = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        if (mounted) setState(() => _isExpired = true);
      }
    });
  }

  Future<void> _verifyPhone() async {
    setState(() => _isLoading = true);
    String inputPhone = _phoneController.text.trim();

    try {
      var query = await FirebaseFirestore.instance
          .collection('tng_users')
          .where('phone', isEqualTo: inputPhone)
          .get();

      if (query.docs.isNotEmpty) {
        var userData = query.docs.first.data();
        if (userData['isActive'] == true) {
          setState(() {
            _validPin = userData['pin']?.toString();
            _isVerifyingPhone = false;
            _isLoading = false;
          });
          _startTimer();
          _triggerFakeNotification(_validPin!);
        } else {
          setState(() => _isLoading = false);
          _showSnackBar("TNG Account Inactive");
        }
      } else {
        setState(() => _isLoading = false);
        _showSnackBar("Number not registered");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Database Error");
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  void _triggerFakeNotification(String pin) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 10),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height - 110, left: 10, right: 10),
          backgroundColor: const Color(0xFF2C3E50),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("TNG EWALLET • now", style: TextStyle(fontSize: 10, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              Text("Your payment PIN is $pin. It expires in 1 minute.", style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.network(
            "https://upload.wikimedia.org/wikipedia/commons/thumb/e/eb/Touch_%27n_Go_eWallet_logo.svg/1200px-Touch_%27n_Go_eWallet_logo.svg.png", 
            height: 40,
            errorBuilder: (c, e, s) => const Icon(Icons.wallet, color: Colors.blue, size: 40),
          ),
          const SizedBox(height: 15),
          Text("Pay RM ${widget.amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Divider(height: 30),
          
          if (_isVerifyingPhone) ...[
            const Text("Enter TNG Mobile Number", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.number, // Shows number pad
              inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Blocks letters
              decoration: InputDecoration(
                hintText: "01XXXXXXXX",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading) 
              const CircularProgressIndicator()
            else
              _rowButtons(
                leftText: "Cancel", 
                leftOnTap: () => Navigator.pop(context), 
                rightText: "GET PIN", 
                rightOnTap: _verifyPhone, 
                rightColor: Colors.blue
              ),
          ] else ...[
            Text(_isExpired ? "PIN EXPIRED" : "Enter PIN", style: TextStyle(fontWeight: FontWeight.bold, color: _isExpired ? Colors.red : Colors.blue)),
            Text("00:${_secondsRemaining.toString().padLeft(2, '0')}", style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number, // Shows number pad
              inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Blocks letters
              obscureText: true,
              enabled: !_isExpired,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(letterSpacing: 10, fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(counterText: "", filled: true, fillColor: _isExpired ? Colors.red[50] : Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 20),
            _rowButtons(
              leftText: "Cancel", 
              leftOnTap: () => Navigator.pop(context), 
              rightText: _isExpired ? "RESEND" : "CONFIRM", 
              rightOnTap: _isExpired ? _verifyPhone : () {
                if (_pinController.text == _validPin) {
                  Navigator.pop(context, true);
                } else {
                  _showSnackBar("Incorrect PIN");
                }
              }, 
              rightColor: _isExpired ? Colors.orange : Colors.blue
            ),
          ],
        ],
      ),
    );
  }

  Widget _rowButtons({required String leftText, required VoidCallback leftOnTap, required String rightText, required VoidCallback rightOnTap, required Color rightColor}) {
    return Row(
      children: [
        Expanded(child: TextButton(onPressed: leftOnTap, child: Text(leftText, style: const TextStyle(color: Colors.grey)))),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: rightOnTap,
            style: ElevatedButton.styleFrom(backgroundColor: rightColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text(rightText, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}