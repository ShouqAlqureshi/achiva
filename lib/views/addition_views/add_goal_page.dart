import 'package:flutter/material.dart';
import 'package:achiva/views/addition_views/add_task_page.dart'; // Import the task page
import 'package:intl/intl.dart'; // Import the intl package for date formatting


class AddGoalPage extends StatefulWidget {
  const AddGoalPage({super.key});

  @override
  _AddGoalPageState createState() => _AddGoalPageState();
}

class _AddGoalPageState extends State<AddGoalPage> {
  final TextEditingController _nameController = TextEditingController();
  bool _visibility = true;
  DateTime? _selectedDate;
  bool _isNameValid = true; // Tracks if the goal name is valid
  bool _isDateValid = true; // Tracks if the date is valid

  // Navigate to the next page to add tasks
  void _goToAddTaskPage() {
    setState(() {
      _isNameValid = _nameController.text.isNotEmpty; // Check if name is not empty
      _isDateValid = _selectedDate != null; // Check if date is selected
    });

    // If both fields are valid, proceed to the next page
    if (_isNameValid && _isDateValid) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddTaskPage(
            goalName: _nameController.text,
            goalDate: _selectedDate!,
            goalVisibility: _visibility,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
    }
  }

  // Display a date picker that doesn't allow selecting past dates
  Future<void> _pickDate(BuildContext context) async {
    final DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today, // Prevent selecting dates before today
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _isDateValid = true; // Reset the date validation when a date is chosen
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a New Goal'),backgroundColor: Colors.grey[200], // Set app bar background color to white
),
      backgroundColor: Colors.grey[200],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Container with Card inside to hold the form fields
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),

                ),
                child: Card(
                  elevation: 5,
                
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Goal Name Field with Validation
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Goal Name',
                            errorText: _isNameValid ? null : 'Please enter a goal name',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: (text) {
                            setState(() {
                              _isNameValid = text.isNotEmpty; // Validate on typing
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Date Field with Validation
                        ListTile(
                          title: Text(
                            _selectedDate == null
                                ? 'Select End Date'
                                : 'End Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                            style: TextStyle(
                              color: _isDateValid ? Colors.black : Colors.red, // Red text if invalid
                            ),
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () => _pickDate(context),
                        ),
                        if (!_isDateValid)
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Text(
                              'Please select an end date',
                              style: TextStyle(color: Colors.red), // Red error message
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Visibility Switch
                        SwitchListTile(
                          title: const Text('Visibility'),
                          value: _visibility,
                          onChanged: (bool value) {
                            setState(() {
                              _visibility = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple, // Set button background color
                ),
                onPressed: _goToAddTaskPage,
                child: const Text(
                  'Next: Add Tasks',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


