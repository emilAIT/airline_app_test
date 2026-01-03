import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';

class CreateAirplaneDialog extends StatefulWidget {
  final Map<String, dynamic>? airplane; // If provided, we are in EDIT mode

  const CreateAirplaneDialog({super.key, this.airplane});

  @override
  State<CreateAirplaneDialog> createState() => _CreateAirplaneDialogState();
}

class _CreateAirplaneDialogState extends State<CreateAirplaneDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  List<dynamic> _templates = [];
  bool _isLoading = false;
  bool _loadingData = true;
  bool _useCustomTemplate = false;
  
  // For total seats calculation
  int _bizRows = 0;
  int _bizSpr = 0;
  int _elRows = 0;
  int _elSpr = 0;
  int _econRows = 0;
  int _econSpr = 0;

  @override
  void initState() {
    super.initState();
    // If editing, we don't need to load templates as strictly because we can't change it,
    // but we might want to show the current one name?
    // Actually, backend prevents changing seat_template_id.
    // So we just load templates for CREATE mode.
    if (widget.airplane == null) {
      _loadTemplates();
    } else {
      _loadingData = false;
      // Initialize total seats specific to the airplane being edited if we had that data?
      // The airplane object comes from list_airplanes response. 
      // Does it have seat details? 
      // AirplaneResponse has `seat_template` object now!
      // So we can show it.
      if (widget.airplane != null && widget.airplane!['seat_template'] != null) {
          final template = widget.airplane!['seat_template'];
          final classLayouts = template['class_layouts'];
          if (classLayouts != null) {
            _bizRows = classLayouts['BUSINESS']?['rows'] ?? 0;
            _bizSpr = classLayouts['BUSINESS']?['seats_per_row'] ?? 0;
            _elRows = classLayouts['EXTRA_LEGROOM']?['rows'] ?? 0;
            _elSpr = classLayouts['EXTRA_LEGROOM']?['seats_per_row'] ?? 0;
            _econRows = classLayouts['ECONOMY']?['rows'] ?? 0;
            _econSpr = classLayouts['ECONOMY']?['seats_per_row'] ?? 0;
          } else {
            // Fallback to total if no class layouts
            _econRows = template['rows'] ?? 0;
            _econSpr = template['seats_per_row'] ?? 0;
          }
      }
    }
  }

  Future<void> _loadTemplates() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.getSeatTemplates();
      
      if (mounted) {
        setState(() {
          _templates = List<dynamic>.from(response.data ?? []);
          _loadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingData = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load templates: ${e.toString()}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _updateTotalSeats() {
    if (_formKey.currentState == null) return;
    _formKey.currentState!.save();
    final formData = _formKey.currentState!.value;
    
    setState(() {
      _bizRows = int.tryParse(formData['biz_rows']?.toString() ?? '0') ?? 0;
      _bizSpr = int.tryParse(formData['biz_spr']?.toString() ?? '0') ?? 0;
      _elRows = int.tryParse(formData['el_rows']?.toString() ?? '0') ?? 0;
      _elSpr = int.tryParse(formData['el_spr']?.toString() ?? '0') ?? 0;
      _econRows = int.tryParse(formData['econ_rows']?.toString() ?? '0') ?? 0;
      _econSpr = int.tryParse(formData['econ_spr']?.toString() ?? '0') ?? 0;
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.saveAndValidate()) {
      setState(() => _isLoading = true);

      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final formData = _formKey.currentState!.value;

        if (widget.airplane == null) {
          // CREATE MODE
          int seatTemplateId;

          if (_useCustomTemplate) {
            final classLayouts = {
              "BUSINESS": {"rows": _bizRows, "seats_per_row": _bizSpr},
              "EXTRA_LEGROOM": {"rows": _elRows, "seats_per_row": _elSpr},
              "ECONOMY": {"rows": _econRows, "seats_per_row": _econSpr},
            };
            
            final totalRows = _bizRows + _elRows + _econRows;
            final maxSpr = [_bizSpr, _elSpr, _econSpr].reduce((a, b) => a > b ? a : b);
            
            final seatLabels = List.generate(maxSpr, (index) => String.fromCharCode(65 + index));
            
            final templateData = {
              'name': formData['template_name'],
              'rows': totalRows,
              'seats_per_row': maxSpr,
              'seat_labels': seatLabels,
              'seat_categories': {}, // No longer used for ranges, using class_layouts
              'class_layouts': classLayouts,
            };
            
            final templateResponse = await apiService.createSeatTemplate(templateData);
            seatTemplateId = templateResponse.data['id'];
          } else {
            seatTemplateId = formData['seat_template_id'];
          }

          final airplaneData = {
            'model': formData['model'],
            'registration_number': formData['registration_number'],
            'seat_template_id': seatTemplateId,
            'status': formData['status'] ?? 'ACTIVE',
          };

          await apiService.createStaffAirplane(airplaneData);
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Airplane created successfully!')));
          }

        } else {
          // EDIT MODE
          final airplaneData = {
            'model': formData['model'],
            'registration_number': formData['registration_number'],
            'status': formData['status'],
            // seat_template_id is ignored by backend logic for updates
          };
          
          await apiService.updateStaffAirplane(widget.airplane!['id'], airplaneData);
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Airplane updated successfully!')));
          }
        }

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save airplane: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.airplane != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Airplane' : 'Create Airplane'),
      content: SizedBox(
        width: double.maxFinite,
        child: _loadingData
            ? const LoadingWidget()
            : SingleChildScrollView(
                child: FormBuilder(
                  key: _formKey,
                  initialValue: isEditing ? {
                    'model': widget.airplane!['model'],
                    'registration_number': widget.airplane!['registration_number'],
                    'status': widget.airplane!['status'] ?? 'ACTIVE',
                  } : {
                    'status': 'ACTIVE',
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status Field
                      FormBuilderDropdown<String>(
                        name: 'status',
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'ACTIVE', child: Text('Active (Can Fly)')),
                          DropdownMenuItem(value: 'MAINTENANCE', child: Text('Maintenance (Repairing)')),
                          DropdownMenuItem(value: 'RETIRED', child: Text('Retired')),
                        ],
                        validator: (value) => value == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      FormBuilderTextField(
                        name: 'model',
                        enabled: !isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Airplane Model',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      FormBuilderTextField(
                        name: 'registration_number',
                        enabled: !isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Registration Number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      if (isEditing) ...[
                        const Divider(),
                         ListTile(
                          title: const Text('Seat Configuration (Read Only)'),
                          subtitle: Text(
                             widget.airplane!['seat_template'] != null 
                             ? '${widget.airplane!['seat_template']['name']} '
                               '(${widget.airplane!['seat_template']['rows']} rows x '
                               '${widget.airplane!['seat_template']['seats_per_row']} seats) \n'
                               'Total Seats: ${widget.airplane!['seat_template']['rows'] * widget.airplane!['seat_template']['seats_per_row']}'
                             : 'No template details available'
                          ),
                          leading: const Icon(Icons.lock_outline),
                        ),
                      ] else ...[
                        FormBuilderSwitch(
                          name: 'use_custom_template',
                          title: const Text('Create Custom Seat Configuration'),
                          initialValue: _useCustomTemplate,
                          onChanged: (val) {
                            setState(() {
                              _useCustomTemplate = val ?? false;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        if (_useCustomTemplate) ...[
                          FormBuilderTextField(
                            name: 'template_name',
                            decoration: const InputDecoration(
                              labelText: 'Configuration Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildSectionLayout('Business (Gold)', 'biz_rows', 'biz_spr', Colors.amber),
                          const SizedBox(height: 16),
                          _buildSectionLayout('Extra Legroom (Blue)', 'el_rows', 'el_spr', Colors.blue),
                          const SizedBox(height: 16),
                          _buildSectionLayout('Economy (Light Blue)', 'econ_rows', 'econ_spr', Colors.lightBlue),
                          const SizedBox(height: 24),
                          
                          // TOTAL SEATS DISPLAY
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.event_seat, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  'Total Capacity: ${(_bizRows * _bizSpr) + (_elRows * _elSpr) + (_econRows * _econSpr)} seats',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          FormBuilderDropdown<int>(
                            name: 'seat_template_id',
                            decoration: const InputDecoration(
                              labelText: 'Select Existing Template',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.event_seat),
                            ),
                            items: _templates.map((template) {
                              return DropdownMenuItem<int>(
                                value: template['id'],
                                child: Text('${template['name']} (${template['rows']}x${template['seats_per_row']} = ${template['rows']*template['seats_per_row']} seats)'),
                              );
                            }).toList(),
                            validator: (value) => value == null ? 'Please select a seat template' : null,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Save Changes' : 'Create'),
        ),
      ],
    );
  }

  Widget _buildSectionLayout(String title, String rowsName, String sprName, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FormBuilderTextField(
                name: rowsName,
                decoration: const InputDecoration(labelText: 'Rows', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (_) => _updateTotalSeats(),
                initialValue: '0',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FormBuilderTextField(
                name: sprName,
                decoration: const InputDecoration(labelText: 'Seats / Row', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (_) => _updateTotalSeats(),
                initialValue: '0',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
