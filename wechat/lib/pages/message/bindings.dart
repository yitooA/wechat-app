import 'package:chatty/pages/frame/welcome/controller.dart';
import 'package:get/get.dart';

class MessageBinding implements Bindings{
  @override
  void dependencies() {
    Get.lazyPut<WelcomeController>(() => WelcomeController());
  }


}