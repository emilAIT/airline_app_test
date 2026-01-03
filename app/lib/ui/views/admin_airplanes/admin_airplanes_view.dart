import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'admin_airplanes_viewmodel.dart';
import '../../../models/airplane_model.dart';
import '../../widgets/scaffold_with_drawer.dart';

class AdminAirplanesView extends StackedView<AdminAirplanesViewModel> {
  const AdminAirplanesView({Key? key}) : super(key: key);

  @override
  Widget builder(
      BuildContext context, AdminAirplanesViewModel viewModel, Widget? child) {
    return ScaffoldWithDrawer(
      title: 'Airplanes Management',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => viewModel.navigateToCreateAirplane(),
          tooltip: 'Create Airplane',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: viewModel.loadAirplanes,
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
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading airplanes',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        viewModel.errorMessage ?? 'Unknown error',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: viewModel.loadAirplanes,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : viewModel.airplanes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.airplanemode_active, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No airplanes found',
                            style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => viewModel.navigateToCreateAirplane(),
                            icon: const Icon(Icons.add),
                            label: const Text('Create First Airplane'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: viewModel.loadAirplanes,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: viewModel.airplanes.length,
                        itemBuilder: (context, index) {
                          final airplane = viewModel.airplanes[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.airplanemode_active,
                                        size: 40,
                                        color: Colors.blue.shade700,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              airplane.model,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold, fontSize: 18),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Total Seats: ${airplane.totalSeats}',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                            Text(
                                              'ID: ${airplane.id}',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          switch (value) {
                                            case 'view_seat_map':
                                              viewModel.showSeatMap(context, airplane);
                                              break;
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'view_seat_map',
                                            child: Row(
                                              children: [
                                                Icon(Icons.event_seat, size: 20),
                                                SizedBox(width: 8),
                                                Text('View Seat Map'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () => viewModel.navigateToUpdateAirplane(airplane),
                                        icon: const Icon(Icons.edit, size: 18),
                                        label: const Text('Update'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue.shade700,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () => viewModel.showDeleteDialog(context, airplane),
                                        icon: const Icon(Icons.delete, size: 18),
                                        label: const Text('Delete'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
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
    );
  }

  @override
  AdminAirplanesViewModel viewModelBuilder(BuildContext context) =>
      AdminAirplanesViewModel();

  @override
  void onViewModelReady(AdminAirplanesViewModel viewModel) {
    viewModel.loadAirplanes();
  }
}

