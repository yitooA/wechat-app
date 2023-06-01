import 'dart:convert';

import 'package:wechat/common/entities/entities.dart';
import 'package:wechat/common/routes/names.dart';
import 'package:wechat/common/utils/http.dart';
import 'package:wechat/pages/frame/sign_in/state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../common/apis/user.dart';
import '../../../common/store/user.dart';
import '../../../common/widgets/toast.dart';

class SignInController extends GetxController{
  SignInController();
  final state = SignInState();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'openid'
    ]
  );

  Future<void> handleSignIn(String type) async {
    //1: email, 2: google 3: facebook 4: apple 5: phone
    try{
      if(type == 'phone number') {
        print('... you are logging  in with phone number ...');
      }else if(type == 'google'){
        var user = await _googleSignIn.signIn();
        if(user!=null){
          String? displayName = user.displayName;
          String email = user.email;
          String id = user.id;
          String photoUrl = user.photoUrl ?? 'assets/icons/google.png';

          LoginRequestEntity loginPanelListRequestEntity = LoginRequestEntity();
          loginPanelListRequestEntity.avatar = photoUrl;
          loginPanelListRequestEntity.name = displayName;
          loginPanelListRequestEntity.email = email;
          loginPanelListRequestEntity.open_id = id;
          loginPanelListRequestEntity.type = 2;
          print(jsonEncode(loginPanelListRequestEntity));
          asyncPostAllData(loginPanelListRequestEntity);
        }
      }else{
        if(kDebugMode){
          print('... login type not sure ...');
        }
      }
    }catch(e) {
      print('...error with login $e');
    }
  }

  asyncPostAllData(LoginRequestEntity loginRequestEntity) async {
    // first save on the database
    // second save in the local storage
    //   var response = await HttpUtil().get('/api/index');
    //   print(response);
    //   UserStore.to.setIsLogin=true;

    EasyLoading.show(
      indicator: CircularProgressIndicator(),
      maskType: EasyLoadingMaskType.clear, dismissOnTap: true
    );
    var result = await UserAPI.Login(params: loginRequestEntity);
    if(result.code==0) {
      await UserStore.to.saveProfile(result.data!);
      EasyLoading.dismiss();
    } else {
      EasyLoading.dismiss();
      toastInfo(msg: 'Internet error');
    }
    Get.offAllNamed(AppRoutes.Message);

  }

}