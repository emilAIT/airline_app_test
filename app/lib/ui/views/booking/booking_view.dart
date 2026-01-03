import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:intl/intl.dart';
import 'booking_viewmodel.dart';
import '../../../models/flight_model.dart';
import '../../../models/seat_model.dart';
import '../../widgets/scaffold_with_drawer.dart';
import 'widgets/seat_map_widget.dart';

class BookingView extends StackedView<BookingViewModel> {
  final String flightId;

  const BookingView({Key? key, required this.flightId}) : super(key: key);

  @override
  Widget builder(
      BuildContext context, BookingViewModel viewModel, Widget? child) {
    return ScaffoldWithDrawer(
      title: 'Create Booking',
      body: viewModel.isBusy && viewModel.flight == null
          ? const Center(child: CircularProgressIndicator())
          : viewModel.hasError && viewModel.flight == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading flight',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          viewModel.errorMessage ?? 'Unknown error',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: viewModel.loadFlightData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : viewModel.flight == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Loading flight details...',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Flight Information Section
                            _buildFlightInfoSection(context, viewModel),
                            const SizedBox(height: 24),

                            // Passengers Section
                            _buildPassengersSection(context, viewModel),
                            const SizedBox(height: 24),

                            // Seat Selection Section
                            if (viewModel.seatMap != null && viewModel.seatMap!.seats.isNotEmpty) ...[
                              _buildSeatSelectionSection(context, viewModel),
                              const SizedBox(height: 24),
                            ] else if (viewModel.seatMap == null) ...[
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      Icon(Icons.event_seat, size: 48, color: Colors.grey.shade400),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Seat map not available',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Seats will be assigned automatically',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Error Message
                            if (viewModel.hasError)
                              _buildErrorMessage(viewModel.errorMessage!),
                            const SizedBox(height: 16),

                            // Create Booking Button
                            _buildCreateBookingButton(context, viewModel),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildFlightInfoSection(BuildContext context, BookingViewModel viewModel) {
    final flight = viewModel.flight!;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flight, size: 32, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Text(
                  'Flight ${flight.flightNumber}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(flight.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    flight.status.name.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(flight.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        viewModel.originAirport?.code ?? flight.originAirportId,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        viewModel.originAirport?.name ?? 'Origin',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('HH:mm').format(flight.departureTime),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(flight.departureTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward, color: Colors.blue.shade700),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        viewModel.destinationAirport?.code ?? flight.destinationAirportId,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        viewModel.destinationAirport?.name ?? 'Destination',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('HH:mm').format(flight.arrivalTime),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(flight.arrivalTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (flight.gate != null || flight.terminal != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              Row(
                children: [
                  if (flight.gate != null) ...[
                    Icon(Icons.door_front_door, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Gate: ${flight.gate}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                  if (flight.terminal != null) ...[
                    if (flight.gate != null) const SizedBox(width: 16),
                    Icon(Icons.terminal, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Terminal: ${flight.terminal}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ],
            // Warning if flight is cancelled or departed
            if (flight.status == FlightStatus.cancelled || 
                flight.status == FlightStatus.departed) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This flight cannot be booked. Status: ${flight.status.name}',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPassengersSection(BuildContext context, BookingViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Passengers',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '${viewModel.passengers.length} ${viewModel.passengers.length == 1 ? 'passenger' : 'passengers'}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...viewModel.passengers.asMap().entries.map((entry) {
          final index = entry.key;
          final passenger = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Passenger ${index + 1}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (viewModel.passengers.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => viewModel.removePassenger(index),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passenger.nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passenger.passportController,
                    decoration: const InputDecoration(
                      labelText: 'Passport Number *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter passport number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passenger.nationalityController,
                    decoration: const InputDecoration(
                      labelText: 'Nationality *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.public),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter nationality';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => viewModel.selectDateOfBirth(context, index),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        passenger.dateOfBirth != null
                            ? DateFormat('yyyy-MM-dd').format(passenger.dateOfBirth!)
                            : 'Select date of birth',
                        style: TextStyle(
                          color: passenger.dateOfBirth != null
                              ? Colors.black87
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: viewModel.addPassenger,
          icon: const Icon(Icons.add),
          label: const Text('Add Passenger'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSeatSelectionSection(BuildContext context, BookingViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seat Selection',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  title: const Text('Auto-assign seats'),
                  subtitle: const Text('Let the system assign seats automatically'),
                  value: viewModel.autoAssignSeats,
                  onChanged: (value) {
                    viewModel.autoAssignSeats = value ?? false;
                  },
                ),
                if (!viewModel.autoAssignSeats) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Select seats for ${viewModel.passengers.length} ${viewModel.passengers.length == 1 ? 'passenger' : 'passengers'}:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SeatMapWidget(
                    seatMap: viewModel.seatMap!,
                    passengers: viewModel.passengers,
                    onSeatSelected: (passengerIndex, seatId) {
                      viewModel.selectSeatForPassenger(passengerIndex, seatId);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateBookingButton(BuildContext context, BookingViewModel viewModel) {
    final flight = viewModel.flight!;
    final isDisabled = !viewModel.canCreateBooking ||
        flight.status == FlightStatus.cancelled ||
        flight.status == FlightStatus.departed;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isDisabled || viewModel.isBusy
            ? null
            : viewModel.createBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child: viewModel.isBusy
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Create Booking',
                style: TextStyle(fontSize: 18),
              ),
      ),
    );
  }

  Color _getStatusColor(FlightStatus status) {
    switch (status) {
      case FlightStatus.scheduled:
        return Colors.blue;
      case FlightStatus.boarding:
        return Colors.orange;
      case FlightStatus.delayed:
        return Colors.orange;
      case FlightStatus.cancelled:
        return Colors.red;
      case FlightStatus.departed:
        return Colors.grey;
      case FlightStatus.landed:
        return Colors.green;
    }
  }

  @override
  BookingViewModel viewModelBuilder(BuildContext context) =>
      BookingViewModel(flightId: flightId);

  @override
  void onViewModelReady(BookingViewModel viewModel) {
    viewModel.loadFlightData();
  }
}
