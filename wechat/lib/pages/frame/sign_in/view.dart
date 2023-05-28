import 'package:chatty/common/values/colors.dart';
import 'package:chatty/pages/frame/sign_in/controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


class SignInPage extends GetView<SignInController> {
  const SignInPage({Key? key}) : super(key: key);

  Widget _buildLogo() {
    return Container(
      margin: EdgeInsets.only(top: 100.h, bottom: 80.h),
      child: Text(
        "WeChat",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.weChatPrimaryText,
          fontWeight: FontWeight.bold,
          fontSize: 34.sp
        ),
      )
    );
  }

  Widget _buildThirdPartyLogin(String loginType, String logo) {
    return GestureDetector(
      child: Container(
      padding: EdgeInsets.all(10.h),
      margin: EdgeInsets.only(bottom: 15.h),
      width: 295.w,
      height: 44.h,
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.all(Radius.circular(5)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: Offset(0,1),
          ),
        ]
      ),
      child: Row(
        mainAxisAlignment: logo == '' ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          logo == '' ? Container () : Container(
            padding: EdgeInsets.only(left: 40.w, right: 30.w),
            child: Image.asset('assets/icons/$logo.png'),
          ),
          Container(
            child: Text(
              'Sign in with $loginType',
              style: TextStyle(
                  color: AppColors.weChatPrimaryText,
                  fontWeight: FontWeight.normal,
                  fontSize: 14.sp
              ),
            ),
          ),
        ],
      ),
    ),
      onTap: () {
        // print('...signup from here third party ${loginType}...');
        controller.handleSignIn("google");
      },
    );
  }

  Widget _buildOrWidget() {
    return Container(
      margin: EdgeInsets.only(top: 20.h, bottom: 35.h),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              indent: 50,
              height: 2.h,
              color: AppColors.primarySecondaryElementText,
            ),
          ),
          const Text('  or  '),
          Expanded(
            child: Divider(
              endIndent: 50,
              height: 2.h,
              color: AppColors.primarySecondaryElementText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupWidget() {
    return GestureDetector(
      child: Column(
        children: [
          Text(
            'Already have an account',
            style: TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.normal,
                fontSize: 12.sp
            ),
          ),
          GestureDetector(
            child: Text(
              'Sign up here',
              style: TextStyle(
                  color: AppColors.weChatPrimaryElement,
                  fontWeight: FontWeight.normal,
                  fontSize: 12.sp
              ),
            ),
          ),

        ],
      ),
      onTap: () {
        print('...signup from here...');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primarySecondaryBackground,
      body: Center(
        child: Column(
          children: [
            _buildLogo(),
            _buildThirdPartyLogin('Google', 'google'),
            _buildThirdPartyLogin('Facebook', 'facebook'),
            _buildThirdPartyLogin('Apple', 'apple'),
            _buildOrWidget(),
            _buildThirdPartyLogin('Phone Number', ''),
            SizedBox(height: 35.h,),
            _buildSignupWidget(),
          ],
        ),
      ),
    );
  }
}
