import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class NotificationIcon extends StatelessWidget {
  const NotificationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: SupabaseService.instance.notificationsNotifier,
      builder: (context, notifications, child) {
        // Count unread: anything that is not true is unread (including null)
        final unreadCount = notifications.where((n) => n['is_read'] != true).length;

        return Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.notifications, size: 28),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
          ],
        );
      },
    );
  }
}
