import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'announcements_viewmodel.dart';
import '../../../models/announcement_model.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/scaffold_with_drawer.dart';

class AnnouncementsView extends StackedView<AnnouncementsViewModel> {
  const AnnouncementsView({Key? key}) : super(key: key);

  @override
  Widget builder(
      BuildContext context, AnnouncementsViewModel viewModel, Widget? child) {
    return ScaffoldWithDrawer(
      title: 'Announcements',
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
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.error.withOpacity(0.5)),
                          ),
                          child: Icon(Icons.error_outline_rounded, size: 64, color: AppTheme.error),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Error loading announcements',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          viewModel.errorMessage ?? 'Unknown error',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.neutral400, fontSize: 16),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: viewModel.loadAnnouncements,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          child: const Text('Retry', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                )
              : viewModel.announcements.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.dark700,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(Icons.campaign_rounded, size: 64, color: AppTheme.neutral500),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No announcements',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Check back later for updates',
                            style: TextStyle(color: AppTheme.neutral400, fontSize: 16),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: viewModel.loadAnnouncements,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Refresh', style: TextStyle(fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            ),
                          ),
                        ],
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
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.dark700,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppTheme.dark600, width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 56,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    _getTypeColor(announcement.type),
                                                    _getTypeColor(announcement.type).withOpacity(0.7),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: _getTypeColor(announcement.type).withOpacity(0.3),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                _getTypeIcon(announcement.type),
                                                color: Colors.white,
                                                size: 28,
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
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 22,
                                                        color: Colors.white,
                                                        letterSpacing: -0.5),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 12, vertical: 6),
                                                    decoration: AppTheme.getBadgeDecoration(
                                                        _getTypeColor(announcement.type)),
                                                    child: Text(
                                                      _getTypeText(announcement.type),
                                                      style: TextStyle(
                                                        color: _getTypeColor(announcement.type),
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 11,
                                                        letterSpacing: 1,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        Container(
                                          width: double.infinity,
                                          height: 1,
                                          color: AppTheme.dark600,
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          announcement.message,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                            height: 1.6,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppTheme.dark600,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.calendar_today_rounded,
                                                  size: 18, color: AppTheme.pink600),
                                              const SizedBox(width: 8),
                                              Text(
                                                DateFormat('MMM dd, yyyy • HH:mm')
                                                    .format(announcement.createdAt),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppTheme.neutral300,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              if (announcement.flightId.isNotEmpty) ...[
                                                const Spacer(),
                                                Icon(Icons.flight_rounded,
                                                    size: 18, color: AppTheme.pink600),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Flight ${announcement.flightId.substring(0, 8)}...',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: AppTheme.neutral300,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
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
    );
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
        return 'DELAY';
      case AnnouncementType.cancellation:
        return 'CANCELLATION';
      case AnnouncementType.gateChange:
        return 'GATE CHANGE';
      case AnnouncementType.boardingStarted:
        return 'BOARDING STARTED';
      case AnnouncementType.general:
        return 'GENERAL';
    }
  }

  @override
  AnnouncementsViewModel viewModelBuilder(BuildContext context) =>
      AnnouncementsViewModel();

  @override
  void onViewModelReady(AnnouncementsViewModel viewModel) {
    viewModel.loadAnnouncements();
    viewModel.startAutoRefresh();
  }
}


