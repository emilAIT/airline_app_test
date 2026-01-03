import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:intl/intl.dart';
import 'create_flight_viewmodel.dart';

@StackedRoute()
class CreateFlightView extends StackedView<CreateFlightViewModel> {
  const CreateFlightView({Key? key}) : super(key: key);

  @override
  Widget builder(
      BuildContext context, CreateFlightViewModel viewModel, Widget? child) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Flight'),
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
                controller: viewModel.flightNumberController,
                decoration: const InputDecoration(
                  labelText: 'Flight Number *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flight),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter flight number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: viewModel.selectedOriginId,
                decoration: const InputDecoration(
                  labelText: 'Origin Airport *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flight_takeoff),
                ),
                items: viewModel.airports
                    .map((airport) => DropdownMenuItem(
                          value: airport.id,
                          child: Text('${airport.code} - ${airport.city}'),
                        ))
                    .toList(),
                onChanged: viewModel.setOrigin,
                validator: (value) {
                  if (value == null) {
                    return 'Please select origin airport';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: viewModel.selectedDestinationId,
                decoration: const InputDecoration(
                  labelText: 'Destination Airport *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flight_land),
                ),
                items: viewModel.airports
                    .map((airport) => DropdownMenuItem(
                          value: airport.id,
                          child: Text('${airport.code} - ${airport.city}'),
                        ))
                    .toList(),
                onChanged: viewModel.setDestination,
                validator: (value) {
                  if (value == null) {
                    return 'Please select destination airport';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => viewModel.selectDepartureTime(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Departure Time *',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    viewModel.selectedDepartureTime != null
                        ? DateFormat('yyyy-MM-dd HH:mm')
                            .format(viewModel.selectedDepartureTime!)
                        : 'Select departure time',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => viewModel.selectArrivalTime(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Arrival Time *',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    viewModel.selectedArrivalTime != null
                        ? DateFormat('yyyy-MM-dd HH:mm')
                            .format(viewModel.selectedArrivalTime!)
                        : 'Select arrival time',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: viewModel.selectedStatus?.name,
                decoration: const InputDecoration(
                  labelText: 'Status',
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
              const SizedBox(height: 16),
              TextFormField(
                controller: viewModel.gateController,
                decoration: const InputDecoration(
                  labelText: 'Gate (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.door_front_door),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: viewModel.terminalController,
                decoration: const InputDecoration(
                  labelText: 'Terminal (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: viewModel.airplaneIdController,
                decoration: const InputDecoration(
                  labelText: 'Airplane ID (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.airplanemode_active),
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
                  onPressed: viewModel.isBusy ? null : viewModel.createFlight,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: viewModel.isBusy
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Create Flight',
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
  CreateFlightViewModel viewModelBuilder(BuildContext context) =>
      CreateFlightViewModel();

  @override
  void onViewModelReady(CreateFlightViewModel viewModel) {
    viewModel.loadAirports();
  }
}

