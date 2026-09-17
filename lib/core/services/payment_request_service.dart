import 'supabase_service.dart';

/// Un reporte de pago por Pago Móvil enviado por el usuario.
class PaymentRequest {
  const PaymentRequest({
    required this.id,
    required this.planName,
    required this.billing,
    required this.reference,
    required this.status,
    required this.createdAt,
    this.amountUsd,
    this.amountVes,
    this.note,
  });

  final String id;
  final String planName; // 'family' | 'premium'
  final String billing; // 'monthly' | 'annual'
  final String reference;
  final String status; // 'pending' | 'approved' | 'rejected'
  final DateTime createdAt;
  final double? amountUsd;
  final double? amountVes;
  final String? note;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory PaymentRequest.fromMap(Map<String, dynamic> m) => PaymentRequest(
        id: m['id'] as String,
        planName: m['plan_name'] as String? ?? 'family',
        billing: m['billing'] as String? ?? 'monthly',
        reference: m['reference'] as String? ?? '',
        status: m['status'] as String? ?? 'pending',
        createdAt:
            DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
        amountUsd: (m['amount_usd'] as num?)?.toDouble(),
        amountVes: (m['amount_ves'] as num?)?.toDouble(),
        note: m['note'] as String?,
      );
}

/// Envía y consulta reportes de pago por Pago Móvil.
///
/// El envío usa la función `submit_payment_request` (SECURITY DEFINER), que fija
/// el usuario y el estado 'pending' de forma segura. La lectura pasa por RLS, que
/// solo devuelve los reportes del propio usuario.
class PaymentRequestService {
  PaymentRequestService._();
  static final PaymentRequestService instance = PaymentRequestService._();

  /// Envía un reporte de pago. Devuelve el id del reporte creado.
  Future<String> submit({
    required String planName,
    required String billing,
    required double amountUsd,
    double? amountVes,
    required String reference,
    String? payerName,
    String? payerPhone,
  }) async {
    final res = await supabase.rpc('submit_payment_request', params: {
      'p_plan_name': planName,
      'p_billing': billing,
      'p_amount_usd': amountUsd,
      'p_amount_ves': amountVes,
      'p_reference': reference,
      'p_payer_name': payerName,
      'p_payer_phone': payerPhone,
    });
    return res.toString();
  }

  /// Últimos reportes del usuario (los más recientes primero).
  Future<List<PaymentRequest>> myRequests({int limit = 5}) async {
    final rows = await supabase
        .from('payment_requests')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((e) => PaymentRequest.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// El reporte más reciente, o null si no hay ninguno.
  Future<PaymentRequest?> latest() async {
    final list = await myRequests(limit: 1);
    return list.isEmpty ? null : list.first;
  }
}
