import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wechat/pages/message/chat/widgets/chat_list.dart';
import 'controller.dart';

class ChatPage extends GetView<ChatController> {
  const ChatPage({Key? key}) : super(key: key);

  AppBar _buildApp() {
    return AppBar(
      title: Obx(() {
        return Container(
          child: Text(
            '${controller.state.to_name}',
            overflow: TextOverflow.clip,
            maxLines: 1,
            style: TextStyle(
              fontFamily: 'Avenir',
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),
        );
      }),
      actions: [
        Container(
          margin: EdgeInsets.only(right: 20.w),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 44.w,
                height: 44.h,
                child: CachedNetworkImage(
                  imageUrl: controller.state.to_avatar.value,
                  imageBuilder: (context, imageProvider) => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22.w),
                      image: DecorationImage(image: imageProvider),
                    ),
                  ),
                  errorWidget: (context, url, error) => Image(
                    image: AssetImage('assets/images/accout_header.png'),
                  ),
                ),
              ),
              Positioned(
                bottom: 5.w,
                right: 0.w,
                height: 14.w,
                child: Container(
                  width: 14.w,
                  height: 14.w,
                  decoration: BoxDecoration(
                    color: controller.state.to_online.value == '1'
                        ? Colors.green
                        : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(width: 2, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildApp(),
      body: Obx(
            () => SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ChatList(),
              ),
              Container(
                padding: EdgeInsets.all(10.w),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20.w),
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 10.w),
                            Expanded(
                              child: TextField(
                                controller: controller.myInputController,
                                keyboardType: TextInputType.multiline,
                                maxLines: null,
                                minLines: 1,
                                decoration: InputDecoration(
                                  hintText: 'Message...',
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.send),
                              onPressed: () {
                                controller.sendMessage();
                              },
                            ),
                            SizedBox(width: 10.w),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    GestureDetector(
                      onTap: () {
                        controller.goMore();
                      },
                      child: Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add),
                      ),
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: controller.state.more_status.value,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 10.w),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      GestureDetector(
                        onTap: () {},
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/icons/file.png',
                              width: 30.w,
                              height: 30.w,
                            ),
                            SizedBox(height: 5.w),
                            Text('Files'),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          controller.imgFromGallery();
                        },
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/icons/photo.png',
                              width: 30.w,
                              height: 30.w,
                            ),
                            SizedBox(height: 5.w),
                            Text('Photo'),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          controller.audioCall();
                        },
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/icons/call.png',
                              width: 30.w,
                              height: 30.w,
                            ),
                            SizedBox(height: 5.w),
                            Text('Voice Call'),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          controller.videoCall();
                        },
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/icons/video.png',
                              width: 30.w,
                              height: 30.w,
                            ),
                            SizedBox(height: 5.w),
                            Text('Video Call'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}