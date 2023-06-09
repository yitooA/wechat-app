
import 'package:get/get.dart';

class VideoCallState {
  RxBool isReadyPreview = false.obs;
  RxBool isJoined = false.obs;
  RxBool isShowAvatar = true.obs;
  RxBool switchCameras = true.obs;
  RxBool switchview = true.obs;
  RxBool switchRender = true.obs;
  RxSet<int> remoteUid = <int>{}.obs;
  RxInt onremoteUid = 0.obs;
  RxString call_time_num = "not connected".obs;
  RxString call_time = "00:00".obs;
  var doc_id = "".obs;
  var channelId = "".obs;

  var to_token = "".obs;
  var to_name = "".obs;
  var to_avatar = "".obs;
  var call_role = "audience".obs;
}
