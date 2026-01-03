import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:intl/intl.dart';
import 'my_bookings_viewmodel.dart';
import '../../widgets/scaffold_with_drawer.dart';

class MyBookingsView extends StackedView<MyBookingsViewModel> {
  const MyBookingsView({Key? key}) : super(key: key);

  @override
  Widget builder(
      BuildContext context, MyBookingsViewModel viewModel, Widget? child) {
    return ScaffoldWithDrawer(
      title: 'My Bookings',
      body: viewModel.isBusy
          ? const Center(child: CircularProgressIndicator())
          : viewModel.bookings.isEmpty
              ? const Center(child: Text('No bookings found'))
              : RefreshIndicator(
                  onRefresh: viewModel.loadBookings,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: viewModel.bookings.length,
                    itemBuilder: (context, index) {
                      final booking = viewModel.bookings[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.confirmation_number, size: 40),
                          title: Text('PNR: ${booking.pnr}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Status: ${booking.status.name}'),
                              Text(
                                  'Created: ${DateFormat('yyyy-MM-dd HH:mm').format(booking.createdAt)}'),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'view',
                                child: Text('View Details'),
                              ),
                              if (booking.status.name == 'created')
                                const PopupMenuItem(
                                  value: 'cancel',
                                  child: Text('Cancel'),
                                ),
                            ],
                            onSelected: (value) {
                              if (value == 'view') {
                                viewModel.viewBooking(booking.id);
                              } else if (value == 'cancel') {
                                viewModel.cancelBooking(booking.id);
                              }
                            },
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  @override
  MyBookingsViewModel viewModelBuilder(BuildContext context) =>
      MyBookingsViewModel();

  @override
  void onViewModelReady(MyBookingsViewModel viewModel) {
    viewModel.loadBookings();
  }
}

