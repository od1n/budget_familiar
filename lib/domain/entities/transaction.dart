import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required String groupId,
    required String userId,
    String? categoryId,
    required double amount,
    required String currencyCode,
    double? amountUsdEquivalent,
    String? exchangeRateId,
    required TransactionType type,
    required DateTime date,
    String? description,
    String? paymentMethod,
    String? notes,
    @Default(false) bool isSynced,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}

enum TransactionType {
  income,
  expense;

  String get label => switch (this) {
        income => 'Ingreso',
        expense => 'Gasto',
      };

  bool get isIncome => this == TransactionType.income;
  bool get isExpense => this == TransactionType.expense;
}

enum PaymentMethod {
  cash,
  card,
  transfer,
  pagomovil,
  zelle,
  crypto,
  other;

  String get label => switch (this) {
        cash => 'Efectivo',
        card => 'Tarjeta',
        transfer => 'Transferencia',
        pagomovil => 'Pago Móvil',
        zelle => 'Zelle',
        crypto => 'Cripto',
        other => 'Otro',
      };
}
