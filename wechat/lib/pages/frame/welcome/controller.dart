import 'package:wechat/common/routes/names.dart';
import 'package:wechat/pages/frame/welcome/state.dart';
import 'package:get/get.dart';

class WelcomeController extends GetxController{
  WelcomeController();
  final title = "WeChat";
  final state = WelcomeState();

  @override
  void onReady() {
    // TODO: implement onReady
    super.onReady();
    try {
      Future.delayed(Duration(seconds: 3), () => Get.offAllNamed(AppRoutes.Message));
    } catch (e) {
      print('Navigation error: $e');
    }

  }
}