import 'dart:ffi';

import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wechat/common/apis/nearby.dart';
import 'package:wechat/common/entities/contact.dart';
import 'package:wechat/pages/profile/nearby/index.dart';

import '../../../common/apis/contact.dart';
import '../../../common/entities/msg.dart';
import '../../../common/store/user.dart';

class UserNearby {
  final String token;
  final double distance;

  UserNearby({required this.token, required this.distance});
}

final token = UserStore.to.profile.token;
final db = FirebaseFirestore.instance;

void goChat(ContactItem contactItem) async {
  var from_messages = await db.collection("message").withConverter(
    fromFirestore: Msg.fromFirestore,
    toFirestore: (Msg msg, options)=>msg.toFirestore(),
  ).where("from_token", isEqualTo: token).where("to_token", isEqualTo: contactItem.token).get();
  print('from messages ${from_messages.docs.isEmpty}');

  var to_messages = await db.collection("message").withConverter(
    fromFirestore: Msg.fromFirestore,
    toFirestore: (Msg msg, options)=>msg.toFirestore(),
  ).where("from_token", isEqualTo: contactItem.token).where("to_token", isEqualTo: token).get();

  print('to messages ${to_messages.docs.isEmpty}');

  if(from_messages.docs.isEmpty && to_messages.docs.isEmpty) {
    var profile = UserStore.to.profile;
    var msgdata = Msg(
      from_token: profile.token,
      to_token: contactItem.token,
      from_name: profile.name,
      to_name: contactItem.name,
      from_avatar: profile.avatar,
      to_avatar: contactItem.avatar,
      from_online: profile.online,
      to_online: contactItem.online,
      last_msg: "",
      last_time: Timestamp.now(),
      msg_num: 0,
    );
    var doc_id = await db.collection("message").withConverter(
        fromFirestore: Msg.fromFirestore,
        toFirestore: (Msg msg, options)=>msg.toFirestore()
    ).add(msgdata);

    Get.offAllNamed(
        '/chat',
        parameters: {
          'doc_id': doc_id.id,
          'to_token': contactItem.token??'',
          'to_name': contactItem.name??'',
          'to_avatar': contactItem.avatar??'',
          'to_online': contactItem.online.toString(),
        }
    );
  } else {
    if(from_messages.docs.isNotEmpty) {
      Get.toNamed(
          '/chat',
          parameters: {
            'doc_id': from_messages.docs.first.id,
            'to_token': contactItem.token??'',
            'to_name': contactItem.name??'',
            'to_avatar': contactItem.avatar??'',
            'to_online': contactItem.online.toString(),
          }
      );
    }

    if(to_messages.docs.isNotEmpty) {
      Get.toNamed(
          '/chat',
          parameters: {
            'doc_id': to_messages.docs.first.id,
            'to_token': contactItem.token??'',
            'to_name': contactItem.name??'',
            'to_avatar': contactItem.avatar??'',
            'to_online': contactItem.online.toString(),
          }
      );
    }
  }
}


class NearbyController extends GetxController {
  final state = NearbyState();
  Position? currentPosition;
  final String? token = Get.parameters['token'];
  final CollectionReference locationsCollection =
  FirebaseFirestore.instance.collection('locations');
  var isLoading = false.obs;
  List<String> nearbyTokens = [];

  NearbyController();

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }
  Future<void> fetchCurrentPosition() async {
    try {
      isLoading.value = true;
      final position = await Geolocator.getCurrentPosition();
      currentPosition = position;
      update();
      saveUserLocation(position.latitude, position.longitude);
      updateLocationOnTokenChange(); // Update location when the token changes
      isLoading.value = false;
    } catch (e) {
      print('Error fetching current position: $e');
      isLoading.value = false;
    }
  }

  Future<void> saveUserLocation(double latitude, double longitude) async {
    final userToken = token; // Token received as a parameter
    try {
      await locationsCollection.doc(userToken).set({
        'latitude': latitude,
        'longitude': longitude,
        'token': userToken,
      });
      print('User location saved successfully');
    } catch (e) {
      print('Error saving user location: $e');
    }
  }


  Future<List<UserNearby>> searchUsersNearby(double maxDistance) async {
    final querySnapshot = await locationsCollection.get();
    final userNearbyList = querySnapshot.docs
        .where((doc) => doc['token'] != token) // Exclude your own token
        .where((doc) {
      final latitude = doc['latitude'];
      final longitude = doc['longitude'];
      final distance = Geolocator.distanceBetween(
        currentPosition!.latitude,
        currentPosition!.longitude,
        double.parse(latitude),
        double.parse(longitude),
      );
      return distance <= maxDistance; // Filter by maximum distance
    })
        .map((doc) => UserNearby(
      token: doc['token'],
      distance: Geolocator.distanceBetween(
        currentPosition!.latitude,
        currentPosition!.longitude,
        double.parse(doc['latitude']),
        double.parse(doc['longitude']),
      ),
    ))
        .toList();
    userNearbyList.forEach((userNearbyList) {
      nearbyTokens.add(userNearbyList.token);
    });
    userNearbyList.forEach((element) {
      state.distanceList.add(element.distance);
    });
    return userNearbyList;
  }

  void getContactInfo(List<String> tokens) {
    NearbyAPI.getContactsByTokens(tokens).then((response) {
      if (response.code == 0) {
        List<ContactItem>? contacts = response.data;
        state.contactList.assignAll(contacts!);
      } else {
        String? errorMessage = response.msg;
        // Handle the error
        // ...
        print('error');
      }
    }).catchError((error) {
      // Handle the error
      // ...
    });
  }

  Future<void> fetchContacts() async {
    try {
      final response = await NearbyAPI.getContactsByTokens(nearbyTokens);

      if(response.code == 0) {
        response.data!.forEach((element) {
          state.contactList.add(element);
          print('state added: ${state.contactList}');
        });
      }
      else {
        print('API error');
      }
    } catch (e) {
      // Handle any errors that occur during the API call
      // ...
    }
  }
  void updateLocationOnTokenChange() {
    final tokenRx = RxString(token!);
    tokenRx.listen((newToken) async {
      if (newToken != null) {
        final position = await Geolocator.getCurrentPosition();
        saveUserLocation(position.latitude, position.longitude);
      }
    });
  }
}

