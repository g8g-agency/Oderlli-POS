class PosConstants {
  static const String counterTableId = '00000000-0000-0000-0000-000000000001';
  static const String counterTableName = 'Counter';

  static bool isCounterTable(String tableId) => tableId == counterTableId;
}
