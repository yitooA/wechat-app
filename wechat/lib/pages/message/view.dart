import 'package:wechat/common/routes/names.dart';
import 'package:wechat/common/values/colors.dart';
import 'package:wechat/pages/message/controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


class MessagePage extends GetView<MessageController> {
  const MessagePage({Key? key}) : super(key: key);

  Widget _headBar() {
    return Center(
      child: Container(
        width: 320.w,
        height: 44.w,
        margin: EdgeInsets.only(bottom: 20.h, top: 20.h),
        child: Row(
          children: [
            Stack(
              children: [
                GestureDetector(
                  child: Container(
                    width: 44.h,
                    height: 44.h,
                    decoration: BoxDecoration(
                      color: AppColors.primarySecondaryBackground,
                      borderRadius: BorderRadius.all(Radius.circular(22.h)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ]
                    ),
                    child: controller.state.headDetail.value.avatar == null ?
                    Image(image: AssetImage("assets/images/account_header.png")) :
                    Text('hi'),
                  ),
                  onTap: () {
                    controller.goProfile();
                  },
                ),
                Positioned(
                  bottom: 5.w,
                  right: 0.w,
                  height: 14.w,
                  child: Container(
                    width: 14.w,
                    height: 14.w,
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 2.w,
                        color: AppColors.primaryElementText,
                      ),
                      color: AppColors.primaryElementStatus,
                      borderRadius: BorderRadius.all(Radius.circular(12.w))
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  title: _headBar(),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: GestureDetector(
          child: Container(
            height: 50.w,
            width: 50.w,
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.primaryElement,
              borderRadius: BorderRadius.all(Radius.circular(40.w)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 2,
                  offset: Offset(1,1)
                ),
              ]
            ),
            child: Image.asset('assets/icons/contact.png'),
          ),
          onTap: () {
            Get.toNamed(AppRoutes.Contact);
          },
        ),
    );
  }
}
