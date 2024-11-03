import 'package:achiva/views/auth/validators.dart';
import 'package:achiva/views/sharedgoal/sharedgoal.dart';
import 'package:flutter/material.dart';
import 'package:achiva/views/addition_views/add_task_page.dart'; // Import the task page
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // Import the intl package for date formatting

class AddGoalPage extends StatefulWidget {
  const AddGoalPage({super.key});

  @override
  _AddGoalPageState createState() => _AddGoalPageState();
}

class _AddGoalPageState extends State<AddGoalPage> {
  final TextEditingController _nameController = TextEditingController();
  bool _visibility = true;
  bool _sharedGoal = false;
  DateTime? _selectedDate;
  bool _isNameValid = true; // Tracks if the goal name is valid
  bool _isDateValid = true; // Tracks if the date is valid
  String? errorMessage = "";
  Validators validate = Validators();
  Sharedgoal sharedgoal = Sharedgoal();

  Future<void> _goToAddTaskPage() async {
    setState(() {
      // Reset error states
      _isDateValid = _selectedDate != null;
      errorMessage = null;
    });

    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _isNameValid = false;
        errorMessage = "Please enter a goal name";
      });
      _showError('Please enter a goal name');
      return;
    }

    try {
      // Wait for the async validation
      bool isValid =
          await validate.isGoalNameValid(_nameController.text, context);

      setState(() {
        _isNameValid = isValid;
        if (!isValid) {
          errorMessage = "The goal name exists, try changing the name";
        }
      });

      // Check all validation conditions
      if (_isNameValid && _isDateValid) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddTaskPage(
              goalName: _nameController.text,
              goalDate: _selectedDate!,
              goalVisibility: _visibility,
              sharedGoal: _sharedGoal,
            ),
          ),
        );
      } else {
        String errorMsg = '';
        if (!_isDateValid) errorMsg = 'Please select an end date';
        if (!_isNameValid) errorMsg = errorMessage ?? 'Invalid goal name';
        _showError(errorMsg);
      }
    } catch (e) {
      _showError('An error occurred while validating the goal name');
      print('Error validating goal name: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
      extendBodyBehindAppBar: true, // Extend the body behind the AppBar
      backgroundColor: Colors.transparent, // Transparent background
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text(
          'Add goal',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        height: double
            .infinity, // Makes the container fill the entire screen height
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
        child: Padding(
          padding: const EdgeInsets.only(
              top: 100.0, left: 16.0, right: 16.0, bottom: 100.0),
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
                            maxLength:
                                100, // Set the maximum number of characters
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(
                                  RegExp(r'^\s*$')),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Goal Name',
                              errorText: _isNameValid ? null : errorMessage,
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onChanged: (text) {
                              setState(() {
                                _isNameValid = text
                                    .trim()
                                    .isNotEmpty; // Validate on typing
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
                                color: _isDateValid
                                    ? Colors.black
                                    : Colors.red, // Red text if invalid
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
                                style: TextStyle(
                                    color: Colors.red), // Red error message
                              ),
                            ),
                          const SizedBox(height: 16),
                          // shared goal Switch
                          SwitchListTile(
                            title: const Text('Shared goal'),
                            value: _sharedGoal,
                            onChanged: (bool value) {
                              setState(() {
                                _sharedGoal = value;
                              });
                            },
                          ),
                          if (_sharedGoal)
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Color.fromARGB(255, 77, 64, 98),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            10), // Adjust the radius as needed
                                      ),
                                    ),
                                    onPressed: () {
                                      sharedgoal.showFriendListDialog(context);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical:
                                              16.0), // Adjust padding as needed
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Invite Collaborators",
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          const SizedBox(width: 16),
                                          const Icon(Icons.send),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isNameValid && _isDateValid
                          ? const Color.fromARGB(255, 30, 12, 48)
                          : Colors.grey[800],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: _goToAddTaskPage,
                    child: const Text(
                      'Next: Add Tasks',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
