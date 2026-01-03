import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'create_announcement_viewmodel.dart';
import '../../../models/announcement_model.dart';

class CreateAnnouncementView extends StackedView<CreateAnnouncementViewModel> {
  const CreateAnnouncementView({Key? key}) : super(key: key);

  @override
  Widget builder(
      BuildContext context, CreateAnnouncementViewModel viewModel, Widget? child) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Announcement'),
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
                controller: viewModel.flightIdController,
                decoration: const InputDecoration(
                  labelText: 'Flight ID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flight),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter flight ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AnnouncementType>(
                value: viewModel.type,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: AnnouncementType.delay, child: Text('Delay')),
                  DropdownMenuItem(value: AnnouncementType.cancellation, child: Text('Cancellation')),
                  DropdownMenuItem(value: AnnouncementType.gateChange, child: Text('Gate Change')),
                  DropdownMenuItem(value: AnnouncementType.boardingStarted, child: Text('Boarding Started')),
                  DropdownMenuItem(value: AnnouncementType.general, child: Text('General')),
                ],
                onChanged: (value) {
                  viewModel.type = value ?? AnnouncementType.general;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: viewModel.titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                maxLength: 120,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: viewModel.messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message),
                ),
                maxLines: 5,
                maxLength: 2000,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter message';
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
                  onPressed: viewModel.isBusy ? null : viewModel.createAnnouncement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: viewModel.isBusy
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Create Announcement',
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
  CreateAnnouncementViewModel viewModelBuilder(BuildContext context) =>
      CreateAnnouncementViewModel();
}

