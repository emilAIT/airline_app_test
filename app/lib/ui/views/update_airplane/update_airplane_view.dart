import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'update_airplane_viewmodel.dart';
import '../../../models/airplane_model.dart';
import '../../widgets/scaffold_with_drawer.dart';

class UpdateAirplaneViewArguments {
  final AirplanePublic airplane;
  UpdateAirplaneViewArguments({required this.airplane});
}

class UpdateAirplaneView extends StackedView<UpdateAirplaneViewModel> {
  final UpdateAirplaneViewArguments args;

  const UpdateAirplaneView({
    Key? key,
    required this.args,
  }) : super(key: key);

  @override
  Widget builder(
      BuildContext context, UpdateAirplaneViewModel viewModel, Widget? child) {
    return ScaffoldWithDrawer(
      title: 'Update Airplane',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: viewModel.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Model: ${args.airplane.model}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Total Seats: ${args.airplane.totalSeats}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: viewModel.modelController,
                decoration: const InputDecoration(
                  labelText: 'New Model Name',
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
                  onPressed: viewModel.isBusy ? null : viewModel.updateAirplane,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: viewModel.isBusy
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Update Airplane',
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
  UpdateAirplaneViewModel viewModelBuilder(BuildContext context) =>
      UpdateAirplaneViewModel(airplane: args.airplane);
}

