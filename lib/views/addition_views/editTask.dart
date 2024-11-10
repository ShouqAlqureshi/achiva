import 'package:achiva/views/addition_views/add_redundence_tasks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditTaskDialog extends StatefulWidget {
  final DocumentReference taskRef;
  final Map<String, dynamic> taskData;
  final DateTime goalDate;
  final CollectionReference usergoallistrefrence; 

  const EditTaskDialog({
    Key? key,
    required this.taskRef,
    required this.taskData,
    required this.goalDate,
     required this.usergoallistrefrence,
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
  bool _changingToWeekly = false;


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
    // Remove any extra spaces and convert to uppercase for consistency
    timeStr = timeStr.trim().toUpperCase();
    
    // Try parsing various formats
    
    // Format 1: "HH:MM AM/PM" or "H:MM AM/PM"
    RegExp amPmFormat = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$');
    var amPmMatch = amPmFormat.firstMatch(timeStr);
    if (amPmMatch != null) {
      int hour = int.parse(amPmMatch.group(1)!);
      int minute = int.parse(amPmMatch.group(2)!);
      String period = amPmMatch.group(3)!;
      
      // Convert to 24-hour format if PM
      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }
      
      return TimeOfDay(hour: hour, minute: minute);
    }
    
    // Format 2: "HH:MM" (24-hour format)
    RegExp militaryFormat = RegExp(r'^(\d{1,2}):(\d{2})$');
    var militaryMatch = militaryFormat.firstMatch(timeStr);
    if (militaryMatch != null) {
      int hour = int.parse(militaryMatch.group(1)!);
      int minute = int.parse(militaryMatch.group(2)!);
      
      // Validate hours and minutes
      if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }
    
    // Format 3: Try parsing with DateFormat
    try {
      DateTime dateTime = DateFormat('hh:mm a').parse(timeStr);
      return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
    } catch (e) {
      debugPrint('DateFormat parsing failed: $e');
    }

    // If all parsing attempts fail, throw an exception
    throw FormatException('Invalid time format: $timeStr');
    
  } catch (e) {
    debugPrint('Error parsing time string: $e');
    // Return current time as fallback
    return TimeOfDay.now();
  }
}

String _formatTimeOfDay(TimeOfDay time) {
  // Consistently format time as "hh:mm AM/PM"
  final now = DateTime.now();
  final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
  final formattedTime = DateFormat('hh:mm a').format(dt).toUpperCase();
  debugPrint('Formatted time: $formattedTime');
  return formattedTime;
}

  DateTime _parseDate(String date) {
    try {
      return DateFormat('yyyy-MM-dd').parse(date);
    } catch (e) {
      return DateTime.now();
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

  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Changes'),
          content: const Text(
            'Changing to no recurrence will delete all related weekly tasks. Are you sure you want to continue?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    ) ?? false;
  }

 Future<void> _handleRecurrenceChange(String? newValue) async {
    if (newValue == null) return;

    // Handle changing from Weekly to No recurrence
    if (_selectedRecurrence == 'Weekly' && newValue == 'No recurrence') {
      final bool confirmed = await _showDeleteConfirmationDialog();
      if (confirmed) {
        setState(() {
          _selectedRecurrence = newValue;
        });
      }
    } 
    // Handle changing from No recurrence to Weekly
    else if (_selectedRecurrence == 'No recurrence' && newValue == 'Weekly') {
      setState(() {
        _selectedRecurrence = newValue;
        _changingToWeekly = true;  // Set flag for save operation
      });
    } else {
      setState(() {
        _selectedRecurrence = newValue;
      });
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

      final Map<String, dynamic> updatedTaskData = {
        'taskName': _taskNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim().isEmpty ? 'Unknown location' : _locationController.text.trim(),
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'startTime': startTimeStr,
        'endTime': endTimeStr,
        'recurrence': _selectedRecurrence,
      };

      // Handle deletion of weekly tasks if changing from Weekly to No recurrence
      if (_selectedRecurrence == 'No recurrence' && widget.taskData['recurrence'] == 'Weekly') {
        final String redundancyId = widget.taskData['redundancyId']?.toString() ?? '';
        
        if (redundancyId.isNotEmpty) {
          final QuerySnapshot tasksToDelete = await widget.usergoallistrefrence
              .doc(widget.taskData['goalName'])
              .collection('tasks')
              .where('redundancyId', isEqualTo: redundancyId)
              .get();

          final batch = FirebaseFirestore.instance.batch();
          
          // Update current task and remove redundancyId
          batch.update(widget.taskRef, {
            ...updatedTaskData,
            'redundancyId': FieldValue.delete(),
          });

          // Delete all other tasks with the same redundancyId
          for (var doc in tasksToDelete.docs) {
            if (doc.id != widget.taskRef.id) {
              batch.delete(doc.reference);
            }
          }

          await batch.commit();
        } else {
          await widget.taskRef.update(updatedTaskData);
        }
      }
      // Handle creation of weekly tasks if changing to Weekly
      else if (_changingToWeekly) {
        final parentCollection = widget.taskRef.parent;
        final String redundancyId = DateTime.now().millisecondsSinceEpoch.toString();
        
        final Map<String, dynamic> baseTaskData = {
          ...updatedTaskData,
          'redundancyId': redundancyId,
          'goalName': widget.taskData['goalName'],
        };

        // Calculate dates from start date to goal date
        DateTime currentDate = _selectedDate;
        final List<DateTime> dates = [];
        
        while (currentDate.isBefore(widget.goalDate) || currentDate.isAtSameMomentAs(widget.goalDate)) {
          dates.add(currentDate);
          currentDate = currentDate.add(const Duration(days: 7));
        }

        final batch = FirebaseFirestore.instance.batch();
        
        // Update the original task
        batch.update(widget.taskRef, baseTaskData);

        // Create additional weekly tasks
        for (int i = 1; i < dates.length; i++) {
          final newTaskRef = parentCollection.doc();
          batch.set(newTaskRef, {
            ...baseTaskData,
            'date': DateFormat('yyyy-MM-dd').format(dates[i]),
          });
        }

        await batch.commit();
      }
      // Handle regular weekly task updates
      else if (_selectedRecurrence == 'Weekly' && widget.taskData['redundancyId'] != null) {
        final QuerySnapshot relatedTasks = await widget.usergoallistrefrence
            .doc(widget.taskData['goalName'])
            .collection('tasks')
            .where('redundancyId', isEqualTo: widget.taskData['redundancyId'])
            .get();

        final batch = FirebaseFirestore.instance.batch();
        
        for (var doc in relatedTasks.docs) {
          final existingData = doc.data() as Map<String, dynamic>;
          final existingDate = DateFormat('yyyy-MM-dd').parse(existingData['date']);
          final originalDate = DateFormat('yyyy-MM-dd').parse(widget.taskData['date']);
          final daysDifference = _selectedDate.difference(originalDate).inDays;
          final newTaskDate = existingDate.add(Duration(days: daysDifference));
          
          final specificTaskUpdate = Map<String, dynamic>.from(updatedTaskData);
          specificTaskUpdate['date'] = DateFormat('yyyy-MM-dd').format(newTaskDate);
          
          batch.update(doc.reference, specificTaskUpdate);
        }

        await batch.commit();
      }
      // Handle regular single task update
      else {
        await widget.taskRef.update(updatedTaskData);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task updated successfully')),
        );
Navigator.of(context).pop();      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating task: $e')),
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
                              items: const [
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
                              onChanged: _handleRecurrenceChange,
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