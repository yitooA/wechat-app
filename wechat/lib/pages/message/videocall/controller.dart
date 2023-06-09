import 'dart:async';
import 'dart:convert';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:wechat/common/apis/apis.dart';
import 'package:wechat/common/entities/entities.dart';
import 'package:wechat/common/routes/routes.dart';
import 'package:wechat/common/store/store.dart';
import 'package:wechat/common/values/server.dart';
import 'package:wechat/common/values/values.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

import 'state.dart';

class VideoCallController extends GetxController {
  final VideoCallState state = VideoCallState();
  late final RtcEngine engine;
  final player = AudioPlayer();
  // 两个人聊天
  ChannelProfileType channelProfileType =
      ChannelProfileType.channelProfileCommunication;
  String appId = APPID;
  final profile_token = UserStore.to.profile.token;
  late final Timer calltimer;
  int call_m = 0;
  int call_s = 0;
  int call_h = 0;
  final db = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    var data = Get.parameters;
    state.to_token.value = data["to_token"] ?? "";
    state.to_name.value = data["to_name"] ?? "";
    state.to_avatar.value = data["to_avatar"] ?? "";
    state.call_role.value = data["call_role"] ?? "";
    state.doc_id.value = data["doc_id"] ?? "";
    _initEngine();
  }

  @override
  void dispose() {
    super.dispose();
    _dispose();
  }

  @override
  void onClose() {
    super.onClose();
    _dispose();
  }

  Future<void> _dispose() async {
    if (calltimer != null) {
      calltimer.cancel();
    }
    if (state.call_role == "anchor") {
      addCallTime();
    }
    await player.pause();
    await engine.leaveChannel();
    await engine.release();
    await player.stop();
  }

  Future<void> _initEngine() async {
    await player.setAsset("assets/Sound_Horizon.mp3");
    engine = createAgoraRtcEngine();
    await engine.initialize(RtcEngineContext(
      appId: appId,
    ));

    engine.registerEventHandler(RtcEngineEventHandler(
      onError: (ErrorCodeType err, String msg) {
        print('[onError] err: $err, msg: $msg');
        // if(err!=ErrorCodeType.errOk){
        //   Get.snackbar(
        //       "call error, confirm return！",
        //       "${msg}",
        //       duration: Duration(seconds: 60),
        //       isDismissible: false,
        //       mainButton: TextButton(
        //           onPressed: () {
        //             if (Get.isSnackbarOpen) {
        //               Get.closeAllSnackbars();
        //             }
        //             Get.offAndToNamed(AppRoutes.Message);
        //           },
        //           child: Container(
        //             width: 40.w,
        //             height: 40.w,
        //             padding: EdgeInsets.all(10.w),
        //             decoration: BoxDecoration(
        //               color: AppColors.primaryElementBg,
        //               borderRadius:
        //               BorderRadius.all(Radius.circular(30.w)),
        //             ),
        //             child: Image.asset("assets/icons/back.png"),
        //           )));
        // }
      },
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        print(
            '[onJoinChannelSuccess] connection: ${connection.toJson()} elapsed: $elapsed');
        state.isJoined.value = true;
      },
      onUserJoined: (RtcConnection connection, int rUid, int elapsed) async {
        print(
            '[onUserJoined] connection: ${connection.toJson()} remoteUid: $rUid elapsed: $elapsed');
        state.remoteUid.value.add(rUid);
        state.onremoteUid.value = rUid;
        state.isShowAvatar.value = false;
        await player.pause();
        if (state.call_role == "anchor") {
          callTime();
        }
      },
      onUserOffline:
          (RtcConnection connection, int rUid, UserOfflineReasonType reason) {
        print(
            '[onUserOffline] connection: ${connection.toJson()}  rUid: $rUid reason: $reason');
        state.remoteUid.value.removeWhere((element) => element == rUid);
        state.onremoteUid.value = 0;
        state.isShowAvatar.value = true;
        // leaveChannel();
      },
      onLeaveChannel: (RtcConnection connection, RtcStats stats) {
        print(
            '[onLeaveChannel] connection: ${connection.toJson()} stats: ${stats.toJson()}');
        state.isJoined.value = false;
        state.remoteUid.value.clear();
        state.onremoteUid.value = 0;
        state.isShowAvatar.value = true;
      },
    ));

    await engine.enableVideo();

    await engine.setVideoEncoderConfiguration(
      const VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 640, height: 360),
        frameRate: 15,
        bitrate: 0,
      ),
    );

    await engine.startPreview();
    state.isReadyPreview.value = true;
    await joinChannel();
    if (state.call_role == "anchor") {
      await sendNotifications("video");
      await player.play();
    }
  }

  callTime() async {
    calltimer = Timer.periodic(Duration(seconds: 1), (timer) {
      call_s = call_s + 1;
      if (call_s >= 60) {
        call_s = 0;
        call_m = call_m + 1;
      }
      if (call_m >= 60) {
        call_m = 0;
        call_h = call_h + 1;
      }
      var h = call_h < 10 ? "0${call_h}" : "${call_h}";
      var m = call_m < 10 ? "0${call_m}" : "${call_m}";
      var s = call_s < 10 ? "0${call_s}" : "${call_s}";

      if (call_h == 0) {
        state.call_time.value = "${m}:${s}";
        state.call_time_num.value = "${call_m} m and ${call_s} s";
      } else {
        state.call_time.value = "${h}:${m}:${s}";
        state.call_time_num.value = "${call_h} h ${call_m} m and ${call_s} s";
      }
    });
  }

  Future<String> getToken() async {
    if (state.call_role == "anchor") {
      state.channelId.value = md5
          .convert(utf8.encode("${profile_token}_${state.to_token}"))
          .toString();
    } else {
      state.channelId.value = md5
          .convert(utf8.encode("${state.to_token}_${profile_token}"))
          .toString();
    }
    CallTokenRequestEntity callTokenRequestEntity =
        new CallTokenRequestEntity();
    callTokenRequestEntity.channel_name = state.channelId.value;
    var res = await ChatAPI.call_token(params: callTokenRequestEntity);
    if (res.code == 0) {
      return res.data!;
    }
    return "";
  }

  addCallTime() async {
    var profile = UserStore.to.profile;
    var msgdata = new ChatCall(
      from_token: profile.token,
      to_token: state.to_token.value,
      from_name: profile.name,
      to_name: state.to_name.value,
      from_avatar: profile.avatar,
      to_avatar: state.to_avatar.value,
      call_time: "${state.call_time_num.value}",
      type: "video",
      last_time: Timestamp.now(),
    );
    var doc_res = await db
        .collection("chatcall")
        .withConverter(
          fromFirestore: ChatCall.fromFirestore,
          toFirestore: (ChatCall msg, options) => msg.toFirestore(),
        )
        .add(msgdata);
    String sendcontent = "Call time ${state.call_time_num.value}【video】";
    sendMessage(sendcontent);
  }
  sendMessage(String sendcontent) async{
    if(state.doc_id.value.isEmpty){
      return;
    }
    final content = Msgcontent(
      token: profile_token,
      content: sendcontent,
      type: "text",
      addtime: Timestamp.now(),
    );

    await db.collection("message").doc(state.doc_id.value).collection("msglist").withConverter(
      fromFirestore: Msgcontent.fromFirestore,
      toFirestore: (Msgcontent msgcontent, options) => msgcontent.toFirestore(),
    ).add(content);
    var message_res = await db.collection("message").doc(state.doc_id.value).withConverter(
      fromFirestore: Msg.fromFirestore,
      toFirestore: (Msg msg, options) => msg.toFirestore(),
    ).get();
    if(message_res.data()!=null){
      var item = message_res.data()!;
      int to_msg_num = item.to_msg_num==null?0:item.to_msg_num!;
      int from_msg_num = item.from_msg_num==null?0:item.from_msg_num!;
      if (item.from_token == profile_token) {
        from_msg_num = from_msg_num + 1;
      } else {
        to_msg_num = to_msg_num + 1;
      }
      await db.collection("message").doc(state.doc_id.value).update({"to_msg_num":to_msg_num,"from_msg_num":from_msg_num,"last_msg":sendcontent,"last_time":Timestamp.now()});
    }

  }

  Future<void> joinChannel() async {
    await [Permission.microphone, Permission.camera].request();
    EasyLoading.show(
        indicator: CircularProgressIndicator(),
        maskType: EasyLoadingMaskType.clear,
        dismissOnTap: true);
    String token = await getToken();
    if (token.isEmpty) {
      EasyLoading.dismiss();
      Get.back();
      return;
    }
    await engine.joinChannel(
      token: token,
      channelId: state.channelId.value,
      uid: 0,
      options: ChannelMediaOptions(
        channelProfile: channelProfileType,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );

    if (state.call_role == "audience") {
      callTime();
    }
    EasyLoading.dismiss();
  }

  sendNotifications(String call_type) async {
    CallRequestEntity callRequestEntity = new CallRequestEntity();
    callRequestEntity.call_type = call_type;
    callRequestEntity.to_token = state.to_token.value;
    callRequestEntity.to_avatar = state.to_avatar.value;
    callRequestEntity.doc_id = state.doc_id.value;
    callRequestEntity.to_name = state.to_name.value;
    var res = await ChatAPI.call_notifications(params: callRequestEntity);
    print(res);
    if (res.code == 0) {
      print("sendNotifications success");
    } else {
      //
    }
  }

  Future<void> leaveChannel() async {
    EasyLoading.show(
        indicator: CircularProgressIndicator(),
        maskType: EasyLoadingMaskType.clear,
        dismissOnTap: true);
    await player.pause();
    await sendNotifications("cancel");
    // await engine.leaveChannel();
    state.isJoined.value = false;
    state.switchCameras.value = true;
    EasyLoading.dismiss();
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }
    Get.back();
  }

  Future<void> switchCamera() async {
    await engine.switchCamera();
    state.switchCameras.value = !state.switchCameras.value;
  }
}
