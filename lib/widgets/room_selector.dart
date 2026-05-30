import 'package:flutter/material.dart';

class RoomSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const RoomSelector({super.key, required this.selected, required this.onSelect});

  static const _rooms = [
    (name: 'סלון', icon: Icons.weekend_outlined),
    (name: 'חדר שינה', icon: Icons.bed_outlined),
    (name: 'מטבח', icon: Icons.kitchen_outlined),
    (name: 'חדר ילדים', icon: Icons.child_care_outlined),
    (name: 'חדר עבודה', icon: Icons.computer_outlined),
    (name: 'חדר אמבטיה', icon: Icons.bathtub_outlined),
    (name: 'מרפסת', icon: Icons.balcony_outlined),
    (name: 'כניסה', icon: Icons.door_front_door_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('בחר חדר',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: _rooms.map((room) {
                final isSelected = selected == room.name;
                return GestureDetector(
                  onTap: () => onSelect(room.name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(room.icon, size: 24,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null),
                        const SizedBox(height: 4),
                        Text(room.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.w600 : FontWeight.w400)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
