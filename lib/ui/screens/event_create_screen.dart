import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/events_repository.dart';
import '../../models/domain/event_campaign.dart';
import '../../state/session_provider.dart';
import '../widgets/main_app_bar.dart';

class EventCreateScreen extends StatefulWidget {
  const EventCreateScreen({super.key});

  @override
  State<EventCreateScreen> createState() => _EventCreateScreenState();
}

class _EventCreateScreenState extends State<EventCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _locationsController = TextEditingController();
  final _targetAmountController = TextEditingController(text: '20000');
  final _extraChargeController = TextEditingController(text: '0');
  final _welcomeTemplateController = TextEditingController();
  final _congratsTemplateController = TextEditingController();

  String _lifecycleStatus = 'running';
  DateTime? _eventDate;
  String _eventId = '';
  bool _isEditMode = false;
  bool _initialized = false;
  bool _loadingEvent = false;
  bool _saving = false;
  String _error = '';
  String _lockedSlug = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    final map = args is Map<String, dynamic> ? args : <String, dynamic>{};
    _eventId = map['eventId']?.toString() ?? '';
    _isEditMode = _eventId.isNotEmpty;
    if (_isEditMode) {
      _loadEventForEdit();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _locationsController.dispose();
    _targetAmountController.dispose();
    _extraChargeController.dispose();
    _welcomeTemplateController.dispose();
    _congratsTemplateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final role = session.role;
    final canCreate = role == 'Owner' || role == 'Manager';

    return Scaffold(
      appBar: MainAppBar(
        title: _isEditMode ? 'Edit Event' : 'Create Event',
        icon: _isEditMode
            ? Icons.edit_calendar_rounded
            : Icons.add_task_rounded,
      ),
      body: !canCreate
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Only Owner/Manager can create events.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _loadingEvent
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Event Title'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter event title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _lifecycleStatus,
                    decoration: const InputDecoration(
                      labelText: 'Lifecycle Status',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'running',
                        child: Text('Running'),
                      ),
                      DropdownMenuItem(value: 'closed', child: Text('Closed')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _lifecycleStatus = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration Label (optional)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  _DateField(
                    label: 'Event Date',
                    value: _eventDate,
                    onPick: () async {
                      final picked = await _pickDate(_eventDate);
                      if (picked == null) return;
                      setState(() => _eventDate = picked);
                    },
                    onClear: () => setState(() => _eventDate = null),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _locationsController,
                    minLines: 2,
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      labelText: 'Locations (comma separated)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _targetAmountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Target Amount',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _extraChargeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Extra Charge Per Head',
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_saving)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton.icon(
                      onPressed: _saveEvent,
                      icon: const Icon(Icons.save_rounded),
                      label: Text(
                        _isEditMode ? 'Update Event' : 'Create Event',
                      ),
                    ),
                  if (_error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _error,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Future<void> _loadEventForEdit() async {
    setState(() {
      _loadingEvent = true;
      _error = '';
    });

    try {
      final event = await context.read<EventsRepository>().fetchEventById(
        _eventId,
      );
      if (!mounted) return;
      if (event == null) {
        setState(() {
          _error = 'Event not found';
          _loadingEvent = false;
        });
        return;
      }
      _hydrateForm(event);
      setState(() => _loadingEvent = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load event: $e';
        _loadingEvent = false;
      });
    }
  }

  void _hydrateForm(EventCampaign event) {
    final anchorDate =
        event.registrationCloseAt ??
        event.targetDeadline ??
        event.registrationOpenAt ??
        event.eventStartAt ??
        event.eventEndAt;
    _titleController.text = event.title;
    _lockedSlug = event.slug;
    _descriptionController.text = event.description;
    _durationController.text = event.durationLabel;
    _locationsController.text = event.locations.join(', ');
    _targetAmountController.text = event.targetAmount.toStringAsFixed(0);
    _extraChargeController.text = event.extraChargePerHead.toStringAsFixed(0);
    _welcomeTemplateController.text = event.welcomeMessageTemplate;
    _congratsTemplateController.text = event.congratsMessageTemplate;
    _lifecycleStatus = _normalizeLifecycleStatus(event.lifecycleStatus);
    _eventDate = anchorDate;
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final session = context.read<SessionProvider>();
    final actorUid = session.currentUser?.uid ?? '';
    if (actorUid.isEmpty) {
      return;
    }

    final title = _titleController.text.trim();
    final slug = _isEditMode
        ? (_lockedSlug.isEmpty ? _slugify(title) : _lockedSlug)
        : _slugify(title);
    final locations = _parseLocations(_locationsController.text);

    final targetAmount = double.tryParse(_targetAmountController.text.trim());
    final extraCharge = double.tryParse(_extraChargeController.text.trim());

    final draft = EventCampaign(
      id: '',
      title: title,
      slug: slug,
      description: _descriptionController.text.trim(),
      targetAmount: targetAmount ?? 20000,
      targetDeadline: _eventDate,
      qualificationStartAt: _eventDate,
      qualificationEndAt: _eventDate,
      durationLabel: _durationController.text.trim(),
      locations: locations,
      extraChargePerHead: extraCharge ?? 0,
      status: _legacyStatusFromLifecycle(_lifecycleStatus),
      lifecycleStatus: _lifecycleStatus,
      registrationOpenAt: _eventDate,
      registrationCloseAt: _eventDate,
      eventStartAt: _eventDate,
      eventEndAt: _eventDate,
      billingMode: 'order_tag',
      welcomeMessageTemplate: _welcomeTemplateController.text.trim(),
      congratsMessageTemplate: _congratsTemplateController.text.trim(),
    );

    setState(() {
      _saving = true;
      _error = '';
    });
    try {
      final actorName = session.currentUser?.fullName ?? 'Unknown';
      if (_isEditMode) {
        await context.read<EventsRepository>().updateEvent(
          eventId: _eventId,
          draft: draft,
          actorUid: actorUid,
          actorName: actorName,
        );
      } else {
        _eventId = await context.read<EventsRepository>().createEvent(
          draft: draft,
          actorUid: actorUid,
          actorName: actorName,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Event updated successfully'
                : 'Event created successfully',
          ),
        ),
      );
      Navigator.pop(context, _eventId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to save event: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<DateTime?> _pickDate(DateTime? initial) async {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );
  }

  static List<String> _parseLocations(String raw) {
    final parts = raw.split(',');
    final result = <String>[];
    for (final part in parts) {
      final clean = part.trim();
      if (clean.isNotEmpty) {
        result.add(clean);
      }
    }
    return result;
  }

  static String _slugify(String input) {
    final lower = input.toLowerCase();
    final cleaned = lower
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (cleaned.isEmpty) {
      return 'event-${DateTime.now().millisecondsSinceEpoch}';
    }
    return cleaned;
  }

  static String _legacyStatusFromLifecycle(String lifecycle) {
    switch (lifecycle) {
      case 'running':
        return 'active';
      case 'closed':
        return 'closed';
      default:
        return 'active';
    }
  }

  static String _normalizeLifecycleStatus(String lifecycle) {
    switch (lifecycle) {
      case 'closed':
      case 'archived':
        return 'closed';
      case 'running':
      case 'enrollment_open':
      case 'draft':
      default:
        return 'running';
    }
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy');
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.calendar_month_rounded),
                onPressed: onPick,
              ),
              if (value != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onClear,
                ),
            ],
          ),
        ),
        child: Text(
          value == null ? 'Not set' : formatter.format(value!),
          style: TextStyle(
            color: value == null ? Colors.grey.shade600 : Colors.black87,
          ),
        ),
      ),
    );
  }
}
