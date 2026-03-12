import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'todo_api_service.g.dart';

@RestApi()
abstract class TodoApiService {
  factory TodoApiService(Dio dio, {String? baseUrl}) = _TodoApiService;

  @GET('users/{userId}/todos.json')
  Future<dynamic> fetchTodos(
    @Path('userId') String userId,
    @Query('auth') String idToken,
  );

  @POST('users/{userId}/todos.json')
  Future<dynamic> createTodo(
    @Path('userId') String userId,
    @Body() Map<String, dynamic> body,
    @Query('auth') String idToken,
  );

  @PATCH('users/{userId}/todos/{todoId}.json')
  Future<void> updateTodo(
    @Path('userId') String userId,
    @Path('todoId') String todoId,
    @Body() Map<String, dynamic> body,
    @Query('auth') String idToken,
  );

  @DELETE('users/{userId}/todos/{todoId}.json')
  Future<void> deleteTodo(
    @Path('userId') String userId,
    @Path('todoId') String todoId,
    @Query('auth') String idToken,
  );
}
