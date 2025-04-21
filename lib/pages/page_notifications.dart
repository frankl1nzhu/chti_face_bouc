import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services_firebase/service_authentification.dart';
import '../services_firebase/service_firestore.dart';
import '../modeles/notification.dart';
import '../widgets/widget_notif.dart';
import '../widgets/widget_vide.dart';

class PageNotifications extends StatelessWidget {
  const PageNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    final memberId = ServiceAuthentification().myId;

    if (memberId == null) {
      print("NOTIFICATIONS PAGE - No user logged in");
      return const Center(
        child: Text("Vous devez être connecté pour voir vos notifications"),
      );
    }

    print("NOTIFICATIONS PAGE - Loading notifications for user: $memberId");

    return StreamBuilder<QuerySnapshot>(
      stream: ServiceFirestore().notificationForUser(memberId),
      builder: (context, snapshot) {
        // Show loading indicator while waiting for data
        if (snapshot.connectionState == ConnectionState.waiting) {
          print("NOTIFICATIONS PAGE - Loading...");
          return const Center(child: CircularProgressIndicator());
        }

        // Handle errors
        if (snapshot.hasError) {
          print("NOTIFICATIONS PAGE - Error: ${snapshot.error}");
          return Center(child: Text("Erreur: ${snapshot.error}"));
        }

        // If no notifications, show empty state
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print("NOTIFICATIONS PAGE - No notifications found");
          return const Center(child: Text("Pas de notifications"));
        }

        // Display the notifications
        final notifications = snapshot.data!.docs;
        print(
          "NOTIFICATIONS PAGE - Found ${notifications.length} notifications",
        );

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = NotificationModel(
              reference: notifications[index].reference,
              id: notifications[index].id,
              data: notifications[index].data() as Map<String, dynamic>,
            );

            print(
              "NOTIFICATION ITEM - ID: ${notification.id}, From: ${notification.from}, Text: ${notification.text}",
            );
            return WidgetNotif(notif: notification);
          },
        );
      },
    );
  }
}
