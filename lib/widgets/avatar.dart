import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  final double radius;
  final String url;

  const Avatar({super.key, required this.radius, required this.url});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      // Use NetworkImage if URL is not empty, otherwise show FlutterLogo
      backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
      child:
          url.isEmpty
              ? FlutterLogo(size: radius) // Show FlutterLogo if no URL
              : null, // Important: child should be null if backgroundImage is used
    );
  }
}
