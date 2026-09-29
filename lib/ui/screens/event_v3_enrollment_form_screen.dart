import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../data/repositories/events_repository.dart';
import '../../models/domain/event_campaign.dart';
import '../../models/domain/event_registration.dart';
import '../../service/sms_service.dart';
import '../../state/session_provider.dart';
import '../widgets/main_app_bar.dart';

class EventV3EnrollmentFormScreen extends StatefulWidget {
  const EventV3EnrollmentFormScreen({super.key});

  @override
  State<EventV3EnrollmentFormScreen> createState() =>
      _EventV3EnrollmentFormScreenState();
}

class _EventV3EnrollmentFormScreenState
    extends State<EventV3EnrollmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _initialized = false;
  bool _loading = true;
  bool _saving = false;

  String _eventId = '';
  String _registrationId = '';
  EventCampaign? _event;
  bool _selfMode = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    final map = args is Map<String, dynamic> ? args : <String, dynamic>{};
    _eventId = map['eventId']?.toString() ?? '';
    _registrationId = map['registrationId']?.toString() ?? '';
    _selfMode = map['selfMode'] != false;

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final repo = context.read<EventsRepository>();
    final session = context.read<SessionProvider>();
    final user = session.currentUser;

    final event = await repo.fetchEventById(_eventId);
    if (!mounted) return;
    if (event == null) {
      setState(() => _loading = false);
      return;
    }

    _event = event;

    if (_registrationId.isNotEmpty) {
      final existing = await repo.fetchRegistrationById(_registrationId);
      if (!mounted) return;
      if (existing != null) {
        _nameController.text = existing.participantName;
        _phoneController.text = existing.participantPhone;
        _addressController.text = existing.participantAddress;
        _selfMode =
            existing.participantUid.isNotEmpty &&
            existing.participantUid == (session.currentUser?.uid ?? '');
      }
    } else {
      _nameController.text = user?.fullName ?? '';
      _phoneController.text = user?.phone ?? '';
      _addressController.text = user?.address ?? '';
    }

    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final canManage = session.role == 'Owner' || session.role == 'Manager';

    return Scaffold(
      appBar: const MainAppBar(
        title: 'Enrollment Form (New)',
        icon: Icons.assignment_rounded,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _event == null
          ? const Center(child: Text('Event not found'))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8F3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Event: ${_event!.title}',
                      style: const TextStyle(
                        color: Color(0xFF1B5E20),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (canManage) ...[
                    const SizedBox(height: 10),
                    SwitchListTile.adaptive(
                      value: _selfMode,
                      onChanged: (value) => setState(() => _selfMode = value),
                      title: Text(
                        _selfMode ? 'Self Enrollment' : 'Enroll On Behalf',
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Participant Name',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone is required';
                      }
                      if (value.trim().length < 10) {
                        return 'Enter valid phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Address is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_saving)
                    const Center(child: CircularProgressIndicator())
                  else if (canManage)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _save(submit: false),
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('Save Draft'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _save(submit: true),
                            icon: const Icon(
                              Icons.check_circle_outline_rounded,
                            ),
                            label: const Text('Submit'),
                          ),
                        ),
                      ],
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () => _save(submit: true),
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Submit Enrollment'),
                    ),
                ],
              ),
            ),
    );
  }

  Future<void> _save({required bool submit}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_event == null) return;

    final session = context.read<SessionProvider>();
    final actorUid = session.currentUser?.uid ?? '';
    if (actorUid.isEmpty) {
      return;
    }
    final actorName = session.currentUser?.fullName ?? 'Unknown';
    final participantUid = _selfMode ? actorUid : '';

    final draft = EventRegistration.empty(eventId: _event!.id).copyWith(
      id: _registrationId,
      participantUid: participantUid,
      participantName: _nameController.text.trim(),
      participantPhone: _phoneController.text.trim(),
      participantAddress: _addressController.text.trim(),
      emergencyPhone: _phoneController.text.trim(),
      roleAtRegistration: _selfMode ? session.role : 'MPO',
      enrollmentStatus: 'enrolled',
      billingStatus: 'open',
    );

    setState(() => _saving = true);
    try {
      final registrationId = await context
          .read<EventsRepository>()
          .upsertRegistration(
            event: _event!,
            draft: draft,
            actorUid: actorUid,
            actorName: actorName,
            submit: submit,
          );
      if (!mounted) return;

      if (submit) {
        await _maybeSendWelcome(
          registrationId: registrationId,
          event: _event!,
          actorUid: actorUid,
          actorName: actorName,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(submit ? 'Enrollment submitted' : 'Draft saved'),
        ),
      );

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.eventEnrollmentDetailsV3,
        arguments: {'eventId': _event!.id, 'registrationId': registrationId},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _maybeSendWelcome({
    required String registrationId,
    required EventCampaign event,
    required String actorUid,
    required String actorName,
  }) async {
    final repo = context.read<EventsRepository>();
    final item = await repo.fetchRegistrationById(registrationId);
    if (!mounted || item == null) return;
    if (item.welcomePromptedAt != null) return;

    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Send Welcome SMS'),
          content: const Text(
            'Enrollment submitted. Welcome message পাঠাতে চান?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
    if (shouldSend != true || !mounted) return;

    final template = event.welcomeMessageTemplate.trim();
    final message = template.isEmpty
        ? 'Welcome ${item.participantName}! ${event.title} enrollment successful.'
        : template
              .replaceAll('{name}', item.participantName)
              .replaceAll('{event}', event.title);

    final launchResult = await SmsService.sendSms(
      number: item.participantPhone,
      message: message,
    );
    if (!mounted) return;

    await repo.logEventMessage(
      eventId: event.id,
      registrationId: item.id,
      participantUid: item.participantUid,
      participantPhone: item.participantPhone,
      messageType: 'welcome',
      messageBody: message,
      launchResult: launchResult,
      triggerSource: 'enrollment',
      actorUid: actorUid,
      actorName: actorName,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Welcome SMS: $launchResult')));
  }
}
