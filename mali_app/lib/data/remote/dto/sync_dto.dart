class SyncChangeRequestDto {
  const SyncChangeRequestDto({
    required this.syncId,
    required this.entity,
    required this.operation,
    required this.payload,
  });

  final String syncId;
  final String entity;
  final String operation;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() {
    return {
      'sync_id': syncId,
      'entity': entity,
      'operation': operation,
      'payload': payload,
    };
  }
}

class SyncPushRequestDto {
  const SyncPushRequestDto({
    required this.changes,
  });

  final List<SyncChangeRequestDto> changes;

  Map<String, dynamic> toJson() {
    return {
      'changes': changes.map((change) => change.toJson()).toList(growable: false),
    };
  }
}

class SyncConflictDto {
  const SyncConflictDto({
    required this.syncId,
    required this.entity,
    required this.operation,
    required this.reason,
  });

  factory SyncConflictDto.fromJson(Map<String, dynamic> json) {
    return SyncConflictDto(
      syncId: json['sync_id'] as String? ?? '',
      entity: json['entity'] as String? ?? '',
      operation: json['operation'] as String? ?? '',
      reason: json['reason'] as String? ?? 'Unknown conflict',
    );
  }

  final String syncId;
  final String entity;
  final String operation;
  final String reason;
}

class SyncPushResponseDto {
  const SyncPushResponseDto({
    required this.acceptedIds,
    required this.conflicts,
  });

  factory SyncPushResponseDto.fromJson(Map<String, dynamic> json) {
    final rawAccepted = json['accepted_ids'] as List<dynamic>? ?? const [];
    final rawConflicts = json['conflicts'] as List<dynamic>? ?? const [];

    return SyncPushResponseDto(
      acceptedIds: rawAccepted.map((item) => item as String).toList(growable: false),
      conflicts: rawConflicts
          .map((item) => SyncConflictDto.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final List<String> acceptedIds;
  final List<SyncConflictDto> conflicts;
}
