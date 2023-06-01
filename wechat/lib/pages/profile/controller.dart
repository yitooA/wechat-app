import 'package:wechat/common/routes/names.dart';
import 'package:wechat/common/store/store.dart';
import 'package:wechat/pages/frame/welcome/state.dart';
import 'package:wechat/pages/profile/state.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ProfileController extends GetxController{
  ProfileController();
  final state = ProfileState();

  void goLogout() async {
    await GoogleSignIn().signOut();
    await UserStore.to.onLogout();
  }
}