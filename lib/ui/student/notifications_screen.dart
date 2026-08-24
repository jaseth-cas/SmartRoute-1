import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock/mock_data.dart';
import '../theme/colors.dart';
import '../components/student_bottom_bar.dart';
import '../components/notification_card.dart';
import '../components/info_banner.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmartColors.smartBackground,
      appBar: AppBar(
        title: const Text('Notificaciones', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/student_home');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/notification_settings'),
          ),
        ],
      ),
      bottomNavigationBar: StudentBottomBar(
        currentRoute: '/notifications',
        onNavigate: (route) => context.go(route),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Notificaciones activas', style: TextStyle(fontWeight: FontWeight.w600, color: SmartColors.smartText)),
                Switch(
                  value: notificationsEnabled,
                  onChanged: (value) => setState(() => notificationsEnabled = value),
                  activeThumbColor: SmartColors.smartBlue,
                ),
              ],
            ),
          ),
          if (!notificationsEnabled)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: InfoBanner(
                text: 'Has desactivado las notificaciones. No recibirás alertas de proximidad.',
                containerColor: SmartColors.smartLightRed,
                contentColor: SmartColors.smartRed,
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: MockData.notifications.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == MockData.notifications.length) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 16.0, bottom: 32.0),
                    child: InfoBanner(
                      text: 'Estas notificaciones son simuladas para fines de demostración académica.',
                      icon: Icons.verified_user,
                    ),
                  );
                }
                return NotificationCard(notification: MockData.notifications[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
