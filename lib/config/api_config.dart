class ApiConfig {
  static const String baseUrl = 'http://localhost:5000';
  
  // Auth endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String profileEndpoint = '/auth/profile';
  static const String updateProfileEndpoint = '/auth/profile';
  static const String logoutEndpoint = '/auth/logout';
  static const String changePasswordEndpoint = '/auth/change-password';
  static const String deleteAccountEndpoint = '/auth/profile';
  
  // Income endpoints
  static const String incomeEndpoint = '/income';
  
  // Expense endpoints
  static const String expenseEndpoint = '/expense';
  
  // Inventory endpoints
  static const String inventoryEndpoint = '/inventory';
}
