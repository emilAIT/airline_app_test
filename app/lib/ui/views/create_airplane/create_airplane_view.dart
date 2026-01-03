import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'create_airplane_viewmodel.dart';
import '../../../models/airplane_model.dart';

class CreateAirplaneView extends StackedView<CreateAirplaneViewModel> {
  const CreateAirplaneView({Key? key}) : super(key: key);

  @override
  Widget builder(
      BuildContext context, CreateAirplaneViewModel viewModel, Widget? child) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Airplane'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: viewModel.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: viewModel.modelController,
                decoration: const InputDecoration(
                  labelText: 'Model *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.airplanemode_active),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter airplane model';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Seat Map Configuration',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: viewModel.rowsController,
                      decoration: const InputDecoration(
                        labelText: 'Number of Rows *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final rows = int.tryParse(value);
                        if (rows == null || rows <= 0) {
                          return 'Must be > 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: viewModel.seatsPerRowController,
                      decoration: const InputDecoration(
                        labelText: 'Seats per Row (e.g., ABCDEF) *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: viewModel.extraLegroomRowsController,
                      decoration: const InputDecoration(
                        labelText: 'Extra Legroom Rows (from start)',
                        border: OutlineInputBorder(),
                        helperText: 'Leave empty for 0',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: viewModel.generateSeatMap,
                child: const Text('Generate Seat Map'),
              ),
              const SizedBox(height: 16),
              if (viewModel.seatMap.isNotEmpty) ...[
                Text(
                  'Generated ${viewModel.seatMap.length} seats',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: viewModel.seatMap.length,
                    itemBuilder: (context, index) {
                      final seat = viewModel.seatMap[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          'Row ${seat.row}, Seat ${seat.seatLabel}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Chip(
                          label: Text(
                            seat.category.name.toUpperCase(),
                            style: const TextStyle(fontSize: 10),
                          ),
                          backgroundColor: seat.category == SeatCategory.extraLegroom
                              ? Colors.orange.shade100
                              : Colors.blue.shade100,
                        ),
                      );
                    },
                  ),
                ),
              ],
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
                  onPressed: viewModel.isBusy || viewModel.seatMap.isEmpty
                      ? null
                      : viewModel.createAirplane,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: viewModel.isBusy
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Create Airplane',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  CreateAirplaneViewModel viewModelBuilder(BuildContext context) =>
      CreateAirplaneViewModel();

  @override
  void onViewModelReady(CreateAirplaneViewModel viewModel) {
    // No initial data needed
  }
}

