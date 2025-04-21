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
    // Si c'est aujourd'hui
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'À l\'instant';
        }
        return 'Il y a ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'}';
      }
      return 'Il y a ${difference.inHours} ${difference.inHours == 1 ? 'heure' : 'heures'}';
    }

    // Si c'est hier
    if (difference.inDays == 1) {
      return 'Hier à ${DateFormat('HH:mm').format(dateTime)}';
    }

    // Si c'est cette semaine (moins de 7 jours)
    if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    }

    // Si c'est cette année
    if (dateTime.year == now.year) {
      return DateFormat('d MMM à HH:mm').format(dateTime);
    }

    // Sinon, affiche la date complète
    return DateFormat('d MMM yyyy').format(dateTime);
  }
}
