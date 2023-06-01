import 'package:wechat/common/routes/names.dart';
import 'package:wechat/pages/message/state.dart';
import 'package:get/get.dart';

class MessageController extends GetxController{
  MessageController();
  final state = MessageState();

  void goProfile() async {
    await Get.toNamed(AppRoutes.Profile);
  }
}