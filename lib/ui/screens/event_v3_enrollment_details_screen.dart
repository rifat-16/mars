import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../data/repositories/events_repository.dart';
import '../../models/domain/event_campaign.dart';
import '../../models/domain/event_payment.dart';
import '../../models/domain/event_registration.dart';
import '../../service/sms_service.dart';
import '../../state/session_provider.dart';
import '../widgets/main_app_bar.dart';

class EventV3EnrollmentDetailsScreen extends StatefulWidget {
  const EventV3EnrollmentDetailsScreen({super.key});

  @override
  State<EventV3EnrollmentDetailsScreen> createState() =>
      _EventV3EnrollmentDetailsScreenState();
}

class _EventV3EnrollmentDetailsScreenState
    extends State<EventV3EnrollmentDetailsScreen> {
  String _eventId = '';
  String _registrationId = '';
  bool _initialized = false;
  bool _actionLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    final map = args is Map<String, dynamic> ? args : <String, dynamic>{};
    _eventId = map['eventId']?.toString() ?? '';
    _registrationId = map['registrationId']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (_eventId.isEmpty || _registrationId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Enrollment reference missing')),
      );
    }

    final session = context.watch<SessionProvider>();
    final role = session.role;
    final uid = session.currentUser?.uid ?? '';
    final privileged = role == 'Owner' || role == 'Manager';
    final owner = role == 'Owner';

    return Scaffold(
      appBar: const MainAppBar(
        title: 'Enrollment Details (New)',
        icon: Icons.assignment_ind_rounded,
      ),
      body: StreamBuilder<EventCampaign?>(
        stream: context.read<EventsRepository>().watchEventById(_eventId),
        builder: (context, eventSnapshot) {
          if (eventSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final event = eventSnapshot.data;
          if (event == null) {
            return const Center(child: Text('Event not found'));
          }

          return StreamBuilder<EventRegistration?>(
            stream: context.read<EventsRepository>().watchRegistrationById(
              _registrationId,
            ),
            builder: (context, registrationSnapshot) {
              if (registrationSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final item = registrationSnapshot.data;
              if (item == null) {
                return const Center(child: Text('Enrollment not found'));
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _header(event: event, item: item),
                  const SizedBox(height: 12),
                  _section(
                    title: 'Quick Actions',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (privileged)
                          ElevatedButton.icon(
                            onPressed: item.isBillingClosed
                                ? null
                                : () => _issueMedicine(item, event),
                            icon: const Icon(Icons.local_hospital_outlined),
                            label: const Text('Issue Medicine'),
                          ),
                        if (owner)
                          OutlinedButton.icon(
                            onPressed: _actionLoading
                                ? null
                                : () => _addPayment(event, item),
                            icon: const Icon(Icons.payments_outlined),
                            label: const Text('Receive Payment'),
                          ),
                        OutlinedButton.icon(
                          onPressed: _actionLoading
                              ? null
                              : () => _sendReminder(event, item),
                          icon: const Icon(Icons.sms_outlined),
                          label: const Text('Reminder SMS'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _section(
                    title: 'Enrollment',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _line('Name', item.participantName),
                        _line('Phone', item.participantPhone),
                        _line('Address', item.participantAddress),
                        _line('Status', 'Enrolled in this event'),
                        if (item.isEligible) _line('Eligible', 'Yes'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _section(
                    title: 'Finance',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _line(
                          'Medicine Issued',
                          '${item.medicineIssuedAmount.toStringAsFixed(0)} TK',
                        ),
                        _line(
                          'Total Paid',
                          '${item.totalPaidAmount.toStringAsFixed(0)} TK',
                        ),
                        _line('Due', '${item.dueAmount.toStringAsFixed(0)} TK'),
                        const SizedBox(height: 8),
                        const Text(
                          'Payment History',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        StreamBuilder<List<EventPayment>>(
                          stream: context
                              .read<EventsRepository>()
                              .watchPayments(
                                registrationId: item.id,
                                role: role,
                                currentUid: uid,
                              ),
                          builder: (context, paymentSnapshot) {
                            if (paymentSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            if (paymentSnapshot.hasError) {
                              final message = _friendlyFirestoreError(
                                paymentSnapshot.error,
                              );
                              return Text(message);
                            }

                            final payments =
                                paymentSnapshot.data ?? const <EventPayment>[];
                            if (payments.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text('No payments yet.'),
                              );
                            }

                            return Column(
                              children: payments.map((payment) {
                                final dateLabel = payment.collectedAt == null
                                    ? 'No date'
                                    : DateFormat(
                                        'dd MMM, hh:mm a',
                                      ).format(payment.collectedAt!);
                                final subtitle = payment.note.trim().isEmpty
                                    ? '${payment.paymentMethod} • $dateLabel'
                                    : '${payment.paymentMethod} • $dateLabel • ${payment.note}';

                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    '${payment.amount.toStringAsFixed(0)} TK',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(subtitle),
                                  trailing: owner
                                      ? Wrap(
                                          spacing: 0,
                                          children: [
                                            IconButton(
                                              onPressed: _actionLoading
                                                  ? null
                                                  : () => _editPayment(
                                                      event,
                                                      payment,
                                                    ),
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                                size: 20,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: _actionLoading
                                                  ? null
                                                  : () => _deletePayment(
                                                      event,
                                                      payment,
                                                    ),
                                              icon: const Icon(
                                                Icons.delete_outline_rounded,
                                                size: 20,
                                              ),
                                            ),
                                          ],
                                        )
                                      : null,
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _header({
    required EventCampaign event,
    required EventRegistration item,
  }) {
    final completion = _completionRatio(event, item);
    final completionText = (completion * 100).toStringAsFixed(0);
    final targetAmount = event.targetAmount <= 0 ? 0.0 : event.targetAmount;
    final issuedAmount = item.medicineIssuedAmount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.participantName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            event.title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(
                item.isEligible ? 'Eligible' : 'Enrolled',
                item.isEligible ? Colors.green : const Color(0xFF1D4ED8),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$completionText%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: completion,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.28),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${issuedAmount.toStringAsFixed(0)} / ${targetAmount.toStringAsFixed(0)} TK completed',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE6DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  double _completionRatio(EventCampaign event, EventRegistration item) {
    if (event.targetAmount <= 0) {
      return 0;
    }

    final ratio = item.medicineIssuedAmount / event.targetAmount;
    if (ratio < 0) return 0;
    if (ratio > 1) return 1;
    return ratio;
  }

  Future<void> _issueMedicine(
    EventRegistration item,
    EventCampaign event,
  ) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.createOrder,
      arguments: {
        'eventId': event.id,
        'eventRegistrationId': item.id,
        'eventParticipantUid': item.participantUid,
        'customerName': item.participantName,
        'phoneNumber': item.participantPhone,
        'address': item.participantAddress,
        'lockCustomer': true,
      },
    );
  }

  Future<void> _sendReminder(
    EventCampaign event,
    EventRegistration item,
  ) async {
    final actorUid = context.read<SessionProvider>().currentUser?.uid ?? '';
    if (actorUid.isEmpty) return;
    final actorName =
        context.read<SessionProvider>().currentUser?.fullName ?? 'Unknown';

    setState(() => _actionLoading = true);
    try {
      final message =
          '${event.title}\nIssued: ${item.medicineIssuedAmount.toStringAsFixed(0)} TK\nPaid: ${item.totalPaidAmount.toStringAsFixed(0)} TK\nDue: ${item.dueAmount.toStringAsFixed(0)} TK';
      final launchResult = await SmsService.sendSms(
        number: item.participantPhone,
        message: message,
      );
      if (!mounted) return;

      await context.read<EventsRepository>().logEventMessage(
        eventId: event.id,
        registrationId: item.id,
        participantUid: item.participantUid,
        participantPhone: item.participantPhone,
        messageType: 'reminder',
        messageBody: message,
        launchResult: launchResult,
        triggerSource: 'manual',
        actorUid: actorUid,
        actorName: actorName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(launchResult)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Reminder failed: $e')));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _addPayment(EventCampaign event, EventRegistration item) async {
    if (_actionLoading) return;
    if (!_ensureOwner()) return;

    final result = await _paymentDialog();
    if (result == null) return;

    final actorUid = context.read<SessionProvider>().currentUser?.uid ?? '';
    if (actorUid.isEmpty) return;
    final actorName =
        context.read<SessionProvider>().currentUser?.fullName ?? 'Unknown';

    setState(() => _actionLoading = true);
    try {
      await context.read<EventsRepository>().addPayment(
        event: event,
        registrationId: item.id,
        amount: result.amount,
        paymentMethod: result.paymentMethod,
        note: result.note,
        actorUid: actorUid,
        actorName: actorName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment added')));
      await _maybeCongrats(event, item.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Add payment failed: $e')));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _editPayment(EventCampaign event, EventPayment payment) async {
    if (_actionLoading) return;
    if (!_ensureOwner()) return;

    final result = await _paymentDialog(existing: payment);
    if (result == null) return;

    final actorUid = context.read<SessionProvider>().currentUser?.uid ?? '';
    if (actorUid.isEmpty) return;
    final actorName =
        context.read<SessionProvider>().currentUser?.fullName ?? 'Unknown';

    setState(() => _actionLoading = true);
    try {
      await context.read<EventsRepository>().updatePayment(
        event: event,
        paymentId: payment.id,
        amount: result.amount,
        paymentMethod: result.paymentMethod,
        note: result.note,
        actorUid: actorUid,
        actorName: actorName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment updated')));
      await _maybeCongrats(event, payment.registrationId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update payment failed: $e')));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _deletePayment(EventCampaign event, EventPayment payment) async {
    if (_actionLoading) return;
    if (!_ensureOwner()) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Payment'),
          content: Text(
            'Delete ${payment.amount.toStringAsFixed(0)} TK payment?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;

    final actorUid = context.read<SessionProvider>().currentUser?.uid ?? '';
    if (actorUid.isEmpty) return;
    final actorName =
        context.read<SessionProvider>().currentUser?.fullName ?? 'Unknown';

    setState(() => _actionLoading = true);
    try {
      await context.read<EventsRepository>().deletePayment(
        event: event,
        paymentId: payment.id,
        actorUid: actorUid,
        actorName: actorName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment deleted')));
      await _maybeCongrats(event, payment.registrationId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete payment failed: $e')));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _maybeCongrats(
    EventCampaign event,
    String registrationId,
  ) async {
    final repo = context.read<EventsRepository>();
    final updated = await repo.fetchRegistrationById(registrationId);
    if (!mounted || updated == null) return;

    if (!updated.isEligible || updated.congratsPromptedAt != null) return;

    final send = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Send Congrats'),
          content: const Text(
            'Participant is eligible now. Send congratulations SMS?',
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
    if (send != true || !mounted) return;

    final messageTemplate = event.congratsMessageTemplate.trim();
    final message = messageTemplate.isEmpty
        ? 'Congratulations ${updated.participantName}! You are now eligible for ${event.title}.'
        : messageTemplate
              .replaceAll('{name}', updated.participantName)
              .replaceAll('{event}', event.title);

    final launchResult = await SmsService.sendSms(
      number: updated.participantPhone,
      message: message,
    );
    if (!mounted) return;

    final actorUid = context.read<SessionProvider>().currentUser?.uid ?? '';
    if (actorUid.isEmpty) return;
    final actorName =
        context.read<SessionProvider>().currentUser?.fullName ?? 'Unknown';

    await repo.logEventMessage(
      eventId: event.id,
      registrationId: updated.id,
      participantUid: updated.participantUid,
      participantPhone: updated.participantPhone,
      messageType: 'congrats',
      messageBody: message,
      launchResult: launchResult,
      triggerSource: 'eligibility',
      actorUid: actorUid,
      actorName: actorName,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Congrats SMS: $launchResult')));
  }

  Future<_PaymentInput?> _paymentDialog({EventPayment? existing}) async {
    final amountController = TextEditingController(
      text: existing == null ? '' : existing.amount.toStringAsFixed(2),
    );
    final noteController = TextEditingController(text: existing?.note ?? '');
    var method = existing?.paymentMethod ?? 'cash';

    return showDialog<_PaymentInput>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add Payment' : 'Edit Payment'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: method,
                    decoration: const InputDecoration(labelText: 'Method'),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'bKash', child: Text('bKash')),
                      DropdownMenuItem(value: 'nagad', child: Text('Nagad')),
                      DropdownMenuItem(value: 'bank', child: Text('Bank')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => method = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(
                      amountController.text.trim(),
                    );
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter valid amount')),
                      );
                      return;
                    }
                    Navigator.pop(
                      context,
                      _PaymentInput(
                        amount: amount,
                        paymentMethod: method,
                        note: noteController.text.trim(),
                      ),
                    );
                  },
                  child: Text(existing == null ? 'Add' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _friendlyFirestoreError(Object? error) {
    if (error is FirebaseException &&
        error.code == 'failed-precondition' &&
        (error.message ?? '').toLowerCase().contains('index')) {
      return 'Payment history index এখন build হচ্ছে. ২-৫ মিনিট পরে আবার দেখুন।';
    }
    return 'Payment load failed: $error';
  }

  bool _ensureOwner() {
    final role = context.read<SessionProvider>().role;
    if (role == 'Owner') {
      return true;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Only Owner can add/edit/delete event payments.'),
      ),
    );
    return false;
  }
}

class _PaymentInput {
  final double amount;
  final String paymentMethod;
  final String note;

  const _PaymentInput({
    required this.amount,
    required this.paymentMethod,
    required this.note,
  });
}
