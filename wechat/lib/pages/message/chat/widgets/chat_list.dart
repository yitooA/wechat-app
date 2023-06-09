import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wechat/common/values/colors.dart';
import 'package:wechat/pages/message/chat/controller.dart';

import 'chat_left.dart';
import 'chat_right.dart';

class ChatList extends GetView<ChatController> {
  const ChatList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
      color: AppColors.primaryBackground,
      padding: EdgeInsets.only(bottom: 80.h),
      child: GestureDetector(
        child: CustomScrollView(
          controller: controller.myScrollController,
          reverse: true,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(
                  vertical: 0.w,
                  horizontal: 0.w
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      var item = controller.state.msgcontentList[index];
                      if(controller.token == item.token) { //comparing user token with msgList token
                        return ChatRightList(item);
                      }
                      return ChatLeftList(item);
                    },
                    childCount: controller.state.msgcontentList.length
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(
                  vertical: 0.w,
                  horizontal: 0.w
              ),
              sliver: SliverToBoxAdapter(
                child: controller.state.isLoading.value ? Align(
                  alignment: Alignment.center, child: Text('loading...'),
                ) : Container(),
              ),
            ),
          ],
        ),
        onTap: () {
          controller.closeAllPop();
        },
      ),
    ),
    );
  }
}
