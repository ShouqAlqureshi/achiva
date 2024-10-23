import 'package:flutter/material.dart';

class SlidingSegmentedControl extends StatefulWidget {
  final Function(int) onValueChanged;
  final int selectedIndex;

  const SlidingSegmentedControl({
    super.key,
    required this.onValueChanged,
    required this.selectedIndex,
  });

  @override
  State<SlidingSegmentedControl> createState() => _SlidingSegmentedControlState();
}

class _SlidingSegmentedControlState extends State<SlidingSegmentedControl> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(50),
      ),
      child: Stack(
        children: [
          // Sliding indicator
          AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: widget.selectedIndex == 0
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.43,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // Buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSegmentButton(
                title: 'Requests',
                index: 0,
              ),
              _buildSegmentButton(
                title: 'Status',
                index: 1,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required int index,
  }) {
    return GestureDetector(
      onTap: () {
        widget.onValueChanged(index);
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.43,
        height: 45,
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: widget.selectedIndex == index
                ? Colors.black
                : Colors.black54,
          ),
        ),
      ),
    );
  }
}

// Usage Example
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SlidingSegmentedControl(
              selectedIndex: _selectedIndex,
              onValueChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}