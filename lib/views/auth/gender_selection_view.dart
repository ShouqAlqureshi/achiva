import 'package:flutter/material.dart';

class GenderSelectionView extends StatefulWidget {
  const GenderSelectionView({super.key});

  @override
  _GenderSelectionViewState createState() => _GenderSelectionViewState();
}

class _GenderSelectionViewState extends State<GenderSelectionView> {
  String? _selectedGender;
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    final userData =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Gender selection",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(255, 240, 238, 249),
                ),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 40),
              const Text(
                'What is your gender?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 71, 71, 71),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildGenderOption(context, 'Female', Icons.female, userData),
                  _buildGenderOption(context, 'Male', Icons.male, userData),
                ],
              ),
              const SizedBox(height: 20),
              if (_errorText != null) // Display error if gender not selected
                Text(
                  _errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  if (_selectedGender == null) {
                    setState(() {
                      _errorText = 'Please select a gender.';
                    });
                  } else {
                    userData['gender'] = _selectedGender;
                    Navigator.of(context).pushNamed('/profilepicturepicker',
                        arguments: userData);
                  }
                },
                child: const Text('CONTINUE', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderOption(BuildContext context, String gender, IconData icon,
      Map<String, dynamic> userData) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender.toLowerCase();
          _errorText = null; // Clear error when gender is selected
        });
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 71, 71, 71).withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: _selectedGender == gender.toLowerCase()
                  ? Colors.deepPurple
                  : Color.fromARGB(255, 71, 71, 71),
              width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              gender,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
