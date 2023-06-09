import 'package:get/get.dart';

import 'controller.dart';

class NearbyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NearbyController>(() => NearbyController());
  }
}
