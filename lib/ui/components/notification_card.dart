import 'package:flutter/material.dart';
import '../../data/models/models.dart';
import '../theme/colors.dart';
import 'smart_route_card.dart';

class NotificationCard extends StatelessWidget {
  final NotificationMock notification;

  const NotificationCard({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case 'alert':
        icon = Icons.warning;
        iconColor = SmartColors.smartRed;
        break;
      case 'info':
        icon = Icons.info;
        iconColor = SmartColors.smartBlue;
        break;
      case 'system':
        icon = Icons.settings;
        iconColor = SmartColors.smartGreen;
        break;
      default:
        icon = Icons.notifications;
        iconColor = SmartColors.smartGray;
    }

    return SmartRouteCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: SmartColors.smartText,
                        ),
                      ),
                    ),
                    if (!notification.read)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: SmartColors.smartBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: const TextStyle(fontSize: 12, color: SmartColors.smartGray, height: 1.5),
                ),
                const SizedBox(height: 8),
                Text(
                  notification.time,
                  style: TextStyle(fontSize: 11, color: SmartColors.smartGray.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
