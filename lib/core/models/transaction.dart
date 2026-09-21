enum TransactionType {
  income,
  expense,
  debtReceivable,
  debtPayable;

  String get arabicLabel {
    switch (this) {
      case TransactionType.income:
        return 'استلام';
      case TransactionType.expense:
        return 'مصروف';
      case TransactionType.debtReceivable:
        return 'لي';
      case TransactionType.debtPayable:
        return 'عليّ';
    }
  }

  bool get isDebt =>
      this == TransactionType.debtReceivable ||
      this == TransactionType.debtPayable;
}

enum PaymentMethod {
  cash,
  bankak,
  myCashi,
  bankTransfer,
  card,
  other,
  unknown;

  String get arabicLabel {
    switch (this) {
      case PaymentMethod.cash:
        return 'كاش';
      case PaymentMethod.bankak:
        return 'Bankak';
      case PaymentMethod.myCashi:
        return 'MyCashi';
      case PaymentMethod.bankTransfer:
        return 'تحويل بنكي';
      case PaymentMethod.card:
        return 'بطاقة';
      case PaymentMethod.other:
        return 'أخرى';
      case PaymentMethod.unknown:
        return 'غير محدد';
    }
  }
}

enum TransactionCategory {
  food,
  transport,
  bills,
  shopping,
  health,
  education,
  rent,
  salary,
  transfer,
  business,
  family,
  other;

  String get arabicLabel {
    switch (this) {
      case TransactionCategory.food:
        return 'طعام';
      case TransactionCategory.transport:
        return 'مواصلات';
      case TransactionCategory.bills:
        return 'فواتير';
      case TransactionCategory.shopping:
        return 'تسوق';
      case TransactionCategory.health:
        return 'صحة';
      case TransactionCategory.education:
        return 'تعليم';
      case TransactionCategory.rent:
        return 'إيجار';
      case TransactionCategory.salary:
        return 'راتب';
      case TransactionCategory.transfer:
        return 'تحويل';
      case TransactionCategory.business:
        return 'عمل';
      case TransactionCategory.family:
        return 'عائلة';
      case TransactionCategory.other:
        return 'أخرى';
    }
  }
}

class Transaction {
  final int? id;
  final TransactionType type;
  final int amount;
  final String currency;
  final String? partyName;
  final TransactionCategory? category;
  final PaymentMethod paymentMethod;
  final String? note;
  final String? reference;
  final DateTime transactionDate;
  final DateTime createdAt;
  final String source;
  final String? sourceText;

  const Transaction({
    this.id,
    required this.type,
    required this.amount,
    this.currency = 'SDG',
    this.partyName,
    this.category,
    this.paymentMethod = PaymentMethod.unknown,
    this.note,
    this.reference,
    required this.transactionDate,
    required this.createdAt,
    this.source = 'manual',
    this.sourceText,
  });

  // Debt records do not affect cash balance.
  int get balanceEffect {
    if (type.isDebt) return 0;
    return type == TransactionType.income ? amount : -amount;
  }

  Transaction copyWith({
    int? id,
    TransactionType? type,
    int? amount,
    String? currency,
    String? partyName,
    TransactionCategory? category,
    PaymentMethod? paymentMethod,
    String? note,
    String? reference,
    DateTime? transactionDate,
    DateTime? createdAt,
    String? source,
    String? sourceText,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      partyName: partyName ?? this.partyName,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      reference: reference ?? this.reference,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      source: source ?? this.source,
      sourceText: sourceText ?? this.sourceText,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type.name,
      'amount': amount,
      'currency': currency,
      'party_name': partyName,
      'category': category?.name,
      'payment_method': paymentMethod.name,
      'note': note,
      'reference': reference,
      'transaction_date': transactionDate.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
      'source': source,
      'source_text': sourceText,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      amount: map['amount'] as int,
      currency: map['currency'] as String? ?? 'SDG',
      partyName: map['party_name'] as String?,
      category: map['category'] != null
          ? TransactionCategory.values.firstWhere(
              (e) => e.name == map['category'],
              orElse: () => TransactionCategory.other,
            )
          : null,
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['payment_method'],
        orElse: () => PaymentMethod.unknown,
      ),
      note: map['note'] as String?,
      reference: map['reference'] as String?,
      transactionDate: DateTime.fromMillisecondsSinceEpoch(
        map['transaction_date'] as int,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int,
      ),
      source: map['source'] as String? ?? 'manual',
      sourceText: map['source_text'] as String?,
    );
  }
}
