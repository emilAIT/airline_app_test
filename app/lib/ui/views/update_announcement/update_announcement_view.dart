import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'update_announcement_viewmodel.dart';
import '../../../models/announcement_model.dart';

class UpdateAnnouncementViewArguments {
  final AnnouncementPublic announcement;
  UpdateAnnouncementViewArguments({required this.announcement});
}

class UpdateAnnouncementView extends StackedView<UpdateAnnouncementViewModel> {
  final UpdateAnnouncementViewArguments args;

  const UpdateAnnouncementView({
    Key? key,
    required this.args,
  }) : super(key: key);

  @override
  Widget builder(
      BuildContext context, UpdateAnnouncementViewModel viewModel, Widget? child) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Announcement'),
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
                'Flight ID: ${args.announcement.flightId}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
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
                  onPressed: viewModel.isBusy ? null : viewModel.updateAnnouncement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: viewModel.isBusy
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Update Announcement',
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
  UpdateAnnouncementViewModel viewModelBuilder(BuildContext context) =>
      UpdateAnnouncementViewModel(announcement: args.announcement);
}

