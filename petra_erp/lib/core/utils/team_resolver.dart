import '../../models/models.dart';

class ResolvedTeam {
  String vendedor;
  String cortador;
  String montador;
  String entregador;

  ResolvedTeam({
    this.vendedor = 'Não atribuído',
    this.cortador = 'Não atribuído',
    this.montador = 'Não atribuído',
    this.entregador = 'Não atribuído',
  });
}

class TeamResolver {
  static ResolvedTeam resolve({
    required List<OrderAssignment> assignments,
    required List<StatusHistory> history,
    required List<Profile> profiles,
  }) {
    final team = ResolvedTeam();

    for (final a in assignments) {
      final name = a.employeeName ?? 'Atribuído';
      if (a.stage == 'corte') {
        team.cortador = name;
      } else if (a.stage == 'montagem') {
        team.montador = name;
      } else if (a.stage == 'entrega') {
        team.entregador = name;
      }
    }

    if (history.isNotEmpty) {
      final sorted =
          List<StatusHistory>.from(history)
            ..sort((a, b) => a.changedAt.compareTo(b.changedAt));
      final firstEntry = sorted.first;
      final creatorProfile = profiles.firstWhere(
        (p) => p.id == firstEntry.changedBy,
        orElse: () => Profile(
          id: '',
          email: '',
          name: '',
          role: '',
          createdAt: DateTime(1970),
        ),
      );
      if (creatorProfile.name.isNotEmpty &&
          creatorProfile.role.toLowerCase() == 'vendedor') {
        team.vendedor = creatorProfile.name;
      } else if (firstEntry.changedByName != null) {
        team.vendedor = firstEntry.changedByName!;
      }
    }

    if (team.vendedor == 'Não atribuído') {
      final sellerProfile = profiles.firstWhere(
        (p) => p.role.toLowerCase() == 'vendedor',
        orElse: () => Profile(
          id: '',
          email: '',
          name: '',
          role: '',
          createdAt: DateTime(1970),
        ),
      );
      if (sellerProfile.name.isNotEmpty) {
        team.vendedor = sellerProfile.name;
      }
    }

    return team;
  }
}
