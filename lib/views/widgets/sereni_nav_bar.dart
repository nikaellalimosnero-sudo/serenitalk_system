import 'package:flutter/material.dart';

import 'sereni_widgets.dart';

/// The blue pill navigation bar: Home, Chat, Profile, Appointments.
class SereniNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const SereniNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _icons = [
    Icons.home_outlined,
    Icons.chat_bubble_outline,
    Icons.person_outline,
    Icons.calendar_today_outlined,
  ];
  static const _labels = ['Home', 'Chat', 'Profile', 'Appointments'];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: SereniColors.brand,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: SereniColors.brand.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < _icons.length; i++)
            Semantics(
              button: true,
              selected: i == currentIndex,
              label: _labels[i],
              child: InkResponse(
                onTap: () => onTap(i),
                radius: 28,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: i == currentIndex
                        ? Colors.white
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _icons[i],
                    size: 24,
                    color: i == currentIndex
                        ? SereniColors.brand
                        : Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
