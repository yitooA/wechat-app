
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wechat/common/entities/entities.dart';
import 'package:wechat/common/values/colors.dart';

import '../../../../common/values/server.dart';

Widget ChatLeftList(Msgcontent item) {
  var imagePath;
  if(item.type == 'image') {
    imagePath = item.content?.replaceAll('http://localhost/', SERVER_API_URL);
  }
  return Container(
    padding: EdgeInsets.symmetric(vertical: 10.w, horizontal: 20.w),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 250.w,
            minHeight: 40.w,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                  padding: EdgeInsets.only(
                      top: 10.w,
                      bottom: 10.w,
                      left: 10.w,
                      right: 10.w
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryElement,
                    borderRadius: BorderRadius.all(Radius.circular(5.w)),
                  ),
                  child: item.type == 'text' ? Text('${item.content}',
                    style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.primaryElementText
                    ),
                  ) :
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 90.w,
                    ),
                    child: GestureDetector(
                      child: CachedNetworkImage(
                        imageUrl: imagePath!,
                      ),
                      onTap: () {

                      },
                    ),
                  )
              ),
            ],
          ),
        ),
      ],
    ),
  );
}