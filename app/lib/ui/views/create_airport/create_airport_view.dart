import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'create_airport_viewmodel.dart';
import '../../widgets/scaffold_with_drawer.dart';

class CreateAirportView extends StackedView<CreateAirportViewModel> {
  const CreateAirportView({Key? key}) : super(key: key);

  @override
  Widget builder(
      BuildContext context, CreateAirportViewModel viewModel, Widget? child) {
    return ScaffoldWithDrawer(
      title: 'Create Airport',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: viewModel.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.airport_shuttle, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'Airport Information',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: viewModel.codeController,
                        decoration: const InputDecoration(
                          labelText: 'Code (3 letters) *',
                          hintText: 'e.g., JFK',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.code),
                        ),
                        maxLength: 3,
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter airport code';
                          }
                          if (value.length != 3) {
                            return 'Code must be exactly 3 letters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: viewModel.nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name *',
                          hintText: 'e.g., John F. Kennedy International Airport',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.airport_shuttle),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter airport name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: viewModel.cityController,
                        decoration: const InputDecoration(
                          labelText: 'City *',
                          hintText: 'e.g., New York',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter city';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: viewModel.countryController,
                        decoration: const InputDecoration(
                          labelText: 'Country *',
                          hintText: 'e.g., United States',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.public),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter country';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
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
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: viewModel.isBusy ? null : viewModel.createAirport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: viewModel.isBusy
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Create Airport',
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
  CreateAirportViewModel viewModelBuilder(BuildContext context) =>
      CreateAirportViewModel();
}
