import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'common/services/storage.dart';
import 'common/store/user.dart';

class Global{
  static Future init() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Get.putAsync<StorageService>(() => StorageService().init());
    Get.put<UserStore>(UserStore());
  }
}