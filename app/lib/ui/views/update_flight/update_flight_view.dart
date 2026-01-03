import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:intl/intl.dart';
import 'update_flight_viewmodel.dart';
import '../../../models/flight_model.dart';

class UpdateFlightViewArguments {
  final FlightPublic flight;
  UpdateFlightViewArguments({required this.flight});
}

class UpdateFlightView extends StackedView<UpdateFlightViewModel> {
  final UpdateFlightViewArguments args;

  const UpdateFlightView({
    Key? key,
    required this.args,
  }) : super(key: key);

  @override
  Widget builder(
      BuildContext context, UpdateFlightViewModel viewModel, Widget? child) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Flight ${args.flight.flightNumber}'),
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
              Text(
                'Flight Number: ${args.flight.flightNumber}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Flight ID: ${args.flight.id}',
                style: TextStyle(
                    fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () => viewModel.selectDepartureTime(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Departure Time',
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
                    labelText: 'Arrival Time',
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
                  labelText: 'Gate',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.door_front_door),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: viewModel.terminalController,
                decoration: const InputDecoration(
                  labelText: 'Terminal',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: viewModel.airplaneIdController,
                decoration: const InputDecoration(
                  labelText: 'Airplane ID',
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
                  onPressed: viewModel.isBusy ? null : viewModel.updateFlight,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: viewModel.isBusy
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Update Flight',
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
  UpdateFlightViewModel viewModelBuilder(BuildContext context) =>
      UpdateFlightViewModel(flight: args.flight);
}

