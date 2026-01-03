import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked/stacked_annotations.dart';
import 'update_flight_status_viewmodel.dart';

@StackedRoute()
class UpdateFlightStatusView extends StackedView<UpdateFlightStatusViewModel> {
  const UpdateFlightStatusView({Key? key}) : super(key: key);

  @override
  Widget builder(
      BuildContext context, UpdateFlightStatusViewModel viewModel, Widget? child) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Flight Status'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: viewModel.flightIdController,
              decoration: const InputDecoration(
                labelText: 'Flight ID *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flight),
                helperText: 'Enter the ID of the flight to update',
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: viewModel.selectedStatus?.name,
              decoration: const InputDecoration(
                labelText: 'New Status *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info),
              ),
              items: viewModel.statuses
                  .map((status) => DropdownMenuItem(
                        value: status.name,
                        child: Text(status.name.toUpperCase()),
                      ))
                  .toList(),
              onChanged: (value) {
                viewModel.setStatus(value);
              },
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
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: viewModel.isBusy ? null : viewModel.updateStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
                child: viewModel.isBusy
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Update Status',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  UpdateFlightStatusViewModel viewModelBuilder(BuildContext context) =>
      UpdateFlightStatusViewModel();
}

