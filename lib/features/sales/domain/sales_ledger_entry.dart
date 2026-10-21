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
    this.invoiceIssuer = '협력사',
    this.adjustmentAmount = 0,
    this.adjustmentReason = '',
    this.month,
    this.contractStartDate,
    this.contractEndDate,
    this.recordDate,
  });

  final String id;
  final String projectName;
  final String contractor;
  final String partner;
  final String elevator;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? month;
  final DateTime? contractStartDate;
  final DateTime? contractEndDate;
  /// First date on which the PDAM work record exists for this site/equipment.
  final DateTime? recordDate;
  final String category;
  final DateTime? billingDate;
  final DateTime? invoiceDate;
  final DateTime? depositDate;
  final int supplyAmount;
  final int installment;
  final String status;
  final String note;
  final String invoiceIssuer;

  String get invoiceIssuerType {
    String normalize(String value) => value.replaceAll(RegExp(r'\s+'), '');
    final issuer = normalize(invoiceIssuer);
    if (issuer.isEmpty) return '협력사';
    if (issuer == '시공사') return '시공사';
    if (issuer == '협력사') return '협력사';
    if (normalize(contractor).isNotEmpty && issuer == normalize(contractor)) {
      return '시공사';
    }
    if (normalize(partner).isNotEmpty && issuer == normalize(partner)) {
      return '협력사';
    }
    return '';
  }

  final int adjustmentAmount;
  final String adjustmentReason;

  factory SalesLedgerEntry.fromJson(Map<String, dynamic> json) {
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
      elevator:
          json['machineNumber']?.toString() ??
          json['elevator']?.toString() ??
          '',
      startDate: nullableDate(json['startDate']),
      endDate: nullableDate(json['endDate']),
      month: json['month']?.toString(),
      contractStartDate: nullableDate(json['contractStartDate']),
      contractEndDate: nullableDate(json['contractEndDate']),
      recordDate: nullableDate(
        json['recordDate'] ??
            json['firstRecordDate'] ??
            json['recordedAt'] ??
            json['workRecordDate'],
      ),
      category: (() {
        final value = json['category']?.toString() ?? '';
        // 종료 상태로 바뀌어도 기존에 저장된 분류(본사/가맹)를 유지한다.
        return value;
      })(),
      billingDate: nullableDate(json['billingDate']),
      invoiceDate: nullableDate(json['invoiceDate']),
      depositDate: nullableDate(json['depositDate']),
      supplyAmount: integer(json['supplyAmount']),
      installment: integer(json['installment']),
      status: json['status']?.toString() ?? '신규',
      note: json['note']?.toString() ?? '',
      invoiceIssuer:
          (json['invoiceIssuer']?.toString().trim().isNotEmpty ?? false)
          ? json['invoiceIssuer'].toString().trim()
          : '협력사',
      adjustmentAmount: integer(json['adjustmentAmount'] ?? json['adjustment']),
      adjustmentReason: json['adjustmentReason']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toEditableJson() => {
    if (month?.isNotEmpty ?? false) 'month': month,
    'startDate': startDate?.toIso8601String().substring(0, 10),
    'endDate': endDate?.toIso8601String().substring(0, 10),
    'category': category,
    'billingDate': billingDate?.toIso8601String().substring(0, 10),
    'invoiceDate': invoiceDate?.toIso8601String().substring(0, 10),
    'depositDate': depositDate?.toIso8601String().substring(0, 10),
    'supplyAmount': supplyAmount,
    'installment': installment,
    'status': status,
    'note': note,
    'invoiceIssuer': invoiceIssuer.trim().isEmpty ? '협력사' : invoiceIssuer,
    'adjustmentAmount': adjustmentAmount,
    'adjustmentReason': adjustmentReason,
  };

  SalesLedgerEntry copyWith({
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
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
    String? invoiceIssuer,
    int? adjustmentAmount,
    String? adjustmentReason,
  }) => SalesLedgerEntry(
    id: id,
    projectName: projectName,
    contractor: contractor,
    partner: partner,
    elevator: elevator,
    startDate: clearStartDate ? null : startDate ?? this.startDate,
    endDate: clearEndDate ? null : endDate ?? this.endDate,
    month: month,
    contractStartDate: contractStartDate,
    contractEndDate: contractEndDate,
    recordDate: recordDate,
    category: category ?? this.category,
    billingDate: clearBillingDate ? null : billingDate ?? this.billingDate,
    invoiceDate: clearInvoiceDate ? null : invoiceDate ?? this.invoiceDate,
    depositDate: clearDepositDate ? null : depositDate ?? this.depositDate,
    supplyAmount: supplyAmount ?? this.supplyAmount,
    installment: installment ?? this.installment,
    status: status ?? this.status,
    note: note ?? this.note,
    invoiceIssuer: invoiceIssuer ?? this.invoiceIssuer,
    adjustmentAmount: adjustmentAmount ?? this.adjustmentAmount,
    adjustmentReason: adjustmentReason ?? this.adjustmentReason,
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

  factory SalesLedgerSummary.fromEntries(Iterable<SalesLedgerEntry> entries) {
    var supplyAmount = 0;
    var billCount = 0;
    var unbilledCount = 0;
    var unissuedInvoiceCount = 0;
    var unpaidAmount = 0;
    for (final entry in entries) {
      supplyAmount += entry.supplyAmount;
      if (entry.billingDate == null) {
        unbilledCount++;
      } else {
        billCount++;
        if (entry.invoiceDate == null) unissuedInvoiceCount++;
        if (entry.depositDate == null) unpaidAmount += entry.supplyAmount;
      }
    }
    return SalesLedgerSummary(
      supplyAmount: supplyAmount,
      billCount: billCount,
      unbilledCount: unbilledCount,
      unissuedInvoiceCount: unissuedInvoiceCount,
      unpaidAmount: unpaidAmount,
    );
  }

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
