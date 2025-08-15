import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dedicated_cowboy/app/services/pres.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

class UserStatusService with WidgetsBindingObserver {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _offlineTimer;

  void init() {
    WidgetsBinding.instance.addObserver(this);
    _setOnline(); // mark online when app starts
    // FirebaseAuth.instance.authStateChanges().listen((user) {
    //   if (user != null) {
    //     print('object aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
    //     PresenceIsolate.start();
    //   } else {
    //     PresenceIsolate.stop();
    //   }
    // });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_auth.currentUser == null) return;

    if (state == AppLifecycleState.resumed) {
      _setOnline();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _setOffline();
    }
  }

  Future<void> _setOnline() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).update({
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    });

    // cancel any pending offline timer
    _offlineTimer?.cancel();
  }

  Future<void> _setOffline() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Optional: Add a short delay to avoid false "offline" during quick app switching
    _offlineTimer = Timer(const Duration(seconds: 5), () async {
      await _firestore.collection('users').doc(uid).update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    });
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _offlineTimer?.cancel();
  }
}
