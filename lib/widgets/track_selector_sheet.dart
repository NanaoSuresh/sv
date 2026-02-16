import 'package:flutter/material.dart';

class TrackOption {
  final String id;
  final String label;
  final bool selected;

  const TrackOption({
    required this.id,
    required this.label,
    required this.selected,
  });
}

class TrackSelectorSheet extends StatelessWidget {
  final String title;
  final List<TrackOption> tracks;
  final ValueChanged<String> onSelected;

  const TrackSelectorSheet({
    super.key,
    required this.title,
    required this.tracks,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (tracks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No tracks available',
                style: TextStyle(color: Colors.white54),
              ),
            )
          else
            ...tracks.map((t) => ListTile(
                  title: Text(
                    t.label,
                    style: TextStyle(
                      color: t.selected
                          ? const Color(0xFF00D9FF)
                          : Colors.white,
                    ),
                  ),
                  trailing: t.selected
                      ? const Icon(Icons.check, color: Color(0xFF00D9FF))
                      : null,
                  onTap: () => onSelected(t.id),
                )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
