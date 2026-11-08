// Backend address. Set it when building the app, for example:
//   flutter build apk --dart-define=API_BASE_URL=https://ez-farms.onrender.com
//   flutter build apk --dart-define=API_BASE_URL=http://203.0.113.25:8080
// Without it, the app uses the local development server below.
const String _configuredBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://172.24.239.38:8080',
);

final String baseUrl = _configuredBaseUrl.endsWith('/')
    ? _configuredBaseUrl.substring(0, _configuredBaseUrl.length - 1)
    : _configuredBaseUrl;

String apiUrl(String endpoint) {
  return '$baseUrl/api/$endpoint';
}

final String getAllOrdersUrl = apiUrl('orders');
final String getAllCustomersUrl = apiUrl('buyer');
final String getAllFarmersUrl = apiUrl('farmer');
final String getAllInventory = apiUrl('inventory');
final String postInventory = apiUrl('inventory');
final String loginUrl = apiUrl('farmerLogin');
final String registerFarmerUrl = apiUrl('farmer');
final String getAllPayments = apiUrl('payment');

String getImageUrl(String imagePath) {
  return '$baseUrl/$imagePath';
}
