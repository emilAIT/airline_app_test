import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:intl/intl.dart';
import 'admin_tickets_viewmodel.dart';
import '../../../models/ticket_model.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/scaffold_with_drawer.dart';

class AdminTicketsView extends StackedView<AdminTicketsViewModel> {
  const AdminTicketsView({Key? key}) : super(key: key);

  @override
  Widget builder(
      BuildContext context, AdminTicketsViewModel viewModel, Widget? child) {
    return ScaffoldWithDrawer(
      title: 'Tickets Management',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: viewModel.loadTickets,
          tooltip: 'Refresh',
        ),
      ],
      body: viewModel.isBusy
          ? const Center(child: CircularProgressIndicator())
          : viewModel.hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: AppTheme.error),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading tickets',
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
                        onPressed: viewModel.loadTickets,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : viewModel.tickets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.confirmation_number, size: 64, color: AppTheme.neutral400),
                          const SizedBox(height: 16),
                          Text(
                            'No tickets found',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.neutral600),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: viewModel.loadTickets,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: viewModel.loadTickets,
                      child: Column(
                        children: [
                          // Search bar
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.dark700,
                              border: Border(
                                bottom: BorderSide(color: AppTheme.dark600, width: 1),
                              ),
                            ),
                            child: _SearchBarWidget(
                              viewModel: viewModel,
                              onSearch: (value) {
                                if (value.isNotEmpty) {
                                  viewModel.searchByTicketNumber(value);
                                } else {
                                  viewModel.loadTickets();
                                }
                              },
                              onClear: () => viewModel.clearSearch(),
                            ),
                          ),
                          // Info bar
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.dark700,
                              border: Border(
                                bottom: BorderSide(color: AppTheme.dark600, width: 1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.pink600.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.info_outline_rounded,
                                      color: AppTheme.pink600, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    viewModel.searchTicketNumber != null
                                        ? 'Search results for: ${viewModel.searchTicketNumber}'
                                        : 'Total tickets: ${viewModel.tickets.length}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: viewModel.tickets.length,
                              itemBuilder: (context, index) {
                                final ticket = viewModel.tickets[index];
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
                                                    AppTheme.pink600,
                                                    AppTheme.pink600.withOpacity(0.7),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppTheme.pink600.withOpacity(0.3),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.confirmation_number_rounded,
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
                                                    ticket.ticketNumber,
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 22,
                                                        color: Colors.white,
                                                        letterSpacing: -0.5),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    ticket.passengerName,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: AppTheme.neutral300,
                                                      fontWeight: FontWeight.w500,
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
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: AppTheme.dark600,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            children: [
                                              _buildInfoRow(
                                                Icons.event_seat_rounded,
                                                'Seat Number',
                                                ticket.seatNumber,
                                              ),
                                              const SizedBox(height: 12),
                                              _buildInfoRow(
                                                Icons.confirmation_number_rounded,
                                                'Booking ID',
                                                ticket.bookingId,
                                              ),
                                              if (ticket.flightSeatId != null) ...[
                                                const SizedBox(height: 12),
                                                _buildInfoRow(
                                                  Icons.flight_rounded,
                                                  'Flight Seat ID',
                                                  ticket.flightSeatId!,
                                                ),
                                              ],
                                              const SizedBox(height: 12),
                                              _buildInfoRow(
                                                Icons.calendar_today_rounded,
                                                'Created',
                                                DateFormat('MMM dd, yyyy • HH:mm').format(ticket.createdAt),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            OutlinedButton.icon(
                                              onPressed: () => viewModel.viewTicketDetails(context, ticket),
                                              icon: const Icon(Icons.visibility_rounded, size: 20),
                                              label: const Text('View Details', style: TextStyle(fontSize: 15)),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppTheme.pink600,
                                                side: BorderSide(color: AppTheme.pink600, width: 2),
                                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                              ),
                                            ),
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
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.pink600),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.neutral400,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  AdminTicketsViewModel viewModelBuilder(BuildContext context) =>
      AdminTicketsViewModel();

  @override
  void onViewModelReady(AdminTicketsViewModel viewModel) {
    viewModel.loadTickets();
  }
}

class _SearchBarWidget extends StatefulWidget {
  final AdminTicketsViewModel viewModel;
  final Function(String) onSearch;
  final VoidCallback onClear;

  const _SearchBarWidget({
    required this.viewModel,
    required this.onSearch,
    required this.onClear,
  });

  @override
  State<_SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<_SearchBarWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.viewModel.searchTicketNumber ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by ticket number...',
              hintStyle: TextStyle(color: AppTheme.neutral400),
              prefixIcon: Icon(Icons.search, color: AppTheme.pink600),
              suffixIcon: widget.viewModel.searchTicketNumber != null
                  ? IconButton(
                      icon: Icon(Icons.clear, color: AppTheme.pink600),
                      onPressed: () {
                        _controller.clear();
                        widget.onClear();
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.dark600,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onSubmitted: widget.onSearch,
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              widget.onSearch(_controller.text);
            }
          },
          icon: const Icon(Icons.search),
          label: const Text('Search'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

