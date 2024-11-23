import 'package:achiva/views/auth/validators.dart';
import 'package:achiva/views/sharedgoal/sharedgoal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // Import the intl package for date formatting
class EditGoalPage extends StatefulWidget {
  final DocumentReference goalRef;
  final String goalName;
  final DateTime goalDate;
  final bool visibility;

  const EditGoalPage({
    super.key,
    required this.goalRef,
    required this.goalName,
    required this.goalDate,
    required this.visibility
  });
  @override
  _EditGoalPageState createState() => _EditGoalPageState();
}
class _EditGoalPageState extends State<EditGoalPage> {
  final TextEditingController _nameController = TextEditingController();
  late bool _visibility;
  bool _sharedGoal = false;
  DateTime? _selectedDate;
  bool _isNameValid = true; // Tracks if the goal name is valid
  bool _isDateValid = true; // Tracks if the date is valid
  String? errorMessage = "";
  Validators validate = Validators();
  // Sharedgoal sharedgoal = Sharedgoal();
  
   @override
  void initState() {
    super.initState();
    _nameController.text = widget.goalName;
    _selectedDate = _parseDate(widget.goalDate.toString());
    _visibility=widget.visibility;
  }

    DateTime _parseDate(String date) {
    try {
      return DateFormat('yyyy-MM-dd').parse(date);
    } catch (e) {
      return DateTime.now();
    }
  }

@override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
          'Edit goal',
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
                           InkWell(
                          onTap: () => _pickDate(context),
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: !_isDateValid
                                    ? Colors.red
                                    : !_isDateValid
                                        ? Colors.red
                                        : Colors.grey[300]!,
                                width: !_isDateValid ? 2 : 1,
                              ),
                              color: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    DateFormat('dd.MM.yyyy').format(_selectedDate!),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: !_isDateValid || !_isDateValid
                                          ? Colors.red
                                          : Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: !_isDateValid || !_isDateValid
                                      ? Colors.red
                                      : Colors.grey[600],
                                ),
                              ],
                            ),
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
                    onPressed: _editGoal,
                    child: const Text(
                      'Edit Goal',
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

  Future<void> _editGoal() async {
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
       try {
      final Map<String, dynamic> updategoalData = {
        'name': _nameController.text.trim(),
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'visibility': _visibility,
      
      };

      await widget.goalRef.update(updategoalData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal updated successfully')),
        );
        Navigator.of(context).pop(); // Close both dialogs
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating task: $e')),
        );
      }
    }
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
}