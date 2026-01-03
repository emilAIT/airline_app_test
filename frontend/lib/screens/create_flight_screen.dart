import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../theme/zaku_colors.dart';

class CreateFlightScreen extends StatefulWidget {
  const CreateFlightScreen({super.key});

  @override
  State<CreateFlightScreen> createState() => _CreateFlightScreenState();
}

class _CreateFlightScreenState extends State<CreateFlightScreen> {
  final _formKey = GlobalKey<FormState>();
  final _flightNumberController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _terminalController = TextEditingController();
  final _gateController = TextEditingController();

  bool _loading = false;
  List<dynamic> _airports = [];
  List<dynamic> _airplanes = [];

  int? _selectedOriginId;
  int? _selectedDestinationId;
  int? _selectedAirplaneId;

  DateTime? _departureDate;
  TimeOfDay? _departureTime;
  DateTime? _arrivalDate;
  TimeOfDay? _arrivalTime;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _flightNumberController.dispose();
    _basePriceController.dispose();
    _terminalController.dispose();
    _gateController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final airports = await ApiService.getAirports();
      final airplanes = await ApiService.staffListAirplanes();

      if (!mounted) return;
      setState(() {
        _airports = airports;
        _airplanes = airplanes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки данных: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDepartureDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _departureDate = date);
    }
  }

  Future<void> _selectDepartureTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _departureTime = time);
    }
  }

  Future<void> _selectArrivalDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _departureDate ?? DateTime.now(),
      firstDate: _departureDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _arrivalDate = date);
    }
  }

  Future<void> _selectArrivalTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _arrivalTime = time);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedOriginId == null) {
      _showError('Выберите аэропорт отправления');
      return;
    }

    if (_selectedDestinationId == null) {
      _showError('Выберите аэропорт прибытия');
      return;
    }

    if (_selectedOriginId == _selectedDestinationId) {
      _showError('Аэропорты отправления и прибытия должны быть разными');
      return;
    }

    if (_departureDate == null || _departureTime == null) {
      _showError('Укажите дату и время вылета');
      return;
    }

    if (_arrivalDate == null || _arrivalTime == null) {
      _showError('Укажите дату и время прилета');
      return;
    }

    final departureDateTime = DateTime(
      _departureDate!.year,
      _departureDate!.month,
      _departureDate!.day,
      _departureTime!.hour,
      _departureTime!.minute,
    );

    final arrivalDateTime = DateTime(
      _arrivalDate!.year,
      _arrivalDate!.month,
      _arrivalDate!.day,
      _arrivalTime!.hour,
      _arrivalTime!.minute,
    );

    if (arrivalDateTime.isBefore(departureDateTime)) {
      _showError('Время прилета должно быть после времени вылета');
      return;
    }

    setState(() => _loading = true);
    try {
      await ApiService.staffCreateFlight(
        flightNumber: _flightNumberController.text.trim(),
        originId: _selectedOriginId!,
        destinationId: _selectedDestinationId!,
        airplaneId: _selectedAirplaneId,
        departureTime: departureDateTime.toIso8601String(),
        arrivalTime: arrivalDateTime.toIso8601String(),
        basePrice: double.parse(_basePriceController.text.trim()),
        terminal: _terminalController.text.trim().isNotEmpty
            ? _terminalController.text.trim()
            : null,
        gate: _gateController.text.trim().isNotEmpty
            ? _gateController.text.trim()
            : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Рейс ${_flightNumberController.text} создан'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.isEmpty ? 'Ошибка создания рейса' : msg),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Создать рейс',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: ZaKuColors.burgundy,
        foregroundColor: Colors.white,
      ),
      body: _loading && _airports.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Flight Number
                    TextFormField(
                      controller: _flightNumberController,
                      decoration: InputDecoration(
                        labelText: 'Номер рейса *',
                        hintText: 'KC101',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Обязательно' : null,
                    ),
                    const SizedBox(height: 16),

                    // Origin Airport
                    DropdownButtonFormField<int>(
                      value: _selectedOriginId,
                      decoration: InputDecoration(
                        labelText: 'Аэропорт отправления *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _airports.map<DropdownMenuItem<int>>((airport) {
                        return DropdownMenuItem<int>(
                          value: airport['id'],
                          child: Text(
                            '${airport['code']} - ${airport['city']}',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedOriginId = value);
                      },
                      validator: (v) => v == null ? 'Выберите аэропорт' : null,
                    ),
                    const SizedBox(height: 16),

                    // Destination Airport
                    DropdownButtonFormField<int>(
                      value: _selectedDestinationId,
                      decoration: InputDecoration(
                        labelText: 'Аэропорт прибытия *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _airports.map<DropdownMenuItem<int>>((airport) {
                        return DropdownMenuItem<int>(
                          value: airport['id'],
                          child: Text(
                            '${airport['code']} - ${airport['city']}',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedDestinationId = value);
                      },
                      validator: (v) => v == null ? 'Выберите аэропорт' : null,
                    ),
                    const SizedBox(height: 16),

                    // Airplane
                    DropdownButtonFormField<int>(
                      value: _selectedAirplaneId,
                      decoration: InputDecoration(
                        labelText: 'Самолет (опционально)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Не выбран'),
                        ),
                        ..._airplanes.map<DropdownMenuItem<int>>((airplane) {
                          return DropdownMenuItem<int>(
                            value: airplane['id'],
                            child: Text(
                              '${airplane['registration_number']} (${airplane['model']})',
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedAirplaneId = value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Departure Date & Time
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectDepartureDate,
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _departureDate == null
                                  ? 'Дата вылета *'
                                  : DateFormat(
                                      'dd.MM.yyyy',
                                    ).format(_departureDate!),
                              style: GoogleFonts.montserrat(),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectDepartureTime,
                            icon: const Icon(Icons.access_time),
                            label: Text(
                              _departureTime == null
                                  ? 'Время вылета *'
                                  : _departureTime!.format(context),
                              style: GoogleFonts.montserrat(),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Arrival Date & Time
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectArrivalDate,
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _arrivalDate == null
                                  ? 'Дата прилета *'
                                  : DateFormat(
                                      'dd.MM.yyyy',
                                    ).format(_arrivalDate!),
                              style: GoogleFonts.montserrat(),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectArrivalTime,
                            icon: const Icon(Icons.access_time),
                            label: Text(
                              _arrivalTime == null
                                  ? 'Время прилета *'
                                  : _arrivalTime!.format(context),
                              style: GoogleFonts.montserrat(),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Base Price
                    TextFormField(
                      controller: _basePriceController,
                      decoration: InputDecoration(
                        labelText: 'Базовая цена *',
                        hintText: '50000',
                        suffixText: '₸',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Обязательно';
                        }
                        if (double.tryParse(v.trim()) == null) {
                          return 'Введите число';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Terminal & Gate
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _terminalController,
                            decoration: InputDecoration(
                              labelText: 'Терминал',
                              hintText: 'A',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _gateController,
                            decoration: InputDecoration(
                              labelText: 'Выход',
                              hintText: '12',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton(
                      onPressed: _loading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ZaKuColors.gold,
                        foregroundColor: ZaKuColors.burgundy,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Создать рейс',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
