import 'package:connectivity_plus/connectivity_plus.dart';

/// بيعرف إذا في نت ولا لأ، وبيبلّغ لما تتغيّر الحالة.
class ConnectivityService {
  final _connectivity = Connectivity();

  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Stream<bool> get onStatusChange => _connectivity.onConnectivityChanged
      .map((result) => !result.contains(ConnectivityResult.none));
}
