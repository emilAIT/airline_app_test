import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked/stacked_annotations.dart';
import 'update_gate_terminal_viewmodel.dart';

@StackedRoute()
class UpdateGateTerminalView extends StackedView<UpdateGateTerminalViewModel> {
  const UpdateGateTerminalView({Key? key}) : super(key: key);

  @override
  Widget builder(
      BuildContext context, UpdateGateTerminalViewModel viewModel, Widget? child) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Gate/Terminal'),
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
            TextField(
              controller: viewModel.gateController,
              decoration: const InputDecoration(
                labelText: 'Gate',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.door_front_door),
                helperText: 'Enter gate number (optional)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: viewModel.terminalController,
              decoration: const InputDecoration(
                labelText: 'Terminal',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
                helperText: 'Enter terminal number (optional)',
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
                onPressed: viewModel.isBusy ? null : viewModel.updateGateTerminal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
                child: viewModel.isBusy
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Update Gate/Terminal',
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
  UpdateGateTerminalViewModel viewModelBuilder(BuildContext context) =>
      UpdateGateTerminalViewModel();
}

