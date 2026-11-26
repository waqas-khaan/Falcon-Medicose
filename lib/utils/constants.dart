class TransactionType {
  static const String loan = "LOAN";
  static const String payment = "PAYMENT";
}

class AppConstants {
  static const String appName = "Falcon Medicose";
  static const String defaultCurrency = "Rs.";

  static const List<String> medicineCategories = [
    'Tablets',
    'Syrups',
    'Capsules',
    'Injections',
    'Drops',
    'Ointments',
    'Suspensions',
    'Inhalers',
    'Surgical & Dental',
    'Supplements',
    'Baby Care',
    'General',
  ];

  static const List<String> expenseCategories = [
    'Rent',
    'Salaries & Staff',
    'Electricity & Utilities',
    'Transport & Delivery',
    'Tea & Refreshments',
    'Maintenance & Repairs',
    'Packaging & Bags',
    'Taxes & Govt Fees',
    'Other / Miscellaneous',
  ];
}
