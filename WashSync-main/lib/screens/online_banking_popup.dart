import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class OnlineBankingPopup extends StatefulWidget {
  final String bankName;
  final double amount;

  const OnlineBankingPopup({super.key, required this.bankName, required this.amount});

  @override
  State<OnlineBankingPopup> createState() => _OnlineBankingPopupState();
}

class _OnlineBankingPopupState extends State<OnlineBankingPopup> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _tacController = TextEditingController();

  int _currentStep = 1; // 1: Login, 2: TAC
  bool _isLoading = false;
  bool _obscurePassword = true; // For the Eye toggle
  bool _isExpired = false;
  String? _validTac;
  
  Timer? _timer;
  int _secondsRemaining = 60; // Set to 1 Minute

  void _startTacTimer() {
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

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    String username = _userController.text.trim();
    String password = _passController.text;

    try {
      var doc = await FirebaseFirestore.instance.collection('bank_users').doc(username).get();

      if (doc.exists) {
        var data = doc.data()!;
        if (data['bank'] != widget.bankName) {
          setState(() => _isLoading = false);
          _showError("Account not linked to ${widget.bankName}");
          return;
        }

        if (data['password'] == password && data['isActive'] == true) {
          setState(() {
            _validTac = data['tac']?.toString();
            _currentStep = 2;
            _isLoading = false;
          });
          _startTacTimer();
          _sendTacNotification(_validTac!);
        } else {
          setState(() => _isLoading = false);
          _showError("Invalid Password");
        }
      } else {
        setState(() => _isLoading = false);
        _showError("Username not found");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("Connection Error");
    }
  }

  void _sendTacNotification(String tac) {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height - 110, left: 10, right: 10),
          backgroundColor: const Color(0xFF1A1A1A),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${widget.bankName.toUpperCase()} • now", style: const TextStyle(fontSize: 10, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              Text("Your TAC is $tac. Valid for 1 minute.", style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _userController.dispose();
    _passController.dispose();
    _tacController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Column(
        children: [
          const Icon(Icons.shield_outlined, color: Colors.blueAccent, size: 36),
          const SizedBox(height: 8),
          Text(widget.bankName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Total: RM ${widget.amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(height: 30),
            
            if (_currentStep == 1) ...[
              TextField(
                controller: _userController,
                decoration: InputDecoration(hintText: "Username", filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 10),
              // PASSWORD FIELD WITH EYE ICON
              TextField(
                controller: _passController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: "Password", 
                  filled: true, 
                  fillColor: Colors.grey[100], 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_isLoading) 
                const CircularProgressIndicator()
              else
                _actionButtons("Cancel", "LOGIN", _handleLogin, Colors.blueAccent),
            ] else ...[
              Text(_isExpired ? "TAC EXPIRED" : "Enter TAC Code", style: TextStyle(fontWeight: FontWeight.bold, color: _isExpired ? Colors.red : Colors.black)),
              Text("00:${_secondsRemaining.toString().padLeft(2, '0')}", style: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(
                controller: _tacController,
                keyboardType: TextInputType.number,
                enabled: !_isExpired,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(letterSpacing: 10, fontSize: 22, fontWeight: FontWeight.bold),
                decoration: InputDecoration(counterText: "", filled: true, fillColor: _isExpired ? Colors.red[50] : Colors.blue[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 20),
              _actionButtons(
                "Back", 
                _isExpired ? "RESEND TAC" : "CONFIRM", 
                _isExpired ? _handleLogin : () {
                  if (_tacController.text == _validTac) {
                    Navigator.pop(context, true);
                  } else {
                    _showError("Incorrect TAC");
                  }
                },
                _isExpired ? Colors.orange : Colors.blueAccent
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionButtons(String left, String right, VoidCallback onRight, Color rightColor) {
    return Row(
      children: [
        Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: Text(left, style: const TextStyle(color: Colors.grey)))),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: onRight,
            style: ElevatedButton.styleFrom(backgroundColor: rightColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
            child: Text(right, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}