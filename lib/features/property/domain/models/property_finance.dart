import '../enums/data_provenance.dart';
import '../value_objects/money_amount.dart';

class WhatsSpecialContent {
  const WhatsSpecialContent({
    this.headline,
    this.body,
    this.highlights = const [],
    this.investmentNotes = const [],
  });

  final String? headline;
  final String? body;
  final List<String> highlights;
  final List<String> investmentNotes;

  bool get hasContent =>
      (headline != null && headline!.isNotEmpty) ||
      (body != null && body!.isNotEmpty) ||
      highlights.isNotEmpty ||
      investmentNotes.isNotEmpty;
}

class RentToOwnTerms {
  const RentToOwnTerms({
    required this.isAvailable,
    this.initialPayment,
    this.monthlyPayment,
    this.minMonthlyPayment,
    this.maxMonthlyPayment,
    this.contractMonths,
    this.ownershipAllocationPercent,
    this.purchasePrice,
    this.remainingAmount,
    this.optionalFees,
    this.eligibilityNotes,
    this.ownershipConditions,
    this.calculationRules = const {},
  });

  final bool isAvailable;
  final MoneyAmount? initialPayment;
  final MoneyAmount? monthlyPayment;
  final MoneyAmount? minMonthlyPayment;
  final MoneyAmount? maxMonthlyPayment;
  final int? contractMonths;
  final double? ownershipAllocationPercent;
  final MoneyAmount? purchasePrice;
  final MoneyAmount? remainingAmount;
  final MoneyAmount? optionalFees;
  final String? eligibilityNotes;
  final String? ownershipConditions;
  /// Backend-configurable calculation rules (no hidden client formulas).
  final Map<String, dynamic> calculationRules;

  bool get shouldShow => isAvailable;
}

class InvestmentMetrics {
  const InvestmentMetrics({
    this.expectedRentalYield,
    this.estimatedAnnualRent,
    this.grossYield,
    this.netYield,
    this.expectedAppreciation,
    this.estimatedOperatingCost,
    this.vacancyAssumption,
    this.paybackYears,
    this.roi,
    this.cashFlowMonthly,
    this.investmentHorizonYears,
    this.provenance = DataProvenance.estimated,
  });

  final double? expectedRentalYield;
  final MoneyAmount? estimatedAnnualRent;
  final double? grossYield;
  final double? netYield;
  final double? expectedAppreciation;
  final MoneyAmount? estimatedOperatingCost;
  final double? vacancyAssumption;
  final double? paybackYears;
  final double? roi;
  final MoneyAmount? cashFlowMonthly;
  final int? investmentHorizonYears;
  final DataProvenance provenance;

  bool get hasAny =>
      expectedRentalYield != null ||
      estimatedAnnualRent != null ||
      grossYield != null ||
      netYield != null ||
      roi != null;
}

class RentalAnalysis {
  const RentalAnalysis({
    this.monthlyRent,
    this.annualRent,
    this.expectedExpenses,
    this.rentalYield,
    this.estimatedMarketRent,
    this.historicalRent = const [],
    this.provenance = DataProvenance.publisherProvided,
  });

  final MoneyAmount? monthlyRent;
  final MoneyAmount? annualRent;
  final MoneyAmount? expectedExpenses;
  final double? rentalYield;
  final MoneyAmount? estimatedMarketRent;
  final List<MoneyAmount> historicalRent;
  final DataProvenance provenance;

  bool get hasAny => monthlyRent != null || annualRent != null;
}

class MortgageDefaults {
  const MortgageDefaults({
    this.downPaymentPercent,
    this.interestRatePercent,
    this.termYears,
    this.includeTaxes = false,
    this.includeInsurance = false,
    this.fees,
  });

  final double? downPaymentPercent;
  final double? interestRatePercent;
  final int? termYears;
  final bool includeTaxes;
  final bool includeInsurance;
  final MoneyAmount? fees;

  bool get isFinancable =>
      downPaymentPercent != null || interestRatePercent != null;
}
