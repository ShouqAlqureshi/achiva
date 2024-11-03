import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditTaskDialog extends StatefulWidget {
  final DocumentReference taskRef;
  final Map<String, dynamic> taskData;

  const EditTaskDialog({
    Key? key,
    required this.taskRef,
    required this.taskData,
  }) : super(key: key);

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController taskNameController;
  late TextEditingController descriptionController;
  late TextEditingController locationController;
  late String selectedRecurrence;
  late DateTime selectedDate;
  late TimeOfDay startTime;
  late TimeOfDay endTime;

  bool isTaskNameValid = true;
  bool isDateValid = true;
  bool isStartTimeValid = true;
  bool isEndTimeValid = true;

  @override
  void initState() {
    super.initState();
    taskNameController = TextEditingController(text: widget.taskData['taskName']);
    descriptionController = TextEditingController(text: widget.taskData['description'] ?? '');
    locationController = TextEditingController(text: widget.taskData['location'] ?? '');
    selectedRecurrence = widget.taskData['recurrence'] ?? 'No recurrence';
    selectedDate = DateFormat('yyyy-MM-dd').parse(widget.taskData['date']);
    startTime = TimeOfDay.fromDateTime(DateFormat('hh:mm a').parse(widget.taskData['startTime']));
    endTime = TimeOfDay.fromDateTime(DateFormat('hh:mm a').parse(widget.taskData['endTime']));
  }

  @override
  void dispose() {
    taskNameController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
        isDateValid = true;
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: startTime,
    );
    if (pickedTime != null && pickedTime != startTime) {
      setState(() {
        startTime = pickedTime;
        isStartTimeValid = true;
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    if (startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start time first.')),
      );
      return;
    }

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: endTime,
    );

    if (pickedTime != null && pickedTime != endTime) {
      final DateTime startDateTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        startTime.hour,
        startTime.minute,
      );
      final DateTime endDateTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        pickedTime.hour,
        pickedTime.minute,
      );

      if (endDateTime.isBefore(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time cannot be before start time.')),
        );
      } else {
        setState(() {
          endTime = pickedTime;
          isEndTimeValid = true;
        });
      }
    }
  }

  Future<void> _saveTask() async {
    if (formKey.currentState!.validate()) {
      try {
        Map<String, dynamic> updatedTaskData = {
          'taskName': taskNameController.text,
          'description': descriptionController.text.isNotEmpty ? descriptionController.text : null,
          'location': locationController.text.isNotEmpty ? locationController.text : null,
          'date': DateFormat('yyyy-MM-dd').format(selectedDate),
          'startTime': startTime.format(context),
          'endTime': endTime.format(context),
          'recurrence': selectedRecurrence,
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
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Task',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 20),
              Form(
                key: formKey,
                child: Column(
                  children: [
                    _buildTaskNameField(),
                    SizedBox(height: 16),
                    _buildDescriptionField(),
                    SizedBox(height: 16),
                    _buildLocationField(),
                    SizedBox(height: 16),
                    _buildDatePicker(),
                    SizedBox(height: 16),
                    _buildStartTimePicker(),
                    SizedBox(height: 16),
                    _buildEndTimePicker(),
                    SizedBox(height: 16),
                    _buildRecurrencePicker(),
                  ],
                ),
              ),
              SizedBox(height: 20),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskNameField() {
    return TextFormField(
      controller: taskNameController,
      maxLength: 100,
      inputFormatters: [
        LengthLimitingTextInputFormatter(100),
        FilteringTextInputFormatter.deny(RegExp(r'^\s*$')),
      ],
      decoration: InputDecoration(
        labelText: 'Task Name (mandatory)',
        errorText: isTaskNameValid ? null : 'Task Name is required',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      validator: (value) => value!.isEmpty ? 'Please enter a task name' : null,
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: descriptionController,
      maxLength: 100,
      inputFormatters: [
        LengthLimitingTextInputFormatter(100),
        FilteringTextInputFormatter.deny(RegExp(r'^\s*$')),
      ],
      decoration: InputDecoration(
        labelText: 'Description (optional)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      maxLines: 3,
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      controller: locationController,
      maxLength: 100,
      inputFormatters: [
        LengthLimitingTextInputFormatter(100),
        FilteringTextInputFormatter.deny(RegExp(r'^\s*$')),
      ],
      decoration: InputDecoration(
        labelText: 'Location (optional)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
            style: TextStyle(
              color: isDateValid ? Colors.black : Colors.red,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () => _selectDate(context),
        ),
      ],
    );
  }

  Widget _buildStartTimePicker() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Start Time: ${startTime.format(context)}',
            style: TextStyle(
              color: isStartTimeValid ? Colors.black : Colors.red,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.access_time),
          onPressed: () => _selectStartTime(context),
        ),
      ],
    );
  }

  Widget _buildEndTimePicker() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'End Time: ${endTime.format(context)}',
            style: TextStyle(
              color: isEndTimeValid ? Colors.black : Colors.red,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.access_time),
          onPressed: () => _selectEndTime(context),
        ),
      ],
    );
  }

  Widget _buildRecurrencePicker() {
    return DropdownButtonFormField<String>(
      value: selectedRecurrence,
      decoration: InputDecoration(
        labelText: 'Recurrence',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'No recurrence', child: Text('No recurrence')),
        DropdownMenuItem(value: 'Weekly', child: Text('Weekly recurrence')),
      ],
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            selectedRecurrence = newValue;
          });
        }
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          child: Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        SizedBox(width: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(
            'Save',
            style: TextStyle(color: Colors.white),
          ),
          onPressed: _saveTask,
        ),
      ],
    );
  }
}