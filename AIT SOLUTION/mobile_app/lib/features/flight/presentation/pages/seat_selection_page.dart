import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ait_airlines/core/utils/navigation_helper.dart';
import 'package:ait_airlines/features/flight/domain/entities/flight.dart';
import 'package:ait_airlines/features/flight/domain/entities/seat_map.dart';
import 'package:ait_airlines/features/flight/presentation/bloc/flight_bloc.dart';
import 'package:ait_airlines/features/flight/presentation/bloc/flight_event.dart';
import 'package:ait_airlines/features/flight/presentation/bloc/flight_state.dart';
import 'package:ait_airlines/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:ait_airlines/features/booking/presentation/bloc/booking_state.dart';
import 'package:ait_airlines/features/booking/presentation/bloc/booking_event.dart';
import 'package:ait_airlines/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ait_airlines/features/auth/presentation/bloc/auth_state.dart';
import 'package:ait_airlines/core/network/api_client.dart';
import 'package:ait_airlines/core/di/injection.dart';

class SeatSelectionPage extends StatefulWidget {
  final Flight flight;
  final int passengersCount;

  const SeatSelectionPage({
    super.key,
    required this.flight,
    required this.passengersCount,
  });

  @override
  State<SeatSelectionPage> createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends State<SeatSelectionPage> {
  int _passengersCount = 1;
  final List<int> _selectedSeatIds = [];

  @override
  void initState() {
    super.initState();
    _passengersCount = widget.passengersCount;
    context.read<FlightBloc>().add(FlightSeatMapRequested(widget.flight.id));
  }

  void _onConfirmSelection() {
    // КРИТИЧЕСКАЯ ПРОВЕРКА: Проверяем, что регистрация еще не закончена
    // Используем UTC время для согласованности с backend
    final now = DateTime.now().toUtc();
    if (widget.flight.checkInCloses != null) {
      // Приводим checkInCloses к UTC для правильного сравнения
      DateTime checkInClosesTime = widget.flight.checkInCloses!;
      if (!checkInClosesTime.isUtc) {
        checkInClosesTime = checkInClosesTime.toUtc();
      }
      if (checkInClosesTime.isBefore(now)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Booking is no longer available - check-in period has ended'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (_selectedSeatIds.length != _passengersCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Выберите ${_passengersCount} мест(а)')),
      );
      return;
    }
    _openPassengerDialog();
  }

  void _openPassengerDialog() async {
    final authState = context.read<AuthBloc>().state;

    // Загружаем данные профиля
    Map<String, dynamic>? profileData;
    if (authState is AuthAuthenticated) {
      try {
        final apiClient = getIt<ApiClient>();
        final response = await apiClient.dio.get('/users/me/profile');
        if (response.statusCode == 200) {
          profileData = response.data;
        }
      } catch (e) {
        // Если не удалось загрузить профиль, продолжаем с пустыми данными
        print('Failed to load profile: $e');
      }
    }

    // Данные владельца из профиля
    String ownerFirst = '';
    String ownerLast = '';
    if (authState is AuthAuthenticated) {
      ownerFirst = profileData?['first_name'] ?? authState.user.firstName ?? '';
      ownerLast = profileData?['last_name'] ?? authState.user.lastName ?? '';
    }
    final ownerPhone = profileData?['phone'] ?? '';
    final ownerPassport = profileData?['passport_number'] ?? '';
    final ownerNationality = profileData?['nationality'] ?? '';

    // Создаем контроллеры для каждого пассажира
    final controllers = List.generate(_passengersCount, (index) {
      if (index == 0) {
        // Первый пассажир (владелец) - заполняем данными из профиля
        return {
          'firstName': TextEditingController(text: ownerFirst),
          'lastName': TextEditingController(text: ownerLast),
          'phone': TextEditingController(text: ownerPhone),
          'passportNumber': TextEditingController(text: ownerPassport),
          'nationality': TextEditingController(text: ownerNationality),
        };
      }
      // Остальные пассажиры - пустые поля
      return {
        'firstName': TextEditingController(),
        'lastName': TextEditingController(),
        'phone': TextEditingController(),
        'passportNumber': TextEditingController(),
        'nationality': TextEditingController(),
      };
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Данные пассажиров',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 500,
          height: MediaQuery.of(context).size.height * 0.7,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(_passengersCount, (index) {
                final isOwner = index == 0;
                final passengerControllers = controllers[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isOwner
                                ? 'Пассажир 1 (вы - владелец)'
                                : 'Пассажир ${index + 1}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (isOwner) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Владелец',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Имя и Фамилия
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: passengerControllers['firstName']
                                  as TextEditingController,
                              decoration: InputDecoration(
                                labelText: 'Имя *',
                                border: const OutlineInputBorder(),
                                hintText:
                                    isOwner ? 'Ваше имя' : 'Имя пассажира',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: passengerControllers['lastName']
                                  as TextEditingController,
                              decoration: InputDecoration(
                                labelText: 'Фамилия *',
                                border: const OutlineInputBorder(),
                                hintText: isOwner
                                    ? 'Ваша фамилия'
                                    : 'Фамилия пассажира',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Телефон
                      TextField(
                        controller: passengerControllers['phone']
                            as TextEditingController,
                        decoration: InputDecoration(
                          labelText: 'Телефон *',
                          border: const OutlineInputBorder(),
                          hintText:
                              isOwner ? '+77771234567' : 'Телефон пассажира',
                          prefixIcon: const Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      // Паспорт
                      TextField(
                        controller: passengerControllers['passportNumber']
                            as TextEditingController,
                        decoration: InputDecoration(
                          labelText: 'ID паспорта *',
                          border: const OutlineInputBorder(),
                          hintText:
                              isOwner ? 'N1234567' : 'ID паспорта пассажира',
                          prefixIcon: const Icon(Icons.credit_card),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Гражданство
                      TextField(
                        controller: passengerControllers['nationality']
                            as TextEditingController,
                        decoration: InputDecoration(
                          labelText: 'Гражданство *',
                          border: const OutlineInputBorder(),
                          hintText:
                              isOwner ? 'Kazakhstan' : 'Гражданство пассажира',
                          prefixIcon: const Icon(Icons.flag),
                        ),
                      ),
                      if (index < _passengersCount - 1) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                      ],
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Назад'),
          ),
          ElevatedButton(
            onPressed: () {
              // ДОПОЛНИТЕЛЬНАЯ ПРОВЕРКА: Еще раз проверяем время регистрации перед созданием бронирования
              // Используем UTC время для согласованности с backend
              final now = DateTime.now().toUtc();
              if (widget.flight.checkInCloses != null) {
                // Приводим checkInCloses к UTC для правильного сравнения
                DateTime checkInClosesTime = widget.flight.checkInCloses!;
                if (!checkInClosesTime.isUtc) {
                  checkInClosesTime = checkInClosesTime.toUtc();
                }
                if (checkInClosesTime.isBefore(now)) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Booking is no longer available - check-in period has ended'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
              }

              // Валидация: проверяем, что все поля заполнены для всех пассажиров
              for (int i = 0; i < _passengersCount; i++) {
                final passengerControllers = controllers[i];
                final firstName =
                    (passengerControllers['firstName'] as TextEditingController)
                        .text
                        .trim();
                final lastName =
                    (passengerControllers['lastName'] as TextEditingController)
                        .text
                        .trim();
                final phone =
                    (passengerControllers['phone'] as TextEditingController)
                        .text
                        .trim();
                final passportNumber = (passengerControllers['passportNumber']
                        as TextEditingController)
                    .text
                    .trim();
                final nationality = (passengerControllers['nationality']
                        as TextEditingController)
                    .text
                    .trim();

                if (firstName.isEmpty ||
                    lastName.isEmpty ||
                    phone.isEmpty ||
                    passportNumber.isEmpty ||
                    nationality.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Заполните все данные для пассажира ${i + 1}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
              }

              // Создаем payload для всех пассажиров
              final passengersPayload = List.generate(_passengersCount, (i) {
                final passengerControllers = controllers[i];
                return {
                  "first_name": (passengerControllers['firstName']
                          as TextEditingController)
                      .text
                      .trim(),
                  "last_name": (passengerControllers['lastName']
                          as TextEditingController)
                      .text
                      .trim(),
                  "phone":
                      (passengerControllers['phone'] as TextEditingController)
                          .text
                          .trim(),
                  "passport_number": (passengerControllers['passportNumber']
                          as TextEditingController)
                      .text
                      .trim(),
                  "nationality": (passengerControllers['nationality']
                          as TextEditingController)
                      .text
                      .trim(),
                  "seat_id": _selectedSeatIds[i],
                };
              });
              Navigator.pop(context);
              context.read<BookingBloc>().add(
                    CreateBookingRequested(
                      flightId: widget.flight.id,
                      passengersCount: _passengersCount,
                      passengers: passengersPayload,
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE94560),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Подтвердить и оплатить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Your Seat',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              '${widget.flight.flightNumber} • ${widget.flight.departureAirport.city} to ${widget.flight.arrivalAirport.city}',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              navigateToHome(context);
            }
          },
          tooltip: 'Back',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => navigateToHome(context),
            tooltip: 'Home',
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
      body: BlocListener<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingCreated) {
            context.push('/payments/checkout', extra: state.booking);
          } else if (state is BookingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.redAccent),
            );
          }
        },
        child: BlocBuilder<FlightBloc, FlightState>(
          builder: (context, state) {
            if (state is FlightLoading) {
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1A1A2E)));
            } else if (state is FlightSeatMapSuccess) {
              return _buildSeatMap(state.seatMap);
            } else if (state is FlightError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            return const Center(child: Text('No seat data available'));
          },
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedSeatIds.isEmpty
                        ? 'Select seats'
                        : 'Price per seat',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${widget.flight.basePrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _selectedSeatIds.length == _passengersCount
                    ? _onConfirmSelection
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE94560),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: BlocBuilder<BookingBloc, BookingState>(
                  builder: (context, state) {
                    if (state is BookingLoading) {
                      return const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      );
                    }
                    return const Text('Book Selected Seat',
                        style: TextStyle(fontWeight: FontWeight.bold));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatMap(SeatMap seatMap) {
    // Group seats by row and class
    final Map<int, List<Map<String, dynamic>>> rows = {};
    // Группируем места по классам, а не по рядам, чтобы избежать дублирования
    final Map<String, Map<int, List<Map<String, dynamic>>>> classSections = {
      'business': {},
      'economy': {}
    };

    for (var seat in seatMap.seats) {
      final rowNum = seat['row_number'] as int;
      final seatClassStr = seat['seat_class'] as String?;
      final seatClass = seatClassStr?.toLowerCase() ?? 'economy';

      if (!rows.containsKey(rowNum)) rows[rowNum] = [];
      rows[rowNum]!.add(Map<String, dynamic>.from(seat));

      // Группируем места по классам: каждое место попадает только в свой класс
      if (seatClass == 'business') {
        if (!classSections['business']!.containsKey(rowNum)) {
          classSections['business']![rowNum] = [];
        }
        classSections['business']![rowNum]!
            .add(Map<String, dynamic>.from(seat));
      } else if (seatClass == 'economy' || seatClass == 'premium_economy') {
        if (!classSections['economy']!.containsKey(rowNum)) {
          classSections['economy']![rowNum] = [];
        }
        classSections['economy']![rowNum]!.add(Map<String, dynamic>.from(seat));
      }
    }

    // Сортируем ряды для каждого класса
    final businessRowKeys = classSections['business']!.keys.toList()..sort();
    final economyRowKeys = classSections['economy']!.keys.toList()..sort();

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildAestheticHeader(),
          _buildPassengersControls(),
          _buildLegend(),
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 60),
                const Icon(Icons.flight_takeoff,
                    color: Color(0xFF1A1A2E), size: 40),
                const SizedBox(height: 20),
                const Text("COCKPIT",
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),

                // Extra room for legs Class Section (бывший Business)
                if (businessRowKeys.isNotEmpty) ...[
                  _buildClassHeader(
                      'EXTRA ROOM FOR LEGS', Colors.amber.shade700),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: businessRowKeys
                          .map((rowKey) => _buildSeatRow(
                              classSections['business']![rowKey]!, 'business'))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildClassDivider(),
                  const SizedBox(height: 24),
                ],

                // Economy Class Section
                if (economyRowKeys.isNotEmpty) ...[
                  _buildClassHeader('ECONOMY CLASS', Colors.blue.shade600),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: economyRowKeys
                          .map((rowKey) => _buildSeatRow(
                              classSections['economy']![rowKey]!, 'economy'))
                          .toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 60),
                const Text("TAIL SECTION",
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildClassHeader(String className, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            className.contains('EXTRA ROOM') || className.contains('BUSINESS')
                ? Icons.star
                : Icons.airline_seat_recline_normal,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            className,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.grey.shade300,
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildAestheticHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildAirportInfo(widget.flight.departureAirport.iataCode,
              widget.flight.departureAirport.city),
          const Column(
            children: [
              Icon(Icons.flight_takeoff, color: Color(0xFFE94560), size: 16),
              SizedBox(height: 4),
              SizedBox(
                  width: 80,
                  child: Divider(color: Colors.white24, thickness: 1)),
            ],
          ),
          _buildAirportInfo(widget.flight.arrivalAirport.iataCode,
              widget.flight.arrivalAirport.city),
        ],
      ),
    );
  }

  Widget _buildPassengersControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Пассажиры',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton(
                    onPressed: _passengersCount > 1
                        ? () {
                            setState(() {
                              _passengersCount--;
                              if (_selectedSeatIds.length > _passengersCount) {
                                _selectedSeatIds.removeRange(
                                    _passengersCount, _selectedSeatIds.length);
                              }
                            });
                          }
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$_passengersCount',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _passengersCount++;
                      });
                    },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSelectedSeatsChips(),
          const SizedBox(height: 12),
          _buildPassengersForm(),
        ],
      ),
    );
  }

  Widget _buildSelectedSeatsChips() {
    if (_selectedSeatIds.isEmpty) {
      return Text(
        'Выберите $_passengersCount ${_passengersCount == 1 ? 'место' : 'места'} для пассажиров (${_selectedSeatIds.length}/${_passengersCount} выбрано)',
        style: TextStyle(color: Colors.grey.shade600),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Выбрано: ${_selectedSeatIds.length}/$_passengersCount мест',
          style: TextStyle(
            color: _selectedSeatIds.length < _passengersCount
                ? Colors.orange.shade700
                : Colors.green.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedSeatIds.asMap().entries.map((entry) {
            final index = entry.key;
            final seatId = entry.value;
            return Chip(
              label: Text('Пассажир ${index + 1}: Место $seatId'),
              onDeleted: () {
                setState(() {
                  // Удаляем место по индексу, чтобы сохранить порядок
                  _selectedSeatIds.removeAt(index);
                });
              },
              deleteIcon: const Icon(Icons.close, size: 18),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPassengersForm() {
    return const SizedBox.shrink();
  }

  Widget _buildAirportInfo(String code, String city) {
    return Column(
      children: [
        Text(code,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold)),
        Text(city, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          // Seat status legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _legendItem(
                  'Available', Colors.white, const Color(0xFF1A1A2E), null),
              _legendItem('Selected', const Color(0xFFE94560),
                  const Color(0xFFE94560), null),
              _legendItem('Taken', const Color(0xFFE1E4E8),
                  const Color(0xFFE1E4E8), Icons.close_rounded),
            ],
          ),
          const SizedBox(height: 12),
          // Class legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _classLegendItem('Extra room for legs', Colors.amber.shade50,
                  Colors.amber.shade600, Icons.star),
              _classLegendItem('Economy Class', Colors.white,
                  Colors.blue.shade600, Icons.airline_seat_recline_normal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String text, Color color, Color border, IconData? icon) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: border, width: 1.5),
          ),
          child:
              icon != null ? Icon(icon, size: 12, color: Colors.black26) : null,
        ),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _classLegendItem(
      String text, Color color, Color iconColor, IconData icon) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: iconColor.withOpacity(0.3), width: 1.5),
          ),
          child: Icon(icon, size: 12, color: iconColor),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontSize: 11,
                color: Colors.black87,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSeatRow(List<Map<String, dynamic>> rowSeats, String seatClass) {
    rowSeats.sort((a, b) =>
        (a['seat_letter'] as String).compareTo(b['seat_letter'] as String));

    final leftSide = rowSeats.take(3).toList();
    final rightSide = rowSeats.skip(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left 3 seats
          ...leftSide.map((s) => _buildSingleSeat(s, seatClass)).toList(),

          // AISLE
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              rowSeats[0]['row_number'].toString(),
              style: const TextStyle(
                  color: Colors.black26,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),

          // Right 3 seats
          ...rightSide.map((s) => _buildSingleSeat(s, seatClass)).toList(),
        ],
      ),
    );
  }

  Widget _buildSingleSeat(Map<String, dynamic> seat, String seatClass) {
    final id = seat['id'] as int;
    final isAvailable = seat['is_available'] as bool;
    final isSelected = _selectedSeatIds.contains(id);
    final letter = seat['seat_letter'] as String;
    final isBusiness = seatClass.toLowerCase() == 'business';

    return GestureDetector(
      onTap: isAvailable
          ? () {
              setState(() {
                if (isSelected) {
                  // Удаляем место при повторном нажатии
                  _selectedSeatIds.remove(id);
                } else {
                  // Проверяем, можем ли добавить еще одно место
                  if (_selectedSeatIds.length < _passengersCount) {
                    _selectedSeatIds.add(id);
                  } else {
                    // Уже выбрано максимальное количество мест
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Можно выбрать максимум $_passengersCount ${_passengersCount == 1 ? 'место' : 'места'}. Выбрано: ${_selectedSeatIds.length}. Увеличьте количество пассажиров или снимите выделение с места.'),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              });
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isBusiness ? 48 : 42, // Business class seats are slightly larger
        height: isBusiness ? 58 : 52,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: !isAvailable
              ? const Color(0xFFE1E4E8)
              : isSelected
                  ? (isBusiness
                      ? Colors.amber.shade600
                      : const Color(0xFFE94560))
                  : (isBusiness ? Colors.amber.shade50 : Colors.white),
          borderRadius: BorderRadius.circular(isBusiness ? 12 : 10),
          border: Border.all(
            color: isSelected
                ? (isBusiness ? Colors.amber.shade600 : const Color(0xFFE94560))
                : (isBusiness
                    ? Colors.amber.shade200
                    : const Color(0xFFD1D5DB)),
            width: isBusiness ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: (isBusiness
                              ? Colors.amber.shade600
                              : const Color(0xFFE94560))
                          .withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2)
                ]
              : (isBusiness
                  ? [
                      BoxShadow(
                          color: Colors.amber.shade100,
                          blurRadius: 4,
                          spreadRadius: 1)
                    ]
                  : null),
        ),
        child: Center(
          child: !isAvailable
              ? const Icon(Icons.close_rounded, size: 20, color: Colors.black12)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isBusiness)
                      Icon(
                        Icons.star,
                        size: 12,
                        color:
                            isSelected ? Colors.white : Colors.amber.shade600,
                      ),
                    Text(
                      letter,
                      style: TextStyle(
                        fontSize: isBusiness ? 14 : 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isBusiness
                                ? Colors.amber.shade700
                                : const Color(0xFF1A1A2E)),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
