import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:airline_app/presentation/cubits/staff_cubit.dart';
import 'package:airline_app/presentation/screens/staff/staff_flight_list.dart';
import 'package:airline_app/presentation/screens/staff/staff_booking_list.dart';
import 'package:airline_app/presentation/screens/staff/staff_announcements_screen.dart';
import 'package:airline_app/presentation/screens/staff/staff_airplane_screen.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  @override
  void initState() {
    super.initState();
    context.read<StaffCubit>().loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            labelColor: Color(0xFF673AB7),
            indicatorColor: Color(0xFF673AB7),
            tabs: [
              Tab(icon: Icon(Icons.flight), text: 'Flights'),
              Tab(icon: Icon(Icons.book_online), text: 'Bookings'),
              Tab(icon: Icon(Icons.campaign), text: 'Announcements'),
              Tab(icon: Icon(Icons.airline_seat_recline_normal), text: 'Airplanes'),
            ],
          ),
          Expanded(
            child: BlocBuilder<StaffCubit, StaffState>(
              builder: (context, state) {
                if (state is StaffLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is StaffError) {
                  return Center(child: Text('Error: ${state.message}'));
                }

                if (state is StaffDataLoaded) {
                  return TabBarView(
                    children: [
                      StaffFlightList(flights: state.flights),
                      StaffBookingList(bookings: state.bookings),
                      const StaffAnnouncementsScreen(),
                      const StaffAirplaneScreen(),
                    ],
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
