import 'package:flutter/material.dart';

class UnfoldingTile extends StatefulWidget {
  final Map<String, dynamic> tileData;
  final Color tileColor;

  const UnfoldingTile({
    super.key,
    required this.tileData,
    required this.tileColor,
  });

  @override
  _UnfoldingTileState createState() => _UnfoldingTileState();
}

class _UnfoldingTileState extends State<UnfoldingTile> {
  bool isUnfolded = false;

  Color getContrastColor(Color backgroundColor) {
    double luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isUnfolded = !isUnfolded;
        });
      },
      child: Card(
        color: widget.tileColor,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                title: Text(
                  'Car: ${widget.tileData['publicId']}',
                  style: TextStyle(
                    color: getContrastColor(widget.tileColor),
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Battery: ${widget.tileData['battery']}%',
                      style: TextStyle(
                        color: getContrastColor(widget.tileColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Distance: ${widget.tileData['distanceToUser'].toStringAsFixed(2)} meters',
                      style: TextStyle(
                        color: getContrastColor(widget.tileColor),
                      ),
                    ),
                  ],
                ),
                trailing: Icon(
                  isUnfolded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: getContrastColor(widget.tileColor),
                ),
              ),
              if (isUnfolded)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Est. Net Gained Minutes: ${widget.tileData['net_gain'].toString()} min',
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dist. from free charger: ${widget.tileData['dist_to_charg'].toStringAsFixed(2)} m',
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Charger addr. ${widget.tileData['char_addr']}',
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      )
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
