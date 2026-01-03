import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:intl/intl.dart';
import 'admin_announcements_viewmodel.dart';
import '../../../models/announcement_model.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/scaffold_with_drawer.dart';

class AdminAnnouncementsView extends StackedView<AdminAnnouncementsViewModel> {
  const AdminAnnouncementsView({Key? key}) : super(key: key);

  @override
  Widget builder(
      BuildContext context, AdminAnnouncementsViewModel viewModel, Widget? child) {
    return ScaffoldWithDrawer(
      title: 'Announcements Management',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: viewModel.loadAnnouncements,
          tooltip: 'Refresh',
        ),
      ],
      body: viewModel.isBusy && viewModel.announcements.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : viewModel.hasError && viewModel.announcements.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: AppTheme.error),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading announcements',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.error),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          viewModel.errorMessage ?? 'Unknown error',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.neutral600),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: viewModel.loadAnnouncements,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : viewModel.announcements.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.campaign_rounded, size: 64, color: AppTheme.neutral500),
                            const SizedBox(height: 16),
                            Text(
                              'No announcements yet',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Announcements will appear here when created',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.neutral400),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: viewModel.loadAnnouncements,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                  onRefresh: viewModel.loadAnnouncements,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.pink50,
                          border: Border(
                            bottom: BorderSide(color: AppTheme.neutral200, width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: AppTheme.pink600, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Auto-refreshing every 10 seconds',
                                style: TextStyle(
                                    color: AppTheme.pink700,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14),
                              ),
                            ),
                            if (viewModel.isBusy)
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.pink600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: viewModel.announcements.length,
                          itemBuilder: (context, index) {
                            final announcement = viewModel.announcements[index];
                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: _getTypeColor(announcement.type).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: _getTypeColor(announcement.type).withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Icon(
                                            _getTypeIcon(announcement.type),
                                            color: _getTypeColor(announcement.type),
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                announcement.title,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 18),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 4),
                                                decoration: AppTheme.getBadgeDecoration(
                                                    _getTypeColor(announcement.type)),
                                                child: Text(
                                                  _getTypeText(announcement.type),
                                                  style: TextStyle(
                                                    color: _getTypeColor(announcement.type),
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          onSelected: (value) {
                                            switch (value) {
                                              case 'edit':
                                                viewModel.navigateToUpdateAnnouncement(announcement);
                                                break;
                                              case 'delete':
                                                viewModel.showDeleteDialog(context, announcement);
                                                break;
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, size: 20),
                                                  SizedBox(width: 8),
                                                  Text('Edit'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                                  SizedBox(width: 8),
                                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Divider(color: AppTheme.neutral200),
                                    const SizedBox(height: 8),
                                    Text(
                                      announcement.message,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.neutral700,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today,
                                            size: 14, color: AppTheme.neutral500),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('yyyy-MM-dd HH:mm')
                                              .format(announcement.createdAt),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.neutral500,
                                          ),
                                        ),
                                        if (announcement.flightId.isNotEmpty) ...[
                                          const SizedBox(width: 16),
                                          Icon(Icons.flight,
                                              size: 14, color: AppTheme.neutral500),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'Flight: ${announcement.flightId.substring(0, 8)}...',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.neutral500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: viewModel.navigateToCreateAnnouncement,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  AdminAnnouncementsViewModel viewModelBuilder(BuildContext context) =>
      AdminAnnouncementsViewModel();

  @override
  void onViewModelReady(AdminAnnouncementsViewModel viewModel) {
    viewModel.loadAnnouncements();
    viewModel.startAutoRefresh();
  }

  Color _getTypeColor(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.delay:
        return AppTheme.warning;
      case AnnouncementType.cancellation:
        return AppTheme.error;
      case AnnouncementType.gateChange:
        return AppTheme.info;
      case AnnouncementType.boardingStarted:
        return AppTheme.success;
      case AnnouncementType.general:
        return AppTheme.neutral500;
    }
  }

  IconData _getTypeIcon(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.delay:
        return Icons.schedule;
      case AnnouncementType.cancellation:
        return Icons.cancel;
      case AnnouncementType.gateChange:
        return Icons.directions;
      case AnnouncementType.boardingStarted:
        return Icons.flight_takeoff;
      case AnnouncementType.general:
        return Icons.info;
    }
  }

  String _getTypeText(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.delay:
        return 'Delay';
      case AnnouncementType.cancellation:
        return 'Cancellation';
      case AnnouncementType.gateChange:
        return 'Gate Change';
      case AnnouncementType.boardingStarted:
        return 'Boarding Started';
      case AnnouncementType.general:
        return 'General';
    }
  }
}

