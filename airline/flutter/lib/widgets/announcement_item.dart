import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class AnnouncementItem extends StatelessWidget {
  final Map<String, dynamic> announcement;

  const AnnouncementItem({super.key, required this.announcement});

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'HIGH':
        return EldiyarTheme.errorRed;
      case 'MEDIUM':
        return EldiyarTheme.accentAmber;
      case 'LOW':
      default:
        return EldiyarTheme.primaryBlue;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'DELAY':
        return Icons.warning_amber_rounded;
      case 'CANCELLATION':
        return Icons.block;
      case 'GATE_CHANGE':
        return Icons.meeting_room;
      case 'BOARDING_SOON':
      case 'BOARDING_STARTED':
        return Icons.flight_takeoff;
      case 'FINAL_CALL':
        return Icons.timer_off;
      case 'SECURITY':
        return Icons.security;
      case 'CHECK_IN':
        return Icons.how_to_reg;
      case 'ARRIVAL':
        return Icons.flight_land;
      default: // GENERAL
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final priority = announcement['priority'] as String?;
    final type = announcement['type'] as String;
    final color = _getPriorityColor(priority);
    final createdAt = DateTime.parse(announcement['created_at']);
    final flight = announcement['flight'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: EldiyarTheme.cardBackground.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(priority == 'HIGH' ? 0.8 : 0.3),
          width: priority == 'HIGH' ? 2 : 1,
        ),
        boxShadow: [
          if (priority == 'HIGH' || priority == 'MEDIUM')
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              spreadRadius: 2,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Banner(
          message: priority == 'HIGH' ? 'ALERT' : (priority == 'MEDIUM' ? 'WARN' : 'INFO'),
          location: BannerLocation.topEnd,
          color: color,
          textStyle: const TextStyle(
            fontSize: 10, 
            fontWeight: FontWeight.bold,
            color: Colors.black, // Contrast
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Icon(
                        _getIconForType(type),
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            announcement['title'],
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (flight != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: EldiyarTheme.cardBackground,
                                border: Border.all(
                                  color: EldiyarTheme.textSecondary.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${flight['flight_number']} • ${flight['destination']['code']}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'RobotoMono', // Monospace feel
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  announcement['message'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: EldiyarTheme.textPrimary.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(color: EldiyarTheme.textSecondary.withOpacity(0.1)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('HH:mm • MMM dd').format(createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'RobotoMono',
                        color: EldiyarTheme.textSecondary,
                      ),
                    ),
                    if (announcement['effective_from'] != null)
                      Text(
                        'Active since ${_formatEffectiveTime(announcement['effective_from'])}',
                         style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color.withOpacity(0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatEffectiveTime(String dateStr) {
    final date = DateTime.parse(dateStr);
    return DateFormat('HH:mm').format(date);
  }
}
