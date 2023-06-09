import '../entities/contact.dart';
import '../utils/http.dart';

class NearbyAPI {
  static Future<ContactResponseEntity> getContactsByTokens(List<String> tokens) async {
    var response = await HttpUtil().post(
      'api/get_users_by_tokens',
      data: {'tokens': tokens},
    );
    return ContactResponseEntity.fromJson(response);
  }
}
