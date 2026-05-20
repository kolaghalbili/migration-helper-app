class Transaction {
  final int id;
  final int payer;
  final String payerName;
  final int? payee;
  final String? payeeName;
  final double amount;
  final double platformFee;
  final double netAmount;
  final String type; // booking / tip / pool
  final String status; // held / released / paid / failed / refunded
  final int? helpRequest;
  final String note;
  final String createdAt;

  Transaction({
    required this.id,
    required this.payer,
    required this.payerName,
    this.payee,
    this.payeeName,
    required this.amount,
    required this.platformFee,
    required this.netAmount,
    required this.type,
    required this.status,
    this.helpRequest,
    required this.note,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> j) => Transaction(
        id: j['id'] ?? 0,
        payer: j['payer'] ?? 0,
        payerName: j['payer_name'] ?? '',
        payee: j['payee'],
        payeeName: j['payee_name'],
        amount: double.tryParse(j['amount'].toString()) ?? 0,
        platformFee: double.tryParse(j['platform_fee'].toString()) ?? 0,
        netAmount: double.tryParse(j['net_amount'].toString()) ?? 0,
        type: j['type'] ?? '',
        status: j['status'] ?? '',
        helpRequest: j['help_request'],
        note: j['note'] ?? '',
        createdAt: j['created_at'] ?? '',
      );
}

class MonthlyEarning {
  final int year;
  final int month;
  final double totalGross;
  final double totalNet;
  final double totalTips;
  final int sessionCount;

  MonthlyEarning({
    required this.year,
    required this.month,
    required this.totalGross,
    required this.totalNet,
    required this.totalTips,
    required this.sessionCount,
  });

  factory MonthlyEarning.fromJson(Map<String, dynamic> j) => MonthlyEarning(
        year: j['year'] ?? 0,
        month: j['month'] ?? 0,
        totalGross: double.tryParse(j['total_gross'].toString()) ?? 0,
        totalNet: double.tryParse(j['total_net'].toString()) ?? 0,
        totalTips: double.tryParse(j['total_tips'].toString()) ?? 0,
        sessionCount: j['session_count'] ?? 0,
      );

  String get monthName {
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[month];
  }
}

class CommunityPool {
  final double balance;
  final double totalDonated;

  CommunityPool({required this.balance, required this.totalDonated});

  factory CommunityPool.fromJson(Map<String, dynamic> j) => CommunityPool(
        balance: double.tryParse(j['balance'].toString()) ?? 0,
        totalDonated: double.tryParse(j['total_donated'].toString()) ?? 0,
      );
}