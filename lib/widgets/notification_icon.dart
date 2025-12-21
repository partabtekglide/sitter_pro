import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationIcon extends StatelessWidget {
  const NotificationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) return const Icon(Icons.notifications_none);

    return StreamBuilder<List<Map<String, dynamic>>>(
      // Sirf UNREAD notifications suno
      stream: Supabase.instance.client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId) 
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Icon(Icons.notifications_none);
        }

        final notifications = snapshot.data!;
        // Count unread
        final unreadCount = notifications.where((n) => n['is_read'] == false).length;

        return Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.notifications, size: 28),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 8, // Adjust to fit the icon
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
