import 'package:achiva/views/activity/incoming_request_view.dart';
import 'package:achiva/views/activity/request_status.dart';
import 'package:achiva/widgets/segmented_control.dart';
import 'package:flutter/material.dart';

class Activity extends StatefulWidget {
  const Activity({super.key});

  @override
  State<Activity> createState() => _ActivityState();
}

class _ActivityState extends State<Activity> {
  late final PageController _pageController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onSegmentTapped(int index) {
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar:
          true, // This allows the body to extend behind the app bar
      backgroundColor:
          Colors.transparent, // Make scaffold background transparent
      appBar: AppBar(
        title: const Text(
          'Activity',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 30, 12, 48),
              Color.fromARGB(255, 77, 64, 98),
            ],
          ),
        ),
        child: SafeArea(
          // Add SafeArea to prevent content from going under status bar
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SlidingSegmentedControl(
                  selectedIndex: _selectedIndex,
                  onValueChanged: _onSegmentTapped,
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  physics: const ClampingScrollPhysics(),
                  children: const [
                    IncomingRequestsPage(),
                    RequestStatus(),
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
