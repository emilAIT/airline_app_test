import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:intl/intl.dart';
import 'flight_search_viewmodel.dart';
import '../../../models/flight_model.dart';
import '../../../services/auth_service.dart';
import '../../../app/app.locator.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/scaffold_with_drawer.dart';

class FlightSearchView extends StackedView<FlightSearchViewModel> {
  const FlightSearchView({Key? key}) : super(key: key);

  @override
  Widget builder(
      BuildContext context, FlightSearchViewModel viewModel, Widget? child) {
    return ScaffoldWithDrawer(
      title: viewModel.isStaff ? 'Admin Dashboard' : 'Search Flights',
      body: viewModel.isStaff
          ? _buildAdminDashboard(context, viewModel)
          : _buildPassengerSearch(context, viewModel),
    );
  }

  Widget _buildAdminDashboard(BuildContext context, FlightSearchViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Netflix-style hero card
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: AppTheme.getPinkGradient(),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.pink600.withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Expanded(
                      child: Text(
                        'Admin Dashboard',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Manage flights, airplanes, and bookings',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Flights Management
          _buildAdminSection(
            title: 'Flights Management',
            icon: Icons.flight_rounded,
            color: AppTheme.pink600,
            children: [
              _buildAdminButton(
                icon: Icons.add_circle,
                label: 'Create Flight',
                onPressed: () => viewModel.navigateToCreateFlight(),
              ),
              _buildAdminButton(
                icon: Icons.list,
                label: 'View All Flights',
                onPressed: () => viewModel.navigateToFlightsList(),
              ),
              _buildAdminButton(
                icon: Icons.edit,
                label: 'Update Flight',
                onPressed: () => viewModel.navigateToUpdateFlight(),
              ),
              _buildAdminButton(
                icon: Icons.delete,
                label: 'Delete Flight',
                onPressed: () => viewModel.navigateToDeleteFlight(),
              ),
              _buildAdminButton(
                icon: Icons.update,
                label: 'Update Flight Status',
                onPressed: () => viewModel.navigateToUpdateFlightStatus(),
              ),
              _buildAdminButton(
                icon: Icons.airport_shuttle,
                label: 'Update Gate/Terminal',
                onPressed: () => viewModel.navigateToUpdateGateTerminal(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Airplanes Management
          _buildAdminSection(
            title: 'Airplanes Management',
            icon: Icons.airplanemode_active,
            color: AppTheme.pink500,
            children: [
              _buildAdminButton(
                icon: Icons.add_circle,
                label: 'Create Airplane',
                onPressed: () => viewModel.navigateToCreateAirplane(),
              ),
              _buildAdminButton(
                icon: Icons.list,
                label: 'View All Airplanes',
                onPressed: () => viewModel.navigateToAirplanesList(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Bookings Management
          _buildAdminSection(
            title: 'Bookings Management',
            icon: Icons.confirmation_number,
            color: AppTheme.pink700,
            children: [
              _buildAdminButton(
                icon: Icons.list,
                label: 'View All Bookings',
                onPressed: () => viewModel.navigateToBookingsList(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Payments Management
          _buildAdminSection(
            title: 'Payments Management',
            icon: Icons.payment,
            color: AppTheme.pink400,
            children: [
              _buildAdminButton(
                icon: Icons.list,
                label: 'View All Payments',
                onPressed: () => viewModel.navigateToPaymentsList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerSearch(BuildContext context, FlightSearchViewModel viewModel) {
    if (viewModel.isBusy && viewModel.allFlights.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.hasError && viewModel.allFlights.isEmpty) {
      return Center(
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
                'Error loading flights',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                viewModel.errorMessage ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.neutral400, fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: viewModel.loadAllFlights,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Retry', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      );
    }

    if (viewModel.allFlights.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.dark700,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.flight_rounded, size: 64, color: AppTheme.neutral500),
            ),
            const SizedBox(height: 24),
            const Text(
              'No flights available',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for updates',
              style: TextStyle(color: AppTheme.neutral400, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.loadAllFlights,
      color: AppTheme.pink600,
      child: ListView.builder(
        padding: const EdgeInsets.all(24.0),
        itemCount: viewModel.allFlights.length,
        itemBuilder: (context, index) {
          final flight = viewModel.allFlights[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
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
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => viewModel.selectFlight(flight.id),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.getPinkGradient(),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    flight.flightNumber,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                if (flight.originAirportCode != null && flight.destinationAirportCode != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '${flight.originAirportCode} → ${flight.destinationAirportCode}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.pink600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: AppTheme.getBadgeDecoration(
                                _getStatusColor(flight.status)),
                            child: Text(
                              flight.status.name.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(flight.status),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('HH:mm').format(flight.departureTime),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('MMM dd, yyyy').format(flight.departureTime),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.neutral400,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.dark600,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: AppTheme.pink600,
                              size: 24,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  DateFormat('HH:mm').format(flight.arrivalTime),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('MMM dd, yyyy').format(flight.arrivalTime),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.neutral400,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (flight.gate != null || flight.terminal != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.dark600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              if (flight.gate != null) ...[
                                Icon(Icons.door_front_door_rounded,
                                    size: 20, color: AppTheme.pink600),
                                const SizedBox(width: 8),
                                Text(
                                  'Gate ${flight.gate}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                              if (flight.terminal != null) ...[
                                if (flight.gate != null) ...[
                                  Container(
                                    width: 1,
                                    height: 20,
                                    margin: const EdgeInsets.symmetric(horizontal: 16),
                                    color: AppTheme.dark500,
                                  ),
                                ],
                                Icon(Icons.terminal_rounded,
                                    size: 20, color: AppTheme.pink600),
                                const SizedBox(width: 8),
                                Text(
                                  'Terminal ${flight.terminal}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  FlightSearchViewModel viewModelBuilder(BuildContext context) =>
      FlightSearchViewModel();

  @override
  void onViewModelReady(FlightSearchViewModel viewModel) {
    viewModel.loadUserData();
    viewModel.loadAirports();
  }
}

// Admin Dashboard Helper Widgets
  Widget _buildAdminSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppTheme.dark700,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dark600, width: 1),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, size: 28, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: children,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

// Helper functions for table
Widget _buildHeaderCell(String text) {
  return Padding(
    padding: const EdgeInsets.all(12.0),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    ),
  );
}

Widget _buildDataCell(
  String text, {
  Color? color,
  FontWeight? fontWeight,
}) {
  return Padding(
    padding: const EdgeInsets.all(12.0),
    child: Text(
      text,
      style: TextStyle(
        color: color ?? Colors.black87,
        fontWeight: fontWeight ?? FontWeight.normal,
        fontSize: 14,
      ),
    ),
  );
}

String _getStatusText(FlightStatus status) {
  switch (status) {
    case FlightStatus.scheduled:
      return 'Scheduled';
    case FlightStatus.boarding:
      return 'Boarding';
    case FlightStatus.delayed:
      return 'Delayed';
    case FlightStatus.cancelled:
      return 'Cancelled';
    case FlightStatus.departed:
      return 'Departed';
    case FlightStatus.landed:
      return 'Landed';
  }
}

  Color _getStatusColor(FlightStatus status) {
  switch (status) {
    case FlightStatus.scheduled:
      return Colors.blue;
    case FlightStatus.boarding:
      return Colors.orange;
    case FlightStatus.delayed:
      return Colors.red;
    case FlightStatus.cancelled:
      return Colors.grey;
    case FlightStatus.departed:
      return Colors.green;
    case FlightStatus.landed:
      return Colors.green.shade700;
  }
}

