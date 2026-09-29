import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../data/repositories/events_repository.dart';
import '../../models/domain/event_campaign.dart';
import '../../state/session_provider.dart';
import '../widgets/main_app_bar.dart';

class EventV3ListScreen extends StatefulWidget {
  const EventV3ListScreen({super.key});

  @override
  State<EventV3ListScreen> createState() => _EventV3ListScreenState();
}

class _EventV3ListScreenState extends State<EventV3ListScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final role = session.role;
    final canManage = role == 'Owner' || role == 'Manager';

    return Scaffold(
      appBar: const MainAppBar(
        title: 'Events (New)',
        icon: Icons.event_note_rounded,
      ),
      body: StreamBuilder<List<EventCampaign>>(
        stream: context.read<EventsRepository>().watchEventsList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load events: ${snapshot.error}'),
            );
          }

          final all = snapshot.data ?? const <EventCampaign>[];
          final events = _filterByTab(all);

          return Column(
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _tabBar(),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: events.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('No events found yet.'),
                            if (canManage) ...[
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: _openCreateEvent,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Create Event'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 2, 14, 18),
                        itemCount: events.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return _EventCard(
                            event: event,
                            canManage: canManage,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.eventHubV3,
                                arguments: {'eventId': event.id},
                              );
                            },
                            onEdit: canManage
                                ? () => _openEditEvent(event.id)
                                : null,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _openCreateEvent,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Event'),
            )
          : null,
    );
  }

  List<EventCampaign> _filterByTab(List<EventCampaign> all) {
    switch (_tab) {
      case 1:
        return all.where((item) => item.isClosed).toList();
      default:
        return all.where((item) => item.isActive).toList();
    }
  }

  Widget _tabBar() {
    const tabs = ['Active', 'Closed'];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE5EFE8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = _tab == index;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _tab = index),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF2F855A)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF2F4B3F),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Future<void> _openCreateEvent() async {
    final result = await Navigator.pushNamed(context, AppRoutes.eventCreate);
    if (!mounted) return;
    final createdId = result is String ? result : '';
    if (createdId.isNotEmpty) {
      Navigator.pushNamed(
        context,
        AppRoutes.eventHubV3,
        arguments: {'eventId': createdId},
      );
    }
  }

  Future<void> _openEditEvent(String eventId) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.eventCreate,
      arguments: {'eventId': eventId},
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventCampaign event;
  final VoidCallback onTap;
  final bool canManage;
  final VoidCallback? onEdit;

  const _EventCard({
    required this.event,
    required this.onTap,
    required this.canManage,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDCE6DE)),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(Icons.celebration_rounded, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Lifecycle: ${event.lifecycleStatus}',
                    style: const TextStyle(
                      color: Color(0xFF546E5A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (canManage)
              IconButton(
                onPressed: onEdit,
                tooltip: 'Edit Event',
                icon: const Icon(
                  Icons.edit_calendar_outlined,
                  color: Color(0xFF2E7D32),
                ),
              ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF2E7D32)),
          ],
        ),
      ),
    );
  }
}
