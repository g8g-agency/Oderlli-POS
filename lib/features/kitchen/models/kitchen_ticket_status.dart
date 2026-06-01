/// KDS ticket-header status — mirrors the backend FSM.
///
/// Backend valid transitions:
///   pending → accepted → preparing → ready → delivered
library;

enum KitchenTicketStatus {
  pending,
  accepted,
  preparing,
  ready,
  delivered,
}

extension KitchenTicketStatusX on KitchenTicketStatus {
  String get label => switch (this) {
        KitchenTicketStatus.pending => 'Pending',
        KitchenTicketStatus.accepted => 'Accepted',
        KitchenTicketStatus.preparing => 'Preparing',
        KitchenTicketStatus.ready => 'Ready',
        KitchenTicketStatus.delivered => 'Delivered',
      };

  bool get isTerminal => this == KitchenTicketStatus.delivered;

  bool get isActive => !isTerminal;
}

KitchenTicketStatus parseKitchenTicketStatus(String raw) {
  return switch (raw.toLowerCase()) {
    'pending' => KitchenTicketStatus.pending,
    'accepted' => KitchenTicketStatus.accepted,
    'preparing' => KitchenTicketStatus.preparing,
    'ready' => KitchenTicketStatus.ready,
    'delivered' => KitchenTicketStatus.delivered,
    _ => KitchenTicketStatus.pending,
  };
}

String serializeKitchenTicketStatus(KitchenTicketStatus status) {
  return switch (status) {
    KitchenTicketStatus.pending => 'pending',
    KitchenTicketStatus.accepted => 'accepted',
    KitchenTicketStatus.preparing => 'preparing',
    KitchenTicketStatus.ready => 'ready',
    KitchenTicketStatus.delivered => 'delivered',
  };
}

/// Valid FSM transitions for bump actions.
const Map<KitchenTicketStatus, KitchenTicketStatus> kNextTicketStatus = {
  KitchenTicketStatus.pending: KitchenTicketStatus.preparing,
  KitchenTicketStatus.accepted: KitchenTicketStatus.preparing,
  KitchenTicketStatus.preparing: KitchenTicketStatus.ready,
  KitchenTicketStatus.ready: KitchenTicketStatus.delivered,
};
