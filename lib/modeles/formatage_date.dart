import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class FormatageDate {
  // Formats timestamp into a relative string (e.g., "10:30" or "Mar 15, 2025")
  String formatTimestamp(int timestamp) {
    DateTime postTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    DateTime now = DateTime.now();
    DateFormat format;

    // Check if the post was made today
    if (now.difference(postTime).inDays == 0 && now.day == postTime.day) {
      format = DateFormat.Hm(); // Show time only (e.g., 10:30)
    } else {
      format = DateFormat.yMMMd(); // Show date (e.g., Mar 15, 2025)
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
    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(dateTime);

    final String formattedDate = _formatDate(dateTime, difference, now);

    return Text(
      formattedDate,
      style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
    );
  }

  String _formatDate(DateTime dateTime, Duration difference, DateTime now) {
    // If it's today
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      }
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    }

    // If it's yesterday
    if (difference.inDays == 1) {
      return 'Yesterday at ${DateFormat('HH:mm').format(dateTime)}';
    }

    // If it's this week (less than 7 days)
    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    // If it's this year
    if (dateTime.year == now.year) {
      return DateFormat('MMM d at HH:mm').format(dateTime);
    }

    // Otherwise, display the full date
    return DateFormat('MMM d yyyy').format(dateTime);
  }
}
