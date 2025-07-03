final String ipAddress = 'localhost';
// final String ipAddress = 'localhost';

final String port = '8080';

String apiUrl(String endpoint) {
  return 'http://$ipAddress:$port/api/$endpoint';
}

final String getAllOrdersUrl = apiUrl('orders');
final String getAllCustomersUrl = apiUrl('buyer');
final String getAllFarmersUrl = apiUrl('farmer');
final String getAllInventory = apiUrl('inventory');
final String postInventory = apiUrl('inventory');
final String loginUrl = apiUrl('farmerLogin');
final String getAllPayments = apiUrl('payment');


   String getImageUrl(String imagePath) {
    return 'http://$ipAddress:$port/$imagePath';
  }
