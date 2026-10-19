import 'api_client.dart';
import 'orders.dart';

class OrderView {
  final LocalOrder order;
  final JobStatus? status;
  const OrderView(this.order, this.status);
}

Future<List<OrderView>> loadOrderViews(ApiClient api) async {
  final orders = await LocalStore.orders();
  final futures = orders.map((o) async {
    try {
      return OrderView(o, await api.getJobStatus(o.jobId));
    } catch (_) {
      return OrderView(o, null);
    }
  }).toList();
  return Future.wait(futures);
}

Future<List<OrderView>> fetchOrderViews() async {
  final api = ApiClient();
  try {
    return await loadOrderViews(api);
  } finally {
    api.dispose();
  }
}
