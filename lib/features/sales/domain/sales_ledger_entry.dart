class SalesLedgerEntry {
  const SalesLedgerEntry({
    required this.id,
    required this.projectName,
    required this.contractor,
    required this.partner,
    required this.elevator,
    required this.startDate,
    required this.endDate,
    required this.category,
    required this.billingDate,
    required this.invoiceDate,
    required this.depositDate,
    required this.supplyAmount,
    required this.installment,
    required this.status,
    required this.note,
  });

  final String id;
  final String projectName;
  final String contractor;
  final String partner;
  final String elevator;
  final DateTime startDate;
  final DateTime? endDate;
  final String category;
  final DateTime? billingDate;
  final DateTime? invoiceDate;
  final DateTime? depositDate;
  final int supplyAmount;
  final int installment;
  final String status;
  final String note;

  factory SalesLedgerEntry.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value, {bool required = false}) {
      final parsed = DateTime.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
      if (required) throw const FormatException('사용 시작일이 올바르지 않습니다.');
      return DateTime.now();
    }

    DateTime? nullableDate(dynamic value) {
      final raw = value?.toString() ?? '';
      return raw.isEmpty ? null : DateTime.tryParse(raw);
    }

    int integer(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
    return SalesLedgerEntry(
      id: json['id']?.toString() ?? '',
      projectName: json['projectName']?.toString() ?? '',
      contractor: json['contractor']?.toString() ?? '',
      partner: json['partner']?.toString() ?? '',
      elevator: json['elevator']?.toString() ?? '',
      startDate: parseDate(json['startDate'], required: true),
      endDate: nullableDate(json['endDate']),
      category: json['category']?.toString() ?? '',
      billingDate: nullableDate(json['billingDate']),
      invoiceDate: nullableDate(json['invoiceDate']),
      depositDate: nullableDate(json['depositDate']),
      supplyAmount: integer(json['supplyAmount']),
      installment: integer(json['installment']),
      status: json['status']?.toString() ?? '신규',
      note: json['note']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toEditableJson() => {
    'category': category,
    'billingDate': billingDate?.toIso8601String().substring(0, 10),
    'invoiceDate': invoiceDate?.toIso8601String().substring(0, 10),
    'depositDate': depositDate?.toIso8601String().substring(0, 10),
    'supplyAmount': supplyAmount,
    'installment': installment,
    'status': status,
    'note': note,
  };

  SalesLedgerEntry copyWith({
    String? category,
    DateTime? billingDate,
    bool clearBillingDate = false,
    DateTime? invoiceDate,
    bool clearInvoiceDate = false,
    DateTime? depositDate,
    bool clearDepositDate = false,
    int? supplyAmount,
    int? installment,
    String? status,
    String? note,
  }) => SalesLedgerEntry(
    id: id,
    projectName: projectName,
    contractor: contractor,
    partner: partner,
    elevator: elevator,
    startDate: startDate,
    endDate: endDate,
    category: category ?? this.category,
    billingDate: clearBillingDate ? null : billingDate ?? this.billingDate,
    invoiceDate: clearInvoiceDate ? null : invoiceDate ?? this.invoiceDate,
    depositDate: clearDepositDate ? null : depositDate ?? this.depositDate,
    supplyAmount: supplyAmount ?? this.supplyAmount,
    installment: installment ?? this.installment,
    status: status ?? this.status,
    note: note ?? this.note,
  );
}

class SalesLedgerSummary {
  const SalesLedgerSummary({
    required this.supplyAmount,
    required this.billCount,
    required this.unbilledCount,
    required this.unissuedInvoiceCount,
    required this.unpaidAmount,
  });

  final int supplyAmount;
  final int billCount;
  final int unbilledCount;
  final int unissuedInvoiceCount;
  final int unpaidAmount;

  factory SalesLedgerSummary.fromJson(Map<String, dynamic> json) {
    int value(String key) => int.tryParse(json[key]?.toString() ?? '') ?? 0;
    return SalesLedgerSummary(
      supplyAmount: value('supplyAmount'),
      billCount: value('billCount'),
      unbilledCount: value('unbilledCount'),
      unissuedInvoiceCount: value('unissuedInvoiceCount'),
      unpaidAmount: value('unpaidAmount'),
    );
  }
}

class SalesStatement {
  const SalesStatement({required this.projectName, required this.items});
  final String projectName;
  final List<SalesLedgerEntry> items;
}
