import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'admin_airports_viewmodel.dart';
import '../../../models/airport_model.dart';
import '../../widgets/scaffold_with_drawer.dart';

class AdminAirportsView extends StackedView<AdminAirportsViewModel> {
  const AdminAirportsView({Key? key}) : super(key: key);

  @override
  Widget builder(
      BuildContext context, AdminAirportsViewModel viewModel, Widget? child) {
    return ScaffoldWithDrawer(
      title: 'Airports Management',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: viewModel.loadAirports,
          tooltip: 'Refresh',
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: viewModel.navigateToCreateAirport,
        backgroundColor: Colors.blue.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: viewModel.isBusy
          ? const Center(child: CircularProgressIndicator())
          : viewModel.hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading airports',
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
                        onPressed: viewModel.loadAirports,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : viewModel.airports.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.airport_shuttle, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No airports found',
                            style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: viewModel.navigateToCreateAirport,
                            icon: const Icon(Icons.add),
                            label: const Text('Create First Airport'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: viewModel.loadAirports,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: viewModel.airports.length,
                        itemBuilder: (context, index) {
                          final airport = viewModel.airports[index];
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
                                      CircleAvatar(
                                        backgroundColor: Colors.blue.shade100,
                                        radius: 30,
                                        child: Icon(
                                          Icons.airport_shuttle,
                                          color: Colors.blue.shade700,
                                          size: 30,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${airport.code} - ${airport.name}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold, fontSize: 18),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${airport.city}, ${airport.country}',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Divider(color: Colors.grey.shade300),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.tag, size: 16, color: Colors.grey.shade600),
                                      const SizedBox(width: 8),
                                      Text(
                                        'ID: ${airport.id}',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () => viewModel.navigateToUpdateAirport(airport),
                                        icon: const Icon(Icons.edit, size: 18),
                                        label: const Text('Edit'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue.shade700,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () => viewModel.showDeleteDialog(context, airport),
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
  AdminAirportsViewModel viewModelBuilder(BuildContext context) =>
      AdminAirportsViewModel();

  @override
  void onViewModelReady(AdminAirportsViewModel viewModel) {
    viewModel.loadAirports();
  }
}
