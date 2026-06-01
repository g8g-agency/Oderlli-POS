/// KDS item-level preparation status — mirrors backend FSM.
library;

enum KitchenItemStatus {
  pending,
  preparing,
  ready,
  completed,
  cancelled,
}

extension KitchenItemStatusX on KitchenItemStatus {
  String get label => switch (this) {
        KitchenItemStatus.pending => 'Pending',
        KitchenItemStatus.preparing => 'Preparing',
        KitchenItemStatus.ready => 'Ready',
        KitchenItemStatus.completed => 'Completed',
        KitchenItemStatus.cancelled => 'Cancelled',
      };

  bool get isTerminal =>
      this == KitchenItemStatus.completed || this == KitchenItemStatus.cancelled;
}

KitchenItemStatus parseKitchenItemStatus(String raw) {
  return switch (raw.toLowerCase()) {
    'pending' => KitchenItemStatus.pending,
    'preparing' => KitchenItemStatus.preparing,
    'ready' => KitchenItemStatus.ready,
    'completed' || 'done' => KitchenItemStatus.completed,
    'cancelled' || 'canceled' => KitchenItemStatus.cancelled,
    _ => KitchenItemStatus.pending,
  };
}

String serializeKitchenItemStatus(KitchenItemStatus status) {
  return switch (status) {
    KitchenItemStatus.pending => 'pending',
    KitchenItemStatus.preparing => 'preparing',
    KitchenItemStatus.ready => 'ready',
    KitchenItemStatus.completed => 'completed',
    KitchenItemStatus.cancelled => 'cancelled',
  };
}
