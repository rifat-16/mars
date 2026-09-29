import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../data/repositories/events_repository.dart';
import '../../models/domain/event_campaign.dart';
import '../../models/domain/event_registration.dart';
import '../../state/session_provider.dart';
import '../widgets/main_app_bar.dart';

class EventV3HubScreen extends StatefulWidget {
  const EventV3HubScreen({super.key});

  @override
  State<EventV3HubScreen> createState() => _EventV3HubScreenState();
}

class _EventV3HubScreenState extends State<EventV3HubScreen> {
  bool _initialized = false;
  String _eventId = '';
  String _search = '';
  String _statusFilter = 'all';
  bool _queueActionLoading = false;
  Stream<EventCampaign?>? _eventStream;
  Stream<List<EventRegistration>>? _registrationsStream;
  String _streamRole = '';
  String _streamUid = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    final map = args is Map<String, dynamic> ? args : <String, dynamic>{};
    _eventId = map['eventId']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (_eventId.isEmpty) {
      return const Scaffold(body: Center(child: Text('Event id missing')));
    }

    final session = context.watch<SessionProvider>();
    final role = session.role;
    final uid = session.currentUser?.uid ?? '';
    final privileged = role == 'Owner' || role == 'Manager';
    _ensureStreams(role: role, uid: uid);

    return Scaffold(
      appBar: const MainAppBar(title: 'Event Hub (New)', icon: Icons.hub),
      body: StreamBuilder<EventCampaign?>(
        stream: _eventStream,
        builder: (context, eventSnapshot) {
          if (eventSnapshot.connectionState == ConnectionState.waiting &&
              !eventSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final event = eventSnapshot.data;
          if (event == null) {
            return const Center(child: Text('Event not found'));
          }

          return StreamBuilder<List<EventRegistration>>(
            stream: _registrationsStream,
            builder: (context, registrationSnapshot) {
              if (registrationSnapshot.connectionState ==
                      ConnectionState.waiting &&
                  !registrationSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (registrationSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Failed to load enrollments: ${registrationSnapshot.error}',
                  ),
                );
              }

              final registrations =
                  registrationSnapshot.data ?? const <EventRegistration>[];
              final filtered = _filterRegistrations(registrations);
              final closeQueue = registrations
                  .where((item) => item.billingStatus == 'close_requested')
                  .toList();

              final eligibleCount = registrations
                  .where((item) => item.isEligible)
                  .length;
              var totalDue = 0.0;
              var totalCollection = 0.0;
              var totalIssued = 0.0;
              for (final item in registrations) {
                totalDue += item.dueAmount;
                totalCollection += item.totalPaidAmount;
                totalIssued += item.medicineIssuedAmount;
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _header(
                    event: event,
                    canManage: privileged,
                    onEdit: privileged ? () => _editEvent(event.id) : null,
                  ),
                  const SizedBox(height: 12),
                  _kpis(
                    enrollmentCount: registrations.length,
                    eligibleCount: eligibleCount,
                    totalDue: totalDue,
                    totalCollection: totalCollection,
                    totalIssued: totalIssued,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.eventEnrollmentFormV3,
                        arguments: {'eventId': event.id},
                      );
                    },
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('New Enrollment'),
                  ),
                  const SizedBox(height: 12),
                  _filtersCard(),
                  if (privileged && closeQueue.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _closeQueueCard(event, closeQueue),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    'Participants',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: const Color(0xFF1A3A2A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text('No enrollments found for current filter'),
                      ),
                    )
                  else
                    ...filtered.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ParticipantCard(
                          item: item,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.eventEnrollmentDetailsV3,
                              arguments: {
                                'eventId': event.id,
                                'registrationId': item.id,
                              },
                            );
                          },
                        ),
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

  void _ensureStreams({required String role, required String uid}) {
    final repository = context.read<EventsRepository>();
    _eventStream ??= repository.watchEventById(_eventId);
    if (_registrationsStream == null ||
        _streamRole != role ||
        _streamUid != uid) {
      _streamRole = role;
      _streamUid = uid;
      _registrationsStream = repository.watchRegistrations(
        eventId: _eventId,
        role: role,
        currentUid: uid,
      );
    }
  }

  List<EventRegistration> _filterRegistrations(
    List<EventRegistration> registrations,
  ) {
    final query = _search.trim().toLowerCase();
    return registrations.where((item) {
      if (query.isNotEmpty) {
        final inName = item.participantName.toLowerCase().contains(query);
        final inPhone = item.participantPhone.toLowerCase().contains(query);
        if (!inName && !inPhone) return false;
      }
      if (_statusFilter == 'enrolled' &&
          (item.enrollmentStatus != 'enrolled' || item.isEligible)) {
        return false;
      }
      if (_statusFilter == 'eligible' && !item.isEligible) {
        return false;
      }
      return true;
    }).toList();
  }

  Widget _filtersCard() {
    const statusOptions = <MapEntry<String, String>>[
      MapEntry('all', 'All'),
      MapEntry('enrolled', 'Enrolled'),
      MapEntry('eligible', 'Eligible'),
    ];

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
          TextField(
            onChanged: (value) => setState(() => _search = value),
            decoration: const InputDecoration(
              labelText: 'Search by name / phone',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 10),
          _filterDropdown(
            label: 'Status',
            value: _statusFilter,
            options: statusOptions,
            onChanged: (value) => setState(() => _statusFilter = value),
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown({
    required String label,
    required String value,
    required List<MapEntry<String, String>> options,
    required ValueChanged<String> onChanged,
  }) {
    const textStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: Color(0xFF2F855A),
    );

    return DropdownButtonFormField<String>(
      isExpanded: true,
      isDense: true,
      style: textStyle,
      value: value,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ).copyWith(labelText: label),
      selectedItemBuilder: (context) {
        return options
            .map(
              (entry) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  entry.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
            )
            .toList();
      },
      items: options
          .map(
            (entry) => DropdownMenuItem(
              value: entry.key,
              child: Text(
                entry.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (next) {
        if (next == null) return;
        onChanged(next);
      },
    );
  }

  Widget _header({
    required EventCampaign event,
    required bool canManage,
    required VoidCallback? onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A9D8F), Color(0xFF3DA35D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (canManage)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  tooltip: 'Edit Event',
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Lifecycle: ${event.lifecycleStatus}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (event.description.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              event.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kpis({
    required int enrollmentCount,
    required int eligibleCount,
    required double totalDue,
    required double totalCollection,
    required double totalIssued,
  }) {
    final cards = <MapEntry<String, String>>[
      MapEntry('Enrollments', enrollmentCount.toString()),
      MapEntry('Eligible', eligibleCount.toString()),
      MapEntry('Issued', '${totalIssued.toStringAsFixed(0)} TK'),
      MapEntry('Collected', '${totalCollection.toStringAsFixed(0)} TK'),
      MapEntry('Total Due', '${totalDue.toStringAsFixed(0)} TK'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        const columns = 2;
        final width = (constraints.maxWidth - spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map(
                (card) => SizedBox(
                  width: width,
                  child: _kpiCard(title: card.key, value: card.value),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _kpiCard({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD6E7D8)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B5E20),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF4A6350),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _closeQueueCard(
    EventCampaign event,
    List<EventRegistration> closeQueue,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF4D9A6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Close Request Queue (${closeQueue.length})',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF7A4D00),
            ),
          ),
          const SizedBox(height: 8),
          ...closeQueue.take(6).map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF0E4C9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.participantName} (${item.participantPhone})',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Due: ${item.dueAmount.toStringAsFixed(0)} TK',
                      style: const TextStyle(
                        color: Color(0xFF5B4630),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _queueActionLoading
                                ? null
                                : () => _approveClose(event, item),
                            icon: const Icon(Icons.lock_open_rounded),
                            label: const Text('Approve'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _queueActionLoading
                                ? null
                                : () => _rejectClose(item),
                            icon: const Icon(Icons.undo_rounded),
                            label: const Text('Reject'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          if (closeQueue.length > 6)
            Text(
              '+${closeQueue.length - 6} more close requests',
              style: const TextStyle(
                color: Color(0xFF7A4D00),
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _editEvent(String eventId) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.eventCreate,
      arguments: {'eventId': eventId},
    );
  }

  Future<void> _approveClose(
    EventCampaign event,
    EventRegistration item,
  ) async {
    final note = await _noteDialog(
      title: 'Approve Close Request',
      hint: 'Optional note',
      actionLabel: 'Approve',
      requiredField: false,
    );
    if (note == null) return;

    final session = context.read<SessionProvider>();
    final actorUid = session.currentUser?.uid ?? '';
    if (actorUid.isEmpty) return;
    final actorName = session.currentUser?.fullName ?? 'Unknown';

    setState(() => _queueActionLoading = true);
    try {
      await context.read<EventsRepository>().approveBillingClose(
        registrationId: item.id,
        actorUid: actorUid,
        actorName: actorName,
        note: note,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Billing closed')));

      await context.read<EventsRepository>().recomputeFinanceSnapshot(
        registrationId: item.id,
        event: event,
        actorUid: actorUid,
        actorName: actorName,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Approve close failed: $e')));
    } finally {
      if (mounted) setState(() => _queueActionLoading = false);
    }
  }

  Future<void> _rejectClose(EventRegistration item) async {
    final note = await _noteDialog(
      title: 'Reject Close Request',
      hint: 'Reason',
      actionLabel: 'Reject',
      requiredField: true,
    );
    if (note == null || note.isEmpty) return;

    final session = context.read<SessionProvider>();
    final actorUid = session.currentUser?.uid ?? '';
    if (actorUid.isEmpty) return;
    final actorName = session.currentUser?.fullName ?? 'Unknown';

    setState(() => _queueActionLoading = true);
    try {
      await context.read<EventsRepository>().rejectBillingClose(
        registrationId: item.id,
        actorUid: actorUid,
        actorName: actorName,
        note: note,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Close request rejected')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Reject close failed: $e')));
    } finally {
      if (mounted) setState(() => _queueActionLoading = false);
    }
  }

  Future<String?> _noteDialog({
    required String title,
    required String hint,
    required String actionLabel,
    required bool requiredField,
  }) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: hint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );

    if (value == null) return null;
    final trimmed = value.trim();
    if (requiredField && trimmed.isEmpty) {
      if (!mounted) return null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Note is required')));
      return null;
    }
    return trimmed;
  }
}

class _ParticipantCard extends StatelessWidget {
  final EventRegistration item;
  final VoidCallback onTap;

  const _ParticipantCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDCE6DE)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFE8F5E9),
              child: Text(
                item.participantName.isEmpty
                    ? '-'
                    : item.participantName[0].toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.participantName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.participantPhone,
                    style: const TextStyle(
                      color: Color(0xFF546E5A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _pill(
                        item.isEligible ? 'Eligible' : 'Enrolled',
                        item.isEligible
                            ? Colors.green
                            : const Color(0xFF1565C0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              'Due ${item.dueAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Color(0xFFB45309),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF2E7D32)),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
