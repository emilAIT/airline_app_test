import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';

class CreateFlightDialog extends StatefulWidget {
  final Map<String, dynamic>? flight;

  const CreateFlightDialog({super.key, this.flight});

  @override
  State<CreateFlightDialog> createState() => _CreateFlightDialogState();
}

class _CreateFlightDialogState extends State<CreateFlightDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  List<dynamic> _airports = [];
  List<dynamic> _airplanes = [];
  bool _isLoading = false;
  bool _loadingData = true;

  bool get isEditing => widget.flight != null;
  int? _selectedAirplaneCapacity;
  int _manualConfigCapacity = 0;

  void _updateManualCapacity() {
    // Deprecated: Layout is now fixed on the plane
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final airportsResponse = await apiService.getAirports();
      final airplanesResponse = await apiService.getStaffAirplanes();
      
      if (mounted) {
        setState(() {
          _airports = List<dynamic>.from(airportsResponse.data ?? []);
          // Filter only ACTIVE airplanes for new flights, but include the current one if editing
          final allAirplanes = List<dynamic>.from(airplanesResponse.data ?? []);
          if (isEditing) {
             _airplanes = allAirplanes; // Allow seeing all, logic can be refined
          } else {
             _airplanes = allAirplanes.where((a) => a['status'] == 'ACTIVE').toList();
          }
          _loadingData = false;
          
          if (isEditing) {
            final airplaneId = widget.flight!['airplane_id'];
            final selectedAirplane = _airplanes.firstWhere(
              (a) => a['id'] == airplaneId,
              orElse: () => null,
            );
            if (selectedAirplane != null) {
              _selectedAirplaneCapacity = selectedAirplane['capacity'];
            }
          }
        });
        
        if (!isEditing && (_airports.isEmpty || _airplanes.isEmpty)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Loaded ${_airports.length} airports and ${_airplanes.length} active airplanes.\n' +
                (_airports.isEmpty 
                    ? 'No airports found. Please create airports first.'
                    : 'No active airplanes found. Please create an active airplane first.'),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingData = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: ${e.toString()}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _submitFlight() async {
    if (_formKey.currentState!.saveAndValidate()) {
      setState(() => _isLoading = true);

      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final formData = _formKey.currentState!.value;
        
        final category_prices = <String, double>{};
        if (formData['business_price'] != null && formData['business_price'].toString().isNotEmpty) {
          category_prices['BUSINESS'] = double.parse(formData['business_price'].toString());
        }
        if (formData['extra_legroom_price'] != null && formData['extra_legroom_price'].toString().isNotEmpty) {
          category_prices['EXTRA_LEGROOM'] = double.parse(formData['extra_legroom_price'].toString());
        }


        final Map<String, dynamic> flightData = {
          'flight_number': formData['flight_number'],
          'origin_airport_id': formData['origin_airport_id'],
          'destination_airport_id': formData['destination_airport_id'],
          'airplane_id': formData['airplane_id'],
          'departure_time': (formData['departure_time'] as DateTime).toIso8601String(),
          'arrival_time': (formData['arrival_time'] as DateTime).toIso8601String(),
          'price': double.parse(formData['price'].toString()),
          'gate': formData['gate'],
          'terminal': formData['terminal'],
          'category_prices': category_prices.isNotEmpty ? category_prices : null,
          'category_allocations': null,
        };

        if (isEditing) {
          if (formData['status'] != null) {
            flightData['status'] = formData['status'];
          }
          await apiService.updateStaffFlight(widget.flight!['id'], flightData);
        } else {
          await apiService.createStaffFlight(flightData);
        }

        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isEditing ? 'Flight updated successfully!' : 'Flight created successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          
          String errorMessage = 'Failed to ${isEditing ? 'update' : 'create'} flight';
          
          if (e is DioException) {
            if (e.response != null && e.response?.data is Map) {
              final data = e.response?.data;
              if (data['detail'] != null) {
                errorMessage = data['detail'].toString(); // Show exact backend message
              }
            } else {
               errorMessage += ': ${e.message}';
            }
          } else {
             errorMessage += ': $e';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Edit Flight' : 'Create Flight'),
      content: SizedBox(
        width: double.maxFinite,
        child: _loadingData
            ? const LoadingWidget()
            : SingleChildScrollView(
                child: FormBuilder(
                  key: _formKey,
                  initialValue: isEditing ? {
                    'flight_number': widget.flight!['flight_number'],
                    'origin_airport_id': widget.flight!['origin_airport_id'],
                    'destination_airport_id': widget.flight!['destination_airport_id'],
                    'airplane_id': widget.flight!['airplane_id'],
                    'departure_time': DateTime.parse(widget.flight!['departure_time']),
                    'arrival_time': DateTime.parse(widget.flight!['arrival_time']),
                    'price': widget.flight!['price'].toString(),
                    'gate': widget.flight!['gate'],
                    'terminal': widget.flight!['terminal'],
                    'status': widget.flight!['status'],
                  } : {},
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isEditing) ...[
                        FormBuilderDropdown<String>(
                          name: 'status',
                          decoration: const InputDecoration(
                            labelText: 'Flight Status',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.info_outline),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'SCHEDULED', child: Text('SCHEDULED')),
                            DropdownMenuItem(value: 'BOARDING', child: Text('BOARDING')),
                            DropdownMenuItem(value: 'DELAYED', child: Text('DELAYED')),
                            DropdownMenuItem(value: 'CANCELLED', child: Text('CANCELLED')),
                            DropdownMenuItem(value: 'DEPARTED', child: Text('DEPARTED')),
                            DropdownMenuItem(value: 'LANDED', child: Text('LANDED')),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      FormBuilderTextField(
                        name: 'flight_number',
                        decoration: const InputDecoration(
                          labelText: 'Flight Number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.toString().isEmpty ? 'This field is required' : null,
                      ),
                      const SizedBox(height: 16),
                      FormBuilderDropdown<int>(
                        name: 'origin_airport_id',
                        decoration: const InputDecoration(
                          labelText: 'Origin Airport',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flight_takeoff),
                        ),
                        items: _airports.map((airport) {
                          return DropdownMenuItem<int>(
                            value: airport['id'],
                            child: Text('${airport['code']} - ${airport['name']}'),
                          );
                        }).toList(),
                        validator: (value) => value == null ? 'Please select an origin airport' : null,
                      ),
                      const SizedBox(height: 16),
                      FormBuilderDropdown<int>(
                        name: 'destination_airport_id',
                        decoration: const InputDecoration(
                          labelText: 'Destination Airport',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flight_land),
                        ),
                        items: _airports.map((airport) {
                          return DropdownMenuItem<int>(
                            value: airport['id'],
                            child: Text('${airport['code']} - ${airport['name']}'),
                          );
                        }).toList(),
                        validator: (value) => value == null ? 'Please select a destination airport' : null,
                      ),
                      const SizedBox(height: 16),
                       FormBuilderDropdown<int>(
                        name: 'airplane_id',
                        decoration: const InputDecoration(
                          labelText: 'Airplane',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.airplanemode_active),
                        ),
                        items: _airplanes.map((airplane) {
                          return DropdownMenuItem<int>(
                            value: airplane['id'],
                            child: Text('${airplane['model']} (${airplane['registration_number']})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            final airplane = _airplanes.firstWhere((a) => a['id'] == value);
                            setState(() {
                              _selectedAirplaneCapacity = airplane['capacity'];
                            });
                          }
                        },
                        validator: (value) => value == null ? 'Please select an airplane' : null,
                      ),
                      if (_selectedAirplaneCapacity != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.airplanemode_active, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'Fixed Capacity: $_selectedAirplaneCapacity seats',
                              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      FormBuilderDateTimePicker(
                        name: 'departure_time',
                        decoration: const InputDecoration(
                          labelText: 'Departure Time',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.toString().isEmpty ? 'This field is required' : null,
                        inputType: InputType.both,
                      ),
                      const SizedBox(height: 16),
                      FormBuilderDateTimePicker(
                        name: 'arrival_time',
                        decoration: const InputDecoration(
                          labelText: 'Arrival Time',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.toString().isEmpty ? 'This field is required' : null,
                        inputType: InputType.both,
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: 'price',
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.toString().isEmpty) {
                            return 'This field is required';
                          }
                          if (double.tryParse(value.toString()) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: 'gate',
                        decoration: const InputDecoration(
                          labelText: 'Gate (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                       const SizedBox(height: 16),
                      const Text(
                        'Category Pricing',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      FormBuilderTextField(
                        name: 'business_price',
                        decoration: const InputDecoration(
                          labelText: 'Business Class Price',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.star, color: Colors.amber),
                          hintText: 'Inherits base price if empty',
                        ),
                        keyboardType: TextInputType.number,
                        initialValue: isEditing && widget.flight!['category_prices'] != null ? 
                            widget.flight!['category_prices']['BUSINESS']?.toString() : null,
                      ),
                      const SizedBox(height: 12),
                      FormBuilderTextField(
                        name: 'extra_legroom_price',
                        decoration: const InputDecoration(
                          labelText: 'Extra Legroom Price',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.airline_seat_legroom_extra, color: Colors.blue),
                          hintText: 'Inherits base price if empty',
                        ),
                        keyboardType: TextInputType.number,
                        initialValue: isEditing && widget.flight!['category_prices'] != null ? 
                            widget.flight!['category_prices']['EXTRA_LEGROOM']?.toString() : null,
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: 'terminal',
                        decoration: const InputDecoration(
                          labelText: 'Terminal (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
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
        if (!_loadingData)
          ElevatedButton(
            onPressed: _isLoading ? null : _submitFlight,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isEditing ? 'Update' : 'Create'),
          ),
      ],
    );
  }
}
