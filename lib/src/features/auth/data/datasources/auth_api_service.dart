import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'auth_api_service.g.dart';

@RestApi(baseUrl: 'https://identitytoolkit.googleapis.com/v1/')
abstract class AuthApiService {
  factory AuthApiService(Dio dio, {String baseUrl}) = _AuthApiService;

  @POST('accounts:signUp')
  Future<dynamic> signUp(
    @Body() Map<String, dynamic> body,
    @Query('key') String apiKey,
  );

  @POST('accounts:signInWithPassword')
  Future<dynamic> signIn(
    @Body() Map<String, dynamic> body,
    @Query('key') String apiKey,
  );

  @POST('accounts:createAuthUri')
  Future<dynamic> createAuthUri(
    @Body() Map<String, dynamic> body,
    @Query('key') String apiKey,
  );
}
