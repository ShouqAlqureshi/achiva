import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditTaskDialog extends StatefulWidget {
  final DocumentReference taskRef;
  final Map<String, dynamic> taskData;
  final DateTime goalDate;

  const EditTaskDialog({
    Key? key,
    required this.taskRef,
    required this.taskData,
    required this.goalDate,
  }) : super(key: key);

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  late String _selectedRecurrence;
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  
  // Original values for change detection
  late String _originalTaskName;
  late String _originalDescription;
  late String _originalLocation;
  late String _originalRecurrence;
  late DateTime _originalDate;
  late TimeOfDay _originalStartTime;
  late TimeOfDay _originalEndTime;
  
  bool _isTaskNameValid = true;
  bool _isDateValid = true;
  bool _isGoalDateValid = true;
  bool _isStartTimeValid = true;
  bool _isEndTimeValid = true;

  @override
  void initState() {
    super.initState();
    // Initialize current values
    _taskNameController.text = widget.taskData['taskName'];
    _descriptionController.text = widget.taskData['description'] ?? '';
    String location = widget.taskData['location'] ?? '';
    _locationController.text = location == 'Unknown location' ? '' : location;
    _selectedRecurrence = widget.taskData['recurrence'] ?? 'No recurrence';
    _selectedDate = _parseDate(widget.taskData['date']);
    
    String startTimeStr = widget.taskData['startTime'] ?? '';
    String endTimeStr = widget.taskData['endTime'] ?? '';
    _startTime = _parseTimeString(startTimeStr);
    _endTime = _parseTimeString(endTimeStr);

    // Store original values
    _originalTaskName = _taskNameController.text;
    _originalDescription = _descriptionController.text;
    _originalLocation = _locationController.text;
    _originalRecurrence = _selectedRecurrence;
    _originalDate = _selectedDate;
    _originalStartTime = _startTime;
    _originalEndTime = _endTime;

    // Add listeners to controllers to detect changes
    _taskNameController.addListener(_onFieldsChanged);
    _descriptionController.addListener(_onFieldsChanged);
    _locationController.addListener(_onFieldsChanged);
  }

  bool _hasChanges() {
    return _taskNameController.text != _originalTaskName ||
           _descriptionController.text != _originalDescription ||
           _locationController.text != _originalLocation ||
           _selectedRecurrence != _originalRecurrence ||
           !_selectedDate.isAtSameMomentAs(_originalDate) ||
           _startTime.hour != _originalStartTime.hour ||
           _startTime.minute != _originalStartTime.minute ||
           _endTime.hour != _originalEndTime.hour ||
           _endTime.minute != _originalEndTime.minute;
  }

  TimeOfDay _parseTimeString(String timeStr) {
    if (timeStr.isEmpty) {
      return TimeOfDay.now();
    }

    try {
      // First try parsing the standard "hh:mm a" format (e.g., "02:30 PM")
      DateTime dateTime = DateFormat('hh:mm a').parse(timeStr);
      return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
    } catch (e) {
      try {
        // If that fails, try parsing 24-hour format (e.g., "14:30")
        List<String> parts = timeStr.split(':');
        if (parts.length == 2) {
          int hour = int.parse(parts[0]);
          int minute = int.parse(parts[1]);
          return TimeOfDay(hour: hour, minute: minute);
        }
      } catch (e) {
        debugPrint('Error parsing time string: $e');
      }
    }

    // Return current time if all parsing fails
    return TimeOfDay.now();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('hh:mm a').format(dt).toUpperCase(); // Ensure consistent format
  }

  DateTime _parseDate(String date) {
    try {
      return DateFormat('yyyy-MM-dd').parse(date);
    } catch (e) {
      return DateTime.now();
    }
  }


  Future<void> _saveTask() async {
    setState(() {
      _isTaskNameValid = _taskNameController.text.trim().isNotEmpty;
      _isDateValid = true;
      _isStartTimeValid = true;
      _validateTimes();
    });

    if (!_isTaskNameValid || !_isDateValid || !_isStartTimeValid || !_isEndTimeValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required fields correctly')),
        );
      }
      return;
    }

    try {
      // Format times as strings
      String startTimeStr = _formatTimeOfDay(_startTime);
      String endTimeStr = _formatTimeOfDay(_endTime);

      // Debug print to see what we're saving
      debugPrint('Saving start time: $startTimeStr');
      debugPrint('Saving end time: $endTimeStr');

      final Map<String, dynamic> updatedTaskData = {
        'taskName': _taskNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim().isEmpty ? 'Unknown location' : _locationController.text.trim(),
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'startTime': startTimeStr,
        'endTime': endTimeStr,
        'recurrence': _selectedRecurrence,
      };

      await widget.taskRef.update(updatedTaskData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task updated successfully')),
        );
        Navigator.of(context).pop();
        Navigator.of(context).pop(); // Close both dialogs
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating task: $e')),
        );
      }
    }
  }

void _onFieldsChanged() {
    setState(() {
      // This will trigger a rebuild to update the save button state
    });
  }

  @override
  void dispose() {
    _taskNameController.removeListener(_onFieldsChanged);
    _descriptionController.removeListener(_onFieldsChanged);
    _locationController.removeListener(_onFieldsChanged);
    _taskNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime today = DateTime.now();
    final DateTime firstDate = DateTime(today.year, today.month, today.day);
    final DateTime lastDate = widget.goalDate;
    setState(() {
      _isGoalDateValid = !lastDate.isBefore(firstDate);
    });

    if (lastDate.isBefore(firstDate)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Goal date has already passed. Please update the goal date.'),
          ),
        );
      }
      return;
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(firstDate) ? firstDate : _selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _isDateValid = true;
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (pickedTime != null && pickedTime != _startTime) {
      setState(() {
        _startTime = pickedTime;
        _isStartTimeValid = true;
        // Validate end time when start time changes
        _validateTimes();
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );

    if (pickedTime != null && pickedTime != _endTime) {
      setState(() {
        _endTime = pickedTime;
        _isEndTimeValid = true;
        // Validate times after selection
        _validateTimes();
      });
    }
  }

  void _validateTimes() {
    final DateTime startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final DateTime endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      setState(() {
        _isEndTimeValid = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time')),
        );
      }
    }
  }

 
    @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
        ),
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Task Name Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Task Name',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                      const Text(
                        ' *',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _taskNameController,
                    maxLength: 50,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(50),
                      FilteringTextInputFormatter.deny(RegExp(r'^\s*$')),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Enter task name',
                      errorText: _isTaskNameValid ? null : 'Required',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description and Location Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _descriptionController,
                          maxLength: 100,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(100),
                            FilteringTextInputFormatter.deny(RegExp(r'^\s*$')),
                          ],
                          decoration: InputDecoration(
                            hintText: 'Enter description',
                            border: OutlineInputBorder(),
                            counterText: '',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _locationController,
                          maxLength: 100,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(100),
                            FilteringTextInputFormatter.deny(RegExp(r'^\s*$')),
                          ],
                          decoration: InputDecoration(
                            hintText: 'Enter location',
                            border: OutlineInputBorder(),
                            counterText: '',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Recurrence and Day Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recurrence',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.grey[300]!),
                            color: Colors.white,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              dropdownColor: Colors.white,
                              value: _selectedRecurrence,
                              isExpanded: true,
                              items: [
                                DropdownMenuItem(
                                  value: 'No recurrence',
                                  child: Text(
                                    'No recurrence',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Weekly',
                                  child: Text(
                                    'Weekly recurrence',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedRecurrence = newValue;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Day',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                            const Text(
                              ' *',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: !_isGoalDateValid
                                    ? Colors.red
                                    : !_isDateValid
                                        ? Colors.red
                                        : Colors.grey[300]!,
                                width: !_isGoalDateValid ? 2 : 1,
                              ),
                              color: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    DateFormat('dd.MM.yyyy').format(_selectedDate),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: !_isGoalDateValid || !_isDateValid
                                          ? Colors.red
                                          : Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: !_isGoalDateValid || !_isDateValid
                                      ? Colors.red
                                      : Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!_isGoalDateValid)
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Text(
                              'Goal date has passed',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Time Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Time-From',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                            const Text(
                              ' *',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                       InkWell(
                          onTap: () => _selectStartTime(context),
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: !_isStartTimeValid
                                    ? Colors.red
                                    : Colors.grey[300]!,
                              ),
                              color: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _startTime.format(context),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: !_isStartTimeValid
                                        ? Colors.red
                                        : Colors.black,
                                  ),
                                ),
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: !_isStartTimeValid
                                      ? Colors.red
                                      : Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Time-To',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                            const Text(
                              ' *',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _selectEndTime(context),
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: !_isEndTimeValid
                                    ? Colors.red
                                    : Colors.grey[300]!,
                              ),
                              color: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _endTime.format(context),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: !_isEndTimeValid
                                        ? Colors.red
                                        : Colors.black,
                                  ),
                                ),
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: !_isEndTimeValid
                                      ? Colors.red
                                      : Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _hasChanges() ? _saveTask : null, // Disable if no changes
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            // Add disabledBackgroundColor for better visual feedback
            disabledBackgroundColor: Colors.grey[300],
          ),
          child: const Text(
            'Save',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    ),
            ],
          ),
        ),
      ),
    );
  }
}