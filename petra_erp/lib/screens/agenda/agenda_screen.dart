import 'package:flutter/material.dart';
import '../../core/utils/error_messages.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/constants/os_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';
import '../../providers/os_provider.dart';
import '../../widgets/widgets.dart';

/// Agenda/calendário das OS com data de entrega prevista (scheduledDate).
class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({super.key});

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _format = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  /// Indexa as OS agendadas por dia (ignora horário).
  Map<DateTime, List<ServiceOrder>> _buildEvents(List<ServiceOrder> orders) {
    final map = <DateTime, List<ServiceOrder>>{};
    for (final o in orders) {
      final d = o.scheduledDate;
      if (d == null) continue;
      final key = DateTime.utc(d.year, d.month, d.day);
      map.putIfAbsent(key, () => []).add(o);
    }
    return map;
  }

  List<ServiceOrder> _eventsForDay(Map<DateTime, List<ServiceOrder>> events, DateTime day) {
    return events[DateTime.utc(day.year, day.month, day.day)] ?? const [];
  }

  bool _isOverdue(ServiceOrder o) {
    if (o.status == OSStatus.entrega || o.scheduledDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = o.scheduledDate!;
    return DateTime(d.year, d.month, d.day).isBefore(today);
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(osProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda de Entregas'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.invalidate(osProvider),
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(friendlyError(err))),
        data: (orders) {
          final events = _buildEvents(orders);
          final selected = _selectedDay ?? _focusedDay;
          final dayOrders = _eventsForDay(events, selected)
            ..sort((a, b) => a.displayNumber.compareTo(b.displayNumber));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: TableCalendar<ServiceOrder>(
                    locale: 'pt_BR',
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _format,
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Mês',
                      CalendarFormat.twoWeeks: '2 semanas',
                      CalendarFormat.week: 'Semana',
                    },
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: (day) => _eventsForDay(events, day),
                    startingDayOfWeek: StartingDayOfWeek.sunday,
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) => setState(() => _format = format),
                    onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                    headerStyle: HeaderStyle(
                      formatButtonDecoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      formatButtonTextStyle: AppTheme.jakarta(
                        fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent),
                      titleTextStyle: AppTheme.syne(fontSize: 15, fontWeight: FontWeight.w800),
                      leftChevronIcon: const Icon(LucideIcons.chevronLeft, size: 18),
                      rightChevronIcon: const Icon(LucideIcons.chevronRight, size: 18),
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      todayTextStyle: AppTheme.jakarta(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                      selectedDecoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      markerDecoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 3,
                    ),
                    calendarBuilders: CalendarBuilders<ServiceOrder>(
                      markerBuilder: (context, day, dayEvents) {
                        if (dayEvents.isEmpty) return null;
                        final hasOverdue = dayEvents.any(_isOverdue);
                        return Positioned(
                          bottom: 4,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: hasOverdue ? AppColors.staleCrit : AppColors.info,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Título do dia selecionado
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(children: [
                    const Icon(LucideIcons.calendarDays, size: 16, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Text(
                      'Entregas de ${AppDateUtils.formatDate(selected)}',
                      style: AppTheme.syne(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    Text('${dayOrders.length} OS',
                        style: AppTheme.jakarta(fontSize: 12, color: AppColors.textMuted)),
                  ]),
                ),
                const SizedBox(height: 8),

                if (dayOrders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: EmptyState(
                      title: 'Nenhuma entrega neste dia',
                      message: 'Selecione outro dia ou agende uma OS.',
                      icon: LucideIcons.calendarX,
                    ),
                  )
                else
                  ...dayOrders.map((o) => _AgendaTile(order: o, overdue: _isOverdue(o))),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AgendaTile extends StatelessWidget {
  final ServiceOrder order;
  final bool overdue;
  const _AgendaTile({required this.order, required this.overdue});

  @override
  Widget build(BuildContext context) {
    final (:color, :bg) = AppColors.statusColors(order.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: overdue ? AppColors.staleCrit.withValues(alpha: 0.5) : AppColors.border),
      ),
      child: ListTile(
        onTap: () => context.push('/orders/${order.id}'),
        leading: Container(
          width: 8,
          decoration: BoxDecoration(
            color: overdue ? AppColors.staleCrit : color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Row(children: [
          Text(order.formattedNumber,
              style: AppTheme.numeric(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(order.customerName ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.jakarta(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ]),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(children: [
            StatusBadge(status: order.status),
            if (overdue) ...[
              const SizedBox(width: 8),
              Text('Vencida',
                  style: AppTheme.jakarta(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.staleCrit)),
            ],
          ]),
        ),
        trailing: Text(Formatters.formatCurrency(order.totalValue),
            style: AppTheme.numeric(fontSize: 12.5, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
