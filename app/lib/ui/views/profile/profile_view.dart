import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:intl/intl.dart';
import 'profile_viewmodel.dart';
import '../../../models/user_model.dart';
import '../../../models/booking_model.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/scaffold_with_drawer.dart';

class ProfileView extends StackedView<ProfileViewModel> {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget builder(
      BuildContext context, ProfileViewModel viewModel, Widget? child) {
    return ScaffoldWithDrawer(
      title: 'Profile',
      body: viewModel.isBusy
          ? const Center(child: CircularProgressIndicator())
          : viewModel.errorMessage != null
              ? SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Show "Вы админ" badge if admin email detected
                        if (viewModel.isAdmin) ...[
                          Container(
                            padding: const EdgeInsets.all(24.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.pink600,
                                  AppTheme.pink800,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.pink600.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.admin_panel_settings_rounded,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Text(
                                  'Вы админ',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                        // Error message
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: AppTheme.error,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading profile',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.error,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                viewModel.errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppTheme.neutral600),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => viewModel.loadUserData(),
                                    child: const Text('Retry'),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton(
                                    onPressed: () => viewModel.navigateToLogin(),
                                    child: const Text('Go to Login'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
          : viewModel.user == null
              ? const Center(child: Text('No user data'))
              : RefreshIndicator(
                  onRefresh: viewModel.loadUserData,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                        // Admin Badge (if user is staff)
                        if (viewModel.user != null && viewModel.user!.role == UserRole.staff) ...[
                          Container(
                            padding: const EdgeInsets.all(24.0),
                            decoration: BoxDecoration(
                              gradient: AppTheme.getPinkGradient(),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.pink600.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.admin_panel_settings_rounded,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Text(
                                  'Вы админ',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        // User Information Card
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.dark700,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.dark600, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.getPinkGradient(),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      size: 28,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Text(
                                    'User Information',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: -0.5),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (viewModel.user != null) ...[
                                _buildInfoRow(
                                    'Email', viewModel.user!.email, Icons.email_rounded),
                                const SizedBox(height: 12),
                                if (viewModel.user!.fullName != null)
                                  _buildInfoRow('Full Name',
                                      viewModel.user!.fullName!, Icons.badge_rounded),
                                if (viewModel.user!.fullName != null)
                                  const SizedBox(height: 12),
                                _buildInfoRow(
                                  'Role',
                                  viewModel.user!.role.name.toUpperCase(),
                                  viewModel.user!.role ==
                                          UserRole.staff
                                      ? Icons.admin_panel_settings_rounded
                                      : Icons.person_outline_rounded,
                                  valueColor: viewModel.user!.role ==
                                          UserRole.staff
                                      ? AppTheme.pink600
                                      : AppTheme.pink500,
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  'Status',
                                  viewModel.user!.isActive
                                      ? 'Active'
                                      : 'Inactive',
                                  Icons.check_circle_rounded,
                                  valueColor: viewModel.user!.isActive
                                      ? AppTheme.success
                                      : AppTheme.neutral500,
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Passenger Profile Card (if user is passenger and profile exists)
                        if (viewModel.user != null && viewModel.user!.role == UserRole.passenger) ...[
                          if (viewModel.profile != null) ...[
                            const SizedBox(height: 24),
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.dark700,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.dark600, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: AppTheme.getPinkGradient(),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Icon(
                                          Icons.contact_page_rounded,
                                          size: 28,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Text(
                                        'Passenger Information',
                                        style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: -0.5),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoRow('Phone Number',
                                      viewModel.profile!.phoneNumber, Icons.phone_rounded),
                                  const SizedBox(height: 12),
                                  _buildInfoRow('Passport Number',
                                      viewModel.profile!.passportNumber,
                                      Icons.credit_card_rounded),
                                  const SizedBox(height: 12),
                                  _buildInfoRow('Nationality',
                                      viewModel.profile!.nationality,
                                      Icons.flag_rounded),
                                  const SizedBox(height: 12),
                                  _buildInfoRow('Date of Birth',
                                      viewModel.profile!.dateOfBirth,
                                      Icons.calendar_today_rounded),
                                ],
                              ),
                            ),
                          ],
                        ],
                        // Staff Information Card (if user is staff)
                        if (viewModel.user != null && viewModel.user!.role == UserRole.staff) ...[
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.dark700,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.dark600, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.getPinkGradient(),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.admin_panel_settings_rounded,
                                        size: 28,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Text(
                                      'Staff Information',
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: -0.5),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  'Role',
                                  'Staff Member',
                                  Icons.badge_rounded,
                                  valueColor: AppTheme.pink600,
                                ),
                                _buildInfoRow(
                                  'Access Level',
                                  'Administrative Access',
                                  Icons.security_rounded,
                                  valueColor: AppTheme.pink600,
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Bookings Section
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.dark700,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.dark600, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.getPinkGradient(),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.confirmation_number_rounded,
                                      size: 28,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Text(
                                    'My Bookings',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: -0.5),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.pink600.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${viewModel.bookings.length}',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              if (viewModel.bookings.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                  child: Center(
                                    child: Text(
                                      'No bookings yet',
                                      style: TextStyle(
                                          color: AppTheme.neutral400,
                                          fontSize: 16),
                                    ),
                                  ),
                                )
                              else
                                  ...viewModel.bookings.map((booking) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.dark600,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: AppTheme.dark500),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'PNR: ${booking.pnr}',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 18,
                                                      color: Colors.white),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6),
                                                decoration: AppTheme.getBadgeDecoration(
                                                    _getStatusColor(booking.status)),
                                                child: Text(
                                                  booking.status.name
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                      color: _getStatusColor(
                                                          booking.status),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 11,
                                                      letterSpacing: 1),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Icon(Icons.calendar_today_rounded,
                                                  size: 16, color: AppTheme.neutral400),
                                              const SizedBox(width: 8),
                                              Text(
                                                DateFormat('MMM dd, yyyy • HH:mm').format(booking.createdAt),
                                                style: TextStyle(
                                                    color: AppTheme.neutral400,
                                                    fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                              ],
                            ),
                          ),
                        // Logout Button
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: ElevatedButton.icon(
                            onPressed: viewModel.isBusy ? null : viewModel.logout,
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Logout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.error,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.dark600,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.pink600.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppTheme.pink600),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.neutral400,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.created:
        return Colors.blue;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  ProfileViewModel viewModelBuilder(BuildContext context) =>
      ProfileViewModel();

  @override
  void onViewModelReady(ProfileViewModel viewModel) {
    viewModel.loadUserData();
  }
}

