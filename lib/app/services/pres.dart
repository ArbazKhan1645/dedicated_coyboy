// import 'dart:isolate';
// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class PresenceIsolate {
//   static Isolate? _isolate;
//   static SendPort? _sendPort;

//   static Future<void> start() async {
//     if (_isolate != null) return; // already running
//     final receivePort = ReceivePort();
//     _isolate = await Isolate.spawn(_presenceLoop, receivePort.sendPort);

//     _sendPort = await receivePort.first as SendPort;
//     _sendPort?.send({'uid': FirebaseAuth.instance.currentUser?.uid});
//   }

//   static void stop() {
//     _isolate?.kill(priority: Isolate.immediate);
//     _isolate = null;
//     _sendPort = null;
//   }

//   static Future<void> _presenceLoop(SendPort sendPort) async {
//     final port = ReceivePort();
//     sendPort.send(port.sendPort);

//     await for (final message in port) {
//       final uid = message['uid'];
//       if (uid != null) {
//         Timer.periodic(const Duration(seconds: 10), (_) async {
//           try {
//             print('1sdad aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
//             await FirebaseFirestore.instance
//                 .collection('users')
//                 .doc(uid)
//                 .update({'lastPing': FieldValue.serverTimestamp()});
//           } catch (e) {
//             print(
//               e.toString() + 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
//             );
//           }
//         });
//       }
//     }
//   }
// }
