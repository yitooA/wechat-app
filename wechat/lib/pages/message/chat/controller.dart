import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wechat/common/entities/entities.dart';
import 'package:wechat/common/widgets/toast.dart';
import 'package:wechat/pages/message/chat/state.dart';
import 'package:get/get.dart';

import '../../../common/apis/chat.dart';
import '../../../common/routes/names.dart';
import '../../../common/store/user.dart';

class ChatController extends GetxController {
  ChatController();
  final state = ChatState();
  late String doc_id;
  final myInputController = TextEditingController();
  //get the sender's token
  final token = UserStore.to.profile.token;

  //firebase database instance
  final db = FirebaseFirestore.instance;
  var listener;

  var isLoadMore = true;
  File? _photo;
  final ImagePicker _picker = ImagePicker();

  ScrollController myScrollController = ScrollController();

  void goMore() {
    state.more_status.value = state.more_status.value ? false : true;
  }

  // Encryption method
  String encryptContent(String content) {
    var secretKey = generateSecretKey();
    var iv = generateInitializationVector();

    final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromUtf8(secretKey)));

    final encrypted = encrypter.encrypt(content, iv: encrypt.IV.fromUtf8(iv));

    return encrypted.base64 + ':' + secretKey + ':' + iv;
  }

// Decryption method
  String decryptContent(String encryptedContent) {
    var parts = encryptedContent.split(':');
    var content = parts[0];
    var secretKey = parts[1];
    var iv = parts[2];

    final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromUtf8(secretKey)));

    final decrypted = encrypter.decrypt64(content, iv: encrypt.IV.fromUtf8(iv));

    return decrypted;
  }

// Generate a random secret key
  String generateSecretKey() {
    final random = Random.secure();
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    return List.generate(32, (_) => charset[random.nextInt(charset.length)]).join();
  }

// Generate a random initialization vector
  String generateInitializationVector() {
    final random = Random.secure();
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    return List.generate(16, (_) => charset[random.nextInt(charset.length)]).join();
  }

  void audioCall() {
    state.more_status.value = false;
    Get.toNamed(
      AppRoutes.VoiceCall,
      parameters: {
        'to_token': state.to_token.value,
        'to_name': state.to_name.value,
        'to_avatar': state.to_avatar.value,
        'call_role': 'anchor',
        'doc_id': doc_id
      },
    );
  }


  void videoCall() {
    state.more_status.value = false;
    Get.toNamed(
      AppRoutes.VideoCall,
      parameters: {
        'to_token': state.to_token.value,
        'to_name': state.to_name.value,
        'to_avatar': state.to_avatar.value,
        'call_role': 'anchor',
        'doc_id': doc_id
      },
    );
  }

  @override
  void onInit() {
    super.onInit();
    print('onInit called');
    var data = Get.parameters;
    print(data);
    doc_id = data['doc_id']!;
    state.to_token.value = data['to_token'] ?? '';
    state.to_name.value = data['to_name'] ?? '';
    state.to_avatar.value = data['to_avatar'] ?? '';
    state.to_online.value = data['to_online'] ?? '1';
    clearMsgNum(doc_id);
  }

  Future<void> clearMsgNum(String doc_id) async {
    var messageResult = await db
        .collection('message')
        .doc(doc_id)
        .withConverter(
      fromFirestore: Msg.fromFirestore,
      toFirestore: (Msg msg, options) => msg.toFirestore(),
    )
        .get();

    if (messageResult.data() != null) {
      var item = messageResult.data()!;
      int to_msg_num = item.to_msg_num == null ? 0 : item.to_msg_num!;
      int from_msg_num = item.from_msg_num == null ? 0 : item.from_msg_num!;
      if (item.from_token == token) {
        to_msg_num = 0;
      } else {
        from_msg_num = 0;
      }
      await db.collection('message').doc(doc_id).update({
        'to_msg_num': to_msg_num,
        'from_msg_num': from_msg_num,
      });
    }
  }

  @override
  void onReady() {
    super.onReady();
    print('onReady called');
    state.msgcontentList.clear();
    final messages = db
        .collection('message')
        .doc(doc_id)
        .collection('msglist')
        .withConverter(
      fromFirestore: Msgcontent.fromFirestore,
      toFirestore: (Msgcontent msg, options) => msg.toFirestore(),
    )
        .orderBy('addtime', descending: true)
        .limit(15);
    listener = messages.snapshots().listen((event) {
      List<Msgcontent> tempMsgList = <Msgcontent>[];
      for (var change in event.docChanges) {
        switch (change.type) {
          case DocumentChangeType.added:
            if (change.doc.data() != null) {
              tempMsgList.add(change.doc.data()!);
              print('${change.doc.data()!}');
              print('...newly added');
            }
            break;
          case DocumentChangeType.modified:
          //TODO: handle this case
            break;
          case DocumentChangeType.removed:
          //TODO: handle this case
            break;
        }
      }
      tempMsgList.reversed.forEach((element) {
        final decryptedContent = decryptContent(element.content!);
        element.content = decryptedContent;
        state.msgcontentList.value.insert(0, element);
      });

      state.msgcontentList.refresh();
      if (myScrollController.hasClients) {
        myScrollController.animateTo(
          myScrollController.position.minScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    myScrollController.addListener(() {
      if (myScrollController.offset + 20 > myScrollController.position.maxScrollExtent) {
        if (isLoadMore) {
          state.isLoading.value = true;
          isLoadMore = false;
          asyncLoadMoreData();
        }
      }
    });
  }

  Future imgFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _photo = File(pickedFile.path);
      uploadFile();
    } else {
      print('No image is selected');
    }
  }

  Future uploadFile() async {
    var result = await ChatAPI.upload_img(file: _photo);
    print(result.code);
    print(result.msg);
    if (result.code == 0) {
      sendImageMessage(result.data!);
    } else {
      toastInfo(msg: 'sending Image error');
    }
  }

  Future<void> sendMessage() async {
    var list = await db.collection('message').doc(doc_id).collection('msgList').get();

    String sendContent = myInputController.text;
    if (sendContent.isEmpty) {
      return;
    }

    String encryptedMessage = encryptContent(sendContent);

    final content = Msgcontent(
      token: token,
      content: encryptedMessage,
      type: 'text',
      addtime: Timestamp.now(),
    );

    await db
        .collection('message')
        .doc(doc_id)
        .collection('msglist')
        .withConverter(
      fromFirestore: Msgcontent.fromFirestore,
      toFirestore: (Msgcontent msg, options) => msg.toFirestore(),
    )
        .add(content)
        .then((DocumentReference doc) {
      myInputController.clear();
    });

    var messageResult = await db
        .collection('message')
        .doc(doc_id)
        .withConverter(
      fromFirestore: Msg.fromFirestore,
      toFirestore: (Msg msg, options) => msg.toFirestore(),
    )
        .get();

    if (messageResult.data() != null) {
      var item = messageResult.data()!;
      int to_msg_num = item.to_msg_num == null ? 0 : item.to_msg_num!;
      int from_msg_num = item.from_msg_num == null ? 0 : item.from_msg_num!;
      if (item.from_token == token) {
        from_msg_num = from_msg_num + 1;
      } else {
        to_msg_num = to_msg_num + 1;
      }
      await db.collection('message').doc(doc_id).update({
        'to_msg_num': to_msg_num,
        'from_msg_num': from_msg_num,
        'last_msg': sendContent,
        'last_time': Timestamp.now(),
      });
    }
  }

  void asyncLoadMoreData() async {
    final messages = await db
        .collection('message')
        .doc(doc_id)
        .collection('msglist')
        .withConverter(
      fromFirestore: Msgcontent.fromFirestore,
      toFirestore: (Msgcontent msg, options) => msg.toFirestore(),
    )
        .orderBy('addtime', descending: true)
        .where(
      'addtime',
      isLessThan: state.msgcontentList.value.last.addtime,
    )
        .limit(10)
        .get();

    if (messages.docs.isNotEmpty) {
      messages.docs.forEach((element) {
        var data = element.data();
        state.msgcontentList.value.add(data);
      });
    }
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      isLoadMore = true;
    });
    state.isLoading.value = false;
  }

  Future<void> sendImageMessage(String url) async {
    var list = await db.collection('message').doc(doc_id).collection('msgList').get();

    final encryptedUrl = encryptContent(url);

    final content = Msgcontent(
      token: token,
      content: encryptedUrl,
      type: 'image',
      addtime: Timestamp.now(),
    );

    await db
        .collection('message')
        .doc(doc_id)
        .collection('msglist')
        .withConverter(
      fromFirestore: Msgcontent.fromFirestore,
      toFirestore: (Msgcontent msg, options) => msg.toFirestore(),
    )
        .add(content)
        .then((DocumentReference doc) {
      myInputController.clear();
    });

    var messageResult = await db
        .collection('message')
        .doc(doc_id)
        .withConverter(
      fromFirestore: Msg.fromFirestore,
      toFirestore: (Msg msg, options) => msg.toFirestore(),
    )
        .get();

    if (messageResult.data() != null) {
      var item = messageResult.data()!;
      int to_msg_num = item.to_msg_num == null ? 0 : item.to_msg_num!;
      int from_msg_num = item.from_msg_num == null ? 0 : item.from_msg_num!;
      if (item.from_token == token) {
        from_msg_num = from_msg_num + 1;
      } else {
        to_msg_num = to_msg_num + 1;
      }
      await db.collection('message').doc(doc_id).update({
        'to_msg_num': to_msg_num,
        'from_msg_num': from_msg_num,
        'last_msg': '[Image]',
        'last_time': Timestamp.now(),
      });
    }
  }

  void closeAllPop() async {
    Get.focusScope?.unfocus();
    state.more_status.value = false;
  }

  @override
  void onClose() {
    super.onClose();
    listener.cancel();
    myInputController.dispose();
    myScrollController.dispose();
    clearMsgNum(doc_id);
  }
}
