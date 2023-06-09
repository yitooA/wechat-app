import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wechat/common/apis/apis.dart';
import 'package:wechat/common/entities/base.dart';
import 'package:wechat/common/entities/entities.dart';
import 'package:wechat/common/routes/names.dart';
import 'package:wechat/common/store/store.dart';
import 'package:wechat/pages/message/state.dart';
import 'package:get/get.dart';

class MessageController extends GetxController {
  MessageController();

  final state = MessageState();
  var db = FirebaseFirestore.instance;
  final token = UserStore.to.profile.token;
  final accessToken = UserStore.to.profile.access_token;


  void goProfile() async {
    await Get.toNamed(AppRoutes.Profile, arguments: state.headDetail.value);
  }

  Position? currentPosition;
  final CollectionReference locationsCollection =
  FirebaseFirestore.instance.collection('locations');


  Future<void> fetchCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      currentPosition = position;
      print(currentPosition);
      update();
      saveUserLocation(position.latitude, position.longitude);
      updateLocationOnTokenChange(); // Update location when the token changes
    } catch (e) {
      print('Error fetching current position: $e');
    }
  }

  void updateLocationOnTokenChange() {
    final tokenRx = RxString(accessToken!);
    tokenRx.listen((newToken) async {
      if (newToken != null) {
        final position = await Geolocator.getCurrentPosition();
        saveUserLocation(position.latitude, position.longitude);
      }
    });
  }

  Future<String> generateRandomDocId() async {
    final random = Random();
    String randomDocId = '';
    for (var i = 0; i < 6; i++) {
      randomDocId += random.nextInt(10).toString();
    }
    return randomDocId;
  }

  Future<void> saveUserLocation(double latitude, double longitude) async {
    final userToken = token; // Token received as a parameter
    try {
      final docId = userToken; // Use the access token as the document ID
      await locationsCollection.doc(docId).set({
        'latitude': latitude,
        'longitude': longitude,
        'token': userToken,
      });
      print('User location saved successfully');
    } catch (e) {
      print('Error saving user location: $e');
    }
  }


  goTabStatus() {
    EasyLoading.show(
      indicator: CircularProgressIndicator(),
      maskType: EasyLoadingMaskType.clear,
      dismissOnTap: true,
    );

    bool previousTabStatus = state.tabStatus.value;
    state.tabStatus.value = !state.tabStatus.value;

    if (state.tabStatus.value && !previousTabStatus && state.msgList.isEmpty) {
      asyncLoadMsgData();
    }

    EasyLoading.dismiss();
  }



  Future<void> asyncLoadMsgData() async {
    try {
      print('asyncLoadMsgData - Start');
      var from_messages = await db
          .collection('message')
          .withConverter(
          fromFirestore: Msg.fromFirestore,
          toFirestore: (Msg msg, options) => msg.toFirestore())
          .where('from_token', isEqualTo: token)
          .get();
      print('from_messages length: ${from_messages.docs.length}');

      var to_messages = await db
          .collection('message')
          .withConverter(
          fromFirestore: Msg.fromFirestore,
          toFirestore: (Msg msg, options) => msg.toFirestore())
          .where('to_token', isEqualTo: token)
          .get();

      print('to_messages length: ${to_messages.docs.length}');

      state.msgList.clear();

      if (from_messages.docs.isNotEmpty) {
        await addMessage(from_messages.docs);
      }

      if (to_messages.docs.isNotEmpty) {
        await addMessage(to_messages.docs);
      }

      print('asyncLoadMsgData - End');
    } catch (error) {
      print('Error loading message data: $error');
    } finally {
      EasyLoading.dismiss();
    }
  }

  addMessage(List<QueryDocumentSnapshot<Msg>> data) {
    data.forEach((element) {
      var item = element.data();
      Message message = Message();
      //save the common properties
      message.doc_id = element.id;
      message.last_time = item.last_time;
      message.msg_num = item.msg_num;
      message.last_msg = item.last_msg;
      if (item.from_token == token) {
        message.name = item.to_name;
        message.avatar = item.to_avatar;
        message.token = item.to_token;
        message.online = item.to_online;
        message.msg_num = item.to_msg_num ?? 0;
      } else {
        message.name = item.from_name;
        message.avatar = item.from_avatar;
        message.token = item.from_token;
        message.online = item.from_online;
        message.msg_num = item.from_msg_num ?? 0;
      }
      state.msgList.add(message);
    });
  }

  @override
  void onInit() {
    super.onInit();
    getProfile();
    _setupSnapshots();
  }

  _setupSnapshots() {
    final token = UserStore.to.profile.token;

    final messageRef = db
        .collection('message')
        .withConverter(
        fromFirestore: Msg.fromFirestore,
        toFirestore: (Msg msg, options) => msg.toFirestore());

    final toMessageRef = messageRef.where('to_token', isEqualTo: token);
    final fromMessageRef = messageRef.where('from_token', isEqualTo: token);

    void handleMessagesChange(QuerySnapshot<Msg> snapshot) {
      print('handleMessagesChange - Start');
      if (state.tabStatus.value) {
        asyncLoadMsgData();
      }
      print('handleMessagesChange - End');
    }

    toMessageRef.snapshots().listen(handleMessagesChange);
    fromMessageRef.snapshots().listen(handleMessagesChange);
  }


  @override
  void onReady() {
    super.onReady();
    firebaseMessageSetup();
    fetchCurrentPosition();
  }

  void getProfile() async {
    var profile = await UserStore.to.profile;
    state.headDetail.value = profile;
    state.headDetail.refresh();
  }

  firebaseMessageSetup() async {
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    print('...My device token is $fcmToken');
    if (fcmToken != null) {
      BindFcmTokenRequestEntity bindFcmTokenRequestEntity =
      BindFcmTokenRequestEntity();
      bindFcmTokenRequestEntity.fcmtoken = fcmToken;
      await ChatAPI.bind_fcmtoken(params: bindFcmTokenRequestEntity);
    }
  }
}
