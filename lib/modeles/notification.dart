import 'package:cloud_firestore/cloud_firestore.dart';
import 'constantes.dart';

class NotificationModel {
  // Renamed to avoid conflict with Flutter's Notification
  final DocumentReference reference;
  final String id;
  final Map<String, dynamic> data;

  NotificationModel({
    required this.reference,
    required this.id,
    required this.data,
  });

  String get from => data[fromKey] ?? ""; // User ID of sender
  String get text =>
      data[textKey] ??
      ""; // Notification text (e.g., "a aimé votre post", "a commenté...")
  int get date => data[dateKey] ?? 0; // Timestamp
  bool get isRead => data[isReadKey] ?? false; // Read status
  String get postId => data[postIdKey] ?? ""; // ID of the related post
}
