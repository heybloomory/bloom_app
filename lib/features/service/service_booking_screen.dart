import 'package:flutter/material.dart';

import '../../core/widgets/glass_container.dart';
import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';
import 'service_data.dart';
import 'add_service_dialog.dart';
import 'service_widgets.dart';

class ServiceBookingScreen extends StatefulWidget {
  final DestinationService service;
  final ServicePhotographer photographer;

  const ServiceBookingScreen({
    super.key,
    required this.service,
    required this.photographer,
  });

  static ServiceBookingScreen fromRoute(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final map = args is Map ? args : const {};

    final serviceId = (map['serviceId'] ?? 'paris_photo_tour').toString();
    final photographerId = (map['photographerId'] ?? 'alex_moreau').toString();

    final service = ServiceCatalog.byId(serviceId);

    final photographer = service.photographers.firstWhere(
      (p) => p.id == photographerId,
      orElse: () => service.photographers.first,
    );

    return ServiceBookingScreen(service: service, photographer: photographer);
  }

  @override
  State<ServiceBookingScreen> createState() => _ServiceBookingScreenState();
}

class _ServiceBookingScreenState extends State<ServiceBookingScreen> {
  DateTime _selectedDate = DateTime(2024, 4, 25);
  String _selectedTime = '6:00 PM';

  final List<String> _timeSlots = const ['10:00 AM', '11:00 AM', '12:00 PM', '6:00 PM'];

  @override
  Widget build(BuildContext context) {
    const dollar = '\u0024';

    return MainAppShell(
      currentRoute: AppRoutes.service,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Text(
                    'Destination > ${widget.service.title}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        barrierColor: Colors.black54,
                        builder: (_) => AddServiceDialog(onAdded: () {}),
                      );
                    },
                    child: GlassContainer(
                      radius: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.add, color: Colors.white70, size: 18),
                          SizedBox(width: 6),
                          Text('Add Service', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.notifications_none, color: Colors.white.withOpacity(0.85)),
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/images/profile.jpg',
                      width: 34,
                      height: 34,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    Image.asset(
                      widget.service.heroImageAsset,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.12),
                              Colors.black.withOpacity(0.60),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.service.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.star, size: 18, color: Colors.amber.shade300),
                              const SizedBox(width: 6),
                              Text(
                                '${widget.service.rating.toStringAsFixed(1)}  (${widget.service.reviews})',
                                style: TextStyle(color: Colors.white.withOpacity(0.85)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.service.description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),
              Center(
                child: Text(
                  'Select Date & Time',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              GlassContainer(
                radius: 22,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _MonthHeader(
                      monthLabel: 'April 2024',
                      onPrev: () {},
                      onNext: () {},
                    ),
                    const SizedBox(height: 10),
                    _WeekRow(selectedDay: _selectedDate.day, onSelect: _onSelectDay),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Available Time Slots ✨',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.88),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _timeSlots.map((t) {
                        final selected = t == _selectedTime;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedTime = t),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withOpacity(selected ? 0.55 : 0.22),
                              ),
                              color: selected
                                  ? const Color(0xFFE2A15D).withOpacity(0.65)
                                  : Colors.white.withOpacity(0.06),
                            ),
                            child: Text(
                              t,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              Text(
                'Select Photographer',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.88),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              GlassContainer(
                radius: 22,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        widget.photographer.avatarAsset,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.photographer.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.star, size: 16, color: Colors.amber.shade300),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.photographer.rating.toStringAsFixed(1)}  (${widget.photographer.reviews})',
                                style: TextStyle(color: Colors.white.withOpacity(0.8)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Paris Photo Tour  ·  Thu, Apr ${_selectedDate.day}  |  $_selectedTime',
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$dollar${widget.service.startingPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              Center(
                child: PrimaryPillButton(
                  label: 'Confirm Booking',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Booked ${widget.service.title} on Apr ${_selectedDate.day} at $_selectedTime',
                        ),
                      ),
                    );
                    Navigator.popUntil(context, ModalRoute.withName(AppRoutes.service));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSelectDay(int day) {
    setState(() {
      _selectedDate = DateTime(2024, 4, day);
    });
  }
}

class _MonthHeader extends StatelessWidget {
  final String monthLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthHeader({
    required this.monthLabel,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onPrev,
          icon: Icon(Icons.chevron_left, color: Colors.white.withOpacity(0.85)),
        ),
        Text(
          monthLabel,
          style: TextStyle(
            color: Colors.white.withOpacity(0.92),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.85)),
        ),
      ],
    );
  }
}

class _WeekRow extends StatelessWidget {
  final int selectedDay;
  final ValueChanged<int> onSelect;

  const _WeekRow({required this.selectedDay, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    // Mirrors the "23 24 25 26 24 25 26 27" style strip from the mock.
    final days = const [23, 24, 25, 26, 24, 25, 26, 27];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _Dow('S'),
            _Dow('M'),
            _Dow('T'),
            _Dow('W'),
            _Dow('T'),
            _Dow('F'),
            _Dow('S'),
            _Dow('S'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: days.map((d) {
            final selected = d == selectedDay;
            return GestureDetector(
              onTap: () => onSelect(d),
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withOpacity(0.14) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(selected ? 0.55 : 0.16),
                  ),
                ),
                child: Text(
                  d.toString(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            8,
            (_) => Text(
              'Available',
              style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }
}

class _Dow extends StatelessWidget {
  final String text;
  const _Dow(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
      ),
    );
  }
}
