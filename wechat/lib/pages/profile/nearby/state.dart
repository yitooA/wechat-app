import 'dart:ffi';

import 'package:get/get.dart';
import 'package:wechat/common/entities/contact.dart';

class NearbyState {
  RxList<ContactItem> contactList = <ContactItem>[].obs;
  RxList<double> distanceList = <double>[].obs;
  bool isLoading;

  NearbyState({
    this.isLoading = false,
  });
}
