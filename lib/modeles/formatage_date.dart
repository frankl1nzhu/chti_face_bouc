import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class FormatageDate {
  // Formats timestamp into a relative string (e.g., "10:30" or "Mar 15, 2024")
  String formatTimestamp(int timestamp) {
    DateTime postTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    DateTime now = DateTime.now();
    DateFormat format;

    // Check if the post was made today
    if (now.difference(postTime).inDays == 0 && now.day == postTime.day) {
      format = DateFormat.Hm(); // Show time only (e.g., 14:35)
    } else {
      format = DateFormat.yMMMd(); // Show date (e.g., Mar 15, 2024)
    }
    return format.format(postTime).toString();
  }
}

// Helper Widget for Date Display
class DateHandler extends StatelessWidget {
  final int timestamp;
  const DateHandler({super.key, required this.timestamp});

  @override
  Widget build(BuildContext context) {
    return Text(
      FormatageDate().formatTimestamp(timestamp),
      style: TextStyle(color: Colors.grey[600], fontSize: 12),
    );
  }
}
