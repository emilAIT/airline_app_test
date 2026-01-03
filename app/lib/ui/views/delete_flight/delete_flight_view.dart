import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked/stacked_annotations.dart';
import 'delete_flight_viewmodel.dart';

@StackedRoute()
class DeleteFlightView extends StackedView<DeleteFlightViewModel> {
  const DeleteFlightView({Key? key}) : super(key: key);

  @override
  Widget builder(
      BuildContext context, DeleteFlightViewModel viewModel, Widget? child) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Flight'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: viewModel.isBusy
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red.shade700, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Enter Flight ID to delete',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: viewModel.flightIdController,
                    decoration: const InputDecoration(
                      labelText: 'Flight ID *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flight),
                      helperText: 'Enter the ID of the flight to delete',
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (viewModel.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
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
                              viewModel.errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (viewModel.flight != null) ...[
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Flight Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow('Flight Number', viewModel.flight!.flightNumber),
                            const SizedBox(height: 8),
                            _buildInfoRow('Status', viewModel.flight!.status.name.toUpperCase()),
                            const SizedBox(height: 8),
                            _buildInfoRow('Departure', viewModel.flight!.departureTime.toString()),
                            const SizedBox(height: 8),
                            _buildInfoRow('Arrival', viewModel.flight!.arrivalTime.toString()),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: viewModel.flightIdController.text.isEmpty
                          ? null
                          : (viewModel.isBusy ? null : viewModel.loadFlight),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                      child: viewModel.isBusy
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Load Flight',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  ),
                  if (viewModel.flight != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: viewModel.isBusy ? null : viewModel.deleteFlight,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                        ),
                        child: viewModel.isBusy
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Delete Flight',
                                style: TextStyle(fontSize: 18),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  @override
  DeleteFlightViewModel viewModelBuilder(BuildContext context) =>
      DeleteFlightViewModel();
}

