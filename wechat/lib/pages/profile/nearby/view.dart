import 'package:get/get.dart';
import 'package:flutter/material.dart';

import 'controller.dart';

class NearbyPage extends StatelessWidget {
  final NearbyController nearbyController = Get.find<NearbyController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Users'),
      ),
      body: GetBuilder<NearbyController>(
        initState: (_) async {
          await nearbyController.fetchCurrentPosition();
          await nearbyController.searchUsersNearby(1000);
          await nearbyController.fetchContacts();
        },
        builder: (controller) {
          return Obx(() {
            if (controller.isLoading.value) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else if (controller.state.contactList.isEmpty) {
              return Center(
                child: Text('No nearby contacts found.'),
              );
            } else {
              return ListView.builder(
                itemCount: controller.state.contactList.length,
                itemBuilder: (context, index) {
                  final contact = controller.state.contactList[index];
                  final distnace = controller.state.distanceList[index];
                  return GestureDetector(
                    onTap: () {
                      // // Handle the gesture and navigate to the chat page
                      // // Pass necessary parameters like contact details
                      // // to the chat page
                      // Get.toNamed(
                      //   '/chat',
                      //   parameters: {
                      //     'to_token': contact.token!,
                      //     'to_name': contact.name!,
                      //     'to_avatar': contact.avatar!,
                      //     'to_online': contact.online.toString(),
                      //   },
                      // );
                      goChat(contact);
                    },
                    child: ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: contact.avatar == null
                            ? Image.asset(
                          "assets/images/account_header.png",
                          width: 44,
                          height: 44,
                        )
                            : ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.network(
                            contact.avatar!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      title: Text(contact.name!),
                      subtitle: Text(
                        'Distance: ${distnace.toStringAsFixed(2)} meters',
                      ),
                    ),
                  );
                },
              );
            }
          });
        },
      ),
    );
  }
}
