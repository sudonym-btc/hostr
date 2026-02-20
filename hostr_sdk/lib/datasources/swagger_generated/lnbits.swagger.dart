// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element_parameter

import 'package:json_annotation/json_annotation.dart';
import 'package:json_annotation/json_annotation.dart' as json;
import 'package:collection/collection.dart';
import 'dart:convert';

import 'package:chopper/chopper.dart';

import 'client_mapping.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http/http.dart' show MultipartFile;
import 'package:chopper/chopper.dart' as chopper;
import 'lnbits.enums.swagger.dart' as enums;
import 'lnbits.metadata.swagger.dart';
export 'lnbits.enums.swagger.dart';

part 'lnbits.swagger.chopper.dart';
part 'lnbits.swagger.g.dart';

// **************************************************************************
// SwaggerChopperGenerator
// **************************************************************************

@ChopperApi()
abstract class Lnbits extends ChopperService {
  static Lnbits create({
    ChopperClient? client,
    http.Client? httpClient,
    Authenticator? authenticator,
    ErrorConverter? errorConverter,
    Converter? converter,
    Uri? baseUrl,
    List<Interceptor>? interceptors,
  }) {
    if (client != null) {
      return _$Lnbits(client);
    }

    final newClient = ChopperClient(
      services: [_$Lnbits()],
      converter: converter ?? $JsonSerializableConverter(),
      interceptors: interceptors ?? [],
      client: httpClient,
      authenticator: authenticator,
      errorConverter: errorConverter,
      baseUrl: baseUrl ?? Uri.parse('http://'),
    );
    return _$Lnbits(newClient);
  }

  ///Get Auth User
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<User>> apiV1AuthGet({String? usr}) {
    generatedMapping.putIfAbsent(User, () => User.fromJsonFactory);

    return _apiV1AuthGet(usr: usr);
  }

  ///Get Auth User
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/api/v1/auth')
  Future<chopper.Response<User>> _apiV1AuthGet({
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get the authenticated user',
      summary: 'Get Auth User',
      operationId: 'get_auth_user_api_v1_auth_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Auth"],
      deprecated: false,
    ),
  });

  ///Login
  Future<chopper.Response> apiV1AuthPost({
    required LoginUsernamePassword? body,
  }) {
    return _apiV1AuthPost(body: body);
  }

  ///Login
  @POST(path: '/api/v1/auth', optionalBody: true)
  Future<chopper.Response> _apiV1AuthPost({
    @Body() required LoginUsernamePassword? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Login via the username and password',
      summary: 'Login',
      operationId: 'login_api_v1_auth_post',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Auth"],
      deprecated: false,
    ),
  });

  ///Nostr Login
  Future<chopper.Response> apiV1AuthNostrPost() {
    return _apiV1AuthNostrPost();
  }

  ///Nostr Login
  @POST(path: '/api/v1/auth/nostr', optionalBody: true)
  Future<chopper.Response> _apiV1AuthNostrPost({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Login via Nostr',
      summary: 'Nostr Login',
      operationId: 'nostr_login_api_v1_auth_nostr_post',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Auth"],
      deprecated: false,
    ),
  });

  ///Login Usr
  Future<chopper.Response> apiV1AuthUsrPost({required LoginUsr? body}) {
    return _apiV1AuthUsrPost(body: body);
  }

  ///Login Usr
  @POST(path: '/api/v1/auth/usr', optionalBody: true)
  Future<chopper.Response> _apiV1AuthUsrPost({
    @Body() required LoginUsr? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Login via the User ID',
      summary: 'Login Usr',
      operationId: 'login_usr_api_v1_auth_usr_post',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Auth"],
      deprecated: false,
    ),
  });

  ///Api Get User Acls
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<UserAcls>> apiV1AuthAclGet({String? usr}) {
    generatedMapping.putIfAbsent(UserAcls, () => UserAcls.fromJsonFactory);

    return _apiV1AuthAclGet(usr: usr);
  }

  ///Api Get User Acls
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/api/v1/auth/acl')
  Future<chopper.Response<UserAcls>> _apiV1AuthAclGet({
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Get User Acls',
      operationId: 'api_get_user_acls_api_v1_auth_acl_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Auth"],
      deprecated: false,
    ),
  });

  ///Api Update User Acl
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<UserAcls>> apiV1AuthAclPut({
    String? usr,
    required UpdateAccessControlList? body,
  }) {
    generatedMapping.putIfAbsent(UserAcls, () => UserAcls.fromJsonFactory);

    return _apiV1AuthAclPut(usr: usr, body: body);
  }

  ///Api Update User Acl
  ///@param usr
  ///@param cookie_access_token
  @PUT(path: '/api/v1/auth/acl', optionalBody: true)
  Future<chopper.Response<UserAcls>> _apiV1AuthAclPut({
    @Query('usr') String? usr,
    @Body() required UpdateAccessControlList? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Update User Acl',
      operationId: 'api_update_user_acl_api_v1_auth_acl_put',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Auth"],
      deprecated: false,
    ),
  });

  ///Api Delete User Acl
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response> apiV1AuthAclDelete({
    String? usr,
    required DeleteAccessControlList? body,
  }) {
    return _apiV1AuthAclDelete(usr: usr, body: body);
  }

  ///Api Delete User Acl
  ///@param usr
  ///@param cookie_access_token
  @DELETE(path: '/api/v1/auth/acl')
  Future<chopper.Response> _apiV1AuthAclDelete({
    @Query('usr') String? usr,
    @Body() required DeleteAccessControlList? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Delete User Acl',
      operationId: 'api_delete_user_acl_api_v1_auth_acl_delete',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Auth"],
      deprecated: false,
    ),
  });

  ///Api Update User Acl
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<UserAcls>> apiV1AuthAclPatch({
    String? usr,
    required UpdateAccessControlList? body,
  }) {
    generatedMapping.putIfAbsent(UserAcls, () => UserAcls.fromJsonFactory);

    return _apiV1AuthAclPatch(usr: usr, body: body);
  }

  ///Api Update User Acl
  ///@param usr
  ///@param cookie_access_token
  @PATCH(path: '/api/v1/auth/acl', optionalBody: true)
  Future<chopper.Response<UserAcls>> _apiV1AuthAclPatch({
    @Query('usr') String? usr,
    @Body() required UpdateAccessControlList? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Update User Acl',
      operationId: 'api_update_user_acl_api_v1_auth_acl_patch',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Auth"],
      deprecated: false,
    ),
  });

  ///Api Create User Api Token
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<ApiTokenResponse>> apiV1AuthAclTokenPost({
    String? usr,
    required ApiTokenRequest? body,
  }) {
    generatedMapping.putIfAbsent(
      ApiTokenResponse,
      () => ApiTokenResponse.fromJsonFactory,
    );

    return _apiV1AuthAclTokenPost(usr: usr, body: body);
  }

  ///Api Create User Api Token
  ///@param usr
  ///@param cookie_access_token
  @POST(path: '/api/v1/auth/acl/token', optionalBody: true)
  Future<chopper.Response<ApiTokenResponse>> _apiV1AuthAclTokenPost({
    @Query('usr') String? usr,
    @Body() required ApiTokenRequest? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Create User Api Token',
      operationId: 'api_create_user_api_token_api_v1_auth_acl_token_post',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Auth"],
      deprecated: false,
    ),
  });

  ///Api Delete User Api Token
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response> apiV1AuthAclTokenDelete({
    String? usr,
    required DeleteTokenRequest? body,
  }) {
    return _apiV1AuthAclTokenDelete(usr: usr, body: body);
  }

  ///Api Delete User Api Token
  ///@param usr
  ///@param cookie_access_token
  @DELETE(path: '/api/v1/auth/acl/token')
  Future<chopper.Response> _apiV1AuthAclTokenDelete({
    @Query('usr') String? usr,
    @Body() required DeleteTokenRequest? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Delete User Api Token',
      operationId: 'api_delete_user_api_token_api_v1_auth_acl_token_delete',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Auth"],
      deprecated: false,
    ),
  });

  ///Login With Sso Provider
  ///@param provider
  ///@param user_id
  Future<chopper.Response> apiV1AuthProviderGet({
    required String? provider,
    String? userId,
  }) {
    return _apiV1AuthProviderGet(provider: provider, userId: userId);
  }

  ///Login With Sso Provider
  ///@param provider
  ///@param user_id
  @GET(path: '/api/v1/auth/{provider}')
  Future<chopper.Response> _apiV1AuthProviderGet({
    @Path('provider') required String? provider,
    @Query('user_id') String? userId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'SSO Provider',
      summary: 'Login With Sso Provider',
      operationId: 'login_with_sso_provider_api_v1_auth__provider__get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Auth"],
      deprecated: false,
    ),
  });

  ///Handle Oauth Token
  ///@param provider
  Future<chopper.Response> apiV1AuthProviderTokenGet({
    required String? provider,
  }) {
    return _apiV1AuthProviderTokenGet(provider: provider);
  }

  ///Handle Oauth Token
  ///@param provider
  @GET(path: '/api/v1/auth/{provider}/token')
  Future<chopper.Response> _apiV1AuthProviderTokenGet({
    @Path('provider') required String? provider,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Handle OAuth callback',
      summary: 'Handle Oauth Token',
      operationId: 'handle_oauth_token_api_v1_auth__provider__token_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Auth"],
      deprecated: false,
    ),
  });

  ///Logout
  Future<chopper.Response> apiV1AuthLogoutPost() {
    return _apiV1AuthLogoutPost();
  }

  ///Logout
  @POST(path: '/api/v1/auth/logout', optionalBody: true)
  Future<chopper.Response> _apiV1AuthLogoutPost({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Logout',
      operationId: 'logout_api_v1_auth_logout_post',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Auth"],
      deprecated: false,
    ),
  });

  ///Register
  Future<chopper.Response> apiV1AuthRegisterPost({
    required RegisterUser? body,
  }) {
    return _apiV1AuthRegisterPost(body: body);
  }

  ///Register
  @POST(path: '/api/v1/auth/register', optionalBody: true)
  Future<chopper.Response> _apiV1AuthRegisterPost({
    @Body() required RegisterUser? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Register',
      operationId: 'register_api_v1_auth_register_post',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Auth"],
      deprecated: false,
    ),
  });

  ///Update Pubkey
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<User>> apiV1AuthPubkeyPut({
    String? usr,
    required UpdateUserPubkey? body,
  }) {
    generatedMapping.putIfAbsent(User, () => User.fromJsonFactory);

    return _apiV1AuthPubkeyPut(usr: usr, body: body);
  }

  ///Update Pubkey
  ///@param usr
  ///@param cookie_access_token
  @PUT(path: '/api/v1/auth/pubkey', optionalBody: true)
  Future<chopper.Response<User>> _apiV1AuthPubkeyPut({
    @Query('usr') String? usr,
    @Body() required UpdateUserPubkey? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Update Pubkey',
      operationId: 'update_pubkey_api_v1_auth_pubkey_put',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Auth"],
      deprecated: false,
    ),
  });

  ///Update Password
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<User>> apiV1AuthPasswordPut({
    String? usr,
    required UpdateUserPassword? body,
  }) {
    generatedMapping.putIfAbsent(User, () => User.fromJsonFactory);

    return _apiV1AuthPasswordPut(usr: usr, body: body);
  }

  ///Update Password
  ///@param usr
  ///@param cookie_access_token
  @PUT(path: '/api/v1/auth/password', optionalBody: true)
  Future<chopper.Response<User>> _apiV1AuthPasswordPut({
    @Query('usr') String? usr,
    @Body() required UpdateUserPassword? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Update Password',
      operationId: 'update_password_api_v1_auth_password_put',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Auth"],
      deprecated: false,
    ),
  });

  ///Reset Password
  Future<chopper.Response> apiV1AuthResetPut({
    required ResetUserPassword? body,
  }) {
    return _apiV1AuthResetPut(body: body);
  }

  ///Reset Password
  @PUT(path: '/api/v1/auth/reset', optionalBody: true)
  Future<chopper.Response> _apiV1AuthResetPut({
    @Body() required ResetUserPassword? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Reset Password',
      operationId: 'reset_password_api_v1_auth_reset_put',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Auth"],
      deprecated: false,
    ),
  });

  ///Update
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<User>> apiV1AuthUpdatePut({
    String? usr,
    required UpdateUser? body,
  }) {
    generatedMapping.putIfAbsent(User, () => User.fromJsonFactory);

    return _apiV1AuthUpdatePut(usr: usr, body: body);
  }

  ///Update
  ///@param usr
  ///@param cookie_access_token
  @PUT(path: '/api/v1/auth/update', optionalBody: true)
  Future<chopper.Response<User>> _apiV1AuthUpdatePut({
    @Query('usr') String? usr,
    @Body() required UpdateUser? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Update',
      operationId: 'update_api_v1_auth_update_put',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Auth"],
      deprecated: false,
    ),
  });

  ///First Install
  Future<chopper.Response> apiV1AuthFirstInstallPut({
    required UpdateSuperuserPassword? body,
  }) {
    return _apiV1AuthFirstInstallPut(body: body);
  }

  ///First Install
  @PUT(path: '/api/v1/auth/first_install', optionalBody: true)
  Future<chopper.Response> _apiV1AuthFirstInstallPut({
    @Body() required UpdateSuperuserPassword? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'First Install',
      operationId: 'first_install_api_v1_auth_first_install_put',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Auth"],
      deprecated: false,
    ),
  });

  ///Audit
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response> adminApiV1AuditGet({String? usr}) {
    return _adminApiV1AuditGet(usr: usr);
  }

  ///Audit
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/admin/api/v1/audit')
  Future<chopper.Response> _adminApiV1AuditGet({
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'show the current balance of the node and the LNbits database',
      summary: 'Audit',
      operationId: 'Audit_admin_api_v1_audit_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Admin UI"],
      deprecated: false,
    ),
  });

  ///Monitor
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response> adminApiV1MonitorGet({String? usr}) {
    return _adminApiV1MonitorGet(usr: usr);
  }

  ///Monitor
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/admin/api/v1/monitor')
  Future<chopper.Response> _adminApiV1MonitorGet({
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'show the current listeners and other monitoring data',
      summary: 'Monitor',
      operationId: 'Monitor_admin_api_v1_monitor_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Admin UI"],
      deprecated: false,
    ),
  });

  ///Testemail
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response> adminApiV1TestemailGet({String? usr}) {
    return _adminApiV1TestemailGet(usr: usr);
  }

  ///Testemail
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/admin/api/v1/testemail')
  Future<chopper.Response> _adminApiV1TestemailGet({
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'send a test email to the admin',
      summary: 'Testemail',
      operationId: 'TestEmail_admin_api_v1_testemail_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Admin UI"],
      deprecated: false,
    ),
  });

  ///Api Get Settings
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<AdminSettings>> adminApiV1SettingsGet({String? usr}) {
    generatedMapping.putIfAbsent(
      AdminSettings,
      () => AdminSettings.fromJsonFactory,
    );

    return _adminApiV1SettingsGet(usr: usr);
  }

  ///Api Get Settings
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/admin/api/v1/settings')
  Future<chopper.Response<AdminSettings>> _adminApiV1SettingsGet({
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Get Settings',
      operationId: 'api_get_settings_admin_api_v1_settings_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Admin UI"],
      deprecated: false,
    ),
  });

  ///Api Update Settings
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response> adminApiV1SettingsPut({
    String? usr,
    required UpdateSettings? body,
  }) {
    return _adminApiV1SettingsPut(usr: usr, body: body);
  }

  ///Api Update Settings
  ///@param usr
  ///@param cookie_access_token
  @PUT(path: '/admin/api/v1/settings', optionalBody: true)
  Future<chopper.Response> _adminApiV1SettingsPut({
    @Query('usr') String? usr,
    @Body() required UpdateSettings? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Update Settings',
      operationId: 'api_update_settings_admin_api_v1_settings_put',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Admin UI"],
      deprecated: false,
    ),
  });

  ///Api Delete Settings
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response> adminApiV1SettingsDelete({String? usr}) {
    return _adminApiV1SettingsDelete(usr: usr);
  }

  ///Api Delete Settings
  ///@param usr
  ///@param cookie_access_token
  @DELETE(path: '/admin/api/v1/settings')
  Future<chopper.Response> _adminApiV1SettingsDelete({
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Delete Settings',
      operationId: 'api_delete_settings_admin_api_v1_settings_delete',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Admin UI"],
      deprecated: false,
    ),
  });

  ///Api Update Settings Partial
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response> adminApiV1SettingsPatch({
    String? usr,
    required Object? body,
  }) {
    return _adminApiV1SettingsPatch(usr: usr, body: body);
  }

  ///Api Update Settings Partial
  ///@param usr
  ///@param cookie_access_token
  @PATCH(path: '/admin/api/v1/settings', optionalBody: true)
  Future<chopper.Response> _adminApiV1SettingsPatch({
    @Query('usr') String? usr,
    @Body() required Object? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Update Settings Partial',
      operationId: 'api_update_settings_partial_admin_api_v1_settings_patch',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Admin UI"],
      deprecated: false,
    ),
  });

  ///Api Reset Settings
  ///@param field_name
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response> adminApiV1SettingsDefaultGet({
    required String? fieldName,
    String? usr,
  }) {
    return _adminApiV1SettingsDefaultGet(fieldName: fieldName, usr: usr);
  }

  ///Api Reset Settings
  ///@param field_name
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/admin/api/v1/settings/default')
  Future<chopper.Response> _adminApiV1SettingsDefaultGet({
    @Query('field_name') required String? fieldName,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Reset Settings',
      operationId: 'api_reset_settings_admin_api_v1_settings_default_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Admin UI"],
      deprecated: false,
    ),
  });

  ///Api Restart Server
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<Object>> adminApiV1RestartGet({String? usr}) {
    return _adminApiV1RestartGet(usr: usr);
  }

  ///Api Restart Server
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/admin/api/v1/restart')
  Future<chopper.Response<Object>> _adminApiV1RestartGet({
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Restart Server',
      operationId: 'api_restart_server_admin_api_v1_restart_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Admin UI"],
      deprecated: false,
    ),
  });

  ///Api Download Backup
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response> adminApiV1BackupGet({String? usr}) {
    return _adminApiV1BackupGet(usr: usr);
  }

  ///Api Download Backup
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/admin/api/v1/backup')
  Future<chopper.Response> _adminApiV1BackupGet({
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Download Backup',
      operationId: 'api_download_backup_admin_api_v1_backup_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Admin UI"],
      deprecated: false,
    ),
  });

  ///Api Get Ok
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response> nodeApiV1OkGet({String? usr}) {
    return _nodeApiV1OkGet(usr: usr);
  }

  ///Api Get Ok
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/node/api/v1/ok')
  Future<chopper.Response> _nodeApiV1OkGet({
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Check if node api can be enabled',
      summary: 'Api Get Ok',
      operationId: 'api_get_ok_node_api_v1_ok_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Node Managment"],
      deprecated: false,
    ),
  });

  ///Api Get Info
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<NodeInfoResponse>> nodeApiV1InfoGet({String? usr}) {
    generatedMapping.putIfAbsent(
      NodeInfoResponse,
      () => NodeInfoResponse.fromJsonFactory,
    );

    return _nodeApiV1InfoGet(usr: usr);
  }

  ///Api Get Info
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/node/api/v1/info')
  Future<chopper.Response<NodeInfoResponse>> _nodeApiV1InfoGet({
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Get Info',
      operationId: 'api_get_info_node_api_v1_info_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Node Managment"],
      deprecated: false,
    ),
  });

  ///Api Get Channels
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<List<NodeChannel>>> nodeApiV1ChannelsGet({
    String? usr,
  }) {
    generatedMapping.putIfAbsent(
      NodeChannel,
      () => NodeChannel.fromJsonFactory,
    );

    return _nodeApiV1ChannelsGet(usr: usr);
  }

  ///Api Get Channels
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/node/api/v1/channels')
  Future<chopper.Response<List<NodeChannel>>> _nodeApiV1ChannelsGet({
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Get Channels',
      operationId: 'api_get_channels_node_api_v1_channels_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Node Managment"],
      deprecated: false,
    ),
  });

  ///Api Create Channel
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<ChannelPoint>> nodeApiV1ChannelsPost({
    String? usr,
    required BodyApiCreateChannelNodeApiV1ChannelsPost? body,
  }) {
    generatedMapping.putIfAbsent(
      ChannelPoint,
      () => ChannelPoint.fromJsonFactory,
    );

    return _nodeApiV1ChannelsPost(usr: usr, body: body);
  }

  ///Api Create Channel
  ///@param usr
  ///@param cookie_access_token
  @POST(path: '/node/api/v1/channels', optionalBody: true)
  Future<chopper.Response<ChannelPoint>> _nodeApiV1ChannelsPost({
    @Query('usr') String? usr,
    @Body() required BodyApiCreateChannelNodeApiV1ChannelsPost? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Create Channel',
      operationId: 'api_create_channel_node_api_v1_channels_post',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Node Managment"],
      deprecated: false,
    ),
  });

  ///Api Delete Channel
  ///@param short_id
  ///@param funding_txid
  ///@param output_index
  ///@param force
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<List<NodeChannel>>> nodeApiV1ChannelsDelete({
    required String? shortId,
    required String? fundingTxid,
    required int? outputIndex,
    bool? force,
    String? usr,
  }) {
    generatedMapping.putIfAbsent(
      NodeChannel,
      () => NodeChannel.fromJsonFactory,
    );

    return _nodeApiV1ChannelsDelete(
      shortId: shortId,
      fundingTxid: fundingTxid,
      outputIndex: outputIndex,
      force: force,
      usr: usr,
    );
  }

  ///Api Delete Channel
  ///@param short_id
  ///@param funding_txid
  ///@param output_index
  ///@param force
  ///@param usr
  ///@param cookie_access_token
  @DELETE(path: '/node/api/v1/channels')
  Future<chopper.Response<List<NodeChannel>>> _nodeApiV1ChannelsDelete({
    @Query('short_id') required String? shortId,
    @Query('funding_txid') required String? fundingTxid,
    @Query('output_index') required int? outputIndex,
    @Query('force') bool? force,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Delete Channel',
      operationId: 'api_delete_channel_node_api_v1_channels_delete',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Node Managment"],
      deprecated: false,
    ),
  });

  ///Api Get Channel
  ///@param channel_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<NodeChannel>> nodeApiV1ChannelsChannelIdGet({
    required String? channelId,
    String? usr,
  }) {
    generatedMapping.putIfAbsent(
      NodeChannel,
      () => NodeChannel.fromJsonFactory,
    );

    return _nodeApiV1ChannelsChannelIdGet(channelId: channelId, usr: usr);
  }

  ///Api Get Channel
  ///@param channel_id
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/node/api/v1/channels/{channel_id}')
  Future<chopper.Response<NodeChannel>> _nodeApiV1ChannelsChannelIdGet({
    @Path('channel_id') required String? channelId,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Get Channel',
      operationId: 'api_get_channel_node_api_v1_channels__channel_id__get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Node Managment"],
      deprecated: false,
    ),
  });

  ///Api Set Channel Fees
  ///@param channel_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response> nodeApiV1ChannelsChannelIdPut({
    required String? channelId,
    String? usr,
    required BodyApiSetChannelFeesNodeApiV1ChannelsChannelIdPut? body,
  }) {
    return _nodeApiV1ChannelsChannelIdPut(
      channelId: channelId,
      usr: usr,
      body: body,
    );
  }

  ///Api Set Channel Fees
  ///@param channel_id
  ///@param usr
  ///@param cookie_access_token
  @PUT(path: '/node/api/v1/channels/{channel_id}', optionalBody: true)
  Future<chopper.Response> _nodeApiV1ChannelsChannelIdPut({
    @Path('channel_id') required String? channelId,
    @Query('usr') String? usr,
    @Body() required BodyApiSetChannelFeesNodeApiV1ChannelsChannelIdPut? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Set Channel Fees',
      operationId: 'api_set_channel_fees_node_api_v1_channels__channel_id__put',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Node Managment"],
      deprecated: false,
    ),
  });

  ///Api Get Payments
  ///@param usr
  ///@param limit
  ///@param offset
  ///@param sortby
  ///@param direction
  ///@param search Text based search
  ///@param cookie_access_token
  Future<chopper.Response<Page>> nodeApiV1PaymentsGet({
    String? usr,
    int? limit,
    int? offset,
    String? sortby,
    enums.NodeApiV1PaymentsGetDirection? direction,
    String? search,
  }) {
    generatedMapping.putIfAbsent(Page, () => Page.fromJsonFactory);

    return _nodeApiV1PaymentsGet(
      usr: usr,
      limit: limit,
      offset: offset,
      sortby: sortby,
      direction: direction?.value?.toString(),
      search: search,
    );
  }

  ///Api Get Payments
  ///@param usr
  ///@param limit
  ///@param offset
  ///@param sortby
  ///@param direction
  ///@param search Text based search
  ///@param cookie_access_token
  @GET(path: '/node/api/v1/payments')
  Future<chopper.Response<Page>> _nodeApiV1PaymentsGet({
    @Query('usr') String? usr,
    @Query('limit') int? limit,
    @Query('offset') int? offset,
    @Query('sortby') String? sortby,
    @Query('direction') String? direction,
    @Query('search') String? search,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Get Payments',
      operationId: 'api_get_payments_node_api_v1_payments_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Node Managment"],
      deprecated: false,
    ),
  });

  ///Api Get Invoices
  ///@param usr
  ///@param limit
  ///@param offset
  ///@param sortby
  ///@param direction
  ///@param search Text based search
  ///@param cookie_access_token
  Future<chopper.Response<Page>> nodeApiV1InvoicesGet({
    String? usr,
    int? limit,
    int? offset,
    String? sortby,
    enums.NodeApiV1InvoicesGetDirection? direction,
    String? search,
  }) {
    generatedMapping.putIfAbsent(Page, () => Page.fromJsonFactory);

    return _nodeApiV1InvoicesGet(
      usr: usr,
      limit: limit,
      offset: offset,
      sortby: sortby,
      direction: direction?.value?.toString(),
      search: search,
    );
  }

  ///Api Get Invoices
  ///@param usr
  ///@param limit
  ///@param offset
  ///@param sortby
  ///@param direction
  ///@param search Text based search
  ///@param cookie_access_token
  @GET(path: '/node/api/v1/invoices')
  Future<chopper.Response<Page>> _nodeApiV1InvoicesGet({
    @Query('usr') String? usr,
    @Query('limit') int? limit,
    @Query('offset') int? offset,
    @Query('sortby') String? sortby,
    @Query('direction') String? direction,
    @Query('search') String? search,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Get Invoices',
      operationId: 'api_get_invoices_node_api_v1_invoices_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Node Managment"],
      deprecated: false,
    ),
  });

  ///Api Get Peers
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<List<NodePeerInfo>>> nodeApiV1PeersGet({
    String? usr,
  }) {
    generatedMapping.putIfAbsent(
      NodePeerInfo,
      () => NodePeerInfo.fromJsonFactory,
    );

    return _nodeApiV1PeersGet(usr: usr);
  }

  ///Api Get Peers
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/node/api/v1/peers')
  Future<chopper.Response<List<NodePeerInfo>>> _nodeApiV1PeersGet({
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Get Peers',
      operationId: 'api_get_peers_node_api_v1_peers_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Node Managment"],
      deprecated: false,
    ),
  });

  ///Api Connect Peer
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response> nodeApiV1PeersPost({
    String? usr,
    required BodyApiConnectPeerNodeApiV1PeersPost? body,
  }) {
    return _nodeApiV1PeersPost(usr: usr, body: body);
  }

  ///Api Connect Peer
  ///@param usr
  ///@param cookie_access_token
  @POST(path: '/node/api/v1/peers', optionalBody: true)
  Future<chopper.Response> _nodeApiV1PeersPost({
    @Query('usr') String? usr,
    @Body() required BodyApiConnectPeerNodeApiV1PeersPost? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Connect Peer',
      operationId: 'api_connect_peer_node_api_v1_peers_post',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Node Managment"],
      deprecated: false,
    ),
  });

  ///Api Get 1Ml Stats
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<NodeRank>> nodeApiV1RankGet({String? usr}) {
    generatedMapping.putIfAbsent(NodeRank, () => NodeRank.fromJsonFactory);

    return _nodeApiV1RankGet(usr: usr);
  }

  ///Api Get 1Ml Stats
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/node/api/v1/rank')
  Future<chopper.Response<NodeRank>> _nodeApiV1RankGet({
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Retrieve node ranks from https://1ml.com',
      summary: 'Api Get 1Ml Stats',
      operationId: 'api_get_1ml_stats_node_api_v1_rank_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Node Managment"],
      deprecated: false,
    ),
  });

  ///Api Get User Extensions
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<List<Extension>>> apiV1ExtensionGet({String? usr}) {
    generatedMapping.putIfAbsent(Extension, () => Extension.fromJsonFactory);

    return _apiV1ExtensionGet(usr: usr);
  }

  ///Api Get User Extensions
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/api/v1/extension')
  Future<chopper.Response<List<Extension>>> _apiV1ExtensionGet({
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Get User Extensions',
      operationId: 'api_get_user_extensions_api_v1_extension_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Extension Managment"],
      deprecated: false,
    ),
  });

  ///Api Install Extension
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response> apiV1ExtensionPost({
    String? usr,
    required CreateExtension? body,
  }) {
    return _apiV1ExtensionPost(usr: usr, body: body);
  }

  ///Api Install Extension
  ///@param usr
  ///@param cookie_access_token
  @POST(path: '/api/v1/extension', optionalBody: true)
  Future<chopper.Response> _apiV1ExtensionPost({
    @Query('usr') String? usr,
    @Body() required CreateExtension? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Install Extension',
      operationId: 'api_install_extension_api_v1_extension_post',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Extension Managment"],
      deprecated: false,
    ),
  });

  ///Api Extension Details
  ///@param ext_id
  ///@param details_link
  Future<chopper.Response> apiV1ExtensionExtIdDetailsGet({
    required String? extId,
    required String? detailsLink,
  }) {
    return _apiV1ExtensionExtIdDetailsGet(
      extId: extId,
      detailsLink: detailsLink,
    );
  }

  ///Api Extension Details
  ///@param ext_id
  ///@param details_link
  @GET(path: '/api/v1/extension/{ext_id}/details')
  Future<chopper.Response> _apiV1ExtensionExtIdDetailsGet({
    @Path('ext_id') required String? extId,
    @Query('details_link') required String? detailsLink,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Extension Details',
      operationId:
          'api_extension_details_api_v1_extension__ext_id__details_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Extension Managment"],
      deprecated: false,
    ),
  });

  ///Api Update Pay To Enable
  ///@param ext_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<SimpleStatus>> apiV1ExtensionExtIdSellPut({
    required String? extId,
    String? usr,
    required PayToEnableInfo? body,
  }) {
    generatedMapping.putIfAbsent(
      SimpleStatus,
      () => SimpleStatus.fromJsonFactory,
    );

    return _apiV1ExtensionExtIdSellPut(extId: extId, usr: usr, body: body);
  }

  ///Api Update Pay To Enable
  ///@param ext_id
  ///@param usr
  ///@param cookie_access_token
  @PUT(path: '/api/v1/extension/{ext_id}/sell', optionalBody: true)
  Future<chopper.Response<SimpleStatus>> _apiV1ExtensionExtIdSellPut({
    @Path('ext_id') required String? extId,
    @Query('usr') String? usr,
    @Body() required PayToEnableInfo? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Update Pay To Enable',
      operationId:
          'api_update_pay_to_enable_api_v1_extension__ext_id__sell_put',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Extension Managment"],
      deprecated: false,
    ),
  });

  ///Api Enable Extension
  ///@param ext_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<SimpleStatus>> apiV1ExtensionExtIdEnablePut({
    required String? extId,
    String? usr,
  }) {
    generatedMapping.putIfAbsent(
      SimpleStatus,
      () => SimpleStatus.fromJsonFactory,
    );

    return _apiV1ExtensionExtIdEnablePut(extId: extId, usr: usr);
  }

  ///Api Enable Extension
  ///@param ext_id
  ///@param usr
  ///@param cookie_access_token
  @PUT(path: '/api/v1/extension/{ext_id}/enable', optionalBody: true)
  Future<chopper.Response<SimpleStatus>> _apiV1ExtensionExtIdEnablePut({
    @Path('ext_id') required String? extId,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Enable Extension',
      operationId: 'api_enable_extension_api_v1_extension__ext_id__enable_put',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Extension Managment"],
      deprecated: false,
    ),
  });

  ///Api Disable Extension
  ///@param ext_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<SimpleStatus>> apiV1ExtensionExtIdDisablePut({
    required String? extId,
    String? usr,
  }) {
    generatedMapping.putIfAbsent(
      SimpleStatus,
      () => SimpleStatus.fromJsonFactory,
    );

    return _apiV1ExtensionExtIdDisablePut(extId: extId, usr: usr);
  }

  ///Api Disable Extension
  ///@param ext_id
  ///@param usr
  ///@param cookie_access_token
  @PUT(path: '/api/v1/extension/{ext_id}/disable', optionalBody: true)
  Future<chopper.Response<SimpleStatus>> _apiV1ExtensionExtIdDisablePut({
    @Path('ext_id') required String? extId,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Disable Extension',
      operationId:
          'api_disable_extension_api_v1_extension__ext_id__disable_put',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Extension Managment"],
      deprecated: false,
    ),
  });

  ///Api Activate Extension
  ///@param ext_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<SimpleStatus>> apiV1ExtensionExtIdActivatePut({
    required String? extId,
    String? usr,
  }) {
    generatedMapping.putIfAbsent(
      SimpleStatus,
      () => SimpleStatus.fromJsonFactory,
    );

    return _apiV1ExtensionExtIdActivatePut(extId: extId, usr: usr);
  }

  ///Api Activate Extension
  ///@param ext_id
  ///@param usr
  ///@param cookie_access_token
  @PUT(path: '/api/v1/extension/{ext_id}/activate', optionalBody: true)
  Future<chopper.Response<SimpleStatus>> _apiV1ExtensionExtIdActivatePut({
    @Path('ext_id') required String? extId,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Activate Extension',
      operationId:
          'api_activate_extension_api_v1_extension__ext_id__activate_put',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Extension Managment"],
      deprecated: false,
    ),
  });

  ///Api Deactivate Extension
  ///@param ext_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<SimpleStatus>> apiV1ExtensionExtIdDeactivatePut({
    required String? extId,
    String? usr,
  }) {
    generatedMapping.putIfAbsent(
      SimpleStatus,
      () => SimpleStatus.fromJsonFactory,
    );

    return _apiV1ExtensionExtIdDeactivatePut(extId: extId, usr: usr);
  }

  ///Api Deactivate Extension
  ///@param ext_id
  ///@param usr
  ///@param cookie_access_token
  @PUT(path: '/api/v1/extension/{ext_id}/deactivate', optionalBody: true)
  Future<chopper.Response<SimpleStatus>> _apiV1ExtensionExtIdDeactivatePut({
    @Path('ext_id') required String? extId,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Deactivate Extension',
      operationId:
          'api_deactivate_extension_api_v1_extension__ext_id__deactivate_put',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Extension Managment"],
      deprecated: false,
    ),
  });

  ///Api Uninstall Extension
  ///@param ext_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<SimpleStatus>> apiV1ExtensionExtIdDelete({
    required String? extId,
    String? usr,
  }) {
    generatedMapping.putIfAbsent(
      SimpleStatus,
      () => SimpleStatus.fromJsonFactory,
    );

    return _apiV1ExtensionExtIdDelete(extId: extId, usr: usr);
  }

  ///Api Uninstall Extension
  ///@param ext_id
  ///@param usr
  ///@param cookie_access_token
  @DELETE(path: '/api/v1/extension/{ext_id}')
  Future<chopper.Response<SimpleStatus>> _apiV1ExtensionExtIdDelete({
    @Path('ext_id') required String? extId,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Uninstall Extension',
      operationId: 'api_uninstall_extension_api_v1_extension__ext_id__delete',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Extension Managment"],
      deprecated: false,
    ),
  });

  ///Get Extension Releases
  ///@param ext_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<List<ExtensionRelease>>>
  apiV1ExtensionExtIdReleasesGet({required String? extId, String? usr}) {
    generatedMapping.putIfAbsent(
      ExtensionRelease,
      () => ExtensionRelease.fromJsonFactory,
    );

    return _apiV1ExtensionExtIdReleasesGet(extId: extId, usr: usr);
  }

  ///Get Extension Releases
  ///@param ext_id
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/api/v1/extension/{ext_id}/releases')
  Future<chopper.Response<List<ExtensionRelease>>>
  _apiV1ExtensionExtIdReleasesGet({
    @Path('ext_id') required String? extId,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Extension Releases',
      operationId:
          'get_extension_releases_api_v1_extension__ext_id__releases_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Extension Managment"],
      deprecated: false,
    ),
  });

  ///Get Pay To Install Invoice
  ///@param ext_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<ReleasePaymentInfo>>
  apiV1ExtensionExtIdInvoiceInstallPut({
    required String? extId,
    String? usr,
    required CreateExtension? body,
  }) {
    generatedMapping.putIfAbsent(
      ReleasePaymentInfo,
      () => ReleasePaymentInfo.fromJsonFactory,
    );

    return _apiV1ExtensionExtIdInvoiceInstallPut(
      extId: extId,
      usr: usr,
      body: body,
    );
  }

  ///Get Pay To Install Invoice
  ///@param ext_id
  ///@param usr
  ///@param cookie_access_token
  @PUT(path: '/api/v1/extension/{ext_id}/invoice/install', optionalBody: true)
  Future<chopper.Response<ReleasePaymentInfo>>
  _apiV1ExtensionExtIdInvoiceInstallPut({
    @Path('ext_id') required String? extId,
    @Query('usr') String? usr,
    @Body() required CreateExtension? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Pay To Install Invoice',
      operationId:
          'get_pay_to_install_invoice_api_v1_extension__ext_id__invoice_install_put',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Extension Managment"],
      deprecated: false,
    ),
  });

  ///Get Pay To Enable Invoice
  ///@param ext_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response> apiV1ExtensionExtIdInvoiceEnablePut({
    required String? extId,
    String? usr,
    required PayToEnableInfo? body,
  }) {
    return _apiV1ExtensionExtIdInvoiceEnablePut(
      extId: extId,
      usr: usr,
      body: body,
    );
  }

  ///Get Pay To Enable Invoice
  ///@param ext_id
  ///@param usr
  ///@param cookie_access_token
  @PUT(path: '/api/v1/extension/{ext_id}/invoice/enable', optionalBody: true)
  Future<chopper.Response> _apiV1ExtensionExtIdInvoiceEnablePut({
    @Path('ext_id') required String? extId,
    @Query('usr') String? usr,
    @Body() required PayToEnableInfo? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Pay To Enable Invoice',
      operationId:
          'get_pay_to_enable_invoice_api_v1_extension__ext_id__invoice_enable_put',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Extension Managment"],
      deprecated: false,
    ),
  });

  ///Get Extension Release
  ///@param org
  ///@param repo
  ///@param tag_name
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response> apiV1ExtensionReleaseOrgRepoTagNameGet({
    required String? org,
    required String? repo,
    required String? tagName,
    String? usr,
  }) {
    return _apiV1ExtensionReleaseOrgRepoTagNameGet(
      org: org,
      repo: repo,
      tagName: tagName,
      usr: usr,
    );
  }

  ///Get Extension Release
  ///@param org
  ///@param repo
  ///@param tag_name
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/api/v1/extension/release/{org}/{repo}/{tag_name}')
  Future<chopper.Response> _apiV1ExtensionReleaseOrgRepoTagNameGet({
    @Path('org') required String? org,
    @Path('repo') required String? repo,
    @Path('tag_name') required String? tagName,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Extension Release',
      operationId:
          'get_extension_release_api_v1_extension_release__org___repo___tag_name__get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Extension Managment"],
      deprecated: false,
    ),
  });

  ///Delete Extension Db
  ///@param ext_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response> apiV1ExtensionExtIdDbDelete({
    required String? extId,
    String? usr,
  }) {
    return _apiV1ExtensionExtIdDbDelete(extId: extId, usr: usr);
  }

  ///Delete Extension Db
  ///@param ext_id
  ///@param usr
  ///@param cookie_access_token
  @DELETE(path: '/api/v1/extension/{ext_id}/db')
  Future<chopper.Response> _apiV1ExtensionExtIdDbDelete({
    @Path('ext_id') required String? extId,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Delete Extension Db',
      operationId: 'delete_extension_db_api_v1_extension__ext_id__db_delete',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Extension Managment"],
      deprecated: false,
    ),
  });

  ///Extensions
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response> apiV1ExtensionAllGet({String? usr}) {
    return _apiV1ExtensionAllGet(usr: usr);
  }

  ///Extensions
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/api/v1/extension/all')
  Future<chopper.Response> _apiV1ExtensionAllGet({
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Extensions',
      operationId: 'extensions_api_v1_extension_all_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Extension Managment"],
      deprecated: false,
    ),
  });

  ///Get Extension Reviews Tags
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<List<ExtensionReviewsStatus>>>
  apiV1ExtensionReviewsTagsGet({String? usr}) {
    generatedMapping.putIfAbsent(
      ExtensionReviewsStatus,
      () => ExtensionReviewsStatus.fromJsonFactory,
    );

    return _apiV1ExtensionReviewsTagsGet(usr: usr);
  }

  ///Get Extension Reviews Tags
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/api/v1/extension/reviews/tags')
  Future<chopper.Response<List<ExtensionReviewsStatus>>>
  _apiV1ExtensionReviewsTagsGet({
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Extension Reviews Tags',
      operationId:
          'get_extension_reviews_tags_api_v1_extension_reviews_tags_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Extension Managment"],
      deprecated: false,
    ),
  });

  ///Get Extension Reviews
  ///@param ext_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<Page>> apiV1ExtensionReviewsExtIdGet({
    required String? extId,
    String? usr,
  }) {
    generatedMapping.putIfAbsent(Page, () => Page.fromJsonFactory);

    return _apiV1ExtensionReviewsExtIdGet(extId: extId, usr: usr);
  }

  ///Get Extension Reviews
  ///@param ext_id
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/api/v1/extension/reviews/{ext_id}')
  Future<chopper.Response<Page>> _apiV1ExtensionReviewsExtIdGet({
    @Path('ext_id') required String? extId,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Extension Reviews',
      operationId:
          'get_extension_reviews_api_v1_extension_reviews__ext_id__get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Extension Managment"],
      deprecated: false,
    ),
  });

  ///Create Extension Review
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<ExtensionReviewPaymentRequest>>
  apiV1ExtensionReviewsPut({
    String? usr,
    required CreateExtensionReview? body,
  }) {
    generatedMapping.putIfAbsent(
      ExtensionReviewPaymentRequest,
      () => ExtensionReviewPaymentRequest.fromJsonFactory,
    );

    return _apiV1ExtensionReviewsPut(usr: usr, body: body);
  }

  ///Create Extension Review
  ///@param usr
  ///@param cookie_access_token
  @PUT(path: '/api/v1/extension/reviews', optionalBody: true)
  Future<chopper.Response<ExtensionReviewPaymentRequest>>
  _apiV1ExtensionReviewsPut({
    @Query('usr') String? usr,
    @Body() required CreateExtensionReview? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Create Extension Review',
      operationId: 'create_extension_review_api_v1_extension_reviews_put',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Extension Managment"],
      deprecated: false,
    ),
  });

  ///Build and download extension zip.
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response> apiV1ExtensionBuilderZipPost({
    String? usr,
    required ExtensionData? body,
  }) {
    return _apiV1ExtensionBuilderZipPost(usr: usr, body: body);
  }

  ///Build and download extension zip.
  ///@param usr
  ///@param cookie_access_token
  @POST(path: '/api/v1/extension/builder/zip', optionalBody: true)
  Future<chopper.Response> _apiV1ExtensionBuilderZipPost({
    @Query('usr') String? usr,
    @Body() required ExtensionData? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'This endpoint generates a zip file for the extension based on the provided data.',
      summary: 'Build and download extension zip.',
      operationId: 'api_build_extension_api_v1_extension_builder_zip_post',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Extension Managment"],
      deprecated: false,
    ),
  });

  ///Build extension based on provided config.
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<SimpleStatus>> apiV1ExtensionBuilderDeployPost({
    String? usr,
    required ExtensionData? body,
  }) {
    generatedMapping.putIfAbsent(
      SimpleStatus,
      () => SimpleStatus.fromJsonFactory,
    );

    return _apiV1ExtensionBuilderDeployPost(usr: usr, body: body);
  }

  ///Build extension based on provided config.
  ///@param usr
  ///@param cookie_access_token
  @POST(path: '/api/v1/extension/builder/deploy', optionalBody: true)
  Future<chopper.Response<SimpleStatus>> _apiV1ExtensionBuilderDeployPost({
    @Query('usr') String? usr,
    @Body() required ExtensionData? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''This endpoint generates a zip file for the extension based on the provided data.
        If `deploy` is set to true, the extension will be installed and activated.''',
      summary: 'Build extension based on provided config.',
      operationId: 'api_deploy_extension_api_v1_extension_builder_deploy_post',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Extension Managment"],
      deprecated: false,
    ),
  });

  ///Build and preview the extension ui.
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<SimpleStatus>> apiV1ExtensionBuilderPreviewPost({
    String? usr,
    required ExtensionData? body,
  }) {
    generatedMapping.putIfAbsent(
      SimpleStatus,
      () => SimpleStatus.fromJsonFactory,
    );

    return _apiV1ExtensionBuilderPreviewPost(usr: usr, body: body);
  }

  ///Build and preview the extension ui.
  ///@param usr
  ///@param cookie_access_token
  @POST(path: '/api/v1/extension/builder/preview', optionalBody: true)
  Future<chopper.Response<SimpleStatus>> _apiV1ExtensionBuilderPreviewPost({
    @Query('usr') String? usr,
    @Body() required ExtensionData? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Build and preview the extension ui.',
      operationId:
          'api_preview_extension_api_v1_extension_builder_preview_post',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Extension Managment"],
      deprecated: false,
    ),
  });

  ///Clean extension builder data.
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<SimpleStatus>> apiV1ExtensionBuilderDelete({
    String? usr,
  }) {
    generatedMapping.putIfAbsent(
      SimpleStatus,
      () => SimpleStatus.fromJsonFactory,
    );

    return _apiV1ExtensionBuilderDelete(usr: usr);
  }

  ///Clean extension builder data.
  ///@param usr
  ///@param cookie_access_token
  @DELETE(path: '/api/v1/extension/builder')
  Future<chopper.Response<SimpleStatus>> _apiV1ExtensionBuilderDelete({
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'This endpoint cleans the extension builder data.',
      summary: 'Clean extension builder data.',
      operationId:
          'api_delete_extension_builder_data_api_v1_extension_builder_delete',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Extension Managment"],
      deprecated: false,
    ),
  });

  ///Api Disconnect Peer
  ///@param peer_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response> nodeApiV1PeersPeerIdDelete({
    required String? peerId,
    String? usr,
  }) {
    return _nodeApiV1PeersPeerIdDelete(peerId: peerId, usr: usr);
  }

  ///Api Disconnect Peer
  ///@param peer_id
  ///@param usr
  ///@param cookie_access_token
  @DELETE(path: '/node/api/v1/peers/{peer_id}')
  Future<chopper.Response> _nodeApiV1PeersPeerIdDelete({
    @Path('peer_id') required String? peerId,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Disconnect Peer',
      operationId: 'api_disconnect_peer_node_api_v1_peers__peer_id__delete',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Node Managment"],
      deprecated: false,
    ),
  });

  ///Api Get Public Info
  Future<chopper.Response<PublicNodeInfo>> nodePublicApiV1InfoGet() {
    generatedMapping.putIfAbsent(
      PublicNodeInfo,
      () => PublicNodeInfo.fromJsonFactory,
    );

    return _nodePublicApiV1InfoGet();
  }

  ///Api Get Public Info
  @GET(path: '/node/public/api/v1/info')
  Future<chopper.Response<PublicNodeInfo>> _nodePublicApiV1InfoGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Get Public Info',
      operationId: 'api_get_public_info_node_public_api_v1_info_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Node Managment"],
      deprecated: false,
    ),
  });

  ///Api Get 1Ml Stats
  Future<chopper.Response<NodeRank>> nodePublicApiV1RankGet() {
    generatedMapping.putIfAbsent(NodeRank, () => NodeRank.fromJsonFactory);

    return _nodePublicApiV1RankGet();
  }

  ///Api Get 1Ml Stats
  @GET(path: '/node/public/api/v1/rank')
  Future<chopper.Response<NodeRank>> _nodePublicApiV1RankGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Retrieve node ranks from https://1ml.com',
      summary: 'Api Get 1Ml Stats',
      operationId: 'api_get_1ml_stats_node_public_api_v1_rank_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Node Managment"],
      deprecated: false,
    ),
  });

  ///get list of payments
  ///@param limit
  ///@param offset
  ///@param sortby
  ///@param direction
  ///@param search Text based search
  ///@param status Supports Filtering. Supports Search
  ///@param tag Supports Filtering. Supports Search
  ///@param checking_id Supports Filtering
  ///@param amount Supports Filtering. Supports Search
  ///@param fee Supports Filtering
  ///@param memo Supports Filtering. Supports Search
  ///@param time Supports Filtering. Supports Search
  ///@param preimage Supports Filtering
  ///@param payment_hash Supports Filtering
  ///@param wallet_id Supports Filtering. Supports Search
  ///@param labels Supports Filtering. Supports Search
  Future<chopper.Response<List<Payment>>> apiV1PaymentsGet({
    int? limit,
    int? offset,
    String? sortby,
    enums.ApiV1PaymentsGetDirection? direction,
    String? search,
    String? status,
    String? tag,
    String? checkingId,
    int? amount,
    int? fee,
    String? memo,
    DateTime? time,
    String? preimage,
    String? paymentHash,
    String? walletId,
    String? labels,
  }) {
    generatedMapping.putIfAbsent(Payment, () => Payment.fromJsonFactory);

    return _apiV1PaymentsGet(
      limit: limit,
      offset: offset,
      sortby: sortby,
      direction: direction?.value?.toString(),
      search: search,
      status: status,
      tag: tag,
      checkingId: checkingId,
      amount: amount,
      fee: fee,
      memo: memo,
      time: time,
      preimage: preimage,
      paymentHash: paymentHash,
      walletId: walletId,
      labels: labels,
    );
  }

  ///get list of payments
  ///@param limit
  ///@param offset
  ///@param sortby
  ///@param direction
  ///@param search Text based search
  ///@param status Supports Filtering. Supports Search
  ///@param tag Supports Filtering. Supports Search
  ///@param checking_id Supports Filtering
  ///@param amount Supports Filtering. Supports Search
  ///@param fee Supports Filtering
  ///@param memo Supports Filtering. Supports Search
  ///@param time Supports Filtering. Supports Search
  ///@param preimage Supports Filtering
  ///@param payment_hash Supports Filtering
  ///@param wallet_id Supports Filtering. Supports Search
  ///@param labels Supports Filtering. Supports Search
  @GET(path: '/api/v1/payments')
  Future<chopper.Response<List<Payment>>> _apiV1PaymentsGet({
    @Query('limit') int? limit,
    @Query('offset') int? offset,
    @Query('sortby') String? sortby,
    @Query('direction') String? direction,
    @Query('search') String? search,
    @Query('status') String? status,
    @Query('tag') String? tag,
    @Query('checking_id') String? checkingId,
    @Query('amount') int? amount,
    @Query('fee') int? fee,
    @Query('memo') String? memo,
    @Query('time') DateTime? time,
    @Query('preimage') String? preimage,
    @Query('payment_hash') String? paymentHash,
    @Query('wallet_id') String? walletId,
    @Query('labels') String? labels,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'get list of payments',
      operationId: 'Payment_List_api_v1_payments_get',
      consumes: [],
      produces: [],
      security: ["APIKeyHeader", "APIKeyQuery"],
      tags: ["Payments"],
      deprecated: false,
    ),
  });

  ///Create or pay an invoice
  Future<chopper.Response<Payment>> apiV1PaymentsPost({
    required CreateInvoice? body,
  }) {
    generatedMapping.putIfAbsent(Payment, () => Payment.fromJsonFactory);

    return _apiV1PaymentsPost(body: body);
  }

  ///Create or pay an invoice
  @POST(path: '/api/v1/payments', optionalBody: true)
  Future<chopper.Response<Payment>> _apiV1PaymentsPost({
    @Body() required CreateInvoice? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          '''This endpoint can be used both to generate and pay a BOLT11 invoice.
        To generate a new invoice for receiving funds into the authorized account,
        specify at least the first four fields in the POST body: `out: false`,
        `amount`, `unit`, and `memo`. To pay an arbitrary invoice from the funds
        already in the authorized account, specify `out: true` and use the `bolt11`
        field to supply the BOLT11 invoice to be paid.''',
      summary: 'Create or pay an invoice',
      operationId: 'api_payments_create_api_v1_payments_post',
      consumes: [],
      produces: [],
      security: ["APIKeyHeader", "APIKeyQuery"],
      tags: ["Payments"],
      deprecated: false,
    ),
  });

  ///Get Payments History
  ///@param group
  ///@param limit
  ///@param offset
  ///@param sortby
  ///@param direction
  ///@param search Text based search
  ///@param status Supports Filtering. Supports Search
  ///@param tag Supports Filtering. Supports Search
  ///@param checking_id Supports Filtering
  ///@param amount Supports Filtering. Supports Search
  ///@param fee Supports Filtering
  ///@param memo Supports Filtering. Supports Search
  ///@param time Supports Filtering. Supports Search
  ///@param preimage Supports Filtering
  ///@param payment_hash Supports Filtering
  ///@param wallet_id Supports Filtering. Supports Search
  ///@param labels Supports Filtering. Supports Search
  Future<chopper.Response<List<PaymentHistoryPoint>>> apiV1PaymentsHistoryGet({
    enums.ApiV1PaymentsHistoryGetGroup? group,
    int? limit,
    int? offset,
    String? sortby,
    enums.ApiV1PaymentsHistoryGetDirection? direction,
    String? search,
    String? status,
    String? tag,
    String? checkingId,
    int? amount,
    int? fee,
    String? memo,
    DateTime? time,
    String? preimage,
    String? paymentHash,
    String? walletId,
    String? labels,
  }) {
    generatedMapping.putIfAbsent(
      PaymentHistoryPoint,
      () => PaymentHistoryPoint.fromJsonFactory,
    );

    return _apiV1PaymentsHistoryGet(
      group: group?.value?.toString(),
      limit: limit,
      offset: offset,
      sortby: sortby,
      direction: direction?.value?.toString(),
      search: search,
      status: status,
      tag: tag,
      checkingId: checkingId,
      amount: amount,
      fee: fee,
      memo: memo,
      time: time,
      preimage: preimage,
      paymentHash: paymentHash,
      walletId: walletId,
      labels: labels,
    );
  }

  ///Get Payments History
  ///@param group
  ///@param limit
  ///@param offset
  ///@param sortby
  ///@param direction
  ///@param search Text based search
  ///@param status Supports Filtering. Supports Search
  ///@param tag Supports Filtering. Supports Search
  ///@param checking_id Supports Filtering
  ///@param amount Supports Filtering. Supports Search
  ///@param fee Supports Filtering
  ///@param memo Supports Filtering. Supports Search
  ///@param time Supports Filtering. Supports Search
  ///@param preimage Supports Filtering
  ///@param payment_hash Supports Filtering
  ///@param wallet_id Supports Filtering. Supports Search
  ///@param labels Supports Filtering. Supports Search
  @GET(path: '/api/v1/payments/history')
  Future<chopper.Response<List<PaymentHistoryPoint>>> _apiV1PaymentsHistoryGet({
    @Query('group') String? group,
    @Query('limit') int? limit,
    @Query('offset') int? offset,
    @Query('sortby') String? sortby,
    @Query('direction') String? direction,
    @Query('search') String? search,
    @Query('status') String? status,
    @Query('tag') String? tag,
    @Query('checking_id') String? checkingId,
    @Query('amount') int? amount,
    @Query('fee') int? fee,
    @Query('memo') String? memo,
    @Query('time') DateTime? time,
    @Query('preimage') String? preimage,
    @Query('payment_hash') String? paymentHash,
    @Query('wallet_id') String? walletId,
    @Query('labels') String? labels,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Payments History',
      operationId: 'Get_payments_history_api_v1_payments_history_get',
      consumes: [],
      produces: [],
      security: ["APIKeyHeader", "APIKeyQuery"],
      tags: ["Payments"],
      deprecated: false,
    ),
  });

  ///Get Payments History For All Users
  ///@param count_by
  ///@param limit
  ///@param offset
  ///@param sortby
  ///@param direction
  ///@param search Text based search
  ///@param usr
  ///@param cookie_access_token
  ///@param status Supports Filtering. Supports Search
  ///@param tag Supports Filtering. Supports Search
  ///@param checking_id Supports Filtering
  ///@param amount Supports Filtering. Supports Search
  ///@param fee Supports Filtering
  ///@param memo Supports Filtering. Supports Search
  ///@param time Supports Filtering. Supports Search
  ///@param preimage Supports Filtering
  ///@param payment_hash Supports Filtering
  ///@param wallet_id Supports Filtering. Supports Search
  ///@param labels Supports Filtering. Supports Search
  Future<chopper.Response<List<PaymentCountStat>>> apiV1PaymentsStatsCountGet({
    enums.ApiV1PaymentsStatsCountGetCountBy? countBy,
    int? limit,
    int? offset,
    String? sortby,
    enums.ApiV1PaymentsStatsCountGetDirection? direction,
    String? search,
    String? usr,
    String? status,
    String? tag,
    String? checkingId,
    int? amount,
    int? fee,
    String? memo,
    DateTime? time,
    String? preimage,
    String? paymentHash,
    String? walletId,
    String? labels,
  }) {
    generatedMapping.putIfAbsent(
      PaymentCountStat,
      () => PaymentCountStat.fromJsonFactory,
    );

    return _apiV1PaymentsStatsCountGet(
      countBy: countBy?.value?.toString(),
      limit: limit,
      offset: offset,
      sortby: sortby,
      direction: direction?.value?.toString(),
      search: search,
      usr: usr,
      status: status,
      tag: tag,
      checkingId: checkingId,
      amount: amount,
      fee: fee,
      memo: memo,
      time: time,
      preimage: preimage,
      paymentHash: paymentHash,
      walletId: walletId,
      labels: labels,
    );
  }

  ///Get Payments History For All Users
  ///@param count_by
  ///@param limit
  ///@param offset
  ///@param sortby
  ///@param direction
  ///@param search Text based search
  ///@param usr
  ///@param cookie_access_token
  ///@param status Supports Filtering. Supports Search
  ///@param tag Supports Filtering. Supports Search
  ///@param checking_id Supports Filtering
  ///@param amount Supports Filtering. Supports Search
  ///@param fee Supports Filtering
  ///@param memo Supports Filtering. Supports Search
  ///@param time Supports Filtering. Supports Search
  ///@param preimage Supports Filtering
  ///@param payment_hash Supports Filtering
  ///@param wallet_id Supports Filtering. Supports Search
  ///@param labels Supports Filtering. Supports Search
  @GET(path: '/api/v1/payments/stats/count')
  Future<chopper.Response<List<PaymentCountStat>>> _apiV1PaymentsStatsCountGet({
    @Query('count_by') String? countBy,
    @Query('limit') int? limit,
    @Query('offset') int? offset,
    @Query('sortby') String? sortby,
    @Query('direction') String? direction,
    @Query('search') String? search,
    @Query('usr') String? usr,
    @Query('status') String? status,
    @Query('tag') String? tag,
    @Query('checking_id') String? checkingId,
    @Query('amount') int? amount,
    @Query('fee') int? fee,
    @Query('memo') String? memo,
    @Query('time') DateTime? time,
    @Query('preimage') String? preimage,
    @Query('payment_hash') String? paymentHash,
    @Query('wallet_id') String? walletId,
    @Query('labels') String? labels,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Payments History For All Users',
      operationId:
          'Get_payments_history_for_all_users_api_v1_payments_stats_count_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Payments"],
      deprecated: false,
    ),
  });

  ///Get Payments History For All Users
  ///@param limit
  ///@param offset
  ///@param sortby
  ///@param direction
  ///@param search Text based search
  ///@param usr
  ///@param cookie_access_token
  ///@param status Supports Filtering. Supports Search
  ///@param tag Supports Filtering. Supports Search
  ///@param checking_id Supports Filtering
  ///@param amount Supports Filtering. Supports Search
  ///@param fee Supports Filtering
  ///@param memo Supports Filtering. Supports Search
  ///@param time Supports Filtering. Supports Search
  ///@param preimage Supports Filtering
  ///@param payment_hash Supports Filtering
  ///@param wallet_id Supports Filtering. Supports Search
  ///@param labels Supports Filtering. Supports Search
  Future<chopper.Response<List<PaymentWalletStats>>>
  apiV1PaymentsStatsWalletsGet({
    int? limit,
    int? offset,
    String? sortby,
    enums.ApiV1PaymentsStatsWalletsGetDirection? direction,
    String? search,
    String? usr,
    String? status,
    String? tag,
    String? checkingId,
    int? amount,
    int? fee,
    String? memo,
    DateTime? time,
    String? preimage,
    String? paymentHash,
    String? walletId,
    String? labels,
  }) {
    generatedMapping.putIfAbsent(
      PaymentWalletStats,
      () => PaymentWalletStats.fromJsonFactory,
    );

    return _apiV1PaymentsStatsWalletsGet(
      limit: limit,
      offset: offset,
      sortby: sortby,
      direction: direction?.value?.toString(),
      search: search,
      usr: usr,
      status: status,
      tag: tag,
      checkingId: checkingId,
      amount: amount,
      fee: fee,
      memo: memo,
      time: time,
      preimage: preimage,
      paymentHash: paymentHash,
      walletId: walletId,
      labels: labels,
    );
  }

  ///Get Payments History For All Users
  ///@param limit
  ///@param offset
  ///@param sortby
  ///@param direction
  ///@param search Text based search
  ///@param usr
  ///@param cookie_access_token
  ///@param status Supports Filtering. Supports Search
  ///@param tag Supports Filtering. Supports Search
  ///@param checking_id Supports Filtering
  ///@param amount Supports Filtering. Supports Search
  ///@param fee Supports Filtering
  ///@param memo Supports Filtering. Supports Search
  ///@param time Supports Filtering. Supports Search
  ///@param preimage Supports Filtering
  ///@param payment_hash Supports Filtering
  ///@param wallet_id Supports Filtering. Supports Search
  ///@param labels Supports Filtering. Supports Search
  @GET(path: '/api/v1/payments/stats/wallets')
  Future<chopper.Response<List<PaymentWalletStats>>>
  _apiV1PaymentsStatsWalletsGet({
    @Query('limit') int? limit,
    @Query('offset') int? offset,
    @Query('sortby') String? sortby,
    @Query('direction') String? direction,
    @Query('search') String? search,
    @Query('usr') String? usr,
    @Query('status') String? status,
    @Query('tag') String? tag,
    @Query('checking_id') String? checkingId,
    @Query('amount') int? amount,
    @Query('fee') int? fee,
    @Query('memo') String? memo,
    @Query('time') DateTime? time,
    @Query('preimage') String? preimage,
    @Query('payment_hash') String? paymentHash,
    @Query('wallet_id') String? walletId,
    @Query('labels') String? labels,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Payments History For All Users',
      operationId:
          'Get_payments_history_for_all_users_api_v1_payments_stats_wallets_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Payments"],
      deprecated: false,
    ),
  });

  ///Get Payments History Per Day
  ///@param usr
  ///@param limit
  ///@param offset
  ///@param sortby
  ///@param direction
  ///@param search Text based search
  ///@param cookie_access_token
  ///@param status Supports Filtering. Supports Search
  ///@param tag Supports Filtering. Supports Search
  ///@param checking_id Supports Filtering
  ///@param amount Supports Filtering. Supports Search
  ///@param fee Supports Filtering
  ///@param memo Supports Filtering. Supports Search
  ///@param time Supports Filtering. Supports Search
  ///@param preimage Supports Filtering
  ///@param payment_hash Supports Filtering
  ///@param wallet_id Supports Filtering. Supports Search
  ///@param labels Supports Filtering. Supports Search
  Future<chopper.Response<List<PaymentDailyStats>>> apiV1PaymentsStatsDailyGet({
    String? usr,
    int? limit,
    int? offset,
    String? sortby,
    enums.ApiV1PaymentsStatsDailyGetDirection? direction,
    String? search,
    String? status,
    String? tag,
    String? checkingId,
    int? amount,
    int? fee,
    String? memo,
    DateTime? time,
    String? preimage,
    String? paymentHash,
    String? walletId,
    String? labels,
  }) {
    generatedMapping.putIfAbsent(
      PaymentDailyStats,
      () => PaymentDailyStats.fromJsonFactory,
    );

    return _apiV1PaymentsStatsDailyGet(
      usr: usr,
      limit: limit,
      offset: offset,
      sortby: sortby,
      direction: direction?.value?.toString(),
      search: search,
      status: status,
      tag: tag,
      checkingId: checkingId,
      amount: amount,
      fee: fee,
      memo: memo,
      time: time,
      preimage: preimage,
      paymentHash: paymentHash,
      walletId: walletId,
      labels: labels,
    );
  }

  ///Get Payments History Per Day
  ///@param usr
  ///@param limit
  ///@param offset
  ///@param sortby
  ///@param direction
  ///@param search Text based search
  ///@param cookie_access_token
  ///@param status Supports Filtering. Supports Search
  ///@param tag Supports Filtering. Supports Search
  ///@param checking_id Supports Filtering
  ///@param amount Supports Filtering. Supports Search
  ///@param fee Supports Filtering
  ///@param memo Supports Filtering. Supports Search
  ///@param time Supports Filtering. Supports Search
  ///@param preimage Supports Filtering
  ///@param payment_hash Supports Filtering
  ///@param wallet_id Supports Filtering. Supports Search
  ///@param labels Supports Filtering. Supports Search
  @GET(path: '/api/v1/payments/stats/daily')
  Future<chopper.Response<List<PaymentDailyStats>>>
  _apiV1PaymentsStatsDailyGet({
    @Query('usr') String? usr,
    @Query('limit') int? limit,
    @Query('offset') int? offset,
    @Query('sortby') String? sortby,
    @Query('direction') String? direction,
    @Query('search') String? search,
    @Query('status') String? status,
    @Query('tag') String? tag,
    @Query('checking_id') String? checkingId,
    @Query('amount') int? amount,
    @Query('fee') int? fee,
    @Query('memo') String? memo,
    @Query('time') DateTime? time,
    @Query('preimage') String? preimage,
    @Query('payment_hash') String? paymentHash,
    @Query('wallet_id') String? walletId,
    @Query('labels') String? labels,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Payments History Per Day',
      operationId:
          'Get_payments_history_per_day_api_v1_payments_stats_daily_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Payments"],
      deprecated: false,
    ),
  });

  ///get paginated list of payments
  ///@param recheck_pending Force check and update of pending payments.
  ///@param limit
  ///@param offset
  ///@param sortby
  ///@param direction
  ///@param search Text based search
  ///@param status Supports Filtering. Supports Search
  ///@param tag Supports Filtering. Supports Search
  ///@param checking_id Supports Filtering
  ///@param amount Supports Filtering. Supports Search
  ///@param fee Supports Filtering
  ///@param memo Supports Filtering. Supports Search
  ///@param time Supports Filtering. Supports Search
  ///@param preimage Supports Filtering
  ///@param payment_hash Supports Filtering
  ///@param wallet_id Supports Filtering. Supports Search
  ///@param labels Supports Filtering. Supports Search
  Future<chopper.Response<Page>> apiV1PaymentsPaginatedGet({
    bool? recheckPending,
    int? limit,
    int? offset,
    String? sortby,
    enums.ApiV1PaymentsPaginatedGetDirection? direction,
    String? search,
    String? status,
    String? tag,
    String? checkingId,
    int? amount,
    int? fee,
    String? memo,
    DateTime? time,
    String? preimage,
    String? paymentHash,
    String? walletId,
    String? labels,
  }) {
    generatedMapping.putIfAbsent(Page, () => Page.fromJsonFactory);

    return _apiV1PaymentsPaginatedGet(
      recheckPending: recheckPending,
      limit: limit,
      offset: offset,
      sortby: sortby,
      direction: direction?.value?.toString(),
      search: search,
      status: status,
      tag: tag,
      checkingId: checkingId,
      amount: amount,
      fee: fee,
      memo: memo,
      time: time,
      preimage: preimage,
      paymentHash: paymentHash,
      walletId: walletId,
      labels: labels,
    );
  }

  ///get paginated list of payments
  ///@param recheck_pending Force check and update of pending payments.
  ///@param limit
  ///@param offset
  ///@param sortby
  ///@param direction
  ///@param search Text based search
  ///@param status Supports Filtering. Supports Search
  ///@param tag Supports Filtering. Supports Search
  ///@param checking_id Supports Filtering
  ///@param amount Supports Filtering. Supports Search
  ///@param fee Supports Filtering
  ///@param memo Supports Filtering. Supports Search
  ///@param time Supports Filtering. Supports Search
  ///@param preimage Supports Filtering
  ///@param payment_hash Supports Filtering
  ///@param wallet_id Supports Filtering. Supports Search
  ///@param labels Supports Filtering. Supports Search
  @GET(path: '/api/v1/payments/paginated')
  Future<chopper.Response<Page>> _apiV1PaymentsPaginatedGet({
    @Query('recheck_pending') bool? recheckPending,
    @Query('limit') int? limit,
    @Query('offset') int? offset,
    @Query('sortby') String? sortby,
    @Query('direction') String? direction,
    @Query('search') String? search,
    @Query('status') String? status,
    @Query('tag') String? tag,
    @Query('checking_id') String? checkingId,
    @Query('amount') int? amount,
    @Query('fee') int? fee,
    @Query('memo') String? memo,
    @Query('time') DateTime? time,
    @Query('preimage') String? preimage,
    @Query('payment_hash') String? paymentHash,
    @Query('wallet_id') String? walletId,
    @Query('labels') String? labels,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'get paginated list of payments',
      operationId: 'Payment_List_api_v1_payments_paginated_get',
      consumes: [],
      produces: [],
      security: ["APIKeyHeader", "APIKeyQuery"],
      tags: ["Payments"],
      deprecated: false,
    ),
  });

  ///get paginated list of payments
  ///@param limit
  ///@param offset
  ///@param sortby
  ///@param direction
  ///@param search Text based search
  ///@param usr
  ///@param cookie_access_token
  ///@param status Supports Filtering. Supports Search
  ///@param tag Supports Filtering. Supports Search
  ///@param checking_id Supports Filtering
  ///@param amount Supports Filtering. Supports Search
  ///@param fee Supports Filtering
  ///@param memo Supports Filtering. Supports Search
  ///@param time Supports Filtering. Supports Search
  ///@param preimage Supports Filtering
  ///@param payment_hash Supports Filtering
  ///@param wallet_id Supports Filtering. Supports Search
  ///@param labels Supports Filtering. Supports Search
  Future<chopper.Response<Page>> apiV1PaymentsAllPaginatedGet({
    int? limit,
    int? offset,
    String? sortby,
    enums.ApiV1PaymentsAllPaginatedGetDirection? direction,
    String? search,
    String? usr,
    String? status,
    String? tag,
    String? checkingId,
    int? amount,
    int? fee,
    String? memo,
    DateTime? time,
    String? preimage,
    String? paymentHash,
    String? walletId,
    String? labels,
  }) {
    generatedMapping.putIfAbsent(Page, () => Page.fromJsonFactory);

    return _apiV1PaymentsAllPaginatedGet(
      limit: limit,
      offset: offset,
      sortby: sortby,
      direction: direction?.value?.toString(),
      search: search,
      usr: usr,
      status: status,
      tag: tag,
      checkingId: checkingId,
      amount: amount,
      fee: fee,
      memo: memo,
      time: time,
      preimage: preimage,
      paymentHash: paymentHash,
      walletId: walletId,
      labels: labels,
    );
  }

  ///get paginated list of payments
  ///@param limit
  ///@param offset
  ///@param sortby
  ///@param direction
  ///@param search Text based search
  ///@param usr
  ///@param cookie_access_token
  ///@param status Supports Filtering. Supports Search
  ///@param tag Supports Filtering. Supports Search
  ///@param checking_id Supports Filtering
  ///@param amount Supports Filtering. Supports Search
  ///@param fee Supports Filtering
  ///@param memo Supports Filtering. Supports Search
  ///@param time Supports Filtering. Supports Search
  ///@param preimage Supports Filtering
  ///@param payment_hash Supports Filtering
  ///@param wallet_id Supports Filtering. Supports Search
  ///@param labels Supports Filtering. Supports Search
  @GET(path: '/api/v1/payments/all/paginated')
  Future<chopper.Response<Page>> _apiV1PaymentsAllPaginatedGet({
    @Query('limit') int? limit,
    @Query('offset') int? offset,
    @Query('sortby') String? sortby,
    @Query('direction') String? direction,
    @Query('search') String? search,
    @Query('usr') String? usr,
    @Query('status') String? status,
    @Query('tag') String? tag,
    @Query('checking_id') String? checkingId,
    @Query('amount') int? amount,
    @Query('fee') int? fee,
    @Query('memo') String? memo,
    @Query('time') DateTime? time,
    @Query('preimage') String? preimage,
    @Query('payment_hash') String? paymentHash,
    @Query('wallet_id') String? walletId,
    @Query('labels') String? labels,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'get paginated list of payments',
      operationId: 'Payment_List_api_v1_payments_all_paginated_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Payments"],
      deprecated: false,
    ),
  });

  ///Api Update Payment Labels
  ///@param payment_hash
  Future<chopper.Response<SimpleStatus>> apiV1PaymentsPaymentHashLabelsPut({
    required String? paymentHash,
    required UpdatePaymentLabels? body,
  }) {
    generatedMapping.putIfAbsent(
      SimpleStatus,
      () => SimpleStatus.fromJsonFactory,
    );

    return _apiV1PaymentsPaymentHashLabelsPut(
      paymentHash: paymentHash,
      body: body,
    );
  }

  ///Api Update Payment Labels
  ///@param payment_hash
  @PUT(path: '/api/v1/payments/{payment_hash}/labels', optionalBody: true)
  Future<chopper.Response<SimpleStatus>> _apiV1PaymentsPaymentHashLabelsPut({
    @Path('payment_hash') required String? paymentHash,
    @Body() required UpdatePaymentLabels? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Update Payment Labels',
      operationId:
          'api_update_payment_labels_api_v1_payments__payment_hash__labels_put',
      consumes: [],
      produces: [],
      security: ["APIKeyHeader", "APIKeyQuery"],
      tags: ["Payments"],
      deprecated: false,
    ),
  });

  ///Api Payments Fee Reserve
  ///@param invoice
  Future<chopper.Response> apiV1PaymentsFeeReserveGet({String? invoice}) {
    return _apiV1PaymentsFeeReserveGet(invoice: invoice);
  }

  ///Api Payments Fee Reserve
  ///@param invoice
  @GET(path: '/api/v1/payments/fee-reserve')
  Future<chopper.Response> _apiV1PaymentsFeeReserveGet({
    @Query('invoice') String? invoice,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Payments Fee Reserve',
      operationId: 'api_payments_fee_reserve_api_v1_payments_fee_reserve_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Payments"],
      deprecated: false,
    ),
  });

  ///Api Payment
  ///@param payment_hash
  ///@param x-api-key
  Future<chopper.Response> apiV1PaymentsPaymentHashGet({
    required Object? paymentHash,
    String? xApiKey,
  }) {
    return _apiV1PaymentsPaymentHashGet(
      paymentHash: paymentHash,
      xApiKey: xApiKey?.toString(),
    );
  }

  ///Api Payment
  ///@param payment_hash
  ///@param x-api-key
  @GET(path: '/api/v1/payments/{payment_hash}')
  Future<chopper.Response> _apiV1PaymentsPaymentHashGet({
    @Path('payment_hash') required Object? paymentHash,
    @Header('x-api-key') String? xApiKey,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Payment',
      operationId: 'api_payment_api_v1_payments__payment_hash__get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Payments"],
      deprecated: false,
    ),
  });

  ///Api Payments Decode
  Future<chopper.Response> apiV1PaymentsDecodePost({
    required DecodePayment? body,
  }) {
    return _apiV1PaymentsDecodePost(body: body);
  }

  ///Api Payments Decode
  @POST(path: '/api/v1/payments/decode', optionalBody: true)
  Future<chopper.Response> _apiV1PaymentsDecodePost({
    @Body() required DecodePayment? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Payments Decode',
      operationId: 'api_payments_decode_api_v1_payments_decode_post',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Payments"],
      deprecated: false,
    ),
  });

  ///Api Payments Settle
  Future<chopper.Response> apiV1PaymentsSettlePost({
    required SettleInvoice? body,
  }) {
    return _apiV1PaymentsSettlePost(body: body);
  }

  ///Api Payments Settle
  @POST(path: '/api/v1/payments/settle', optionalBody: true)
  Future<chopper.Response> _apiV1PaymentsSettlePost({
    @Body() required SettleInvoice? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Payments Settle',
      operationId: 'api_payments_settle_api_v1_payments_settle_post',
      consumes: [],
      produces: [],
      security: ["APIKeyHeader", "APIKeyQuery"],
      tags: ["Payments"],
      deprecated: false,
    ),
  });

  ///Api Payments Cancel
  Future<chopper.Response> apiV1PaymentsCancelPost({
    required CancelInvoice? body,
  }) {
    return _apiV1PaymentsCancelPost(body: body);
  }

  ///Api Payments Cancel
  @POST(path: '/api/v1/payments/cancel', optionalBody: true)
  Future<chopper.Response> _apiV1PaymentsCancelPost({
    @Body() required CancelInvoice? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Payments Cancel',
      operationId: 'api_payments_cancel_api_v1_payments_cancel_post',
      consumes: [],
      produces: [],
      security: ["APIKeyHeader", "APIKeyQuery"],
      tags: ["Payments"],
      deprecated: false,
    ),
  });

  ///Api Payment Pay With Nfc
  ///@param payment_request
  Future<chopper.Response<SimpleStatus>>
  apiV1PaymentsPaymentRequestPayWithNfcPost({
    required String? paymentRequest,
    required CreateLnurlWithdraw? body,
  }) {
    generatedMapping.putIfAbsent(
      SimpleStatus,
      () => SimpleStatus.fromJsonFactory,
    );

    return _apiV1PaymentsPaymentRequestPayWithNfcPost(
      paymentRequest: paymentRequest,
      body: body,
    );
  }

  ///Api Payment Pay With Nfc
  ///@param payment_request
  @POST(
    path: '/api/v1/payments/{payment_request}/pay-with-nfc',
    optionalBody: true,
  )
  Future<chopper.Response<SimpleStatus>>
  _apiV1PaymentsPaymentRequestPayWithNfcPost({
    @Path('payment_request') required String? paymentRequest,
    @Body() required CreateLnurlWithdraw? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Payment Pay With Nfc',
      operationId:
          'api_payment_pay_with_nfc_api_v1_payments__payment_request__pay_with_nfc_post',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Payments"],
      deprecated: false,
    ),
  });

  ///Api Wallet
  Future<chopper.Response> apiV1WalletGet() {
    return _apiV1WalletGet();
  }

  ///Api Wallet
  @GET(path: '/api/v1/wallet')
  Future<chopper.Response> _apiV1WalletGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Wallet',
      operationId: 'api_wallet_api_v1_wallet_get',
      consumes: [],
      produces: [],
      security: ["APIKeyHeader", "APIKeyQuery"],
      tags: ["Wallet"],
      deprecated: false,
    ),
  });

  ///Api Create Wallet
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<Wallet>> apiV1WalletPost({
    String? usr,
    required CreateWallet? body,
  }) {
    generatedMapping.putIfAbsent(Wallet, () => Wallet.fromJsonFactory);

    return _apiV1WalletPost(usr: usr, body: body);
  }

  ///Api Create Wallet
  ///@param usr
  ///@param cookie_access_token
  @POST(path: '/api/v1/wallet', optionalBody: true)
  Future<chopper.Response<Wallet>> _apiV1WalletPost({
    @Query('usr') String? usr,
    @Body() required CreateWallet? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Create Wallet',
      operationId: 'api_create_wallet_api_v1_wallet_post',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Wallet"],
      deprecated: false,
    ),
  });

  ///Api Update Wallet
  Future<chopper.Response<Wallet>> apiV1WalletPatch({
    required BodyApiUpdateWalletApiV1WalletPatch? body,
  }) {
    generatedMapping.putIfAbsent(Wallet, () => Wallet.fromJsonFactory);

    return _apiV1WalletPatch(body: body);
  }

  ///Api Update Wallet
  @PATCH(path: '/api/v1/wallet', optionalBody: true)
  Future<chopper.Response<Wallet>> _apiV1WalletPatch({
    @Body() required BodyApiUpdateWalletApiV1WalletPatch? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Update Wallet',
      operationId: 'api_update_wallet_api_v1_wallet_patch',
      consumes: [],
      produces: [],
      security: ["APIKeyHeader", "APIKeyQuery"],
      tags: ["Wallet"],
      deprecated: false,
    ),
  });

  ///get paginated list of user wallets
  ///@param usr
  ///@param limit
  ///@param offset
  ///@param sortby
  ///@param direction
  ///@param search Text based search
  ///@param cookie_access_token
  ///@param id Supports Filtering. Supports Search
  ///@param name Supports Filtering. Supports Search
  ///@param currency Supports Filtering. Supports Search
  Future<chopper.Response<Page>> apiV1WalletPaginatedGet({
    String? usr,
    int? limit,
    int? offset,
    String? sortby,
    enums.ApiV1WalletPaginatedGetDirection? direction,
    String? search,
    String? id,
    String? name,
    String? currency,
  }) {
    generatedMapping.putIfAbsent(Page, () => Page.fromJsonFactory);

    return _apiV1WalletPaginatedGet(
      usr: usr,
      limit: limit,
      offset: offset,
      sortby: sortby,
      direction: direction?.value?.toString(),
      search: search,
      id: id,
      name: name,
      currency: currency,
    );
  }

  ///get paginated list of user wallets
  ///@param usr
  ///@param limit
  ///@param offset
  ///@param sortby
  ///@param direction
  ///@param search Text based search
  ///@param cookie_access_token
  ///@param id Supports Filtering. Supports Search
  ///@param name Supports Filtering. Supports Search
  ///@param currency Supports Filtering. Supports Search
  @GET(path: '/api/v1/wallet/paginated')
  Future<chopper.Response<Page>> _apiV1WalletPaginatedGet({
    @Query('usr') String? usr,
    @Query('limit') int? limit,
    @Query('offset') int? offset,
    @Query('sortby') String? sortby,
    @Query('direction') String? direction,
    @Query('search') String? search,
    @Query('id') String? id,
    @Query('name') String? name,
    @Query('currency') String? currency,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'get paginated list of user wallets',
      operationId: 'Wallet_List_api_v1_wallet_paginated_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Wallet"],
      deprecated: false,
    ),
  });

  ///Api Invite Wallet Share
  Future<chopper.Response<WalletSharePermission>> apiV1WalletShareInvitePut({
    required WalletSharePermission? body,
  }) {
    generatedMapping.putIfAbsent(
      WalletSharePermission,
      () => WalletSharePermission.fromJsonFactory,
    );

    return _apiV1WalletShareInvitePut(body: body);
  }

  ///Api Invite Wallet Share
  @PUT(path: '/api/v1/wallet/share/invite', optionalBody: true)
  Future<chopper.Response<WalletSharePermission>> _apiV1WalletShareInvitePut({
    @Body() required WalletSharePermission? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Invite Wallet Share',
      operationId: 'api_invite_wallet_share_api_v1_wallet_share_invite_put',
      consumes: [],
      produces: [],
      security: ["APIKeyHeader", "APIKeyQuery"],
      tags: ["Wallet"],
      deprecated: false,
    ),
  });

  ///Api Reject Wallet Invitation
  ///@param share_request_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<SimpleStatus>>
  apiV1WalletShareInviteShareRequestIdDelete({
    required String? shareRequestId,
    String? usr,
  }) {
    generatedMapping.putIfAbsent(
      SimpleStatus,
      () => SimpleStatus.fromJsonFactory,
    );

    return _apiV1WalletShareInviteShareRequestIdDelete(
      shareRequestId: shareRequestId,
      usr: usr,
    );
  }

  ///Api Reject Wallet Invitation
  ///@param share_request_id
  ///@param usr
  ///@param cookie_access_token
  @DELETE(path: '/api/v1/wallet/share/invite/{share_request_id}')
  Future<chopper.Response<SimpleStatus>>
  _apiV1WalletShareInviteShareRequestIdDelete({
    @Path('share_request_id') required String? shareRequestId,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Reject Wallet Invitation',
      operationId:
          'api_reject_wallet_invitation_api_v1_wallet_share_invite__share_request_id__delete',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Wallet"],
      deprecated: false,
    ),
  });

  ///Api Accept Wallet Share Request
  Future<chopper.Response<WalletSharePermission>> apiV1WalletSharePut({
    required WalletSharePermission? body,
  }) {
    generatedMapping.putIfAbsent(
      WalletSharePermission,
      () => WalletSharePermission.fromJsonFactory,
    );

    return _apiV1WalletSharePut(body: body);
  }

  ///Api Accept Wallet Share Request
  @PUT(path: '/api/v1/wallet/share', optionalBody: true)
  Future<chopper.Response<WalletSharePermission>> _apiV1WalletSharePut({
    @Body() required WalletSharePermission? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Accept Wallet Share Request',
      operationId: 'api_accept_wallet_share_request_api_v1_wallet_share_put',
      consumes: [],
      produces: [],
      security: ["APIKeyHeader", "APIKeyQuery"],
      tags: ["Wallet"],
      deprecated: false,
    ),
  });

  ///Api Delete Wallet Share Permissions
  ///@param share_request_id
  Future<chopper.Response<SimpleStatus>> apiV1WalletShareShareRequestIdDelete({
    required String? shareRequestId,
  }) {
    generatedMapping.putIfAbsent(
      SimpleStatus,
      () => SimpleStatus.fromJsonFactory,
    );

    return _apiV1WalletShareShareRequestIdDelete(
      shareRequestId: shareRequestId,
    );
  }

  ///Api Delete Wallet Share Permissions
  ///@param share_request_id
  @DELETE(path: '/api/v1/wallet/share/{share_request_id}')
  Future<chopper.Response<SimpleStatus>> _apiV1WalletShareShareRequestIdDelete({
    @Path('share_request_id') required String? shareRequestId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Delete Wallet Share Permissions',
      operationId:
          'api_delete_wallet_share_permissions_api_v1_wallet_share__share_request_id__delete',
      consumes: [],
      produces: [],
      security: ["APIKeyHeader", "APIKeyQuery"],
      tags: ["Wallet"],
      deprecated: false,
    ),
  });

  ///Api Update Wallet Name
  ///@param new_name
  Future<chopper.Response> apiV1WalletNewNamePut({required String? newName}) {
    return _apiV1WalletNewNamePut(newName: newName);
  }

  ///Api Update Wallet Name
  ///@param new_name
  @PUT(path: '/api/v1/wallet/{new_name}', optionalBody: true)
  Future<chopper.Response> _apiV1WalletNewNamePut({
    @Path('new_name') required String? newName,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Update Wallet Name',
      operationId: 'api_update_wallet_name_api_v1_wallet__new_name__put',
      consumes: [],
      produces: [],
      security: ["APIKeyHeader", "APIKeyQuery"],
      tags: ["Wallet"],
      deprecated: false,
    ),
  });

  ///Api Reset Wallet Keys
  ///@param wallet_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<Wallet>> apiV1WalletResetWalletIdPut({
    required String? walletId,
    String? usr,
  }) {
    generatedMapping.putIfAbsent(Wallet, () => Wallet.fromJsonFactory);

    return _apiV1WalletResetWalletIdPut(walletId: walletId, usr: usr);
  }

  ///Api Reset Wallet Keys
  ///@param wallet_id
  ///@param usr
  ///@param cookie_access_token
  @PUT(path: '/api/v1/wallet/reset/{wallet_id}', optionalBody: true)
  Future<chopper.Response<Wallet>> _apiV1WalletResetWalletIdPut({
    @Path('wallet_id') required String? walletId,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Reset Wallet Keys',
      operationId: 'api_reset_wallet_keys_api_v1_wallet_reset__wallet_id__put',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Wallet"],
      deprecated: false,
    ),
  });

  ///Api Put Stored Paylinks
  ///@param wallet_id
  Future<chopper.Response<List<StoredPayLink>>>
  apiV1WalletStoredPaylinksWalletIdPut({
    required String? walletId,
    required StoredPayLinks? body,
  }) {
    generatedMapping.putIfAbsent(
      StoredPayLink,
      () => StoredPayLink.fromJsonFactory,
    );

    return _apiV1WalletStoredPaylinksWalletIdPut(
      walletId: walletId,
      body: body,
    );
  }

  ///Api Put Stored Paylinks
  ///@param wallet_id
  @PUT(path: '/api/v1/wallet/stored_paylinks/{wallet_id}', optionalBody: true)
  Future<chopper.Response<List<StoredPayLink>>>
  _apiV1WalletStoredPaylinksWalletIdPut({
    @Path('wallet_id') required String? walletId,
    @Body() required StoredPayLinks? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Put Stored Paylinks',
      operationId:
          'api_put_stored_paylinks_api_v1_wallet_stored_paylinks__wallet_id__put',
      consumes: [],
      produces: [],
      security: ["APIKeyHeader", "APIKeyQuery"],
      tags: ["Wallet"],
      deprecated: false,
    ),
  });

  ///Api Delete Wallet
  ///@param wallet_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response> apiV1WalletWalletIdDelete({
    required String? walletId,
    String? usr,
  }) {
    return _apiV1WalletWalletIdDelete(walletId: walletId, usr: usr);
  }

  ///Api Delete Wallet
  ///@param wallet_id
  ///@param usr
  ///@param cookie_access_token
  @DELETE(path: '/api/v1/wallet/{wallet_id}')
  Future<chopper.Response> _apiV1WalletWalletIdDelete({
    @Path('wallet_id') required String? walletId,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Delete Wallet',
      operationId: 'api_delete_wallet_api_v1_wallet__wallet_id__delete',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Wallet"],
      deprecated: false,
    ),
  });

  ///Health
  Future<chopper.Response<Object>> apiV1HealthGet() {
    return _apiV1HealthGet();
  }

  ///Health
  @GET(path: '/api/v1/health')
  Future<chopper.Response<Object>> _apiV1HealthGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Health',
      operationId: 'health_api_v1_health_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Core"],
      deprecated: false,
    ),
  });

  ///Health Check
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<Object>> apiV1StatusGet({String? usr}) {
    return _apiV1StatusGet(usr: usr);
  }

  ///Health Check
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/api/v1/status')
  Future<chopper.Response<Object>> _apiV1StatusGet({
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Health Check',
      operationId: 'health_check_api_v1_status_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Core"],
      deprecated: false,
    ),
  });

  ///Wallets
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<List<Wallet>>> apiV1WalletsGet({String? usr}) {
    generatedMapping.putIfAbsent(Wallet, () => Wallet.fromJsonFactory);

    return _apiV1WalletsGet(usr: usr);
  }

  ///Wallets
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/api/v1/wallets')
  Future<chopper.Response<List<Wallet>>> _apiV1WalletsGet({
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get basic info for all of user\'s wallets.',
      summary: 'Wallets',
      operationId: 'Wallets_api_v1_wallets_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Core"],
      deprecated: false,
    ),
  });

  ///Api Create Account
  Future<chopper.Response<Wallet>> apiV1AccountPost({
    required CreateWallet? body,
  }) {
    generatedMapping.putIfAbsent(Wallet, () => Wallet.fromJsonFactory);

    return _apiV1AccountPost(body: body);
  }

  ///Api Create Account
  @POST(path: '/api/v1/account', optionalBody: true)
  Future<chopper.Response<Wallet>> _apiV1AccountPost({
    @Body() required CreateWallet? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Create Account',
      operationId: 'api_create_account_api_v1_account_post',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Core"],
      deprecated: false,
    ),
  });

  ///Api Exchange Rate History
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<List<Object>>> apiV1RateHistoryGet({String? usr}) {
    return _apiV1RateHistoryGet(usr: usr);
  }

  ///Api Exchange Rate History
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/api/v1/rate/history')
  Future<chopper.Response<List<Object>>> _apiV1RateHistoryGet({
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Exchange Rate History',
      operationId: 'api_exchange_rate_history_api_v1_rate_history_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Core"],
      deprecated: false,
    ),
  });

  ///Api Check Fiat Rate
  ///@param currency
  Future<chopper.Response<Object>> apiV1RateCurrencyGet({
    required String? currency,
  }) {
    return _apiV1RateCurrencyGet(currency: currency);
  }

  ///Api Check Fiat Rate
  ///@param currency
  @GET(path: '/api/v1/rate/{currency}')
  Future<chopper.Response<Object>> _apiV1RateCurrencyGet({
    @Path('currency') required String? currency,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Check Fiat Rate',
      operationId: 'api_check_fiat_rate_api_v1_rate__currency__get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Core"],
      deprecated: false,
    ),
  });

  ///Api List Currencies Available
  Future<chopper.Response<List<String>>> apiV1CurrenciesGet() {
    return _apiV1CurrenciesGet();
  }

  ///Api List Currencies Available
  @GET(path: '/api/v1/currencies')
  Future<chopper.Response<List<String>>> _apiV1CurrenciesGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api List Currencies Available',
      operationId: 'api_list_currencies_available_api_v1_currencies_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Core"],
      deprecated: false,
    ),
  });

  ///Api Fiat As Sats
  Future<chopper.Response> apiV1ConversionPost({
    required ConversionData? body,
  }) {
    return _apiV1ConversionPost(body: body);
  }

  ///Api Fiat As Sats
  @POST(path: '/api/v1/conversion', optionalBody: true)
  Future<chopper.Response> _apiV1ConversionPost({
    @Body() required ConversionData? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Fiat As Sats',
      operationId: 'api_fiat_as_sats_api_v1_conversion_post',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Core"],
      deprecated: false,
    ),
  });

  ///Img
  ///@param data
  Future<chopper.Response> apiV1QrcodeDataGet({required String? data}) {
    return _apiV1QrcodeDataGet(data: data);
  }

  ///Img
  ///@param data
  @GET(path: '/api/v1/qrcode/{data}')
  Future<chopper.Response> _apiV1QrcodeDataGet({
    @Path('data') required String? data,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Img',
      operationId: 'img_api_v1_qrcode__data__get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Core"],
      deprecated: false,
    ),
  });

  ///Img
  ///@param data
  Future<chopper.Response> apiV1QrcodeGet({required String? data}) {
    return _apiV1QrcodeGet(data: data);
  }

  ///Img
  ///@param data
  @GET(path: '/api/v1/qrcode')
  Future<chopper.Response> _apiV1QrcodeGet({
    @Query('data') required String? data,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Img',
      operationId: 'img_api_v1_qrcode_get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Core"],
      deprecated: false,
    ),
  });

  ///Websocket Update Post
  ///@param item_id
  ///@param data
  Future<chopper.Response> apiV1WsItemIdPost({
    required String? itemId,
    required String? data,
  }) {
    return _apiV1WsItemIdPost(itemId: itemId, data: data);
  }

  ///Websocket Update Post
  ///@param item_id
  ///@param data
  @POST(path: '/api/v1/ws/{item_id}', optionalBody: true)
  Future<chopper.Response> _apiV1WsItemIdPost({
    @Path('item_id') required String? itemId,
    @Query('data') required String? data,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Websocket Update Post',
      operationId: 'websocket_update_post_api_v1_ws__item_id__post',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Websocket"],
      deprecated: false,
    ),
  });

  ///Websocket Update Get
  ///@param item_id
  ///@param data
  Future<chopper.Response> apiV1WsItemIdDataGet({
    required String? itemId,
    required String? data,
  }) {
    return _apiV1WsItemIdDataGet(itemId: itemId, data: data);
  }

  ///Websocket Update Get
  ///@param item_id
  ///@param data
  @GET(path: '/api/v1/ws/{item_id}/{data}')
  Future<chopper.Response> _apiV1WsItemIdDataGet({
    @Path('item_id') required String? itemId,
    @Path('data') required String? data,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Websocket Update Get',
      operationId: 'websocket_update_get_api_v1_ws__item_id___data__get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Websocket"],
      deprecated: false,
    ),
  });

  ///Api Generic Webhook Handler
  ///@param provider_name
  Future<chopper.Response<SimpleStatus>> apiV1CallbackProviderNamePost({
    required String? providerName,
  }) {
    generatedMapping.putIfAbsent(
      SimpleStatus,
      () => SimpleStatus.fromJsonFactory,
    );

    return _apiV1CallbackProviderNamePost(providerName: providerName);
  }

  ///Api Generic Webhook Handler
  ///@param provider_name
  @POST(path: '/api/v1/callback/{provider_name}', optionalBody: true)
  Future<chopper.Response<SimpleStatus>> _apiV1CallbackProviderNamePost({
    @Path('provider_name') required String? providerName,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Generic Webhook Handler',
      operationId:
          'api_generic_webhook_handler_api_v1_callback__provider_name__post',
      consumes: [],
      produces: [],
      security: [],
      tags: ["callback"],
      deprecated: false,
    ),
  });

  ///Tinyurl
  ///@param url
  ///@param endless
  Future<chopper.Response> apiV1TinyurlPost({
    required String? url,
    bool? endless,
  }) {
    return _apiV1TinyurlPost(url: url, endless: endless);
  }

  ///Tinyurl
  ///@param url
  ///@param endless
  @POST(path: '/api/v1/tinyurl', optionalBody: true)
  Future<chopper.Response> _apiV1TinyurlPost({
    @Query('url') required String? url,
    @Query('endless') bool? endless,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'creates a tinyurl',
      summary: 'Tinyurl',
      operationId: 'Tinyurl_api_v1_tinyurl_post',
      consumes: [],
      produces: [],
      security: ["APIKeyHeader", "APIKeyQuery"],
      tags: ["Tinyurl"],
      deprecated: false,
    ),
  });

  ///Tinyurl
  ///@param tinyurl_id
  Future<chopper.Response> apiV1TinyurlTinyurlIdGet({
    required String? tinyurlId,
  }) {
    return _apiV1TinyurlTinyurlIdGet(tinyurlId: tinyurlId);
  }

  ///Tinyurl
  ///@param tinyurl_id
  @GET(path: '/api/v1/tinyurl/{tinyurl_id}')
  Future<chopper.Response> _apiV1TinyurlTinyurlIdGet({
    @Path('tinyurl_id') required String? tinyurlId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'get a tinyurl by id',
      summary: 'Tinyurl',
      operationId: 'Tinyurl_api_v1_tinyurl__tinyurl_id__get',
      consumes: [],
      produces: [],
      security: ["APIKeyHeader", "APIKeyQuery"],
      tags: ["Tinyurl"],
      deprecated: false,
    ),
  });

  ///Tinyurl
  ///@param tinyurl_id
  Future<chopper.Response> apiV1TinyurlTinyurlIdDelete({
    required String? tinyurlId,
  }) {
    return _apiV1TinyurlTinyurlIdDelete(tinyurlId: tinyurlId);
  }

  ///Tinyurl
  ///@param tinyurl_id
  @DELETE(path: '/api/v1/tinyurl/{tinyurl_id}')
  Future<chopper.Response> _apiV1TinyurlTinyurlIdDelete({
    @Path('tinyurl_id') required String? tinyurlId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'delete a tinyurl by id',
      summary: 'Tinyurl',
      operationId: 'Tinyurl_api_v1_tinyurl__tinyurl_id__delete',
      consumes: [],
      produces: [],
      security: ["APIKeyHeader", "APIKeyQuery"],
      tags: ["Tinyurl"],
      deprecated: false,
    ),
  });

  ///Tinyurl
  ///@param tinyurl_id
  Future<chopper.Response> tTinyurlIdGet({required String? tinyurlId}) {
    return _tTinyurlIdGet(tinyurlId: tinyurlId);
  }

  ///Tinyurl
  ///@param tinyurl_id
  @GET(path: '/t/{tinyurl_id}')
  Future<chopper.Response> _tTinyurlIdGet({
    @Path('tinyurl_id') required String? tinyurlId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'redirects a tinyurl by id',
      summary: 'Tinyurl',
      operationId: 'Tinyurl_t__tinyurl_id__get',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Tinyurl"],
      deprecated: false,
    ),
  });

  ///Api Create Webpush Subscription
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<WebPushSubscription>> apiV1WebpushPost({
    String? usr,
    required CreateWebPushSubscription? body,
  }) {
    generatedMapping.putIfAbsent(
      WebPushSubscription,
      () => WebPushSubscription.fromJsonFactory,
    );

    return _apiV1WebpushPost(usr: usr, body: body);
  }

  ///Api Create Webpush Subscription
  ///@param usr
  ///@param cookie_access_token
  @POST(path: '/api/v1/webpush', optionalBody: true)
  Future<chopper.Response<WebPushSubscription>> _apiV1WebpushPost({
    @Query('usr') String? usr,
    @Body() required CreateWebPushSubscription? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Create Webpush Subscription',
      operationId: 'api_create_webpush_subscription_api_v1_webpush_post',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Webpush"],
      deprecated: false,
    ),
  });

  ///Api Delete Webpush Subscription
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response> apiV1WebpushDelete({String? usr}) {
    return _apiV1WebpushDelete(usr: usr);
  }

  ///Api Delete Webpush Subscription
  ///@param usr
  ///@param cookie_access_token
  @DELETE(path: '/api/v1/webpush')
  Future<chopper.Response> _apiV1WebpushDelete({
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Delete Webpush Subscription',
      operationId: 'api_delete_webpush_subscription_api_v1_webpush_delete',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Webpush"],
      deprecated: false,
    ),
  });

  ///Get paginated list of accounts
  ///@param usr
  ///@param limit
  ///@param offset
  ///@param sortby
  ///@param direction
  ///@param search Text based search
  ///@param cookie_access_token
  ///@param id Supports Filtering. Supports Search
  ///@param username Supports Filtering. Supports Search
  ///@param email Supports Filtering. Supports Search
  ///@param pubkey Supports Filtering. Supports Search
  ///@param external_id Supports Filtering. Supports Search
  ///@param wallet_id Supports Filtering. Supports Search
  Future<chopper.Response<Page>> usersApiV1UserGet({
    String? usr,
    int? limit,
    int? offset,
    String? sortby,
    enums.UsersApiV1UserGetDirection? direction,
    String? search,
    String? id,
    String? username,
    String? email,
    String? pubkey,
    String? externalId,
    String? walletId,
  }) {
    generatedMapping.putIfAbsent(Page, () => Page.fromJsonFactory);

    return _usersApiV1UserGet(
      usr: usr,
      limit: limit,
      offset: offset,
      sortby: sortby,
      direction: direction?.value?.toString(),
      search: search,
      id: id,
      username: username,
      email: email,
      pubkey: pubkey,
      externalId: externalId,
      walletId: walletId,
    );
  }

  ///Get paginated list of accounts
  ///@param usr
  ///@param limit
  ///@param offset
  ///@param sortby
  ///@param direction
  ///@param search Text based search
  ///@param cookie_access_token
  ///@param id Supports Filtering. Supports Search
  ///@param username Supports Filtering. Supports Search
  ///@param email Supports Filtering. Supports Search
  ///@param pubkey Supports Filtering. Supports Search
  ///@param external_id Supports Filtering. Supports Search
  ///@param wallet_id Supports Filtering. Supports Search
  @GET(path: '/users/api/v1/user')
  Future<chopper.Response<Page>> _usersApiV1UserGet({
    @Query('usr') String? usr,
    @Query('limit') int? limit,
    @Query('offset') int? offset,
    @Query('sortby') String? sortby,
    @Query('direction') String? direction,
    @Query('search') String? search,
    @Query('id') String? id,
    @Query('username') String? username,
    @Query('email') String? email,
    @Query('pubkey') String? pubkey,
    @Query('external_id') String? externalId,
    @Query('wallet_id') String? walletId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get paginated list of accounts',
      operationId: 'Get_accounts_users_api_v1_user_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Users"],
      deprecated: false,
    ),
  });

  ///Create User
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<CreateUser>> usersApiV1UserPost({
    String? usr,
    required CreateUser? body,
  }) {
    generatedMapping.putIfAbsent(CreateUser, () => CreateUser.fromJsonFactory);

    return _usersApiV1UserPost(usr: usr, body: body);
  }

  ///Create User
  ///@param usr
  ///@param cookie_access_token
  @POST(path: '/users/api/v1/user', optionalBody: true)
  Future<chopper.Response<CreateUser>> _usersApiV1UserPost({
    @Query('usr') String? usr,
    @Body() required CreateUser? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Create User',
      operationId: 'Create_user_users_api_v1_user_post',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Users"],
      deprecated: false,
    ),
  });

  ///Get user by Id
  ///@param user_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<User>> usersApiV1UserUserIdGet({
    required String? userId,
    String? usr,
  }) {
    generatedMapping.putIfAbsent(User, () => User.fromJsonFactory);

    return _usersApiV1UserUserIdGet(userId: userId, usr: usr);
  }

  ///Get user by Id
  ///@param user_id
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/users/api/v1/user/{user_id}')
  Future<chopper.Response<User>> _usersApiV1UserUserIdGet({
    @Path('user_id') required String? userId,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get user by Id',
      operationId: 'Get_user_users_api_v1_user__user_id__get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Users"],
      deprecated: false,
    ),
  });

  ///Update User
  ///@param user_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<CreateUser>> usersApiV1UserUserIdPut({
    required String? userId,
    String? usr,
    required CreateUser? body,
  }) {
    generatedMapping.putIfAbsent(CreateUser, () => CreateUser.fromJsonFactory);

    return _usersApiV1UserUserIdPut(userId: userId, usr: usr, body: body);
  }

  ///Update User
  ///@param user_id
  ///@param usr
  ///@param cookie_access_token
  @PUT(path: '/users/api/v1/user/{user_id}', optionalBody: true)
  Future<chopper.Response<CreateUser>> _usersApiV1UserUserIdPut({
    @Path('user_id') required String? userId,
    @Query('usr') String? usr,
    @Body() required CreateUser? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Update User',
      operationId: 'Update_user_users_api_v1_user__user_id__put',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Users"],
      deprecated: false,
    ),
  });

  ///Delete User By Id
  ///@param user_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<SimpleStatus>> usersApiV1UserUserIdDelete({
    required String? userId,
    String? usr,
  }) {
    generatedMapping.putIfAbsent(
      SimpleStatus,
      () => SimpleStatus.fromJsonFactory,
    );

    return _usersApiV1UserUserIdDelete(userId: userId, usr: usr);
  }

  ///Delete User By Id
  ///@param user_id
  ///@param usr
  ///@param cookie_access_token
  @DELETE(path: '/users/api/v1/user/{user_id}')
  Future<chopper.Response<SimpleStatus>> _usersApiV1UserUserIdDelete({
    @Path('user_id') required String? userId,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Delete User By Id',
      operationId: 'Delete_user_by_Id_users_api_v1_user__user_id__delete',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Users"],
      deprecated: false,
    ),
  });

  ///Reset User Password
  ///@param user_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<String>> usersApiV1UserUserIdResetPasswordPut({
    required String? userId,
    String? usr,
  }) {
    return _usersApiV1UserUserIdResetPasswordPut(userId: userId, usr: usr);
  }

  ///Reset User Password
  ///@param user_id
  ///@param usr
  ///@param cookie_access_token
  @PUT(path: '/users/api/v1/user/{user_id}/reset_password', optionalBody: true)
  Future<chopper.Response<String>> _usersApiV1UserUserIdResetPasswordPut({
    @Path('user_id') required String? userId,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Reset User Password',
      operationId:
          'Reset_user_password_users_api_v1_user__user_id__reset_password_put',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Users"],
      deprecated: false,
    ),
  });

  ///Give Or Revoke Admin Permsisions To A User
  ///@param user_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<SimpleStatus>> usersApiV1UserUserIdAdminGet({
    required String? userId,
    String? usr,
  }) {
    generatedMapping.putIfAbsent(
      SimpleStatus,
      () => SimpleStatus.fromJsonFactory,
    );

    return _usersApiV1UserUserIdAdminGet(userId: userId, usr: usr);
  }

  ///Give Or Revoke Admin Permsisions To A User
  ///@param user_id
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/users/api/v1/user/{user_id}/admin')
  Future<chopper.Response<SimpleStatus>> _usersApiV1UserUserIdAdminGet({
    @Path('user_id') required String? userId,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Give Or Revoke Admin Permsisions To A User',
      operationId:
          'Give_or_revoke_admin_permsisions_to_a_user_users_api_v1_user__user_id__admin_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Users"],
      deprecated: false,
    ),
  });

  ///Get Wallets For User
  ///@param user_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<List<Wallet>>> usersApiV1UserUserIdWalletGet({
    required String? userId,
    String? usr,
  }) {
    generatedMapping.putIfAbsent(Wallet, () => Wallet.fromJsonFactory);

    return _usersApiV1UserUserIdWalletGet(userId: userId, usr: usr);
  }

  ///Get Wallets For User
  ///@param user_id
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/users/api/v1/user/{user_id}/wallet')
  Future<chopper.Response<List<Wallet>>> _usersApiV1UserUserIdWalletGet({
    @Path('user_id') required String? userId,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get Wallets For User',
      operationId:
          'Get_wallets_for_user_users_api_v1_user__user_id__wallet_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Users"],
      deprecated: false,
    ),
  });

  ///Create A New Wallet For User
  ///@param user_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response> usersApiV1UserUserIdWalletPost({
    required String? userId,
    String? usr,
    required BodyCreateANewWalletForUserUsersApiV1UserUserIdWalletPost? body,
  }) {
    return _usersApiV1UserUserIdWalletPost(
      userId: userId,
      usr: usr,
      body: body,
    );
  }

  ///Create A New Wallet For User
  ///@param user_id
  ///@param usr
  ///@param cookie_access_token
  @POST(path: '/users/api/v1/user/{user_id}/wallet', optionalBody: true)
  Future<chopper.Response> _usersApiV1UserUserIdWalletPost({
    @Path('user_id') required String? userId,
    @Query('usr') String? usr,
    @Body()
    required BodyCreateANewWalletForUserUsersApiV1UserUserIdWalletPost? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Create A New Wallet For User',
      operationId:
          'Create_a_new_wallet_for_user_users_api_v1_user__user_id__wallet_post',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Users"],
      deprecated: false,
    ),
  });

  ///Reactivate Deleted Wallet
  ///@param user_id
  ///@param wallet
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<SimpleStatus>>
  usersApiV1UserUserIdWalletWalletUndeletePut({
    required String? userId,
    required String? wallet,
    String? usr,
  }) {
    generatedMapping.putIfAbsent(
      SimpleStatus,
      () => SimpleStatus.fromJsonFactory,
    );

    return _usersApiV1UserUserIdWalletWalletUndeletePut(
      userId: userId,
      wallet: wallet,
      usr: usr,
    );
  }

  ///Reactivate Deleted Wallet
  ///@param user_id
  ///@param wallet
  ///@param usr
  ///@param cookie_access_token
  @PUT(
    path: '/users/api/v1/user/{user_id}/wallet/{wallet}/undelete',
    optionalBody: true,
  )
  Future<chopper.Response<SimpleStatus>>
  _usersApiV1UserUserIdWalletWalletUndeletePut({
    @Path('user_id') required String? userId,
    @Path('wallet') required String? wallet,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Reactivate Deleted Wallet',
      operationId:
          'Reactivate_deleted_wallet_users_api_v1_user__user_id__wallet__wallet__undelete_put',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Users"],
      deprecated: false,
    ),
  });

  ///Soft delete (only sets a flag) all user wallets.
  ///@param user_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<SimpleStatus>> usersApiV1UserUserIdWalletsDelete({
    required String? userId,
    String? usr,
  }) {
    generatedMapping.putIfAbsent(
      SimpleStatus,
      () => SimpleStatus.fromJsonFactory,
    );

    return _usersApiV1UserUserIdWalletsDelete(userId: userId, usr: usr);
  }

  ///Soft delete (only sets a flag) all user wallets.
  ///@param user_id
  ///@param usr
  ///@param cookie_access_token
  @DELETE(path: '/users/api/v1/user/{user_id}/wallets')
  Future<chopper.Response<SimpleStatus>> _usersApiV1UserUserIdWalletsDelete({
    @Path('user_id') required String? userId,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Soft delete (only sets a flag) all user wallets.',
      operationId:
          'Delete_all_wallets_for_user_users_api_v1_user__user_id__wallets_delete',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Users"],
      deprecated: false,
    ),
  });

  ///First time it is called it does a soft delete (only sets a flag).The second time it is called will delete the entry from the DB
  ///@param user_id
  ///@param wallet
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<SimpleStatus>>
  usersApiV1UserUserIdWalletWalletDelete({
    required String? userId,
    required String? wallet,
    String? usr,
  }) {
    generatedMapping.putIfAbsent(
      SimpleStatus,
      () => SimpleStatus.fromJsonFactory,
    );

    return _usersApiV1UserUserIdWalletWalletDelete(
      userId: userId,
      wallet: wallet,
      usr: usr,
    );
  }

  ///First time it is called it does a soft delete (only sets a flag).The second time it is called will delete the entry from the DB
  ///@param user_id
  ///@param wallet
  ///@param usr
  ///@param cookie_access_token
  @DELETE(path: '/users/api/v1/user/{user_id}/wallet/{wallet}')
  Future<chopper.Response<SimpleStatus>>
  _usersApiV1UserUserIdWalletWalletDelete({
    @Path('user_id') required String? userId,
    @Path('wallet') required String? wallet,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary:
          'First time it is called it does a soft delete (only sets a flag).The second time it is called will delete the entry from the DB',
      operationId:
          'Delete_wallet_by_id_users_api_v1_user__user_id__wallet__wallet__delete',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Users"],
      deprecated: false,
    ),
  });

  ///Update balance for a particular wallet.
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<SimpleStatus>> usersApiV1BalancePut({
    String? usr,
    required UpdateBalance? body,
  }) {
    generatedMapping.putIfAbsent(
      SimpleStatus,
      () => SimpleStatus.fromJsonFactory,
    );

    return _usersApiV1BalancePut(usr: usr, body: body);
  }

  ///Update balance for a particular wallet.
  ///@param usr
  ///@param cookie_access_token
  @PUT(path: '/users/api/v1/balance', optionalBody: true)
  Future<chopper.Response<SimpleStatus>> _usersApiV1BalancePut({
    @Query('usr') String? usr,
    @Body() required UpdateBalance? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Update balance for a particular wallet.',
      operationId: 'UpdateBalance_users_api_v1_balance_put',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Users"],
      deprecated: false,
    ),
  });

  ///Get paginated list audit entries
  ///@param usr
  ///@param limit
  ///@param offset
  ///@param sortby
  ///@param direction
  ///@param search Text based search
  ///@param cookie_access_token
  ///@param ip_address Supports Filtering. Supports Search
  ///@param user_id Supports Filtering. Supports Search
  ///@param path Supports Filtering. Supports Search
  ///@param request_method Supports Filtering. Supports Search
  ///@param response_code Supports Filtering. Supports Search
  ///@param component Supports Filtering. Supports Search
  Future<chopper.Response<Page>> auditApiV1Get({
    String? usr,
    int? limit,
    int? offset,
    String? sortby,
    enums.AuditApiV1GetDirection? direction,
    String? search,
    String? ipAddress,
    String? userId,
    String? path,
    String? requestMethod,
    String? responseCode,
    String? component,
  }) {
    generatedMapping.putIfAbsent(Page, () => Page.fromJsonFactory);

    return _auditApiV1Get(
      usr: usr,
      limit: limit,
      offset: offset,
      sortby: sortby,
      direction: direction?.value?.toString(),
      search: search,
      ipAddress: ipAddress,
      userId: userId,
      path: path,
      requestMethod: requestMethod,
      responseCode: responseCode,
      component: component,
    );
  }

  ///Get paginated list audit entries
  ///@param usr
  ///@param limit
  ///@param offset
  ///@param sortby
  ///@param direction
  ///@param search Text based search
  ///@param cookie_access_token
  ///@param ip_address Supports Filtering. Supports Search
  ///@param user_id Supports Filtering. Supports Search
  ///@param path Supports Filtering. Supports Search
  ///@param request_method Supports Filtering. Supports Search
  ///@param response_code Supports Filtering. Supports Search
  ///@param component Supports Filtering. Supports Search
  @GET(path: '/audit/api/v1')
  Future<chopper.Response<Page>> _auditApiV1Get({
    @Query('usr') String? usr,
    @Query('limit') int? limit,
    @Query('offset') int? offset,
    @Query('sortby') String? sortby,
    @Query('direction') String? direction,
    @Query('search') String? search,
    @Query('ip_address') String? ipAddress,
    @Query('user_id') String? userId,
    @Query('path') String? path,
    @Query('request_method') String? requestMethod,
    @Query('response_code') String? responseCode,
    @Query('component') String? component,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get paginated list audit entries',
      operationId: 'Get_audit_entries_audit_api_v1_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Audit"],
      deprecated: false,
    ),
  });

  ///Get paginated list audit entries
  ///@param usr
  ///@param limit
  ///@param offset
  ///@param sortby
  ///@param direction
  ///@param search Text based search
  ///@param cookie_access_token
  ///@param ip_address Supports Filtering. Supports Search
  ///@param user_id Supports Filtering. Supports Search
  ///@param path Supports Filtering. Supports Search
  ///@param request_method Supports Filtering. Supports Search
  ///@param response_code Supports Filtering. Supports Search
  ///@param component Supports Filtering. Supports Search
  Future<chopper.Response<AuditStats>> auditApiV1StatsGet({
    String? usr,
    int? limit,
    int? offset,
    String? sortby,
    enums.AuditApiV1StatsGetDirection? direction,
    String? search,
    String? ipAddress,
    String? userId,
    String? path,
    String? requestMethod,
    String? responseCode,
    String? component,
  }) {
    generatedMapping.putIfAbsent(AuditStats, () => AuditStats.fromJsonFactory);

    return _auditApiV1StatsGet(
      usr: usr,
      limit: limit,
      offset: offset,
      sortby: sortby,
      direction: direction?.value?.toString(),
      search: search,
      ipAddress: ipAddress,
      userId: userId,
      path: path,
      requestMethod: requestMethod,
      responseCode: responseCode,
      component: component,
    );
  }

  ///Get paginated list audit entries
  ///@param usr
  ///@param limit
  ///@param offset
  ///@param sortby
  ///@param direction
  ///@param search Text based search
  ///@param cookie_access_token
  ///@param ip_address Supports Filtering. Supports Search
  ///@param user_id Supports Filtering. Supports Search
  ///@param path Supports Filtering. Supports Search
  ///@param request_method Supports Filtering. Supports Search
  ///@param response_code Supports Filtering. Supports Search
  ///@param component Supports Filtering. Supports Search
  @GET(path: '/audit/api/v1/stats')
  Future<chopper.Response<AuditStats>> _auditApiV1StatsGet({
    @Query('usr') String? usr,
    @Query('limit') int? limit,
    @Query('offset') int? offset,
    @Query('sortby') String? sortby,
    @Query('direction') String? direction,
    @Query('search') String? search,
    @Query('ip_address') String? ipAddress,
    @Query('user_id') String? userId,
    @Query('path') String? path,
    @Query('request_method') String? requestMethod,
    @Query('response_code') String? responseCode,
    @Query('component') String? component,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get paginated list audit entries',
      operationId: 'Get_audit_entries_audit_api_v1_stats_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Audit"],
      deprecated: false,
    ),
  });

  ///Get paginated list user assets
  ///@param usr
  ///@param limit
  ///@param offset
  ///@param sortby
  ///@param direction
  ///@param search Text based search
  ///@param cookie_access_token
  Future<chopper.Response<Page>> apiV1AssetsPaginatedGet({
    String? usr,
    int? limit,
    int? offset,
    String? sortby,
    enums.ApiV1AssetsPaginatedGetDirection? direction,
    String? search,
  }) {
    generatedMapping.putIfAbsent(Page, () => Page.fromJsonFactory);

    return _apiV1AssetsPaginatedGet(
      usr: usr,
      limit: limit,
      offset: offset,
      sortby: sortby,
      direction: direction?.value?.toString(),
      search: search,
    );
  }

  ///Get paginated list user assets
  ///@param usr
  ///@param limit
  ///@param offset
  ///@param sortby
  ///@param direction
  ///@param search Text based search
  ///@param cookie_access_token
  @GET(path: '/api/v1/assets/paginated')
  Future<chopper.Response<Page>> _apiV1AssetsPaginatedGet({
    @Query('usr') String? usr,
    @Query('limit') int? limit,
    @Query('offset') int? offset,
    @Query('sortby') String? sortby,
    @Query('direction') String? direction,
    @Query('search') String? search,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get paginated list user assets',
      operationId: 'Get_user_assets_api_v1_assets_paginated_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Assets"],
      deprecated: false,
    ),
  });

  ///Get user asset by ID
  ///@param asset_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<AssetInfo>> apiV1AssetsAssetIdGet({
    required String? assetId,
    String? usr,
  }) {
    generatedMapping.putIfAbsent(AssetInfo, () => AssetInfo.fromJsonFactory);

    return _apiV1AssetsAssetIdGet(assetId: assetId, usr: usr);
  }

  ///Get user asset by ID
  ///@param asset_id
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/api/v1/assets/{asset_id}')
  Future<chopper.Response<AssetInfo>> _apiV1AssetsAssetIdGet({
    @Path('asset_id') required String? assetId,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get user asset by ID',
      operationId: 'Get_user_asset_api_v1_assets__asset_id__get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Assets"],
      deprecated: false,
    ),
  });

  ///Update user asset by ID
  ///@param asset_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<AssetInfo>> apiV1AssetsAssetIdPut({
    required String? assetId,
    String? usr,
    required AssetUpdate? body,
  }) {
    generatedMapping.putIfAbsent(AssetInfo, () => AssetInfo.fromJsonFactory);

    return _apiV1AssetsAssetIdPut(assetId: assetId, usr: usr, body: body);
  }

  ///Update user asset by ID
  ///@param asset_id
  ///@param usr
  ///@param cookie_access_token
  @PUT(path: '/api/v1/assets/{asset_id}', optionalBody: true)
  Future<chopper.Response<AssetInfo>> _apiV1AssetsAssetIdPut({
    @Path('asset_id') required String? assetId,
    @Query('usr') String? usr,
    @Body() required AssetUpdate? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Update user asset by ID',
      operationId: 'Update_user_asset_api_v1_assets__asset_id__put',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Assets"],
      deprecated: false,
    ),
  });

  ///Delete user asset by ID
  ///@param asset_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<SimpleStatus>> apiV1AssetsAssetIdDelete({
    required String? assetId,
    String? usr,
  }) {
    generatedMapping.putIfAbsent(
      SimpleStatus,
      () => SimpleStatus.fromJsonFactory,
    );

    return _apiV1AssetsAssetIdDelete(assetId: assetId, usr: usr);
  }

  ///Delete user asset by ID
  ///@param asset_id
  ///@param usr
  ///@param cookie_access_token
  @DELETE(path: '/api/v1/assets/{asset_id}')
  Future<chopper.Response<SimpleStatus>> _apiV1AssetsAssetIdDelete({
    @Path('asset_id') required String? assetId,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Delete user asset by ID',
      operationId: 'Delete_user_asset_api_v1_assets__asset_id__delete',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Assets"],
      deprecated: false,
    ),
  });

  ///Get user asset binary data by ID
  ///@param asset_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response> apiV1AssetsAssetIdBinaryGet({
    required String? assetId,
    String? usr,
  }) {
    return _apiV1AssetsAssetIdBinaryGet(assetId: assetId, usr: usr);
  }

  ///Get user asset binary data by ID
  ///@param asset_id
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/api/v1/assets/{asset_id}/binary')
  Future<chopper.Response> _apiV1AssetsAssetIdBinaryGet({
    @Path('asset_id') required String? assetId,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get user asset binary data by ID',
      operationId: 'Get_user_asset_binary_api_v1_assets__asset_id__binary_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Assets"],
      deprecated: false,
    ),
  });

  ///Get user asset thumbnail data by ID
  ///@param asset_id
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response> apiV1AssetsAssetIdThumbnailGet({
    required String? assetId,
    String? usr,
  }) {
    return _apiV1AssetsAssetIdThumbnailGet(assetId: assetId, usr: usr);
  }

  ///Get user asset thumbnail data by ID
  ///@param asset_id
  ///@param usr
  ///@param cookie_access_token
  @GET(path: '/api/v1/assets/{asset_id}/thumbnail')
  Future<chopper.Response> _apiV1AssetsAssetIdThumbnailGet({
    @Path('asset_id') required String? assetId,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Get user asset thumbnail data by ID',
      operationId:
          'Get_user_asset_thumbnail_api_v1_assets__asset_id__thumbnail_get',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Assets"],
      deprecated: false,
    ),
  });

  ///Upload user assets
  ///@param public_asset
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<AssetInfo>> apiV1AssetsPost({
    bool? publicAsset,
    String? usr,
    required BodyUploadApiV1AssetsPost body,
  }) {
    generatedMapping.putIfAbsent(AssetInfo, () => AssetInfo.fromJsonFactory);

    return _apiV1AssetsPost(publicAsset: publicAsset, usr: usr, body: body);
  }

  ///Upload user assets
  ///@param public_asset
  ///@param usr
  ///@param cookie_access_token
  @POST(path: '/api/v1/assets', optionalBody: true)
  @Multipart()
  Future<chopper.Response<AssetInfo>> _apiV1AssetsPost({
    @Query('public_asset') bool? publicAsset,
    @Query('usr') String? usr,
    @Part() required BodyUploadApiV1AssetsPost body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Upload user assets',
      operationId: 'Upload_api_v1_assets_post',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Assets"],
      deprecated: false,
    ),
  });

  ///Api Test Fiat Provider
  ///@param provider
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response<SimpleStatus>> apiV1FiatCheckProviderPut({
    required String? provider,
    String? usr,
  }) {
    generatedMapping.putIfAbsent(
      SimpleStatus,
      () => SimpleStatus.fromJsonFactory,
    );

    return _apiV1FiatCheckProviderPut(provider: provider, usr: usr);
  }

  ///Api Test Fiat Provider
  ///@param provider
  ///@param usr
  ///@param cookie_access_token
  @PUT(path: '/api/v1/fiat/check/{provider}', optionalBody: true)
  Future<chopper.Response<SimpleStatus>> _apiV1FiatCheckProviderPut({
    @Path('provider') required String? provider,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Test Fiat Provider',
      operationId: 'api_test_fiat_provider_api_v1_fiat_check__provider__put',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Fiat API"],
      deprecated: false,
    ),
  });

  ///Create Subscription
  ///@param provider
  Future<chopper.Response<FiatSubscriptionResponse>>
  apiV1FiatProviderSubscriptionPost({
    required String? provider,
    required CreateFiatSubscription? body,
  }) {
    generatedMapping.putIfAbsent(
      FiatSubscriptionResponse,
      () => FiatSubscriptionResponse.fromJsonFactory,
    );

    return _apiV1FiatProviderSubscriptionPost(provider: provider, body: body);
  }

  ///Create Subscription
  ///@param provider
  @POST(path: '/api/v1/fiat/{provider}/subscription', optionalBody: true)
  Future<chopper.Response<FiatSubscriptionResponse>>
  _apiV1FiatProviderSubscriptionPost({
    @Path('provider') required String? provider,
    @Body() required CreateFiatSubscription? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Create Subscription',
      operationId:
          'create_subscription_api_v1_fiat__provider__subscription_post',
      consumes: [],
      produces: [],
      security: ["APIKeyHeader", "APIKeyQuery"],
      tags: ["Fiat API"],
      deprecated: false,
    ),
  });

  ///Cancel Subscription
  ///@param provider
  ///@param subscription_id
  Future<chopper.Response<FiatSubscriptionResponse>>
  apiV1FiatProviderSubscriptionSubscriptionIdDelete({
    required String? provider,
    required String? subscriptionId,
  }) {
    generatedMapping.putIfAbsent(
      FiatSubscriptionResponse,
      () => FiatSubscriptionResponse.fromJsonFactory,
    );

    return _apiV1FiatProviderSubscriptionSubscriptionIdDelete(
      provider: provider,
      subscriptionId: subscriptionId,
    );
  }

  ///Cancel Subscription
  ///@param provider
  ///@param subscription_id
  @DELETE(path: '/api/v1/fiat/{provider}/subscription/{subscription_id}')
  Future<chopper.Response<FiatSubscriptionResponse>>
  _apiV1FiatProviderSubscriptionSubscriptionIdDelete({
    @Path('provider') required String? provider,
    @Path('subscription_id') required String? subscriptionId,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Cancel Subscription',
      operationId:
          'cancel_subscription_api_v1_fiat__provider__subscription__subscription_id__delete',
      consumes: [],
      produces: [],
      security: ["APIKeyHeader", "APIKeyQuery"],
      tags: ["Fiat API"],
      deprecated: false,
    ),
  });

  ///Connection Token
  ///@param provider
  ///@param usr
  ///@param cookie_access_token
  Future<chopper.Response> apiV1FiatProviderConnectionTokenPost({
    required String? provider,
    String? usr,
  }) {
    return _apiV1FiatProviderConnectionTokenPost(provider: provider, usr: usr);
  }

  ///Connection Token
  ///@param provider
  ///@param usr
  ///@param cookie_access_token
  @POST(path: '/api/v1/fiat/{provider}/connection_token', optionalBody: true)
  Future<chopper.Response> _apiV1FiatProviderConnectionTokenPost({
    @Path('provider') required String? provider,
    @Query('usr') String? usr,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Connection Token',
      operationId:
          'connection_token_api_v1_fiat__provider__connection_token_post',
      consumes: [],
      produces: [],
      security: ["OAuth2PasswordBearer", "HTTPBearer"],
      tags: ["Fiat API"],
      deprecated: false,
    ),
  });

  ///Api Lnurlscan
  ///@param code
  @deprecated
  Future<chopper.Response> apiV1LnurlscanCodeGet({required String? code}) {
    return _apiV1LnurlscanCodeGet(code: code);
  }

  ///Api Lnurlscan
  ///@param code
  @deprecated
  @GET(path: '/api/v1/lnurlscan/{code}')
  Future<chopper.Response> _apiV1LnurlscanCodeGet({
    @Path('code') required String? code,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Lnurlscan',
      operationId: 'api_lnurlscan_api_v1_lnurlscan__code__get',
      consumes: [],
      produces: [],
      security: ["APIKeyHeader", "APIKeyQuery"],
      tags: ["LNURL"],
      deprecated: true,
    ),
  });

  ///Api Lnurlscan Post
  Future<chopper.Response> apiV1LnurlscanPost({required LnurlScan? body}) {
    return _apiV1LnurlscanPost(body: body);
  }

  ///Api Lnurlscan Post
  @POST(path: '/api/v1/lnurlscan', optionalBody: true)
  Future<chopper.Response> _apiV1LnurlscanPost({
    @Body() required LnurlScan? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Lnurlscan Post',
      operationId: 'api_lnurlscan_post_api_v1_lnurlscan_post',
      consumes: [],
      produces: [],
      security: ["APIKeyHeader", "APIKeyQuery"],
      tags: ["LNURL"],
      deprecated: false,
    ),
  });

  ///Api Perform Lnurlauth
  Future<chopper.Response<LnurlResponseModel>> apiV1LnurlauthPost({
    required LnurlAuthResponse? body,
  }) {
    generatedMapping.putIfAbsent(
      LnurlResponseModel,
      () => LnurlResponseModel.fromJsonFactory,
    );

    return _apiV1LnurlauthPost(body: body);
  }

  ///Api Perform Lnurlauth
  @POST(path: '/api/v1/lnurlauth', optionalBody: true)
  Future<chopper.Response<LnurlResponseModel>> _apiV1LnurlauthPost({
    @Body() required LnurlAuthResponse? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '',
      summary: 'Api Perform Lnurlauth',
      operationId: 'api_perform_lnurlauth_api_v1_lnurlauth_post',
      consumes: [],
      produces: [],
      security: ["APIKeyHeader", "APIKeyQuery"],
      tags: ["LNURL"],
      deprecated: false,
    ),
  });

  ///Api Payments Pay Lnurl
  Future<chopper.Response<Payment>> apiV1PaymentsLnurlPost({
    required CreateLnurlPayment? body,
  }) {
    generatedMapping.putIfAbsent(Payment, () => Payment.fromJsonFactory);

    return _apiV1PaymentsLnurlPost(body: body);
  }

  ///Api Payments Pay Lnurl
  @POST(path: '/api/v1/payments/lnurl', optionalBody: true)
  Future<chopper.Response<Payment>> _apiV1PaymentsLnurlPost({
    @Body() required CreateLnurlPayment? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: '''Pay an LNURL payment request.
Either provice `res` (LnurlPayResponse) or `lnurl` (str) in the `data` object.''',
      summary: 'Api Payments Pay Lnurl',
      operationId: 'api_payments_pay_lnurl_api_v1_payments_lnurl_post',
      consumes: [],
      produces: [],
      security: ["APIKeyHeader", "APIKeyQuery"],
      tags: ["LNURL"],
      deprecated: false,
    ),
  });
}

@JsonSerializable(explicitToJson: true)
class AccessControlList {
  const AccessControlList({
    required this.id,
    required this.name,
    this.endpoints,
    this.tokenIdList,
  });

  factory AccessControlList.fromJson(Map<String, dynamic> json) =>
      _$AccessControlListFromJson(json);

  static const toJsonFactory = _$AccessControlListToJson;
  Map<String, dynamic> toJson() => _$AccessControlListToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'name', includeIfNull: false)
  final String name;
  @JsonKey(
    name: 'endpoints',
    includeIfNull: false,
    defaultValue: <EndpointAccess>[],
  )
  final List<EndpointAccess>? endpoints;
  @JsonKey(
    name: 'token_id_list',
    includeIfNull: false,
    defaultValue: <SimpleItem>[],
  )
  final List<SimpleItem>? tokenIdList;
  static const fromJsonFactory = _$AccessControlListFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AccessControlList &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.endpoints, endpoints) ||
                const DeepCollectionEquality().equals(
                  other.endpoints,
                  endpoints,
                )) &&
            (identical(other.tokenIdList, tokenIdList) ||
                const DeepCollectionEquality().equals(
                  other.tokenIdList,
                  tokenIdList,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(endpoints) ^
      const DeepCollectionEquality().hash(tokenIdList) ^
      runtimeType.hashCode;
}

extension $AccessControlListExtension on AccessControlList {
  AccessControlList copyWith({
    String? id,
    String? name,
    List<EndpointAccess>? endpoints,
    List<SimpleItem>? tokenIdList,
  }) {
    return AccessControlList(
      id: id ?? this.id,
      name: name ?? this.name,
      endpoints: endpoints ?? this.endpoints,
      tokenIdList: tokenIdList ?? this.tokenIdList,
    );
  }

  AccessControlList copyWithWrapped({
    Wrapped<String>? id,
    Wrapped<String>? name,
    Wrapped<List<EndpointAccess>?>? endpoints,
    Wrapped<List<SimpleItem>?>? tokenIdList,
  }) {
    return AccessControlList(
      id: (id != null ? id.value : this.id),
      name: (name != null ? name.value : this.name),
      endpoints: (endpoints != null ? endpoints.value : this.endpoints),
      tokenIdList: (tokenIdList != null ? tokenIdList.value : this.tokenIdList),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ActionFields {
  const ActionFields({
    this.generateAction,
    this.generatePaymentLogic,
    this.walletId,
    this.currency,
    this.amount,
    this.amountSource,
    this.paidFlag,
  });

  factory ActionFields.fromJson(Map<String, dynamic> json) =>
      _$ActionFieldsFromJson(json);

  static const toJsonFactory = _$ActionFieldsToJson;
  Map<String, dynamic> toJson() => _$ActionFieldsToJson(this);

  @JsonKey(name: 'generate_action', includeIfNull: false, defaultValue: false)
  final bool? generateAction;
  @JsonKey(
    name: 'generate_payment_logic',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? generatePaymentLogic;
  @JsonKey(name: 'wallet_id', includeIfNull: false)
  final String? walletId;
  @JsonKey(name: 'currency', includeIfNull: false)
  final String? currency;
  @JsonKey(name: 'amount', includeIfNull: false)
  final String? amount;
  @JsonKey(
    name: 'amount_source',
    includeIfNull: false,
    toJson: actionFieldsAmountSourceNullableToJson,
    fromJson: actionFieldsAmountSourceNullableFromJson,
  )
  final enums.ActionFieldsAmountSource? amountSource;
  @JsonKey(name: 'paid_flag', includeIfNull: false)
  final String? paidFlag;
  static const fromJsonFactory = _$ActionFieldsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ActionFields &&
            (identical(other.generateAction, generateAction) ||
                const DeepCollectionEquality().equals(
                  other.generateAction,
                  generateAction,
                )) &&
            (identical(other.generatePaymentLogic, generatePaymentLogic) ||
                const DeepCollectionEquality().equals(
                  other.generatePaymentLogic,
                  generatePaymentLogic,
                )) &&
            (identical(other.walletId, walletId) ||
                const DeepCollectionEquality().equals(
                  other.walletId,
                  walletId,
                )) &&
            (identical(other.currency, currency) ||
                const DeepCollectionEquality().equals(
                  other.currency,
                  currency,
                )) &&
            (identical(other.amount, amount) ||
                const DeepCollectionEquality().equals(other.amount, amount)) &&
            (identical(other.amountSource, amountSource) ||
                const DeepCollectionEquality().equals(
                  other.amountSource,
                  amountSource,
                )) &&
            (identical(other.paidFlag, paidFlag) ||
                const DeepCollectionEquality().equals(
                  other.paidFlag,
                  paidFlag,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(generateAction) ^
      const DeepCollectionEquality().hash(generatePaymentLogic) ^
      const DeepCollectionEquality().hash(walletId) ^
      const DeepCollectionEquality().hash(currency) ^
      const DeepCollectionEquality().hash(amount) ^
      const DeepCollectionEquality().hash(amountSource) ^
      const DeepCollectionEquality().hash(paidFlag) ^
      runtimeType.hashCode;
}

extension $ActionFieldsExtension on ActionFields {
  ActionFields copyWith({
    bool? generateAction,
    bool? generatePaymentLogic,
    String? walletId,
    String? currency,
    String? amount,
    enums.ActionFieldsAmountSource? amountSource,
    String? paidFlag,
  }) {
    return ActionFields(
      generateAction: generateAction ?? this.generateAction,
      generatePaymentLogic: generatePaymentLogic ?? this.generatePaymentLogic,
      walletId: walletId ?? this.walletId,
      currency: currency ?? this.currency,
      amount: amount ?? this.amount,
      amountSource: amountSource ?? this.amountSource,
      paidFlag: paidFlag ?? this.paidFlag,
    );
  }

  ActionFields copyWithWrapped({
    Wrapped<bool?>? generateAction,
    Wrapped<bool?>? generatePaymentLogic,
    Wrapped<String?>? walletId,
    Wrapped<String?>? currency,
    Wrapped<String?>? amount,
    Wrapped<enums.ActionFieldsAmountSource?>? amountSource,
    Wrapped<String?>? paidFlag,
  }) {
    return ActionFields(
      generateAction: (generateAction != null
          ? generateAction.value
          : this.generateAction),
      generatePaymentLogic: (generatePaymentLogic != null
          ? generatePaymentLogic.value
          : this.generatePaymentLogic),
      walletId: (walletId != null ? walletId.value : this.walletId),
      currency: (currency != null ? currency.value : this.currency),
      amount: (amount != null ? amount.value : this.amount),
      amountSource: (amountSource != null
          ? amountSource.value
          : this.amountSource),
      paidFlag: (paidFlag != null ? paidFlag.value : this.paidFlag),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class AdminSettings {
  const AdminSettings({
    this.keycloakDiscoveryUrl,
    this.keycloakClientId,
    this.keycloakClientSecret,
    this.keycloakClientCustomOrg,
    this.keycloakClientCustomIcon,
    this.githubClientId,
    this.githubClientSecret,
    this.googleClientId,
    this.googleClientSecret,
    this.nostrAbsoluteRequestUrls,
    this.authTokenExpireMinutes,
    this.authAllMethods,
    this.authAllowedMethods,
    this.authCredetialsUpdateThreshold,
    this.authAuthenticationCacheMinutes,
    this.lnbitsAuditEnabled,
    this.lnbitsAuditRetentionDays,
    this.lnbitsAuditLogIpAddress,
    this.lnbitsAuditLogPathParams,
    this.lnbitsAuditLogQueryParams,
    this.lnbitsAuditLogRequestBody,
    this.lnbitsAuditIncludePaths,
    this.lnbitsAuditExcludePaths,
    this.lnbitsAuditHttpMethods,
    this.lnbitsAuditHttpResponseCodes,
    this.lnbitsNodeUi,
    this.lnbitsPublicNodeUi,
    this.lnbitsNodeUiTransactions,
    this.lnbitsWebpushPubkey,
    this.lnbitsWebpushPrivkey,
    this.lightningInvoiceExpiry,
    this.paypalEnabled,
    this.paypalApiEndpoint,
    this.paypalClientId,
    this.paypalClientSecret,
    this.paypalPaymentSuccessUrl,
    this.paypalPaymentWebhookUrl,
    this.paypalWebhookId,
    this.paypalLimits,
    this.stripeEnabled,
    this.stripeApiEndpoint,
    this.stripeApiSecretKey,
    this.stripePaymentSuccessUrl,
    this.stripePaymentWebhookUrl,
    this.stripeWebhookSigningSecret,
    this.stripeLimits,
    this.breezLiquidApiKey,
    this.breezLiquidSeed,
    this.breezLiquidFeeOffsetSat,
    this.strikeApiEndpoint,
    this.strikeApiKey,
    this.breezApiKey,
    this.breezGreenlightSeed,
    this.breezGreenlightInviteCode,
    this.breezGreenlightDeviceKey,
    this.breezGreenlightDeviceCert,
    this.breezUseTrampoline,
    this.nwcPairingUrl,
    this.lntipsApiEndpoint,
    this.lntipsApiKey,
    this.lntipsAdminKey,
    this.lntipsInvoiceKey,
    this.sparkUrl,
    this.sparkToken,
    this.opennodeApiEndpoint,
    this.opennodeKey,
    this.opennodeAdminKey,
    this.opennodeInvoiceKey,
    this.phoenixdApiEndpoint,
    this.phoenixdApiPassword,
    this.zbdApiEndpoint,
    this.zbdApiKey,
    this.boltzClientEndpoint,
    this.boltzClientMacaroon,
    this.boltzClientPassword,
    this.boltzClientCert,
    this.boltzMnemonic,
    this.albyApiEndpoint,
    this.albyAccessToken,
    this.blinkApiEndpoint,
    this.blinkWsEndpoint,
    this.blinkToken,
    this.lnpayApiEndpoint,
    this.lnpayApiKey,
    this.lnpayWalletKey,
    this.lnpayAdminKey,
    this.lndGrpcEndpoint,
    this.lndGrpcCert,
    this.lndGrpcPort,
    this.lndGrpcAdminMacaroon,
    this.lndGrpcInvoiceMacaroon,
    this.lndGrpcMacaroon,
    this.lndGrpcMacaroonEncrypted,
    this.lndRestEndpoint,
    this.lndRestCert,
    this.lndRestMacaroon,
    this.lndRestMacaroonEncrypted,
    this.lndRestRouteHints,
    this.lndRestAllowSelfPayment,
    this.lndCert,
    this.lndAdminMacaroon,
    this.lndInvoiceMacaroon,
    this.lndRestAdminMacaroon,
    this.lndRestInvoiceMacaroon,
    this.eclairUrl,
    this.eclairPass,
    this.corelightningRestUrl,
    this.corelightningRestMacaroon,
    this.corelightningRestCert,
    this.corelightningRpc,
    this.corelightningPayCommand,
    this.clightningRpc,
    this.clnrestUrl,
    this.clnrestCa,
    this.clnrestCert,
    this.clnrestReadonlyRune,
    this.clnrestInvoiceRune,
    this.clnrestPayRune,
    this.clnrestRenepayRune,
    this.clnrestLastPayIndex,
    this.clnrestNodeid,
    this.clicheEndpoint,
    this.lnbitsEndpoint,
    this.lnbitsKey,
    this.lnbitsAdminKey,
    this.lnbitsInvoiceKey,
    this.fakeWalletSecret,
    this.lnbitsDenomination,
    this.lnbitsBackendWalletClass,
    this.lnbitsFundingSourcePayInvoiceWaitSeconds,
    this.fundingSourceMaxRetries,
    this.lnbitsNostrNotificationsEnabled,
    this.lnbitsNostrNotificationsPrivateKey,
    this.lnbitsNostrNotificationsIdentifiers,
    this.lnbitsTelegramNotificationsEnabled,
    this.lnbitsTelegramNotificationsAccessToken,
    this.lnbitsTelegramNotificationsChatId,
    this.lnbitsEmailNotificationsEnabled,
    this.lnbitsEmailNotificationsEmail,
    this.lnbitsEmailNotificationsUsername,
    this.lnbitsEmailNotificationsPassword,
    this.lnbitsEmailNotificationsServer,
    this.lnbitsEmailNotificationsPort,
    this.lnbitsEmailNotificationsToEmails,
    this.lnbitsNotificationSettingsUpdate,
    this.lnbitsNotificationCreditDebit,
    this.notificationBalanceDeltaThresholdSats,
    this.lnbitsNotificationServerStartStop,
    this.lnbitsNotificationWatchdog,
    this.lnbitsNotificationServerStatusHours,
    this.lnbitsNotificationIncomingPaymentAmountSats,
    this.lnbitsNotificationOutgoingPaymentAmountSats,
    this.lnbitsRateLimitNo,
    this.lnbitsRateLimitUnit,
    this.lnbitsAllowedIps,
    this.lnbitsBlockedIps,
    this.lnbitsCallbackUrlRules,
    this.lnbitsWalletLimitMaxBalance,
    this.lnbitsWalletLimitDailyMaxWithdraw,
    this.lnbitsWalletLimitSecsBetweenTrans,
    this.lnbitsOnlyAllowIncomingPayments,
    this.lnbitsWatchdogSwitchToVoidwallet,
    this.lnbitsWatchdogIntervalMinutes,
    this.lnbitsWatchdogDelta,
    this.lnbitsMaxOutgoingPaymentAmountSats,
    this.lnbitsMaxIncomingPaymentAmountSats,
    this.lnbitsExchangeRateCacheSeconds,
    this.lnbitsExchangeHistorySize,
    this.lnbitsExchangeHistoryRefreshIntervalSeconds,
    this.lnbitsExchangeRateProviders,
    this.lnbitsReserveFeeMin,
    this.lnbitsReserveFeePercent,
    this.lnbitsServiceFee,
    this.lnbitsServiceFeeIgnoreInternal,
    this.lnbitsServiceFeeMax,
    this.lnbitsServiceFeeWallet,
    this.lnbitsMaxAssetSizeMb,
    this.lnbitsAssetsAllowedMimeTypes,
    this.lnbitsAssetThumbnailWidth,
    this.lnbitsAssetThumbnailHeight,
    this.lnbitsAssetThumbnailFormat,
    this.lnbitsMaxAssetsPerUser,
    this.lnbitsAssetsNoLimitUsers,
    this.lnbitsBaseurl,
    this.lnbitsHideApi,
    this.lnbitsSiteTitle,
    this.lnbitsSiteTagline,
    this.lnbitsSiteDescription,
    this.lnbitsShowHomePageElements,
    this.lnbitsDefaultWalletName,
    this.lnbitsCustomBadge,
    this.lnbitsCustomBadgeColor,
    this.lnbitsThemeOptions,
    this.lnbitsCustomLogo,
    this.lnbitsCustomImage,
    this.lnbitsAdSpaceTitle,
    this.lnbitsAdSpace,
    this.lnbitsAdSpaceEnabled,
    this.lnbitsAllowedCurrencies,
    this.lnbitsDefaultAccountingCurrency,
    this.lnbitsQrLogo,
    this.lnbitsAppleTouchIcon,
    this.lnbitsDefaultReaction,
    this.lnbitsDefaultTheme,
    this.lnbitsDefaultBorder,
    this.lnbitsDefaultGradient,
    this.lnbitsDefaultBgimage,
    this.lnbitsAdminExtensions,
    this.lnbitsUserDefaultExtensions,
    this.lnbitsExtensionsDeactivateAll,
    this.lnbitsExtensionsBuilderActivateNonAdmins,
    this.lnbitsExtensionsReviewsUrl,
    this.lnbitsExtensionsManifests,
    this.lnbitsExtensionsBuilderManifestUrl,
    this.lnbitsAdminUsers,
    this.lnbitsAllowedUsers,
    this.lnbitsAllowNewAccounts,
    required this.isSuperUser,
    this.lnbitsAllowedFundingSources,
  });

  factory AdminSettings.fromJson(Map<String, dynamic> json) =>
      _$AdminSettingsFromJson(json);

  static const toJsonFactory = _$AdminSettingsToJson;
  Map<String, dynamic> toJson() => _$AdminSettingsToJson(this);

  @JsonKey(name: 'keycloak_discovery_url', includeIfNull: false)
  final String? keycloakDiscoveryUrl;
  @JsonKey(name: 'keycloak_client_id', includeIfNull: false)
  final String? keycloakClientId;
  @JsonKey(name: 'keycloak_client_secret', includeIfNull: false)
  final String? keycloakClientSecret;
  @JsonKey(name: 'keycloak_client_custom_org', includeIfNull: false)
  final String? keycloakClientCustomOrg;
  @JsonKey(name: 'keycloak_client_custom_icon', includeIfNull: false)
  final String? keycloakClientCustomIcon;
  @JsonKey(name: 'github_client_id', includeIfNull: false)
  final String? githubClientId;
  @JsonKey(name: 'github_client_secret', includeIfNull: false)
  final String? githubClientSecret;
  @JsonKey(name: 'google_client_id', includeIfNull: false)
  final String? googleClientId;
  @JsonKey(name: 'google_client_secret', includeIfNull: false)
  final String? googleClientSecret;
  @JsonKey(
    name: 'nostr_absolute_request_urls',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? nostrAbsoluteRequestUrls;
  @JsonKey(name: 'auth_token_expire_minutes', includeIfNull: false)
  final int? authTokenExpireMinutes;
  @JsonKey(
    name: 'auth_all_methods',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? authAllMethods;
  @JsonKey(
    name: 'auth_allowed_methods',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? authAllowedMethods;
  @JsonKey(name: 'auth_credetials_update_threshold', includeIfNull: false)
  final int? authCredetialsUpdateThreshold;
  @JsonKey(name: 'auth_authentication_cache_minutes', includeIfNull: false)
  final int? authAuthenticationCacheMinutes;
  @JsonKey(
    name: 'lnbits_audit_enabled',
    includeIfNull: false,
    defaultValue: true,
  )
  final bool? lnbitsAuditEnabled;
  @JsonKey(name: 'lnbits_audit_retention_days', includeIfNull: false)
  final int? lnbitsAuditRetentionDays;
  @JsonKey(
    name: 'lnbits_audit_log_ip_address',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? lnbitsAuditLogIpAddress;
  @JsonKey(
    name: 'lnbits_audit_log_path_params',
    includeIfNull: false,
    defaultValue: true,
  )
  final bool? lnbitsAuditLogPathParams;
  @JsonKey(
    name: 'lnbits_audit_log_query_params',
    includeIfNull: false,
    defaultValue: true,
  )
  final bool? lnbitsAuditLogQueryParams;
  @JsonKey(
    name: 'lnbits_audit_log_request_body',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? lnbitsAuditLogRequestBody;
  @JsonKey(
    name: 'lnbits_audit_include_paths',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsAuditIncludePaths;
  @JsonKey(
    name: 'lnbits_audit_exclude_paths',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsAuditExcludePaths;
  @JsonKey(
    name: 'lnbits_audit_http_methods',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsAuditHttpMethods;
  @JsonKey(
    name: 'lnbits_audit_http_response_codes',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsAuditHttpResponseCodes;
  @JsonKey(name: 'lnbits_node_ui', includeIfNull: false, defaultValue: false)
  final bool? lnbitsNodeUi;
  @JsonKey(
    name: 'lnbits_public_node_ui',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? lnbitsPublicNodeUi;
  @JsonKey(
    name: 'lnbits_node_ui_transactions',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? lnbitsNodeUiTransactions;
  @JsonKey(name: 'lnbits_webpush_pubkey', includeIfNull: false)
  final String? lnbitsWebpushPubkey;
  @JsonKey(name: 'lnbits_webpush_privkey', includeIfNull: false)
  final String? lnbitsWebpushPrivkey;
  @JsonKey(name: 'lightning_invoice_expiry', includeIfNull: false)
  final int? lightningInvoiceExpiry;
  @JsonKey(name: 'paypal_enabled', includeIfNull: false, defaultValue: false)
  final bool? paypalEnabled;
  @JsonKey(name: 'paypal_api_endpoint', includeIfNull: false)
  final String? paypalApiEndpoint;
  @JsonKey(name: 'paypal_client_id', includeIfNull: false)
  final String? paypalClientId;
  @JsonKey(name: 'paypal_client_secret', includeIfNull: false)
  final String? paypalClientSecret;
  @JsonKey(name: 'paypal_payment_success_url', includeIfNull: false)
  final String? paypalPaymentSuccessUrl;
  @JsonKey(name: 'paypal_payment_webhook_url', includeIfNull: false)
  final String? paypalPaymentWebhookUrl;
  @JsonKey(name: 'paypal_webhook_id', includeIfNull: false)
  final String? paypalWebhookId;
  @JsonKey(name: 'paypal_limits', includeIfNull: false)
  final FiatProviderLimits? paypalLimits;
  @JsonKey(name: 'stripe_enabled', includeIfNull: false, defaultValue: false)
  final bool? stripeEnabled;
  @JsonKey(name: 'stripe_api_endpoint', includeIfNull: false)
  final String? stripeApiEndpoint;
  @JsonKey(name: 'stripe_api_secret_key', includeIfNull: false)
  final String? stripeApiSecretKey;
  @JsonKey(name: 'stripe_payment_success_url', includeIfNull: false)
  final String? stripePaymentSuccessUrl;
  @JsonKey(name: 'stripe_payment_webhook_url', includeIfNull: false)
  final String? stripePaymentWebhookUrl;
  @JsonKey(name: 'stripe_webhook_signing_secret', includeIfNull: false)
  final String? stripeWebhookSigningSecret;
  @JsonKey(name: 'stripe_limits', includeIfNull: false)
  final FiatProviderLimits? stripeLimits;
  @JsonKey(name: 'breez_liquid_api_key', includeIfNull: false)
  final String? breezLiquidApiKey;
  @JsonKey(name: 'breez_liquid_seed', includeIfNull: false)
  final String? breezLiquidSeed;
  @JsonKey(name: 'breez_liquid_fee_offset_sat', includeIfNull: false)
  final int? breezLiquidFeeOffsetSat;
  @JsonKey(name: 'strike_api_endpoint', includeIfNull: false)
  final String? strikeApiEndpoint;
  @JsonKey(name: 'strike_api_key', includeIfNull: false)
  final String? strikeApiKey;
  @JsonKey(name: 'breez_api_key', includeIfNull: false)
  final String? breezApiKey;
  @JsonKey(name: 'breez_greenlight_seed', includeIfNull: false)
  final String? breezGreenlightSeed;
  @JsonKey(name: 'breez_greenlight_invite_code', includeIfNull: false)
  final String? breezGreenlightInviteCode;
  @JsonKey(name: 'breez_greenlight_device_key', includeIfNull: false)
  final String? breezGreenlightDeviceKey;
  @JsonKey(name: 'breez_greenlight_device_cert', includeIfNull: false)
  final String? breezGreenlightDeviceCert;
  @JsonKey(
    name: 'breez_use_trampoline',
    includeIfNull: false,
    defaultValue: true,
  )
  final bool? breezUseTrampoline;
  @JsonKey(name: 'nwc_pairing_url', includeIfNull: false)
  final String? nwcPairingUrl;
  @JsonKey(name: 'lntips_api_endpoint', includeIfNull: false)
  final String? lntipsApiEndpoint;
  @JsonKey(name: 'lntips_api_key', includeIfNull: false)
  final String? lntipsApiKey;
  @JsonKey(name: 'lntips_admin_key', includeIfNull: false)
  final String? lntipsAdminKey;
  @JsonKey(name: 'lntips_invoice_key', includeIfNull: false)
  final String? lntipsInvoiceKey;
  @JsonKey(name: 'spark_url', includeIfNull: false)
  final String? sparkUrl;
  @JsonKey(name: 'spark_token', includeIfNull: false)
  final String? sparkToken;
  @JsonKey(name: 'opennode_api_endpoint', includeIfNull: false)
  final String? opennodeApiEndpoint;
  @JsonKey(name: 'opennode_key', includeIfNull: false)
  final String? opennodeKey;
  @JsonKey(name: 'opennode_admin_key', includeIfNull: false)
  final String? opennodeAdminKey;
  @JsonKey(name: 'opennode_invoice_key', includeIfNull: false)
  final String? opennodeInvoiceKey;
  @JsonKey(name: 'phoenixd_api_endpoint', includeIfNull: false)
  final String? phoenixdApiEndpoint;
  @JsonKey(name: 'phoenixd_api_password', includeIfNull: false)
  final String? phoenixdApiPassword;
  @JsonKey(name: 'zbd_api_endpoint', includeIfNull: false)
  final String? zbdApiEndpoint;
  @JsonKey(name: 'zbd_api_key', includeIfNull: false)
  final String? zbdApiKey;
  @JsonKey(name: 'boltz_client_endpoint', includeIfNull: false)
  final String? boltzClientEndpoint;
  @JsonKey(name: 'boltz_client_macaroon', includeIfNull: false)
  final String? boltzClientMacaroon;
  @JsonKey(name: 'boltz_client_password', includeIfNull: false)
  final String? boltzClientPassword;
  @JsonKey(name: 'boltz_client_cert', includeIfNull: false)
  final String? boltzClientCert;
  @JsonKey(name: 'boltz_mnemonic', includeIfNull: false)
  final String? boltzMnemonic;
  @JsonKey(name: 'alby_api_endpoint', includeIfNull: false)
  final String? albyApiEndpoint;
  @JsonKey(name: 'alby_access_token', includeIfNull: false)
  final String? albyAccessToken;
  @JsonKey(name: 'blink_api_endpoint', includeIfNull: false)
  final String? blinkApiEndpoint;
  @JsonKey(name: 'blink_ws_endpoint', includeIfNull: false)
  final String? blinkWsEndpoint;
  @JsonKey(name: 'blink_token', includeIfNull: false)
  final String? blinkToken;
  @JsonKey(name: 'lnpay_api_endpoint', includeIfNull: false)
  final String? lnpayApiEndpoint;
  @JsonKey(name: 'lnpay_api_key', includeIfNull: false)
  final String? lnpayApiKey;
  @JsonKey(name: 'lnpay_wallet_key', includeIfNull: false)
  final String? lnpayWalletKey;
  @JsonKey(name: 'lnpay_admin_key', includeIfNull: false)
  final String? lnpayAdminKey;
  @JsonKey(name: 'lnd_grpc_endpoint', includeIfNull: false)
  final String? lndGrpcEndpoint;
  @JsonKey(name: 'lnd_grpc_cert', includeIfNull: false)
  final String? lndGrpcCert;
  @JsonKey(name: 'lnd_grpc_port', includeIfNull: false)
  final int? lndGrpcPort;
  @JsonKey(name: 'lnd_grpc_admin_macaroon', includeIfNull: false)
  final String? lndGrpcAdminMacaroon;
  @JsonKey(name: 'lnd_grpc_invoice_macaroon', includeIfNull: false)
  final String? lndGrpcInvoiceMacaroon;
  @JsonKey(name: 'lnd_grpc_macaroon', includeIfNull: false)
  final String? lndGrpcMacaroon;
  @JsonKey(name: 'lnd_grpc_macaroon_encrypted', includeIfNull: false)
  final String? lndGrpcMacaroonEncrypted;
  @JsonKey(name: 'lnd_rest_endpoint', includeIfNull: false)
  final String? lndRestEndpoint;
  @JsonKey(name: 'lnd_rest_cert', includeIfNull: false)
  final String? lndRestCert;
  @JsonKey(name: 'lnd_rest_macaroon', includeIfNull: false)
  final String? lndRestMacaroon;
  @JsonKey(name: 'lnd_rest_macaroon_encrypted', includeIfNull: false)
  final String? lndRestMacaroonEncrypted;
  @JsonKey(
    name: 'lnd_rest_route_hints',
    includeIfNull: false,
    defaultValue: true,
  )
  final bool? lndRestRouteHints;
  @JsonKey(
    name: 'lnd_rest_allow_self_payment',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? lndRestAllowSelfPayment;
  @JsonKey(name: 'lnd_cert', includeIfNull: false)
  final String? lndCert;
  @JsonKey(name: 'lnd_admin_macaroon', includeIfNull: false)
  final String? lndAdminMacaroon;
  @JsonKey(name: 'lnd_invoice_macaroon', includeIfNull: false)
  final String? lndInvoiceMacaroon;
  @JsonKey(name: 'lnd_rest_admin_macaroon', includeIfNull: false)
  final String? lndRestAdminMacaroon;
  @JsonKey(name: 'lnd_rest_invoice_macaroon', includeIfNull: false)
  final String? lndRestInvoiceMacaroon;
  @JsonKey(name: 'eclair_url', includeIfNull: false)
  final String? eclairUrl;
  @JsonKey(name: 'eclair_pass', includeIfNull: false)
  final String? eclairPass;
  @JsonKey(name: 'corelightning_rest_url', includeIfNull: false)
  final String? corelightningRestUrl;
  @JsonKey(name: 'corelightning_rest_macaroon', includeIfNull: false)
  final String? corelightningRestMacaroon;
  @JsonKey(name: 'corelightning_rest_cert', includeIfNull: false)
  final String? corelightningRestCert;
  @JsonKey(name: 'corelightning_rpc', includeIfNull: false)
  final String? corelightningRpc;
  @JsonKey(name: 'corelightning_pay_command', includeIfNull: false)
  final String? corelightningPayCommand;
  @JsonKey(name: 'clightning_rpc', includeIfNull: false)
  final String? clightningRpc;
  @JsonKey(name: 'clnrest_url', includeIfNull: false)
  final String? clnrestUrl;
  @JsonKey(name: 'clnrest_ca', includeIfNull: false)
  final String? clnrestCa;
  @JsonKey(name: 'clnrest_cert', includeIfNull: false)
  final String? clnrestCert;
  @JsonKey(name: 'clnrest_readonly_rune', includeIfNull: false)
  final String? clnrestReadonlyRune;
  @JsonKey(name: 'clnrest_invoice_rune', includeIfNull: false)
  final String? clnrestInvoiceRune;
  @JsonKey(name: 'clnrest_pay_rune', includeIfNull: false)
  final String? clnrestPayRune;
  @JsonKey(name: 'clnrest_renepay_rune', includeIfNull: false)
  final String? clnrestRenepayRune;
  @JsonKey(name: 'clnrest_last_pay_index', includeIfNull: false)
  final String? clnrestLastPayIndex;
  @JsonKey(name: 'clnrest_nodeid', includeIfNull: false)
  final String? clnrestNodeid;
  @JsonKey(name: 'cliche_endpoint', includeIfNull: false)
  final String? clicheEndpoint;
  @JsonKey(name: 'lnbits_endpoint', includeIfNull: false)
  final String? lnbitsEndpoint;
  @JsonKey(name: 'lnbits_key', includeIfNull: false)
  final String? lnbitsKey;
  @JsonKey(name: 'lnbits_admin_key', includeIfNull: false)
  final String? lnbitsAdminKey;
  @JsonKey(name: 'lnbits_invoice_key', includeIfNull: false)
  final String? lnbitsInvoiceKey;
  @JsonKey(name: 'fake_wallet_secret', includeIfNull: false)
  final String? fakeWalletSecret;
  @JsonKey(name: 'lnbits_denomination', includeIfNull: false)
  final String? lnbitsDenomination;
  @JsonKey(name: 'lnbits_backend_wallet_class', includeIfNull: false)
  final String? lnbitsBackendWalletClass;
  @JsonKey(
    name: 'lnbits_funding_source_pay_invoice_wait_seconds',
    includeIfNull: false,
  )
  final int? lnbitsFundingSourcePayInvoiceWaitSeconds;
  @JsonKey(name: 'funding_source_max_retries', includeIfNull: false)
  final int? fundingSourceMaxRetries;
  @JsonKey(
    name: 'lnbits_nostr_notifications_enabled',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? lnbitsNostrNotificationsEnabled;
  @JsonKey(name: 'lnbits_nostr_notifications_private_key', includeIfNull: false)
  final String? lnbitsNostrNotificationsPrivateKey;
  @JsonKey(
    name: 'lnbits_nostr_notifications_identifiers',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsNostrNotificationsIdentifiers;
  @JsonKey(
    name: 'lnbits_telegram_notifications_enabled',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? lnbitsTelegramNotificationsEnabled;
  @JsonKey(
    name: 'lnbits_telegram_notifications_access_token',
    includeIfNull: false,
  )
  final String? lnbitsTelegramNotificationsAccessToken;
  @JsonKey(name: 'lnbits_telegram_notifications_chat_id', includeIfNull: false)
  final String? lnbitsTelegramNotificationsChatId;
  @JsonKey(
    name: 'lnbits_email_notifications_enabled',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? lnbitsEmailNotificationsEnabled;
  @JsonKey(name: 'lnbits_email_notifications_email', includeIfNull: false)
  final String? lnbitsEmailNotificationsEmail;
  @JsonKey(name: 'lnbits_email_notifications_username', includeIfNull: false)
  final String? lnbitsEmailNotificationsUsername;
  @JsonKey(name: 'lnbits_email_notifications_password', includeIfNull: false)
  final String? lnbitsEmailNotificationsPassword;
  @JsonKey(name: 'lnbits_email_notifications_server', includeIfNull: false)
  final String? lnbitsEmailNotificationsServer;
  @JsonKey(name: 'lnbits_email_notifications_port', includeIfNull: false)
  final int? lnbitsEmailNotificationsPort;
  @JsonKey(
    name: 'lnbits_email_notifications_to_emails',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsEmailNotificationsToEmails;
  @JsonKey(
    name: 'lnbits_notification_settings_update',
    includeIfNull: false,
    defaultValue: true,
  )
  final bool? lnbitsNotificationSettingsUpdate;
  @JsonKey(
    name: 'lnbits_notification_credit_debit',
    includeIfNull: false,
    defaultValue: true,
  )
  final bool? lnbitsNotificationCreditDebit;
  @JsonKey(
    name: 'notification_balance_delta_threshold_sats',
    includeIfNull: false,
  )
  final int? notificationBalanceDeltaThresholdSats;
  @JsonKey(
    name: 'lnbits_notification_server_start_stop',
    includeIfNull: false,
    defaultValue: true,
  )
  final bool? lnbitsNotificationServerStartStop;
  @JsonKey(
    name: 'lnbits_notification_watchdog',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? lnbitsNotificationWatchdog;
  @JsonKey(
    name: 'lnbits_notification_server_status_hours',
    includeIfNull: false,
  )
  final int? lnbitsNotificationServerStatusHours;
  @JsonKey(
    name: 'lnbits_notification_incoming_payment_amount_sats',
    includeIfNull: false,
  )
  final int? lnbitsNotificationIncomingPaymentAmountSats;
  @JsonKey(
    name: 'lnbits_notification_outgoing_payment_amount_sats',
    includeIfNull: false,
  )
  final int? lnbitsNotificationOutgoingPaymentAmountSats;
  @JsonKey(name: 'lnbits_rate_limit_no', includeIfNull: false)
  final int? lnbitsRateLimitNo;
  @JsonKey(name: 'lnbits_rate_limit_unit', includeIfNull: false)
  final String? lnbitsRateLimitUnit;
  @JsonKey(
    name: 'lnbits_allowed_ips',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsAllowedIps;
  @JsonKey(
    name: 'lnbits_blocked_ips',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsBlockedIps;
  @JsonKey(
    name: 'lnbits_callback_url_rules',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsCallbackUrlRules;
  @JsonKey(name: 'lnbits_wallet_limit_max_balance', includeIfNull: false)
  final int? lnbitsWalletLimitMaxBalance;
  @JsonKey(name: 'lnbits_wallet_limit_daily_max_withdraw', includeIfNull: false)
  final int? lnbitsWalletLimitDailyMaxWithdraw;
  @JsonKey(name: 'lnbits_wallet_limit_secs_between_trans', includeIfNull: false)
  final int? lnbitsWalletLimitSecsBetweenTrans;
  @JsonKey(
    name: 'lnbits_only_allow_incoming_payments',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? lnbitsOnlyAllowIncomingPayments;
  @JsonKey(
    name: 'lnbits_watchdog_switch_to_voidwallet',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? lnbitsWatchdogSwitchToVoidwallet;
  @JsonKey(name: 'lnbits_watchdog_interval_minutes', includeIfNull: false)
  final int? lnbitsWatchdogIntervalMinutes;
  @JsonKey(name: 'lnbits_watchdog_delta', includeIfNull: false)
  final int? lnbitsWatchdogDelta;
  @JsonKey(
    name: 'lnbits_max_outgoing_payment_amount_sats',
    includeIfNull: false,
  )
  final int? lnbitsMaxOutgoingPaymentAmountSats;
  @JsonKey(
    name: 'lnbits_max_incoming_payment_amount_sats',
    includeIfNull: false,
  )
  final int? lnbitsMaxIncomingPaymentAmountSats;
  @JsonKey(name: 'lnbits_exchange_rate_cache_seconds', includeIfNull: false)
  final int? lnbitsExchangeRateCacheSeconds;
  @JsonKey(name: 'lnbits_exchange_history_size', includeIfNull: false)
  final int? lnbitsExchangeHistorySize;
  @JsonKey(
    name: 'lnbits_exchange_history_refresh_interval_seconds',
    includeIfNull: false,
  )
  final int? lnbitsExchangeHistoryRefreshIntervalSeconds;
  @JsonKey(
    name: 'lnbits_exchange_rate_providers',
    includeIfNull: false,
    defaultValue: <ExchangeRateProvider>[],
  )
  final List<ExchangeRateProvider>? lnbitsExchangeRateProviders;
  @JsonKey(name: 'lnbits_reserve_fee_min', includeIfNull: false)
  final int? lnbitsReserveFeeMin;
  @JsonKey(name: 'lnbits_reserve_fee_percent', includeIfNull: false)
  final double? lnbitsReserveFeePercent;
  @JsonKey(name: 'lnbits_service_fee', includeIfNull: false)
  final double? lnbitsServiceFee;
  @JsonKey(
    name: 'lnbits_service_fee_ignore_internal',
    includeIfNull: false,
    defaultValue: true,
  )
  final bool? lnbitsServiceFeeIgnoreInternal;
  @JsonKey(name: 'lnbits_service_fee_max', includeIfNull: false)
  final int? lnbitsServiceFeeMax;
  @JsonKey(name: 'lnbits_service_fee_wallet', includeIfNull: false)
  final String? lnbitsServiceFeeWallet;
  @JsonKey(name: 'lnbits_max_asset_size_mb', includeIfNull: false)
  final double? lnbitsMaxAssetSizeMb;
  @JsonKey(
    name: 'lnbits_assets_allowed_mime_types',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsAssetsAllowedMimeTypes;
  @JsonKey(name: 'lnbits_asset_thumbnail_width', includeIfNull: false)
  final int? lnbitsAssetThumbnailWidth;
  @JsonKey(name: 'lnbits_asset_thumbnail_height', includeIfNull: false)
  final int? lnbitsAssetThumbnailHeight;
  @JsonKey(name: 'lnbits_asset_thumbnail_format', includeIfNull: false)
  final String? lnbitsAssetThumbnailFormat;
  @JsonKey(name: 'lnbits_max_assets_per_user', includeIfNull: false)
  final int? lnbitsMaxAssetsPerUser;
  @JsonKey(
    name: 'lnbits_assets_no_limit_users',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsAssetsNoLimitUsers;
  @JsonKey(name: 'lnbits_baseurl', includeIfNull: false)
  final String? lnbitsBaseurl;
  @JsonKey(name: 'lnbits_hide_api', includeIfNull: false, defaultValue: false)
  final bool? lnbitsHideApi;
  @JsonKey(name: 'lnbits_site_title', includeIfNull: false)
  final String? lnbitsSiteTitle;
  @JsonKey(name: 'lnbits_site_tagline', includeIfNull: false)
  final String? lnbitsSiteTagline;
  @JsonKey(name: 'lnbits_site_description', includeIfNull: false)
  final String? lnbitsSiteDescription;
  @JsonKey(
    name: 'lnbits_show_home_page_elements',
    includeIfNull: false,
    defaultValue: true,
  )
  final bool? lnbitsShowHomePageElements;
  @JsonKey(name: 'lnbits_default_wallet_name', includeIfNull: false)
  final String? lnbitsDefaultWalletName;
  @JsonKey(name: 'lnbits_custom_badge', includeIfNull: false)
  final String? lnbitsCustomBadge;
  @JsonKey(name: 'lnbits_custom_badge_color', includeIfNull: false)
  final String? lnbitsCustomBadgeColor;
  @JsonKey(
    name: 'lnbits_theme_options',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsThemeOptions;
  @JsonKey(name: 'lnbits_custom_logo', includeIfNull: false)
  final String? lnbitsCustomLogo;
  @JsonKey(name: 'lnbits_custom_image', includeIfNull: false)
  final String? lnbitsCustomImage;
  @JsonKey(name: 'lnbits_ad_space_title', includeIfNull: false)
  final String? lnbitsAdSpaceTitle;
  @JsonKey(name: 'lnbits_ad_space', includeIfNull: false)
  final String? lnbitsAdSpace;
  @JsonKey(
    name: 'lnbits_ad_space_enabled',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? lnbitsAdSpaceEnabled;
  @JsonKey(
    name: 'lnbits_allowed_currencies',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsAllowedCurrencies;
  @JsonKey(name: 'lnbits_default_accounting_currency', includeIfNull: false)
  final String? lnbitsDefaultAccountingCurrency;
  @JsonKey(name: 'lnbits_qr_logo', includeIfNull: false)
  final String? lnbitsQrLogo;
  @JsonKey(name: 'lnbits_apple_touch_icon', includeIfNull: false)
  final String? lnbitsAppleTouchIcon;
  @JsonKey(name: 'lnbits_default_reaction', includeIfNull: false)
  final String? lnbitsDefaultReaction;
  @JsonKey(name: 'lnbits_default_theme', includeIfNull: false)
  final String? lnbitsDefaultTheme;
  @JsonKey(name: 'lnbits_default_border', includeIfNull: false)
  final String? lnbitsDefaultBorder;
  @JsonKey(
    name: 'lnbits_default_gradient',
    includeIfNull: false,
    defaultValue: true,
  )
  final bool? lnbitsDefaultGradient;
  @JsonKey(name: 'lnbits_default_bgimage', includeIfNull: false)
  final String? lnbitsDefaultBgimage;
  @JsonKey(
    name: 'lnbits_admin_extensions',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsAdminExtensions;
  @JsonKey(
    name: 'lnbits_user_default_extensions',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsUserDefaultExtensions;
  @JsonKey(
    name: 'lnbits_extensions_deactivate_all',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? lnbitsExtensionsDeactivateAll;
  @JsonKey(
    name: 'lnbits_extensions_builder_activate_non_admins',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? lnbitsExtensionsBuilderActivateNonAdmins;
  @JsonKey(name: 'lnbits_extensions_reviews_url', includeIfNull: false)
  final String? lnbitsExtensionsReviewsUrl;
  @JsonKey(
    name: 'lnbits_extensions_manifests',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsExtensionsManifests;
  @JsonKey(name: 'lnbits_extensions_builder_manifest_url', includeIfNull: false)
  final String? lnbitsExtensionsBuilderManifestUrl;
  @JsonKey(
    name: 'lnbits_admin_users',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsAdminUsers;
  @JsonKey(
    name: 'lnbits_allowed_users',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsAllowedUsers;
  @JsonKey(
    name: 'lnbits_allow_new_accounts',
    includeIfNull: false,
    defaultValue: true,
  )
  final bool? lnbitsAllowNewAccounts;
  @JsonKey(name: 'is_super_user', includeIfNull: false)
  final bool isSuperUser;
  @JsonKey(
    name: 'lnbits_allowed_funding_sources',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsAllowedFundingSources;
  static const fromJsonFactory = _$AdminSettingsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AdminSettings &&
            (identical(other.keycloakDiscoveryUrl, keycloakDiscoveryUrl) ||
                const DeepCollectionEquality().equals(
                  other.keycloakDiscoveryUrl,
                  keycloakDiscoveryUrl,
                )) &&
            (identical(other.keycloakClientId, keycloakClientId) ||
                const DeepCollectionEquality().equals(
                  other.keycloakClientId,
                  keycloakClientId,
                )) &&
            (identical(other.keycloakClientSecret, keycloakClientSecret) ||
                const DeepCollectionEquality().equals(
                  other.keycloakClientSecret,
                  keycloakClientSecret,
                )) &&
            (identical(
                  other.keycloakClientCustomOrg,
                  keycloakClientCustomOrg,
                ) ||
                const DeepCollectionEquality().equals(
                  other.keycloakClientCustomOrg,
                  keycloakClientCustomOrg,
                )) &&
            (identical(
                  other.keycloakClientCustomIcon,
                  keycloakClientCustomIcon,
                ) ||
                const DeepCollectionEquality().equals(
                  other.keycloakClientCustomIcon,
                  keycloakClientCustomIcon,
                )) &&
            (identical(other.githubClientId, githubClientId) ||
                const DeepCollectionEquality().equals(
                  other.githubClientId,
                  githubClientId,
                )) &&
            (identical(other.githubClientSecret, githubClientSecret) ||
                const DeepCollectionEquality().equals(
                  other.githubClientSecret,
                  githubClientSecret,
                )) &&
            (identical(other.googleClientId, googleClientId) ||
                const DeepCollectionEquality().equals(
                  other.googleClientId,
                  googleClientId,
                )) &&
            (identical(other.googleClientSecret, googleClientSecret) ||
                const DeepCollectionEquality().equals(
                  other.googleClientSecret,
                  googleClientSecret,
                )) &&
            (identical(
                  other.nostrAbsoluteRequestUrls,
                  nostrAbsoluteRequestUrls,
                ) ||
                const DeepCollectionEquality().equals(
                  other.nostrAbsoluteRequestUrls,
                  nostrAbsoluteRequestUrls,
                )) &&
            (identical(other.authTokenExpireMinutes, authTokenExpireMinutes) ||
                const DeepCollectionEquality().equals(
                  other.authTokenExpireMinutes,
                  authTokenExpireMinutes,
                )) &&
            (identical(other.authAllMethods, authAllMethods) ||
                const DeepCollectionEquality().equals(
                  other.authAllMethods,
                  authAllMethods,
                )) &&
            (identical(other.authAllowedMethods, authAllowedMethods) ||
                const DeepCollectionEquality().equals(
                  other.authAllowedMethods,
                  authAllowedMethods,
                )) &&
            (identical(
                  other.authCredetialsUpdateThreshold,
                  authCredetialsUpdateThreshold,
                ) ||
                const DeepCollectionEquality().equals(
                  other.authCredetialsUpdateThreshold,
                  authCredetialsUpdateThreshold,
                )) &&
            (identical(
                  other.authAuthenticationCacheMinutes,
                  authAuthenticationCacheMinutes,
                ) ||
                const DeepCollectionEquality().equals(
                  other.authAuthenticationCacheMinutes,
                  authAuthenticationCacheMinutes,
                )) &&
            (identical(other.lnbitsAuditEnabled, lnbitsAuditEnabled) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAuditEnabled,
                  lnbitsAuditEnabled,
                )) &&
            (identical(
                  other.lnbitsAuditRetentionDays,
                  lnbitsAuditRetentionDays,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAuditRetentionDays,
                  lnbitsAuditRetentionDays,
                )) &&
            (identical(
                  other.lnbitsAuditLogIpAddress,
                  lnbitsAuditLogIpAddress,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAuditLogIpAddress,
                  lnbitsAuditLogIpAddress,
                )) &&
            (identical(
                  other.lnbitsAuditLogPathParams,
                  lnbitsAuditLogPathParams,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAuditLogPathParams,
                  lnbitsAuditLogPathParams,
                )) &&
            (identical(
                  other.lnbitsAuditLogQueryParams,
                  lnbitsAuditLogQueryParams,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAuditLogQueryParams,
                  lnbitsAuditLogQueryParams,
                )) &&
            (identical(
                  other.lnbitsAuditLogRequestBody,
                  lnbitsAuditLogRequestBody,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAuditLogRequestBody,
                  lnbitsAuditLogRequestBody,
                )) &&
            (identical(
                  other.lnbitsAuditIncludePaths,
                  lnbitsAuditIncludePaths,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAuditIncludePaths,
                  lnbitsAuditIncludePaths,
                )) &&
            (identical(
                  other.lnbitsAuditExcludePaths,
                  lnbitsAuditExcludePaths,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAuditExcludePaths,
                  lnbitsAuditExcludePaths,
                )) &&
            (identical(other.lnbitsAuditHttpMethods, lnbitsAuditHttpMethods) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAuditHttpMethods,
                  lnbitsAuditHttpMethods,
                )) &&
            (identical(
                  other.lnbitsAuditHttpResponseCodes,
                  lnbitsAuditHttpResponseCodes,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAuditHttpResponseCodes,
                  lnbitsAuditHttpResponseCodes,
                )) &&
            (identical(other.lnbitsNodeUi, lnbitsNodeUi) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsNodeUi,
                  lnbitsNodeUi,
                )) &&
            (identical(other.lnbitsPublicNodeUi, lnbitsPublicNodeUi) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsPublicNodeUi,
                  lnbitsPublicNodeUi,
                )) &&
            (identical(
                  other.lnbitsNodeUiTransactions,
                  lnbitsNodeUiTransactions,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsNodeUiTransactions,
                  lnbitsNodeUiTransactions,
                )) &&
            (identical(other.lnbitsWebpushPubkey, lnbitsWebpushPubkey) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsWebpushPubkey,
                  lnbitsWebpushPubkey,
                )) &&
            (identical(other.lnbitsWebpushPrivkey, lnbitsWebpushPrivkey) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsWebpushPrivkey,
                  lnbitsWebpushPrivkey,
                )) &&
            (identical(other.lightningInvoiceExpiry, lightningInvoiceExpiry) ||
                const DeepCollectionEquality().equals(
                  other.lightningInvoiceExpiry,
                  lightningInvoiceExpiry,
                )) &&
            (identical(other.paypalEnabled, paypalEnabled) ||
                const DeepCollectionEquality().equals(
                  other.paypalEnabled,
                  paypalEnabled,
                )) &&
            (identical(other.paypalApiEndpoint, paypalApiEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.paypalApiEndpoint,
                  paypalApiEndpoint,
                )) &&
            (identical(other.paypalClientId, paypalClientId) ||
                const DeepCollectionEquality().equals(
                  other.paypalClientId,
                  paypalClientId,
                )) &&
            (identical(other.paypalClientSecret, paypalClientSecret) ||
                const DeepCollectionEquality().equals(
                  other.paypalClientSecret,
                  paypalClientSecret,
                )) &&
            (identical(
                  other.paypalPaymentSuccessUrl,
                  paypalPaymentSuccessUrl,
                ) ||
                const DeepCollectionEquality().equals(
                  other.paypalPaymentSuccessUrl,
                  paypalPaymentSuccessUrl,
                )) &&
            (identical(
                  other.paypalPaymentWebhookUrl,
                  paypalPaymentWebhookUrl,
                ) ||
                const DeepCollectionEquality().equals(
                  other.paypalPaymentWebhookUrl,
                  paypalPaymentWebhookUrl,
                )) &&
            (identical(other.paypalWebhookId, paypalWebhookId) ||
                const DeepCollectionEquality().equals(
                  other.paypalWebhookId,
                  paypalWebhookId,
                )) &&
            (identical(other.paypalLimits, paypalLimits) ||
                const DeepCollectionEquality().equals(
                  other.paypalLimits,
                  paypalLimits,
                )) &&
            (identical(other.stripeEnabled, stripeEnabled) ||
                const DeepCollectionEquality().equals(
                  other.stripeEnabled,
                  stripeEnabled,
                )) &&
            (identical(other.stripeApiEndpoint, stripeApiEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.stripeApiEndpoint,
                  stripeApiEndpoint,
                )) &&
            (identical(other.stripeApiSecretKey, stripeApiSecretKey) ||
                const DeepCollectionEquality().equals(
                  other.stripeApiSecretKey,
                  stripeApiSecretKey,
                )) &&
            (identical(
                  other.stripePaymentSuccessUrl,
                  stripePaymentSuccessUrl,
                ) ||
                const DeepCollectionEquality().equals(
                  other.stripePaymentSuccessUrl,
                  stripePaymentSuccessUrl,
                )) &&
            (identical(
                  other.stripePaymentWebhookUrl,
                  stripePaymentWebhookUrl,
                ) ||
                const DeepCollectionEquality().equals(
                  other.stripePaymentWebhookUrl,
                  stripePaymentWebhookUrl,
                )) &&
            (identical(
                  other.stripeWebhookSigningSecret,
                  stripeWebhookSigningSecret,
                ) ||
                const DeepCollectionEquality().equals(
                  other.stripeWebhookSigningSecret,
                  stripeWebhookSigningSecret,
                )) &&
            (identical(other.stripeLimits, stripeLimits) ||
                const DeepCollectionEquality().equals(
                  other.stripeLimits,
                  stripeLimits,
                )) &&
            (identical(other.breezLiquidApiKey, breezLiquidApiKey) ||
                const DeepCollectionEquality().equals(
                  other.breezLiquidApiKey,
                  breezLiquidApiKey,
                )) &&
            (identical(other.breezLiquidSeed, breezLiquidSeed) ||
                const DeepCollectionEquality().equals(
                  other.breezLiquidSeed,
                  breezLiquidSeed,
                )) &&
            (identical(
                  other.breezLiquidFeeOffsetSat,
                  breezLiquidFeeOffsetSat,
                ) ||
                const DeepCollectionEquality().equals(
                  other.breezLiquidFeeOffsetSat,
                  breezLiquidFeeOffsetSat,
                )) &&
            (identical(other.strikeApiEndpoint, strikeApiEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.strikeApiEndpoint,
                  strikeApiEndpoint,
                )) &&
            (identical(other.strikeApiKey, strikeApiKey) ||
                const DeepCollectionEquality().equals(
                  other.strikeApiKey,
                  strikeApiKey,
                )) &&
            (identical(other.breezApiKey, breezApiKey) ||
                const DeepCollectionEquality().equals(
                  other.breezApiKey,
                  breezApiKey,
                )) &&
            (identical(other.breezGreenlightSeed, breezGreenlightSeed) ||
                const DeepCollectionEquality().equals(
                  other.breezGreenlightSeed,
                  breezGreenlightSeed,
                )) &&
            (identical(
                  other.breezGreenlightInviteCode,
                  breezGreenlightInviteCode,
                ) ||
                const DeepCollectionEquality().equals(
                  other.breezGreenlightInviteCode,
                  breezGreenlightInviteCode,
                )) &&
            (identical(
                  other.breezGreenlightDeviceKey,
                  breezGreenlightDeviceKey,
                ) ||
                const DeepCollectionEquality().equals(
                  other.breezGreenlightDeviceKey,
                  breezGreenlightDeviceKey,
                )) &&
            (identical(
                  other.breezGreenlightDeviceCert,
                  breezGreenlightDeviceCert,
                ) ||
                const DeepCollectionEquality().equals(
                  other.breezGreenlightDeviceCert,
                  breezGreenlightDeviceCert,
                )) &&
            (identical(other.breezUseTrampoline, breezUseTrampoline) ||
                const DeepCollectionEquality().equals(
                  other.breezUseTrampoline,
                  breezUseTrampoline,
                )) &&
            (identical(other.nwcPairingUrl, nwcPairingUrl) ||
                const DeepCollectionEquality().equals(
                  other.nwcPairingUrl,
                  nwcPairingUrl,
                )) &&
            (identical(other.lntipsApiEndpoint, lntipsApiEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.lntipsApiEndpoint,
                  lntipsApiEndpoint,
                )) &&
            (identical(other.lntipsApiKey, lntipsApiKey) ||
                const DeepCollectionEquality().equals(
                  other.lntipsApiKey,
                  lntipsApiKey,
                )) &&
            (identical(other.lntipsAdminKey, lntipsAdminKey) ||
                const DeepCollectionEquality().equals(
                  other.lntipsAdminKey,
                  lntipsAdminKey,
                )) &&
            (identical(other.lntipsInvoiceKey, lntipsInvoiceKey) ||
                const DeepCollectionEquality().equals(
                  other.lntipsInvoiceKey,
                  lntipsInvoiceKey,
                )) &&
            (identical(other.sparkUrl, sparkUrl) ||
                const DeepCollectionEquality().equals(
                  other.sparkUrl,
                  sparkUrl,
                )) &&
            (identical(other.sparkToken, sparkToken) ||
                const DeepCollectionEquality().equals(
                  other.sparkToken,
                  sparkToken,
                )) &&
            (identical(other.opennodeApiEndpoint, opennodeApiEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.opennodeApiEndpoint,
                  opennodeApiEndpoint,
                )) &&
            (identical(other.opennodeKey, opennodeKey) ||
                const DeepCollectionEquality().equals(
                  other.opennodeKey,
                  opennodeKey,
                )) &&
            (identical(other.opennodeAdminKey, opennodeAdminKey) ||
                const DeepCollectionEquality().equals(
                  other.opennodeAdminKey,
                  opennodeAdminKey,
                )) &&
            (identical(other.opennodeInvoiceKey, opennodeInvoiceKey) ||
                const DeepCollectionEquality().equals(
                  other.opennodeInvoiceKey,
                  opennodeInvoiceKey,
                )) &&
            (identical(other.phoenixdApiEndpoint, phoenixdApiEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.phoenixdApiEndpoint,
                  phoenixdApiEndpoint,
                )) &&
            (identical(other.phoenixdApiPassword, phoenixdApiPassword) ||
                const DeepCollectionEquality().equals(
                  other.phoenixdApiPassword,
                  phoenixdApiPassword,
                )) &&
            (identical(other.zbdApiEndpoint, zbdApiEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.zbdApiEndpoint,
                  zbdApiEndpoint,
                )) &&
            (identical(other.zbdApiKey, zbdApiKey) ||
                const DeepCollectionEquality().equals(
                  other.zbdApiKey,
                  zbdApiKey,
                )) &&
            (identical(other.boltzClientEndpoint, boltzClientEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.boltzClientEndpoint,
                  boltzClientEndpoint,
                )) &&
            (identical(other.boltzClientMacaroon, boltzClientMacaroon) ||
                const DeepCollectionEquality().equals(
                  other.boltzClientMacaroon,
                  boltzClientMacaroon,
                )) &&
            (identical(other.boltzClientPassword, boltzClientPassword) ||
                const DeepCollectionEquality().equals(
                  other.boltzClientPassword,
                  boltzClientPassword,
                )) &&
            (identical(other.boltzClientCert, boltzClientCert) ||
                const DeepCollectionEquality().equals(
                  other.boltzClientCert,
                  boltzClientCert,
                )) &&
            (identical(other.boltzMnemonic, boltzMnemonic) ||
                const DeepCollectionEquality().equals(
                  other.boltzMnemonic,
                  boltzMnemonic,
                )) &&
            (identical(other.albyApiEndpoint, albyApiEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.albyApiEndpoint,
                  albyApiEndpoint,
                )) &&
            (identical(other.albyAccessToken, albyAccessToken) ||
                const DeepCollectionEquality().equals(
                  other.albyAccessToken,
                  albyAccessToken,
                )) &&
            (identical(other.blinkApiEndpoint, blinkApiEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.blinkApiEndpoint,
                  blinkApiEndpoint,
                )) &&
            (identical(other.blinkWsEndpoint, blinkWsEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.blinkWsEndpoint,
                  blinkWsEndpoint,
                )) &&
            (identical(other.blinkToken, blinkToken) ||
                const DeepCollectionEquality().equals(
                  other.blinkToken,
                  blinkToken,
                )) &&
            (identical(other.lnpayApiEndpoint, lnpayApiEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.lnpayApiEndpoint,
                  lnpayApiEndpoint,
                )) &&
            (identical(other.lnpayApiKey, lnpayApiKey) ||
                const DeepCollectionEquality().equals(
                  other.lnpayApiKey,
                  lnpayApiKey,
                )) &&
            (identical(other.lnpayWalletKey, lnpayWalletKey) ||
                const DeepCollectionEquality().equals(
                  other.lnpayWalletKey,
                  lnpayWalletKey,
                )) &&
            (identical(other.lnpayAdminKey, lnpayAdminKey) ||
                const DeepCollectionEquality().equals(
                  other.lnpayAdminKey,
                  lnpayAdminKey,
                )) &&
            (identical(other.lndGrpcEndpoint, lndGrpcEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.lndGrpcEndpoint,
                  lndGrpcEndpoint,
                )) &&
            (identical(other.lndGrpcCert, lndGrpcCert) ||
                const DeepCollectionEquality().equals(
                  other.lndGrpcCert,
                  lndGrpcCert,
                )) &&
            (identical(other.lndGrpcPort, lndGrpcPort) ||
                const DeepCollectionEquality().equals(
                  other.lndGrpcPort,
                  lndGrpcPort,
                )) &&
            (identical(other.lndGrpcAdminMacaroon, lndGrpcAdminMacaroon) ||
                const DeepCollectionEquality().equals(
                  other.lndGrpcAdminMacaroon,
                  lndGrpcAdminMacaroon,
                )) &&
            (identical(other.lndGrpcInvoiceMacaroon, lndGrpcInvoiceMacaroon) ||
                const DeepCollectionEquality().equals(
                  other.lndGrpcInvoiceMacaroon,
                  lndGrpcInvoiceMacaroon,
                )) &&
            (identical(other.lndGrpcMacaroon, lndGrpcMacaroon) ||
                const DeepCollectionEquality().equals(
                  other.lndGrpcMacaroon,
                  lndGrpcMacaroon,
                )) &&
            (identical(
                  other.lndGrpcMacaroonEncrypted,
                  lndGrpcMacaroonEncrypted,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lndGrpcMacaroonEncrypted,
                  lndGrpcMacaroonEncrypted,
                )) &&
            (identical(other.lndRestEndpoint, lndRestEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.lndRestEndpoint,
                  lndRestEndpoint,
                )) &&
            (identical(other.lndRestCert, lndRestCert) ||
                const DeepCollectionEquality().equals(
                  other.lndRestCert,
                  lndRestCert,
                )) &&
            (identical(other.lndRestMacaroon, lndRestMacaroon) ||
                const DeepCollectionEquality().equals(
                  other.lndRestMacaroon,
                  lndRestMacaroon,
                )) &&
            (identical(
                  other.lndRestMacaroonEncrypted,
                  lndRestMacaroonEncrypted,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lndRestMacaroonEncrypted,
                  lndRestMacaroonEncrypted,
                )) &&
            (identical(other.lndRestRouteHints, lndRestRouteHints) ||
                const DeepCollectionEquality().equals(
                  other.lndRestRouteHints,
                  lndRestRouteHints,
                )) &&
            (identical(
                  other.lndRestAllowSelfPayment,
                  lndRestAllowSelfPayment,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lndRestAllowSelfPayment,
                  lndRestAllowSelfPayment,
                )) &&
            (identical(other.lndCert, lndCert) ||
                const DeepCollectionEquality().equals(
                  other.lndCert,
                  lndCert,
                )) &&
            (identical(other.lndAdminMacaroon, lndAdminMacaroon) ||
                const DeepCollectionEquality().equals(
                  other.lndAdminMacaroon,
                  lndAdminMacaroon,
                )) &&
            (identical(other.lndInvoiceMacaroon, lndInvoiceMacaroon) ||
                const DeepCollectionEquality().equals(
                  other.lndInvoiceMacaroon,
                  lndInvoiceMacaroon,
                )) &&
            (identical(other.lndRestAdminMacaroon, lndRestAdminMacaroon) ||
                const DeepCollectionEquality().equals(
                  other.lndRestAdminMacaroon,
                  lndRestAdminMacaroon,
                )) &&
            (identical(other.lndRestInvoiceMacaroon, lndRestInvoiceMacaroon) ||
                const DeepCollectionEquality().equals(
                  other.lndRestInvoiceMacaroon,
                  lndRestInvoiceMacaroon,
                )) &&
            (identical(other.eclairUrl, eclairUrl) ||
                const DeepCollectionEquality().equals(
                  other.eclairUrl,
                  eclairUrl,
                )) &&
            (identical(other.eclairPass, eclairPass) ||
                const DeepCollectionEquality().equals(
                  other.eclairPass,
                  eclairPass,
                )) &&
            (identical(other.corelightningRestUrl, corelightningRestUrl) ||
                const DeepCollectionEquality().equals(
                  other.corelightningRestUrl,
                  corelightningRestUrl,
                )) &&
            (identical(
                  other.corelightningRestMacaroon,
                  corelightningRestMacaroon,
                ) ||
                const DeepCollectionEquality().equals(
                  other.corelightningRestMacaroon,
                  corelightningRestMacaroon,
                )) &&
            (identical(other.corelightningRestCert, corelightningRestCert) ||
                const DeepCollectionEquality().equals(
                  other.corelightningRestCert,
                  corelightningRestCert,
                )) &&
            (identical(other.corelightningRpc, corelightningRpc) ||
                const DeepCollectionEquality().equals(
                  other.corelightningRpc,
                  corelightningRpc,
                )) &&
            (identical(
                  other.corelightningPayCommand,
                  corelightningPayCommand,
                ) ||
                const DeepCollectionEquality().equals(
                  other.corelightningPayCommand,
                  corelightningPayCommand,
                )) &&
            (identical(other.clightningRpc, clightningRpc) ||
                const DeepCollectionEquality().equals(
                  other.clightningRpc,
                  clightningRpc,
                )) &&
            (identical(other.clnrestUrl, clnrestUrl) ||
                const DeepCollectionEquality().equals(
                  other.clnrestUrl,
                  clnrestUrl,
                )) &&
            (identical(other.clnrestCa, clnrestCa) ||
                const DeepCollectionEquality().equals(
                  other.clnrestCa,
                  clnrestCa,
                )) &&
            (identical(other.clnrestCert, clnrestCert) ||
                const DeepCollectionEquality().equals(
                  other.clnrestCert,
                  clnrestCert,
                )) &&
            (identical(other.clnrestReadonlyRune, clnrestReadonlyRune) ||
                const DeepCollectionEquality().equals(
                  other.clnrestReadonlyRune,
                  clnrestReadonlyRune,
                )) &&
            (identical(other.clnrestInvoiceRune, clnrestInvoiceRune) ||
                const DeepCollectionEquality().equals(
                  other.clnrestInvoiceRune,
                  clnrestInvoiceRune,
                )) &&
            (identical(other.clnrestPayRune, clnrestPayRune) ||
                const DeepCollectionEquality().equals(
                  other.clnrestPayRune,
                  clnrestPayRune,
                )) &&
            (identical(other.clnrestRenepayRune, clnrestRenepayRune) ||
                const DeepCollectionEquality().equals(
                  other.clnrestRenepayRune,
                  clnrestRenepayRune,
                )) &&
            (identical(other.clnrestLastPayIndex, clnrestLastPayIndex) ||
                const DeepCollectionEquality().equals(
                  other.clnrestLastPayIndex,
                  clnrestLastPayIndex,
                )) &&
            (identical(other.clnrestNodeid, clnrestNodeid) ||
                const DeepCollectionEquality().equals(
                  other.clnrestNodeid,
                  clnrestNodeid,
                )) &&
            (identical(other.clicheEndpoint, clicheEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.clicheEndpoint,
                  clicheEndpoint,
                )) &&
            (identical(other.lnbitsEndpoint, lnbitsEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsEndpoint,
                  lnbitsEndpoint,
                )) &&
            (identical(other.lnbitsKey, lnbitsKey) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsKey,
                  lnbitsKey,
                )) &&
            (identical(other.lnbitsAdminKey, lnbitsAdminKey) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAdminKey,
                  lnbitsAdminKey,
                )) &&
            (identical(other.lnbitsInvoiceKey, lnbitsInvoiceKey) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsInvoiceKey,
                  lnbitsInvoiceKey,
                )) &&
            (identical(other.fakeWalletSecret, fakeWalletSecret) ||
                const DeepCollectionEquality().equals(
                  other.fakeWalletSecret,
                  fakeWalletSecret,
                )) &&
            (identical(other.lnbitsDenomination, lnbitsDenomination) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsDenomination,
                  lnbitsDenomination,
                )) &&
            (identical(
                  other.lnbitsBackendWalletClass,
                  lnbitsBackendWalletClass,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsBackendWalletClass,
                  lnbitsBackendWalletClass,
                )) &&
            (identical(
                  other.lnbitsFundingSourcePayInvoiceWaitSeconds,
                  lnbitsFundingSourcePayInvoiceWaitSeconds,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsFundingSourcePayInvoiceWaitSeconds,
                  lnbitsFundingSourcePayInvoiceWaitSeconds,
                )) &&
            (identical(
                  other.fundingSourceMaxRetries,
                  fundingSourceMaxRetries,
                ) ||
                const DeepCollectionEquality().equals(
                  other.fundingSourceMaxRetries,
                  fundingSourceMaxRetries,
                )) &&
            (identical(
                  other.lnbitsNostrNotificationsEnabled,
                  lnbitsNostrNotificationsEnabled,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsNostrNotificationsEnabled,
                  lnbitsNostrNotificationsEnabled,
                )) &&
            (identical(
                  other.lnbitsNostrNotificationsPrivateKey,
                  lnbitsNostrNotificationsPrivateKey,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsNostrNotificationsPrivateKey,
                  lnbitsNostrNotificationsPrivateKey,
                )) &&
            (identical(
                  other.lnbitsNostrNotificationsIdentifiers,
                  lnbitsNostrNotificationsIdentifiers,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsNostrNotificationsIdentifiers,
                  lnbitsNostrNotificationsIdentifiers,
                )) &&
            (identical(
                  other.lnbitsTelegramNotificationsEnabled,
                  lnbitsTelegramNotificationsEnabled,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsTelegramNotificationsEnabled,
                  lnbitsTelegramNotificationsEnabled,
                )) &&
            (identical(
                  other.lnbitsTelegramNotificationsAccessToken,
                  lnbitsTelegramNotificationsAccessToken,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsTelegramNotificationsAccessToken,
                  lnbitsTelegramNotificationsAccessToken,
                )) &&
            (identical(
                  other.lnbitsTelegramNotificationsChatId,
                  lnbitsTelegramNotificationsChatId,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsTelegramNotificationsChatId,
                  lnbitsTelegramNotificationsChatId,
                )) &&
            (identical(
                  other.lnbitsEmailNotificationsEnabled,
                  lnbitsEmailNotificationsEnabled,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsEmailNotificationsEnabled,
                  lnbitsEmailNotificationsEnabled,
                )) &&
            (identical(
                  other.lnbitsEmailNotificationsEmail,
                  lnbitsEmailNotificationsEmail,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsEmailNotificationsEmail,
                  lnbitsEmailNotificationsEmail,
                )) &&
            (identical(
                  other.lnbitsEmailNotificationsUsername,
                  lnbitsEmailNotificationsUsername,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsEmailNotificationsUsername,
                  lnbitsEmailNotificationsUsername,
                )) &&
            (identical(
                  other.lnbitsEmailNotificationsPassword,
                  lnbitsEmailNotificationsPassword,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsEmailNotificationsPassword,
                  lnbitsEmailNotificationsPassword,
                )) &&
            (identical(
                  other.lnbitsEmailNotificationsServer,
                  lnbitsEmailNotificationsServer,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsEmailNotificationsServer,
                  lnbitsEmailNotificationsServer,
                )) &&
            (identical(
                  other.lnbitsEmailNotificationsPort,
                  lnbitsEmailNotificationsPort,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsEmailNotificationsPort,
                  lnbitsEmailNotificationsPort,
                )) &&
            (identical(
                  other.lnbitsEmailNotificationsToEmails,
                  lnbitsEmailNotificationsToEmails,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsEmailNotificationsToEmails,
                  lnbitsEmailNotificationsToEmails,
                )) &&
            (identical(
                  other.lnbitsNotificationSettingsUpdate,
                  lnbitsNotificationSettingsUpdate,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsNotificationSettingsUpdate,
                  lnbitsNotificationSettingsUpdate,
                )) &&
            (identical(
                  other.lnbitsNotificationCreditDebit,
                  lnbitsNotificationCreditDebit,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsNotificationCreditDebit,
                  lnbitsNotificationCreditDebit,
                )) &&
            (identical(
                  other.notificationBalanceDeltaThresholdSats,
                  notificationBalanceDeltaThresholdSats,
                ) ||
                const DeepCollectionEquality().equals(
                  other.notificationBalanceDeltaThresholdSats,
                  notificationBalanceDeltaThresholdSats,
                )) &&
            (identical(
                  other.lnbitsNotificationServerStartStop,
                  lnbitsNotificationServerStartStop,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsNotificationServerStartStop,
                  lnbitsNotificationServerStartStop,
                )) &&
            (identical(
                  other.lnbitsNotificationWatchdog,
                  lnbitsNotificationWatchdog,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsNotificationWatchdog,
                  lnbitsNotificationWatchdog,
                )) &&
            (identical(
                  other.lnbitsNotificationServerStatusHours,
                  lnbitsNotificationServerStatusHours,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsNotificationServerStatusHours,
                  lnbitsNotificationServerStatusHours,
                )) &&
            (identical(
                  other.lnbitsNotificationIncomingPaymentAmountSats,
                  lnbitsNotificationIncomingPaymentAmountSats,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsNotificationIncomingPaymentAmountSats,
                  lnbitsNotificationIncomingPaymentAmountSats,
                )) &&
            (identical(
                  other.lnbitsNotificationOutgoingPaymentAmountSats,
                  lnbitsNotificationOutgoingPaymentAmountSats,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsNotificationOutgoingPaymentAmountSats,
                  lnbitsNotificationOutgoingPaymentAmountSats,
                )) &&
            (identical(other.lnbitsRateLimitNo, lnbitsRateLimitNo) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsRateLimitNo,
                  lnbitsRateLimitNo,
                )) &&
            (identical(other.lnbitsRateLimitUnit, lnbitsRateLimitUnit) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsRateLimitUnit,
                  lnbitsRateLimitUnit,
                )) &&
            (identical(other.lnbitsAllowedIps, lnbitsAllowedIps) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAllowedIps,
                  lnbitsAllowedIps,
                )) &&
            (identical(other.lnbitsBlockedIps, lnbitsBlockedIps) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsBlockedIps,
                  lnbitsBlockedIps,
                )) &&
            (identical(other.lnbitsCallbackUrlRules, lnbitsCallbackUrlRules) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsCallbackUrlRules,
                  lnbitsCallbackUrlRules,
                )) &&
            (identical(
                  other.lnbitsWalletLimitMaxBalance,
                  lnbitsWalletLimitMaxBalance,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsWalletLimitMaxBalance,
                  lnbitsWalletLimitMaxBalance,
                )) &&
            (identical(
                  other.lnbitsWalletLimitDailyMaxWithdraw,
                  lnbitsWalletLimitDailyMaxWithdraw,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsWalletLimitDailyMaxWithdraw,
                  lnbitsWalletLimitDailyMaxWithdraw,
                )) &&
            (identical(
                  other.lnbitsWalletLimitSecsBetweenTrans,
                  lnbitsWalletLimitSecsBetweenTrans,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsWalletLimitSecsBetweenTrans,
                  lnbitsWalletLimitSecsBetweenTrans,
                )) &&
            (identical(
                  other.lnbitsOnlyAllowIncomingPayments,
                  lnbitsOnlyAllowIncomingPayments,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsOnlyAllowIncomingPayments,
                  lnbitsOnlyAllowIncomingPayments,
                )) &&
            (identical(
                  other.lnbitsWatchdogSwitchToVoidwallet,
                  lnbitsWatchdogSwitchToVoidwallet,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsWatchdogSwitchToVoidwallet,
                  lnbitsWatchdogSwitchToVoidwallet,
                )) &&
            (identical(
                  other.lnbitsWatchdogIntervalMinutes,
                  lnbitsWatchdogIntervalMinutes,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsWatchdogIntervalMinutes,
                  lnbitsWatchdogIntervalMinutes,
                )) &&
            (identical(other.lnbitsWatchdogDelta, lnbitsWatchdogDelta) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsWatchdogDelta,
                  lnbitsWatchdogDelta,
                )) &&
            (identical(
                  other.lnbitsMaxOutgoingPaymentAmountSats,
                  lnbitsMaxOutgoingPaymentAmountSats,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsMaxOutgoingPaymentAmountSats,
                  lnbitsMaxOutgoingPaymentAmountSats,
                )) &&
            (identical(
                  other.lnbitsMaxIncomingPaymentAmountSats,
                  lnbitsMaxIncomingPaymentAmountSats,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsMaxIncomingPaymentAmountSats,
                  lnbitsMaxIncomingPaymentAmountSats,
                )) &&
            (identical(
                  other.lnbitsExchangeRateCacheSeconds,
                  lnbitsExchangeRateCacheSeconds,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsExchangeRateCacheSeconds,
                  lnbitsExchangeRateCacheSeconds,
                )) &&
            (identical(
                  other.lnbitsExchangeHistorySize,
                  lnbitsExchangeHistorySize,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsExchangeHistorySize,
                  lnbitsExchangeHistorySize,
                )) &&
            (identical(
                  other.lnbitsExchangeHistoryRefreshIntervalSeconds,
                  lnbitsExchangeHistoryRefreshIntervalSeconds,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsExchangeHistoryRefreshIntervalSeconds,
                  lnbitsExchangeHistoryRefreshIntervalSeconds,
                )) &&
            (identical(
                  other.lnbitsExchangeRateProviders,
                  lnbitsExchangeRateProviders,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsExchangeRateProviders,
                  lnbitsExchangeRateProviders,
                )) &&
            (identical(other.lnbitsReserveFeeMin, lnbitsReserveFeeMin) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsReserveFeeMin,
                  lnbitsReserveFeeMin,
                )) &&
            (identical(
                  other.lnbitsReserveFeePercent,
                  lnbitsReserveFeePercent,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsReserveFeePercent,
                  lnbitsReserveFeePercent,
                )) &&
            (identical(other.lnbitsServiceFee, lnbitsServiceFee) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsServiceFee,
                  lnbitsServiceFee,
                )) &&
            (identical(
                  other.lnbitsServiceFeeIgnoreInternal,
                  lnbitsServiceFeeIgnoreInternal,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsServiceFeeIgnoreInternal,
                  lnbitsServiceFeeIgnoreInternal,
                )) &&
            (identical(other.lnbitsServiceFeeMax, lnbitsServiceFeeMax) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsServiceFeeMax,
                  lnbitsServiceFeeMax,
                )) &&
            (identical(other.lnbitsServiceFeeWallet, lnbitsServiceFeeWallet) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsServiceFeeWallet,
                  lnbitsServiceFeeWallet,
                )) &&
            (identical(other.lnbitsMaxAssetSizeMb, lnbitsMaxAssetSizeMb) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsMaxAssetSizeMb,
                  lnbitsMaxAssetSizeMb,
                )) &&
            (identical(
                  other.lnbitsAssetsAllowedMimeTypes,
                  lnbitsAssetsAllowedMimeTypes,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAssetsAllowedMimeTypes,
                  lnbitsAssetsAllowedMimeTypes,
                )) &&
            (identical(
                  other.lnbitsAssetThumbnailWidth,
                  lnbitsAssetThumbnailWidth,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAssetThumbnailWidth,
                  lnbitsAssetThumbnailWidth,
                )) &&
            (identical(
                  other.lnbitsAssetThumbnailHeight,
                  lnbitsAssetThumbnailHeight,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAssetThumbnailHeight,
                  lnbitsAssetThumbnailHeight,
                )) &&
            (identical(
                  other.lnbitsAssetThumbnailFormat,
                  lnbitsAssetThumbnailFormat,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAssetThumbnailFormat,
                  lnbitsAssetThumbnailFormat,
                )) &&
            (identical(other.lnbitsMaxAssetsPerUser, lnbitsMaxAssetsPerUser) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsMaxAssetsPerUser,
                  lnbitsMaxAssetsPerUser,
                )) &&
            (identical(
                  other.lnbitsAssetsNoLimitUsers,
                  lnbitsAssetsNoLimitUsers,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAssetsNoLimitUsers,
                  lnbitsAssetsNoLimitUsers,
                )) &&
            (identical(other.lnbitsBaseurl, lnbitsBaseurl) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsBaseurl,
                  lnbitsBaseurl,
                )) &&
            (identical(other.lnbitsHideApi, lnbitsHideApi) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsHideApi,
                  lnbitsHideApi,
                )) &&
            (identical(other.lnbitsSiteTitle, lnbitsSiteTitle) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsSiteTitle,
                  lnbitsSiteTitle,
                )) &&
            (identical(other.lnbitsSiteTagline, lnbitsSiteTagline) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsSiteTagline,
                  lnbitsSiteTagline,
                )) &&
            (identical(other.lnbitsSiteDescription, lnbitsSiteDescription) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsSiteDescription,
                  lnbitsSiteDescription,
                )) &&
            (identical(
                  other.lnbitsShowHomePageElements,
                  lnbitsShowHomePageElements,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsShowHomePageElements,
                  lnbitsShowHomePageElements,
                )) &&
            (identical(
                  other.lnbitsDefaultWalletName,
                  lnbitsDefaultWalletName,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsDefaultWalletName,
                  lnbitsDefaultWalletName,
                )) &&
            (identical(other.lnbitsCustomBadge, lnbitsCustomBadge) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsCustomBadge,
                  lnbitsCustomBadge,
                )) &&
            (identical(other.lnbitsCustomBadgeColor, lnbitsCustomBadgeColor) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsCustomBadgeColor,
                  lnbitsCustomBadgeColor,
                )) &&
            (identical(other.lnbitsThemeOptions, lnbitsThemeOptions) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsThemeOptions,
                  lnbitsThemeOptions,
                )) &&
            (identical(other.lnbitsCustomLogo, lnbitsCustomLogo) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsCustomLogo,
                  lnbitsCustomLogo,
                )) &&
            (identical(other.lnbitsCustomImage, lnbitsCustomImage) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsCustomImage,
                  lnbitsCustomImage,
                )) &&
            (identical(other.lnbitsAdSpaceTitle, lnbitsAdSpaceTitle) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAdSpaceTitle,
                  lnbitsAdSpaceTitle,
                )) &&
            (identical(other.lnbitsAdSpace, lnbitsAdSpace) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAdSpace,
                  lnbitsAdSpace,
                )) &&
            (identical(other.lnbitsAdSpaceEnabled, lnbitsAdSpaceEnabled) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAdSpaceEnabled,
                  lnbitsAdSpaceEnabled,
                )) &&
            (identical(
                  other.lnbitsAllowedCurrencies,
                  lnbitsAllowedCurrencies,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAllowedCurrencies,
                  lnbitsAllowedCurrencies,
                )) &&
            (identical(
                  other.lnbitsDefaultAccountingCurrency,
                  lnbitsDefaultAccountingCurrency,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsDefaultAccountingCurrency,
                  lnbitsDefaultAccountingCurrency,
                )) &&
            (identical(other.lnbitsQrLogo, lnbitsQrLogo) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsQrLogo,
                  lnbitsQrLogo,
                )) &&
            (identical(other.lnbitsAppleTouchIcon, lnbitsAppleTouchIcon) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAppleTouchIcon,
                  lnbitsAppleTouchIcon,
                )) &&
            (identical(other.lnbitsDefaultReaction, lnbitsDefaultReaction) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsDefaultReaction,
                  lnbitsDefaultReaction,
                )) &&
            (identical(other.lnbitsDefaultTheme, lnbitsDefaultTheme) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsDefaultTheme,
                  lnbitsDefaultTheme,
                )) &&
            (identical(other.lnbitsDefaultBorder, lnbitsDefaultBorder) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsDefaultBorder,
                  lnbitsDefaultBorder,
                )) &&
            (identical(other.lnbitsDefaultGradient, lnbitsDefaultGradient) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsDefaultGradient,
                  lnbitsDefaultGradient,
                )) &&
            (identical(other.lnbitsDefaultBgimage, lnbitsDefaultBgimage) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsDefaultBgimage,
                  lnbitsDefaultBgimage,
                )) &&
            (identical(other.lnbitsAdminExtensions, lnbitsAdminExtensions) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAdminExtensions,
                  lnbitsAdminExtensions,
                )) &&
            (identical(
                  other.lnbitsUserDefaultExtensions,
                  lnbitsUserDefaultExtensions,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsUserDefaultExtensions,
                  lnbitsUserDefaultExtensions,
                )) &&
            (identical(
                  other.lnbitsExtensionsDeactivateAll,
                  lnbitsExtensionsDeactivateAll,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsExtensionsDeactivateAll,
                  lnbitsExtensionsDeactivateAll,
                )) &&
            (identical(
                  other.lnbitsExtensionsBuilderActivateNonAdmins,
                  lnbitsExtensionsBuilderActivateNonAdmins,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsExtensionsBuilderActivateNonAdmins,
                  lnbitsExtensionsBuilderActivateNonAdmins,
                )) &&
            (identical(
                  other.lnbitsExtensionsReviewsUrl,
                  lnbitsExtensionsReviewsUrl,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsExtensionsReviewsUrl,
                  lnbitsExtensionsReviewsUrl,
                )) &&
            (identical(
                  other.lnbitsExtensionsManifests,
                  lnbitsExtensionsManifests,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsExtensionsManifests,
                  lnbitsExtensionsManifests,
                )) &&
            (identical(
                  other.lnbitsExtensionsBuilderManifestUrl,
                  lnbitsExtensionsBuilderManifestUrl,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsExtensionsBuilderManifestUrl,
                  lnbitsExtensionsBuilderManifestUrl,
                )) &&
            (identical(other.lnbitsAdminUsers, lnbitsAdminUsers) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAdminUsers,
                  lnbitsAdminUsers,
                )) &&
            (identical(other.lnbitsAllowedUsers, lnbitsAllowedUsers) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAllowedUsers,
                  lnbitsAllowedUsers,
                )) &&
            (identical(other.lnbitsAllowNewAccounts, lnbitsAllowNewAccounts) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAllowNewAccounts,
                  lnbitsAllowNewAccounts,
                )) &&
            (identical(other.isSuperUser, isSuperUser) ||
                const DeepCollectionEquality().equals(
                  other.isSuperUser,
                  isSuperUser,
                )) &&
            (identical(
                  other.lnbitsAllowedFundingSources,
                  lnbitsAllowedFundingSources,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAllowedFundingSources,
                  lnbitsAllowedFundingSources,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(keycloakDiscoveryUrl) ^
      const DeepCollectionEquality().hash(keycloakClientId) ^
      const DeepCollectionEquality().hash(keycloakClientSecret) ^
      const DeepCollectionEquality().hash(keycloakClientCustomOrg) ^
      const DeepCollectionEquality().hash(keycloakClientCustomIcon) ^
      const DeepCollectionEquality().hash(githubClientId) ^
      const DeepCollectionEquality().hash(githubClientSecret) ^
      const DeepCollectionEquality().hash(googleClientId) ^
      const DeepCollectionEquality().hash(googleClientSecret) ^
      const DeepCollectionEquality().hash(nostrAbsoluteRequestUrls) ^
      const DeepCollectionEquality().hash(authTokenExpireMinutes) ^
      const DeepCollectionEquality().hash(authAllMethods) ^
      const DeepCollectionEquality().hash(authAllowedMethods) ^
      const DeepCollectionEquality().hash(authCredetialsUpdateThreshold) ^
      const DeepCollectionEquality().hash(authAuthenticationCacheMinutes) ^
      const DeepCollectionEquality().hash(lnbitsAuditEnabled) ^
      const DeepCollectionEquality().hash(lnbitsAuditRetentionDays) ^
      const DeepCollectionEquality().hash(lnbitsAuditLogIpAddress) ^
      const DeepCollectionEquality().hash(lnbitsAuditLogPathParams) ^
      const DeepCollectionEquality().hash(lnbitsAuditLogQueryParams) ^
      const DeepCollectionEquality().hash(lnbitsAuditLogRequestBody) ^
      const DeepCollectionEquality().hash(lnbitsAuditIncludePaths) ^
      const DeepCollectionEquality().hash(lnbitsAuditExcludePaths) ^
      const DeepCollectionEquality().hash(lnbitsAuditHttpMethods) ^
      const DeepCollectionEquality().hash(lnbitsAuditHttpResponseCodes) ^
      const DeepCollectionEquality().hash(lnbitsNodeUi) ^
      const DeepCollectionEquality().hash(lnbitsPublicNodeUi) ^
      const DeepCollectionEquality().hash(lnbitsNodeUiTransactions) ^
      const DeepCollectionEquality().hash(lnbitsWebpushPubkey) ^
      const DeepCollectionEquality().hash(lnbitsWebpushPrivkey) ^
      const DeepCollectionEquality().hash(lightningInvoiceExpiry) ^
      const DeepCollectionEquality().hash(paypalEnabled) ^
      const DeepCollectionEquality().hash(paypalApiEndpoint) ^
      const DeepCollectionEquality().hash(paypalClientId) ^
      const DeepCollectionEquality().hash(paypalClientSecret) ^
      const DeepCollectionEquality().hash(paypalPaymentSuccessUrl) ^
      const DeepCollectionEquality().hash(paypalPaymentWebhookUrl) ^
      const DeepCollectionEquality().hash(paypalWebhookId) ^
      const DeepCollectionEquality().hash(paypalLimits) ^
      const DeepCollectionEquality().hash(stripeEnabled) ^
      const DeepCollectionEquality().hash(stripeApiEndpoint) ^
      const DeepCollectionEquality().hash(stripeApiSecretKey) ^
      const DeepCollectionEquality().hash(stripePaymentSuccessUrl) ^
      const DeepCollectionEquality().hash(stripePaymentWebhookUrl) ^
      const DeepCollectionEquality().hash(stripeWebhookSigningSecret) ^
      const DeepCollectionEquality().hash(stripeLimits) ^
      const DeepCollectionEquality().hash(breezLiquidApiKey) ^
      const DeepCollectionEquality().hash(breezLiquidSeed) ^
      const DeepCollectionEquality().hash(breezLiquidFeeOffsetSat) ^
      const DeepCollectionEquality().hash(strikeApiEndpoint) ^
      const DeepCollectionEquality().hash(strikeApiKey) ^
      const DeepCollectionEquality().hash(breezApiKey) ^
      const DeepCollectionEquality().hash(breezGreenlightSeed) ^
      const DeepCollectionEquality().hash(breezGreenlightInviteCode) ^
      const DeepCollectionEquality().hash(breezGreenlightDeviceKey) ^
      const DeepCollectionEquality().hash(breezGreenlightDeviceCert) ^
      const DeepCollectionEquality().hash(breezUseTrampoline) ^
      const DeepCollectionEquality().hash(nwcPairingUrl) ^
      const DeepCollectionEquality().hash(lntipsApiEndpoint) ^
      const DeepCollectionEquality().hash(lntipsApiKey) ^
      const DeepCollectionEquality().hash(lntipsAdminKey) ^
      const DeepCollectionEquality().hash(lntipsInvoiceKey) ^
      const DeepCollectionEquality().hash(sparkUrl) ^
      const DeepCollectionEquality().hash(sparkToken) ^
      const DeepCollectionEquality().hash(opennodeApiEndpoint) ^
      const DeepCollectionEquality().hash(opennodeKey) ^
      const DeepCollectionEquality().hash(opennodeAdminKey) ^
      const DeepCollectionEquality().hash(opennodeInvoiceKey) ^
      const DeepCollectionEquality().hash(phoenixdApiEndpoint) ^
      const DeepCollectionEquality().hash(phoenixdApiPassword) ^
      const DeepCollectionEquality().hash(zbdApiEndpoint) ^
      const DeepCollectionEquality().hash(zbdApiKey) ^
      const DeepCollectionEquality().hash(boltzClientEndpoint) ^
      const DeepCollectionEquality().hash(boltzClientMacaroon) ^
      const DeepCollectionEquality().hash(boltzClientPassword) ^
      const DeepCollectionEquality().hash(boltzClientCert) ^
      const DeepCollectionEquality().hash(boltzMnemonic) ^
      const DeepCollectionEquality().hash(albyApiEndpoint) ^
      const DeepCollectionEquality().hash(albyAccessToken) ^
      const DeepCollectionEquality().hash(blinkApiEndpoint) ^
      const DeepCollectionEquality().hash(blinkWsEndpoint) ^
      const DeepCollectionEquality().hash(blinkToken) ^
      const DeepCollectionEquality().hash(lnpayApiEndpoint) ^
      const DeepCollectionEquality().hash(lnpayApiKey) ^
      const DeepCollectionEquality().hash(lnpayWalletKey) ^
      const DeepCollectionEquality().hash(lnpayAdminKey) ^
      const DeepCollectionEquality().hash(lndGrpcEndpoint) ^
      const DeepCollectionEquality().hash(lndGrpcCert) ^
      const DeepCollectionEquality().hash(lndGrpcPort) ^
      const DeepCollectionEquality().hash(lndGrpcAdminMacaroon) ^
      const DeepCollectionEquality().hash(lndGrpcInvoiceMacaroon) ^
      const DeepCollectionEquality().hash(lndGrpcMacaroon) ^
      const DeepCollectionEquality().hash(lndGrpcMacaroonEncrypted) ^
      const DeepCollectionEquality().hash(lndRestEndpoint) ^
      const DeepCollectionEquality().hash(lndRestCert) ^
      const DeepCollectionEquality().hash(lndRestMacaroon) ^
      const DeepCollectionEquality().hash(lndRestMacaroonEncrypted) ^
      const DeepCollectionEquality().hash(lndRestRouteHints) ^
      const DeepCollectionEquality().hash(lndRestAllowSelfPayment) ^
      const DeepCollectionEquality().hash(lndCert) ^
      const DeepCollectionEquality().hash(lndAdminMacaroon) ^
      const DeepCollectionEquality().hash(lndInvoiceMacaroon) ^
      const DeepCollectionEquality().hash(lndRestAdminMacaroon) ^
      const DeepCollectionEquality().hash(lndRestInvoiceMacaroon) ^
      const DeepCollectionEquality().hash(eclairUrl) ^
      const DeepCollectionEquality().hash(eclairPass) ^
      const DeepCollectionEquality().hash(corelightningRestUrl) ^
      const DeepCollectionEquality().hash(corelightningRestMacaroon) ^
      const DeepCollectionEquality().hash(corelightningRestCert) ^
      const DeepCollectionEquality().hash(corelightningRpc) ^
      const DeepCollectionEquality().hash(corelightningPayCommand) ^
      const DeepCollectionEquality().hash(clightningRpc) ^
      const DeepCollectionEquality().hash(clnrestUrl) ^
      const DeepCollectionEquality().hash(clnrestCa) ^
      const DeepCollectionEquality().hash(clnrestCert) ^
      const DeepCollectionEquality().hash(clnrestReadonlyRune) ^
      const DeepCollectionEquality().hash(clnrestInvoiceRune) ^
      const DeepCollectionEquality().hash(clnrestPayRune) ^
      const DeepCollectionEquality().hash(clnrestRenepayRune) ^
      const DeepCollectionEquality().hash(clnrestLastPayIndex) ^
      const DeepCollectionEquality().hash(clnrestNodeid) ^
      const DeepCollectionEquality().hash(clicheEndpoint) ^
      const DeepCollectionEquality().hash(lnbitsEndpoint) ^
      const DeepCollectionEquality().hash(lnbitsKey) ^
      const DeepCollectionEquality().hash(lnbitsAdminKey) ^
      const DeepCollectionEquality().hash(lnbitsInvoiceKey) ^
      const DeepCollectionEquality().hash(fakeWalletSecret) ^
      const DeepCollectionEquality().hash(lnbitsDenomination) ^
      const DeepCollectionEquality().hash(lnbitsBackendWalletClass) ^
      const DeepCollectionEquality().hash(
        lnbitsFundingSourcePayInvoiceWaitSeconds,
      ) ^
      const DeepCollectionEquality().hash(fundingSourceMaxRetries) ^
      const DeepCollectionEquality().hash(lnbitsNostrNotificationsEnabled) ^
      const DeepCollectionEquality().hash(lnbitsNostrNotificationsPrivateKey) ^
      const DeepCollectionEquality().hash(lnbitsNostrNotificationsIdentifiers) ^
      const DeepCollectionEquality().hash(lnbitsTelegramNotificationsEnabled) ^
      const DeepCollectionEquality().hash(
        lnbitsTelegramNotificationsAccessToken,
      ) ^
      const DeepCollectionEquality().hash(lnbitsTelegramNotificationsChatId) ^
      const DeepCollectionEquality().hash(lnbitsEmailNotificationsEnabled) ^
      const DeepCollectionEquality().hash(lnbitsEmailNotificationsEmail) ^
      const DeepCollectionEquality().hash(lnbitsEmailNotificationsUsername) ^
      const DeepCollectionEquality().hash(lnbitsEmailNotificationsPassword) ^
      const DeepCollectionEquality().hash(lnbitsEmailNotificationsServer) ^
      const DeepCollectionEquality().hash(lnbitsEmailNotificationsPort) ^
      const DeepCollectionEquality().hash(lnbitsEmailNotificationsToEmails) ^
      const DeepCollectionEquality().hash(lnbitsNotificationSettingsUpdate) ^
      const DeepCollectionEquality().hash(lnbitsNotificationCreditDebit) ^
      const DeepCollectionEquality().hash(
        notificationBalanceDeltaThresholdSats,
      ) ^
      const DeepCollectionEquality().hash(lnbitsNotificationServerStartStop) ^
      const DeepCollectionEquality().hash(lnbitsNotificationWatchdog) ^
      const DeepCollectionEquality().hash(lnbitsNotificationServerStatusHours) ^
      const DeepCollectionEquality().hash(
        lnbitsNotificationIncomingPaymentAmountSats,
      ) ^
      const DeepCollectionEquality().hash(
        lnbitsNotificationOutgoingPaymentAmountSats,
      ) ^
      const DeepCollectionEquality().hash(lnbitsRateLimitNo) ^
      const DeepCollectionEquality().hash(lnbitsRateLimitUnit) ^
      const DeepCollectionEquality().hash(lnbitsAllowedIps) ^
      const DeepCollectionEquality().hash(lnbitsBlockedIps) ^
      const DeepCollectionEquality().hash(lnbitsCallbackUrlRules) ^
      const DeepCollectionEquality().hash(lnbitsWalletLimitMaxBalance) ^
      const DeepCollectionEquality().hash(lnbitsWalletLimitDailyMaxWithdraw) ^
      const DeepCollectionEquality().hash(lnbitsWalletLimitSecsBetweenTrans) ^
      const DeepCollectionEquality().hash(lnbitsOnlyAllowIncomingPayments) ^
      const DeepCollectionEquality().hash(lnbitsWatchdogSwitchToVoidwallet) ^
      const DeepCollectionEquality().hash(lnbitsWatchdogIntervalMinutes) ^
      const DeepCollectionEquality().hash(lnbitsWatchdogDelta) ^
      const DeepCollectionEquality().hash(lnbitsMaxOutgoingPaymentAmountSats) ^
      const DeepCollectionEquality().hash(lnbitsMaxIncomingPaymentAmountSats) ^
      const DeepCollectionEquality().hash(lnbitsExchangeRateCacheSeconds) ^
      const DeepCollectionEquality().hash(lnbitsExchangeHistorySize) ^
      const DeepCollectionEquality().hash(
        lnbitsExchangeHistoryRefreshIntervalSeconds,
      ) ^
      const DeepCollectionEquality().hash(lnbitsExchangeRateProviders) ^
      const DeepCollectionEquality().hash(lnbitsReserveFeeMin) ^
      const DeepCollectionEquality().hash(lnbitsReserveFeePercent) ^
      const DeepCollectionEquality().hash(lnbitsServiceFee) ^
      const DeepCollectionEquality().hash(lnbitsServiceFeeIgnoreInternal) ^
      const DeepCollectionEquality().hash(lnbitsServiceFeeMax) ^
      const DeepCollectionEquality().hash(lnbitsServiceFeeWallet) ^
      const DeepCollectionEquality().hash(lnbitsMaxAssetSizeMb) ^
      const DeepCollectionEquality().hash(lnbitsAssetsAllowedMimeTypes) ^
      const DeepCollectionEquality().hash(lnbitsAssetThumbnailWidth) ^
      const DeepCollectionEquality().hash(lnbitsAssetThumbnailHeight) ^
      const DeepCollectionEquality().hash(lnbitsAssetThumbnailFormat) ^
      const DeepCollectionEquality().hash(lnbitsMaxAssetsPerUser) ^
      const DeepCollectionEquality().hash(lnbitsAssetsNoLimitUsers) ^
      const DeepCollectionEquality().hash(lnbitsBaseurl) ^
      const DeepCollectionEquality().hash(lnbitsHideApi) ^
      const DeepCollectionEquality().hash(lnbitsSiteTitle) ^
      const DeepCollectionEquality().hash(lnbitsSiteTagline) ^
      const DeepCollectionEquality().hash(lnbitsSiteDescription) ^
      const DeepCollectionEquality().hash(lnbitsShowHomePageElements) ^
      const DeepCollectionEquality().hash(lnbitsDefaultWalletName) ^
      const DeepCollectionEquality().hash(lnbitsCustomBadge) ^
      const DeepCollectionEquality().hash(lnbitsCustomBadgeColor) ^
      const DeepCollectionEquality().hash(lnbitsThemeOptions) ^
      const DeepCollectionEquality().hash(lnbitsCustomLogo) ^
      const DeepCollectionEquality().hash(lnbitsCustomImage) ^
      const DeepCollectionEquality().hash(lnbitsAdSpaceTitle) ^
      const DeepCollectionEquality().hash(lnbitsAdSpace) ^
      const DeepCollectionEquality().hash(lnbitsAdSpaceEnabled) ^
      const DeepCollectionEquality().hash(lnbitsAllowedCurrencies) ^
      const DeepCollectionEquality().hash(lnbitsDefaultAccountingCurrency) ^
      const DeepCollectionEquality().hash(lnbitsQrLogo) ^
      const DeepCollectionEquality().hash(lnbitsAppleTouchIcon) ^
      const DeepCollectionEquality().hash(lnbitsDefaultReaction) ^
      const DeepCollectionEquality().hash(lnbitsDefaultTheme) ^
      const DeepCollectionEquality().hash(lnbitsDefaultBorder) ^
      const DeepCollectionEquality().hash(lnbitsDefaultGradient) ^
      const DeepCollectionEquality().hash(lnbitsDefaultBgimage) ^
      const DeepCollectionEquality().hash(lnbitsAdminExtensions) ^
      const DeepCollectionEquality().hash(lnbitsUserDefaultExtensions) ^
      const DeepCollectionEquality().hash(lnbitsExtensionsDeactivateAll) ^
      const DeepCollectionEquality().hash(
        lnbitsExtensionsBuilderActivateNonAdmins,
      ) ^
      const DeepCollectionEquality().hash(lnbitsExtensionsReviewsUrl) ^
      const DeepCollectionEquality().hash(lnbitsExtensionsManifests) ^
      const DeepCollectionEquality().hash(lnbitsExtensionsBuilderManifestUrl) ^
      const DeepCollectionEquality().hash(lnbitsAdminUsers) ^
      const DeepCollectionEquality().hash(lnbitsAllowedUsers) ^
      const DeepCollectionEquality().hash(lnbitsAllowNewAccounts) ^
      const DeepCollectionEquality().hash(isSuperUser) ^
      const DeepCollectionEquality().hash(lnbitsAllowedFundingSources) ^
      runtimeType.hashCode;
}

extension $AdminSettingsExtension on AdminSettings {
  AdminSettings copyWith({
    String? keycloakDiscoveryUrl,
    String? keycloakClientId,
    String? keycloakClientSecret,
    String? keycloakClientCustomOrg,
    String? keycloakClientCustomIcon,
    String? githubClientId,
    String? githubClientSecret,
    String? googleClientId,
    String? googleClientSecret,
    List<String>? nostrAbsoluteRequestUrls,
    int? authTokenExpireMinutes,
    List<String>? authAllMethods,
    List<String>? authAllowedMethods,
    int? authCredetialsUpdateThreshold,
    int? authAuthenticationCacheMinutes,
    bool? lnbitsAuditEnabled,
    int? lnbitsAuditRetentionDays,
    bool? lnbitsAuditLogIpAddress,
    bool? lnbitsAuditLogPathParams,
    bool? lnbitsAuditLogQueryParams,
    bool? lnbitsAuditLogRequestBody,
    List<String>? lnbitsAuditIncludePaths,
    List<String>? lnbitsAuditExcludePaths,
    List<String>? lnbitsAuditHttpMethods,
    List<String>? lnbitsAuditHttpResponseCodes,
    bool? lnbitsNodeUi,
    bool? lnbitsPublicNodeUi,
    bool? lnbitsNodeUiTransactions,
    String? lnbitsWebpushPubkey,
    String? lnbitsWebpushPrivkey,
    int? lightningInvoiceExpiry,
    bool? paypalEnabled,
    String? paypalApiEndpoint,
    String? paypalClientId,
    String? paypalClientSecret,
    String? paypalPaymentSuccessUrl,
    String? paypalPaymentWebhookUrl,
    String? paypalWebhookId,
    FiatProviderLimits? paypalLimits,
    bool? stripeEnabled,
    String? stripeApiEndpoint,
    String? stripeApiSecretKey,
    String? stripePaymentSuccessUrl,
    String? stripePaymentWebhookUrl,
    String? stripeWebhookSigningSecret,
    FiatProviderLimits? stripeLimits,
    String? breezLiquidApiKey,
    String? breezLiquidSeed,
    int? breezLiquidFeeOffsetSat,
    String? strikeApiEndpoint,
    String? strikeApiKey,
    String? breezApiKey,
    String? breezGreenlightSeed,
    String? breezGreenlightInviteCode,
    String? breezGreenlightDeviceKey,
    String? breezGreenlightDeviceCert,
    bool? breezUseTrampoline,
    String? nwcPairingUrl,
    String? lntipsApiEndpoint,
    String? lntipsApiKey,
    String? lntipsAdminKey,
    String? lntipsInvoiceKey,
    String? sparkUrl,
    String? sparkToken,
    String? opennodeApiEndpoint,
    String? opennodeKey,
    String? opennodeAdminKey,
    String? opennodeInvoiceKey,
    String? phoenixdApiEndpoint,
    String? phoenixdApiPassword,
    String? zbdApiEndpoint,
    String? zbdApiKey,
    String? boltzClientEndpoint,
    String? boltzClientMacaroon,
    String? boltzClientPassword,
    String? boltzClientCert,
    String? boltzMnemonic,
    String? albyApiEndpoint,
    String? albyAccessToken,
    String? blinkApiEndpoint,
    String? blinkWsEndpoint,
    String? blinkToken,
    String? lnpayApiEndpoint,
    String? lnpayApiKey,
    String? lnpayWalletKey,
    String? lnpayAdminKey,
    String? lndGrpcEndpoint,
    String? lndGrpcCert,
    int? lndGrpcPort,
    String? lndGrpcAdminMacaroon,
    String? lndGrpcInvoiceMacaroon,
    String? lndGrpcMacaroon,
    String? lndGrpcMacaroonEncrypted,
    String? lndRestEndpoint,
    String? lndRestCert,
    String? lndRestMacaroon,
    String? lndRestMacaroonEncrypted,
    bool? lndRestRouteHints,
    bool? lndRestAllowSelfPayment,
    String? lndCert,
    String? lndAdminMacaroon,
    String? lndInvoiceMacaroon,
    String? lndRestAdminMacaroon,
    String? lndRestInvoiceMacaroon,
    String? eclairUrl,
    String? eclairPass,
    String? corelightningRestUrl,
    String? corelightningRestMacaroon,
    String? corelightningRestCert,
    String? corelightningRpc,
    String? corelightningPayCommand,
    String? clightningRpc,
    String? clnrestUrl,
    String? clnrestCa,
    String? clnrestCert,
    String? clnrestReadonlyRune,
    String? clnrestInvoiceRune,
    String? clnrestPayRune,
    String? clnrestRenepayRune,
    String? clnrestLastPayIndex,
    String? clnrestNodeid,
    String? clicheEndpoint,
    String? lnbitsEndpoint,
    String? lnbitsKey,
    String? lnbitsAdminKey,
    String? lnbitsInvoiceKey,
    String? fakeWalletSecret,
    String? lnbitsDenomination,
    String? lnbitsBackendWalletClass,
    int? lnbitsFundingSourcePayInvoiceWaitSeconds,
    int? fundingSourceMaxRetries,
    bool? lnbitsNostrNotificationsEnabled,
    String? lnbitsNostrNotificationsPrivateKey,
    List<String>? lnbitsNostrNotificationsIdentifiers,
    bool? lnbitsTelegramNotificationsEnabled,
    String? lnbitsTelegramNotificationsAccessToken,
    String? lnbitsTelegramNotificationsChatId,
    bool? lnbitsEmailNotificationsEnabled,
    String? lnbitsEmailNotificationsEmail,
    String? lnbitsEmailNotificationsUsername,
    String? lnbitsEmailNotificationsPassword,
    String? lnbitsEmailNotificationsServer,
    int? lnbitsEmailNotificationsPort,
    List<String>? lnbitsEmailNotificationsToEmails,
    bool? lnbitsNotificationSettingsUpdate,
    bool? lnbitsNotificationCreditDebit,
    int? notificationBalanceDeltaThresholdSats,
    bool? lnbitsNotificationServerStartStop,
    bool? lnbitsNotificationWatchdog,
    int? lnbitsNotificationServerStatusHours,
    int? lnbitsNotificationIncomingPaymentAmountSats,
    int? lnbitsNotificationOutgoingPaymentAmountSats,
    int? lnbitsRateLimitNo,
    String? lnbitsRateLimitUnit,
    List<String>? lnbitsAllowedIps,
    List<String>? lnbitsBlockedIps,
    List<String>? lnbitsCallbackUrlRules,
    int? lnbitsWalletLimitMaxBalance,
    int? lnbitsWalletLimitDailyMaxWithdraw,
    int? lnbitsWalletLimitSecsBetweenTrans,
    bool? lnbitsOnlyAllowIncomingPayments,
    bool? lnbitsWatchdogSwitchToVoidwallet,
    int? lnbitsWatchdogIntervalMinutes,
    int? lnbitsWatchdogDelta,
    int? lnbitsMaxOutgoingPaymentAmountSats,
    int? lnbitsMaxIncomingPaymentAmountSats,
    int? lnbitsExchangeRateCacheSeconds,
    int? lnbitsExchangeHistorySize,
    int? lnbitsExchangeHistoryRefreshIntervalSeconds,
    List<ExchangeRateProvider>? lnbitsExchangeRateProviders,
    int? lnbitsReserveFeeMin,
    double? lnbitsReserveFeePercent,
    double? lnbitsServiceFee,
    bool? lnbitsServiceFeeIgnoreInternal,
    int? lnbitsServiceFeeMax,
    String? lnbitsServiceFeeWallet,
    double? lnbitsMaxAssetSizeMb,
    List<String>? lnbitsAssetsAllowedMimeTypes,
    int? lnbitsAssetThumbnailWidth,
    int? lnbitsAssetThumbnailHeight,
    String? lnbitsAssetThumbnailFormat,
    int? lnbitsMaxAssetsPerUser,
    List<String>? lnbitsAssetsNoLimitUsers,
    String? lnbitsBaseurl,
    bool? lnbitsHideApi,
    String? lnbitsSiteTitle,
    String? lnbitsSiteTagline,
    String? lnbitsSiteDescription,
    bool? lnbitsShowHomePageElements,
    String? lnbitsDefaultWalletName,
    String? lnbitsCustomBadge,
    String? lnbitsCustomBadgeColor,
    List<String>? lnbitsThemeOptions,
    String? lnbitsCustomLogo,
    String? lnbitsCustomImage,
    String? lnbitsAdSpaceTitle,
    String? lnbitsAdSpace,
    bool? lnbitsAdSpaceEnabled,
    List<String>? lnbitsAllowedCurrencies,
    String? lnbitsDefaultAccountingCurrency,
    String? lnbitsQrLogo,
    String? lnbitsAppleTouchIcon,
    String? lnbitsDefaultReaction,
    String? lnbitsDefaultTheme,
    String? lnbitsDefaultBorder,
    bool? lnbitsDefaultGradient,
    String? lnbitsDefaultBgimage,
    List<String>? lnbitsAdminExtensions,
    List<String>? lnbitsUserDefaultExtensions,
    bool? lnbitsExtensionsDeactivateAll,
    bool? lnbitsExtensionsBuilderActivateNonAdmins,
    String? lnbitsExtensionsReviewsUrl,
    List<String>? lnbitsExtensionsManifests,
    String? lnbitsExtensionsBuilderManifestUrl,
    List<String>? lnbitsAdminUsers,
    List<String>? lnbitsAllowedUsers,
    bool? lnbitsAllowNewAccounts,
    bool? isSuperUser,
    List<String>? lnbitsAllowedFundingSources,
  }) {
    return AdminSettings(
      keycloakDiscoveryUrl: keycloakDiscoveryUrl ?? this.keycloakDiscoveryUrl,
      keycloakClientId: keycloakClientId ?? this.keycloakClientId,
      keycloakClientSecret: keycloakClientSecret ?? this.keycloakClientSecret,
      keycloakClientCustomOrg:
          keycloakClientCustomOrg ?? this.keycloakClientCustomOrg,
      keycloakClientCustomIcon:
          keycloakClientCustomIcon ?? this.keycloakClientCustomIcon,
      githubClientId: githubClientId ?? this.githubClientId,
      githubClientSecret: githubClientSecret ?? this.githubClientSecret,
      googleClientId: googleClientId ?? this.googleClientId,
      googleClientSecret: googleClientSecret ?? this.googleClientSecret,
      nostrAbsoluteRequestUrls:
          nostrAbsoluteRequestUrls ?? this.nostrAbsoluteRequestUrls,
      authTokenExpireMinutes:
          authTokenExpireMinutes ?? this.authTokenExpireMinutes,
      authAllMethods: authAllMethods ?? this.authAllMethods,
      authAllowedMethods: authAllowedMethods ?? this.authAllowedMethods,
      authCredetialsUpdateThreshold:
          authCredetialsUpdateThreshold ?? this.authCredetialsUpdateThreshold,
      authAuthenticationCacheMinutes:
          authAuthenticationCacheMinutes ?? this.authAuthenticationCacheMinutes,
      lnbitsAuditEnabled: lnbitsAuditEnabled ?? this.lnbitsAuditEnabled,
      lnbitsAuditRetentionDays:
          lnbitsAuditRetentionDays ?? this.lnbitsAuditRetentionDays,
      lnbitsAuditLogIpAddress:
          lnbitsAuditLogIpAddress ?? this.lnbitsAuditLogIpAddress,
      lnbitsAuditLogPathParams:
          lnbitsAuditLogPathParams ?? this.lnbitsAuditLogPathParams,
      lnbitsAuditLogQueryParams:
          lnbitsAuditLogQueryParams ?? this.lnbitsAuditLogQueryParams,
      lnbitsAuditLogRequestBody:
          lnbitsAuditLogRequestBody ?? this.lnbitsAuditLogRequestBody,
      lnbitsAuditIncludePaths:
          lnbitsAuditIncludePaths ?? this.lnbitsAuditIncludePaths,
      lnbitsAuditExcludePaths:
          lnbitsAuditExcludePaths ?? this.lnbitsAuditExcludePaths,
      lnbitsAuditHttpMethods:
          lnbitsAuditHttpMethods ?? this.lnbitsAuditHttpMethods,
      lnbitsAuditHttpResponseCodes:
          lnbitsAuditHttpResponseCodes ?? this.lnbitsAuditHttpResponseCodes,
      lnbitsNodeUi: lnbitsNodeUi ?? this.lnbitsNodeUi,
      lnbitsPublicNodeUi: lnbitsPublicNodeUi ?? this.lnbitsPublicNodeUi,
      lnbitsNodeUiTransactions:
          lnbitsNodeUiTransactions ?? this.lnbitsNodeUiTransactions,
      lnbitsWebpushPubkey: lnbitsWebpushPubkey ?? this.lnbitsWebpushPubkey,
      lnbitsWebpushPrivkey: lnbitsWebpushPrivkey ?? this.lnbitsWebpushPrivkey,
      lightningInvoiceExpiry:
          lightningInvoiceExpiry ?? this.lightningInvoiceExpiry,
      paypalEnabled: paypalEnabled ?? this.paypalEnabled,
      paypalApiEndpoint: paypalApiEndpoint ?? this.paypalApiEndpoint,
      paypalClientId: paypalClientId ?? this.paypalClientId,
      paypalClientSecret: paypalClientSecret ?? this.paypalClientSecret,
      paypalPaymentSuccessUrl:
          paypalPaymentSuccessUrl ?? this.paypalPaymentSuccessUrl,
      paypalPaymentWebhookUrl:
          paypalPaymentWebhookUrl ?? this.paypalPaymentWebhookUrl,
      paypalWebhookId: paypalWebhookId ?? this.paypalWebhookId,
      paypalLimits: paypalLimits ?? this.paypalLimits,
      stripeEnabled: stripeEnabled ?? this.stripeEnabled,
      stripeApiEndpoint: stripeApiEndpoint ?? this.stripeApiEndpoint,
      stripeApiSecretKey: stripeApiSecretKey ?? this.stripeApiSecretKey,
      stripePaymentSuccessUrl:
          stripePaymentSuccessUrl ?? this.stripePaymentSuccessUrl,
      stripePaymentWebhookUrl:
          stripePaymentWebhookUrl ?? this.stripePaymentWebhookUrl,
      stripeWebhookSigningSecret:
          stripeWebhookSigningSecret ?? this.stripeWebhookSigningSecret,
      stripeLimits: stripeLimits ?? this.stripeLimits,
      breezLiquidApiKey: breezLiquidApiKey ?? this.breezLiquidApiKey,
      breezLiquidSeed: breezLiquidSeed ?? this.breezLiquidSeed,
      breezLiquidFeeOffsetSat:
          breezLiquidFeeOffsetSat ?? this.breezLiquidFeeOffsetSat,
      strikeApiEndpoint: strikeApiEndpoint ?? this.strikeApiEndpoint,
      strikeApiKey: strikeApiKey ?? this.strikeApiKey,
      breezApiKey: breezApiKey ?? this.breezApiKey,
      breezGreenlightSeed: breezGreenlightSeed ?? this.breezGreenlightSeed,
      breezGreenlightInviteCode:
          breezGreenlightInviteCode ?? this.breezGreenlightInviteCode,
      breezGreenlightDeviceKey:
          breezGreenlightDeviceKey ?? this.breezGreenlightDeviceKey,
      breezGreenlightDeviceCert:
          breezGreenlightDeviceCert ?? this.breezGreenlightDeviceCert,
      breezUseTrampoline: breezUseTrampoline ?? this.breezUseTrampoline,
      nwcPairingUrl: nwcPairingUrl ?? this.nwcPairingUrl,
      lntipsApiEndpoint: lntipsApiEndpoint ?? this.lntipsApiEndpoint,
      lntipsApiKey: lntipsApiKey ?? this.lntipsApiKey,
      lntipsAdminKey: lntipsAdminKey ?? this.lntipsAdminKey,
      lntipsInvoiceKey: lntipsInvoiceKey ?? this.lntipsInvoiceKey,
      sparkUrl: sparkUrl ?? this.sparkUrl,
      sparkToken: sparkToken ?? this.sparkToken,
      opennodeApiEndpoint: opennodeApiEndpoint ?? this.opennodeApiEndpoint,
      opennodeKey: opennodeKey ?? this.opennodeKey,
      opennodeAdminKey: opennodeAdminKey ?? this.opennodeAdminKey,
      opennodeInvoiceKey: opennodeInvoiceKey ?? this.opennodeInvoiceKey,
      phoenixdApiEndpoint: phoenixdApiEndpoint ?? this.phoenixdApiEndpoint,
      phoenixdApiPassword: phoenixdApiPassword ?? this.phoenixdApiPassword,
      zbdApiEndpoint: zbdApiEndpoint ?? this.zbdApiEndpoint,
      zbdApiKey: zbdApiKey ?? this.zbdApiKey,
      boltzClientEndpoint: boltzClientEndpoint ?? this.boltzClientEndpoint,
      boltzClientMacaroon: boltzClientMacaroon ?? this.boltzClientMacaroon,
      boltzClientPassword: boltzClientPassword ?? this.boltzClientPassword,
      boltzClientCert: boltzClientCert ?? this.boltzClientCert,
      boltzMnemonic: boltzMnemonic ?? this.boltzMnemonic,
      albyApiEndpoint: albyApiEndpoint ?? this.albyApiEndpoint,
      albyAccessToken: albyAccessToken ?? this.albyAccessToken,
      blinkApiEndpoint: blinkApiEndpoint ?? this.blinkApiEndpoint,
      blinkWsEndpoint: blinkWsEndpoint ?? this.blinkWsEndpoint,
      blinkToken: blinkToken ?? this.blinkToken,
      lnpayApiEndpoint: lnpayApiEndpoint ?? this.lnpayApiEndpoint,
      lnpayApiKey: lnpayApiKey ?? this.lnpayApiKey,
      lnpayWalletKey: lnpayWalletKey ?? this.lnpayWalletKey,
      lnpayAdminKey: lnpayAdminKey ?? this.lnpayAdminKey,
      lndGrpcEndpoint: lndGrpcEndpoint ?? this.lndGrpcEndpoint,
      lndGrpcCert: lndGrpcCert ?? this.lndGrpcCert,
      lndGrpcPort: lndGrpcPort ?? this.lndGrpcPort,
      lndGrpcAdminMacaroon: lndGrpcAdminMacaroon ?? this.lndGrpcAdminMacaroon,
      lndGrpcInvoiceMacaroon:
          lndGrpcInvoiceMacaroon ?? this.lndGrpcInvoiceMacaroon,
      lndGrpcMacaroon: lndGrpcMacaroon ?? this.lndGrpcMacaroon,
      lndGrpcMacaroonEncrypted:
          lndGrpcMacaroonEncrypted ?? this.lndGrpcMacaroonEncrypted,
      lndRestEndpoint: lndRestEndpoint ?? this.lndRestEndpoint,
      lndRestCert: lndRestCert ?? this.lndRestCert,
      lndRestMacaroon: lndRestMacaroon ?? this.lndRestMacaroon,
      lndRestMacaroonEncrypted:
          lndRestMacaroonEncrypted ?? this.lndRestMacaroonEncrypted,
      lndRestRouteHints: lndRestRouteHints ?? this.lndRestRouteHints,
      lndRestAllowSelfPayment:
          lndRestAllowSelfPayment ?? this.lndRestAllowSelfPayment,
      lndCert: lndCert ?? this.lndCert,
      lndAdminMacaroon: lndAdminMacaroon ?? this.lndAdminMacaroon,
      lndInvoiceMacaroon: lndInvoiceMacaroon ?? this.lndInvoiceMacaroon,
      lndRestAdminMacaroon: lndRestAdminMacaroon ?? this.lndRestAdminMacaroon,
      lndRestInvoiceMacaroon:
          lndRestInvoiceMacaroon ?? this.lndRestInvoiceMacaroon,
      eclairUrl: eclairUrl ?? this.eclairUrl,
      eclairPass: eclairPass ?? this.eclairPass,
      corelightningRestUrl: corelightningRestUrl ?? this.corelightningRestUrl,
      corelightningRestMacaroon:
          corelightningRestMacaroon ?? this.corelightningRestMacaroon,
      corelightningRestCert:
          corelightningRestCert ?? this.corelightningRestCert,
      corelightningRpc: corelightningRpc ?? this.corelightningRpc,
      corelightningPayCommand:
          corelightningPayCommand ?? this.corelightningPayCommand,
      clightningRpc: clightningRpc ?? this.clightningRpc,
      clnrestUrl: clnrestUrl ?? this.clnrestUrl,
      clnrestCa: clnrestCa ?? this.clnrestCa,
      clnrestCert: clnrestCert ?? this.clnrestCert,
      clnrestReadonlyRune: clnrestReadonlyRune ?? this.clnrestReadonlyRune,
      clnrestInvoiceRune: clnrestInvoiceRune ?? this.clnrestInvoiceRune,
      clnrestPayRune: clnrestPayRune ?? this.clnrestPayRune,
      clnrestRenepayRune: clnrestRenepayRune ?? this.clnrestRenepayRune,
      clnrestLastPayIndex: clnrestLastPayIndex ?? this.clnrestLastPayIndex,
      clnrestNodeid: clnrestNodeid ?? this.clnrestNodeid,
      clicheEndpoint: clicheEndpoint ?? this.clicheEndpoint,
      lnbitsEndpoint: lnbitsEndpoint ?? this.lnbitsEndpoint,
      lnbitsKey: lnbitsKey ?? this.lnbitsKey,
      lnbitsAdminKey: lnbitsAdminKey ?? this.lnbitsAdminKey,
      lnbitsInvoiceKey: lnbitsInvoiceKey ?? this.lnbitsInvoiceKey,
      fakeWalletSecret: fakeWalletSecret ?? this.fakeWalletSecret,
      lnbitsDenomination: lnbitsDenomination ?? this.lnbitsDenomination,
      lnbitsBackendWalletClass:
          lnbitsBackendWalletClass ?? this.lnbitsBackendWalletClass,
      lnbitsFundingSourcePayInvoiceWaitSeconds:
          lnbitsFundingSourcePayInvoiceWaitSeconds ??
          this.lnbitsFundingSourcePayInvoiceWaitSeconds,
      fundingSourceMaxRetries:
          fundingSourceMaxRetries ?? this.fundingSourceMaxRetries,
      lnbitsNostrNotificationsEnabled:
          lnbitsNostrNotificationsEnabled ??
          this.lnbitsNostrNotificationsEnabled,
      lnbitsNostrNotificationsPrivateKey:
          lnbitsNostrNotificationsPrivateKey ??
          this.lnbitsNostrNotificationsPrivateKey,
      lnbitsNostrNotificationsIdentifiers:
          lnbitsNostrNotificationsIdentifiers ??
          this.lnbitsNostrNotificationsIdentifiers,
      lnbitsTelegramNotificationsEnabled:
          lnbitsTelegramNotificationsEnabled ??
          this.lnbitsTelegramNotificationsEnabled,
      lnbitsTelegramNotificationsAccessToken:
          lnbitsTelegramNotificationsAccessToken ??
          this.lnbitsTelegramNotificationsAccessToken,
      lnbitsTelegramNotificationsChatId:
          lnbitsTelegramNotificationsChatId ??
          this.lnbitsTelegramNotificationsChatId,
      lnbitsEmailNotificationsEnabled:
          lnbitsEmailNotificationsEnabled ??
          this.lnbitsEmailNotificationsEnabled,
      lnbitsEmailNotificationsEmail:
          lnbitsEmailNotificationsEmail ?? this.lnbitsEmailNotificationsEmail,
      lnbitsEmailNotificationsUsername:
          lnbitsEmailNotificationsUsername ??
          this.lnbitsEmailNotificationsUsername,
      lnbitsEmailNotificationsPassword:
          lnbitsEmailNotificationsPassword ??
          this.lnbitsEmailNotificationsPassword,
      lnbitsEmailNotificationsServer:
          lnbitsEmailNotificationsServer ?? this.lnbitsEmailNotificationsServer,
      lnbitsEmailNotificationsPort:
          lnbitsEmailNotificationsPort ?? this.lnbitsEmailNotificationsPort,
      lnbitsEmailNotificationsToEmails:
          lnbitsEmailNotificationsToEmails ??
          this.lnbitsEmailNotificationsToEmails,
      lnbitsNotificationSettingsUpdate:
          lnbitsNotificationSettingsUpdate ??
          this.lnbitsNotificationSettingsUpdate,
      lnbitsNotificationCreditDebit:
          lnbitsNotificationCreditDebit ?? this.lnbitsNotificationCreditDebit,
      notificationBalanceDeltaThresholdSats:
          notificationBalanceDeltaThresholdSats ??
          this.notificationBalanceDeltaThresholdSats,
      lnbitsNotificationServerStartStop:
          lnbitsNotificationServerStartStop ??
          this.lnbitsNotificationServerStartStop,
      lnbitsNotificationWatchdog:
          lnbitsNotificationWatchdog ?? this.lnbitsNotificationWatchdog,
      lnbitsNotificationServerStatusHours:
          lnbitsNotificationServerStatusHours ??
          this.lnbitsNotificationServerStatusHours,
      lnbitsNotificationIncomingPaymentAmountSats:
          lnbitsNotificationIncomingPaymentAmountSats ??
          this.lnbitsNotificationIncomingPaymentAmountSats,
      lnbitsNotificationOutgoingPaymentAmountSats:
          lnbitsNotificationOutgoingPaymentAmountSats ??
          this.lnbitsNotificationOutgoingPaymentAmountSats,
      lnbitsRateLimitNo: lnbitsRateLimitNo ?? this.lnbitsRateLimitNo,
      lnbitsRateLimitUnit: lnbitsRateLimitUnit ?? this.lnbitsRateLimitUnit,
      lnbitsAllowedIps: lnbitsAllowedIps ?? this.lnbitsAllowedIps,
      lnbitsBlockedIps: lnbitsBlockedIps ?? this.lnbitsBlockedIps,
      lnbitsCallbackUrlRules:
          lnbitsCallbackUrlRules ?? this.lnbitsCallbackUrlRules,
      lnbitsWalletLimitMaxBalance:
          lnbitsWalletLimitMaxBalance ?? this.lnbitsWalletLimitMaxBalance,
      lnbitsWalletLimitDailyMaxWithdraw:
          lnbitsWalletLimitDailyMaxWithdraw ??
          this.lnbitsWalletLimitDailyMaxWithdraw,
      lnbitsWalletLimitSecsBetweenTrans:
          lnbitsWalletLimitSecsBetweenTrans ??
          this.lnbitsWalletLimitSecsBetweenTrans,
      lnbitsOnlyAllowIncomingPayments:
          lnbitsOnlyAllowIncomingPayments ??
          this.lnbitsOnlyAllowIncomingPayments,
      lnbitsWatchdogSwitchToVoidwallet:
          lnbitsWatchdogSwitchToVoidwallet ??
          this.lnbitsWatchdogSwitchToVoidwallet,
      lnbitsWatchdogIntervalMinutes:
          lnbitsWatchdogIntervalMinutes ?? this.lnbitsWatchdogIntervalMinutes,
      lnbitsWatchdogDelta: lnbitsWatchdogDelta ?? this.lnbitsWatchdogDelta,
      lnbitsMaxOutgoingPaymentAmountSats:
          lnbitsMaxOutgoingPaymentAmountSats ??
          this.lnbitsMaxOutgoingPaymentAmountSats,
      lnbitsMaxIncomingPaymentAmountSats:
          lnbitsMaxIncomingPaymentAmountSats ??
          this.lnbitsMaxIncomingPaymentAmountSats,
      lnbitsExchangeRateCacheSeconds:
          lnbitsExchangeRateCacheSeconds ?? this.lnbitsExchangeRateCacheSeconds,
      lnbitsExchangeHistorySize:
          lnbitsExchangeHistorySize ?? this.lnbitsExchangeHistorySize,
      lnbitsExchangeHistoryRefreshIntervalSeconds:
          lnbitsExchangeHistoryRefreshIntervalSeconds ??
          this.lnbitsExchangeHistoryRefreshIntervalSeconds,
      lnbitsExchangeRateProviders:
          lnbitsExchangeRateProviders ?? this.lnbitsExchangeRateProviders,
      lnbitsReserveFeeMin: lnbitsReserveFeeMin ?? this.lnbitsReserveFeeMin,
      lnbitsReserveFeePercent:
          lnbitsReserveFeePercent ?? this.lnbitsReserveFeePercent,
      lnbitsServiceFee: lnbitsServiceFee ?? this.lnbitsServiceFee,
      lnbitsServiceFeeIgnoreInternal:
          lnbitsServiceFeeIgnoreInternal ?? this.lnbitsServiceFeeIgnoreInternal,
      lnbitsServiceFeeMax: lnbitsServiceFeeMax ?? this.lnbitsServiceFeeMax,
      lnbitsServiceFeeWallet:
          lnbitsServiceFeeWallet ?? this.lnbitsServiceFeeWallet,
      lnbitsMaxAssetSizeMb: lnbitsMaxAssetSizeMb ?? this.lnbitsMaxAssetSizeMb,
      lnbitsAssetsAllowedMimeTypes:
          lnbitsAssetsAllowedMimeTypes ?? this.lnbitsAssetsAllowedMimeTypes,
      lnbitsAssetThumbnailWidth:
          lnbitsAssetThumbnailWidth ?? this.lnbitsAssetThumbnailWidth,
      lnbitsAssetThumbnailHeight:
          lnbitsAssetThumbnailHeight ?? this.lnbitsAssetThumbnailHeight,
      lnbitsAssetThumbnailFormat:
          lnbitsAssetThumbnailFormat ?? this.lnbitsAssetThumbnailFormat,
      lnbitsMaxAssetsPerUser:
          lnbitsMaxAssetsPerUser ?? this.lnbitsMaxAssetsPerUser,
      lnbitsAssetsNoLimitUsers:
          lnbitsAssetsNoLimitUsers ?? this.lnbitsAssetsNoLimitUsers,
      lnbitsBaseurl: lnbitsBaseurl ?? this.lnbitsBaseurl,
      lnbitsHideApi: lnbitsHideApi ?? this.lnbitsHideApi,
      lnbitsSiteTitle: lnbitsSiteTitle ?? this.lnbitsSiteTitle,
      lnbitsSiteTagline: lnbitsSiteTagline ?? this.lnbitsSiteTagline,
      lnbitsSiteDescription:
          lnbitsSiteDescription ?? this.lnbitsSiteDescription,
      lnbitsShowHomePageElements:
          lnbitsShowHomePageElements ?? this.lnbitsShowHomePageElements,
      lnbitsDefaultWalletName:
          lnbitsDefaultWalletName ?? this.lnbitsDefaultWalletName,
      lnbitsCustomBadge: lnbitsCustomBadge ?? this.lnbitsCustomBadge,
      lnbitsCustomBadgeColor:
          lnbitsCustomBadgeColor ?? this.lnbitsCustomBadgeColor,
      lnbitsThemeOptions: lnbitsThemeOptions ?? this.lnbitsThemeOptions,
      lnbitsCustomLogo: lnbitsCustomLogo ?? this.lnbitsCustomLogo,
      lnbitsCustomImage: lnbitsCustomImage ?? this.lnbitsCustomImage,
      lnbitsAdSpaceTitle: lnbitsAdSpaceTitle ?? this.lnbitsAdSpaceTitle,
      lnbitsAdSpace: lnbitsAdSpace ?? this.lnbitsAdSpace,
      lnbitsAdSpaceEnabled: lnbitsAdSpaceEnabled ?? this.lnbitsAdSpaceEnabled,
      lnbitsAllowedCurrencies:
          lnbitsAllowedCurrencies ?? this.lnbitsAllowedCurrencies,
      lnbitsDefaultAccountingCurrency:
          lnbitsDefaultAccountingCurrency ??
          this.lnbitsDefaultAccountingCurrency,
      lnbitsQrLogo: lnbitsQrLogo ?? this.lnbitsQrLogo,
      lnbitsAppleTouchIcon: lnbitsAppleTouchIcon ?? this.lnbitsAppleTouchIcon,
      lnbitsDefaultReaction:
          lnbitsDefaultReaction ?? this.lnbitsDefaultReaction,
      lnbitsDefaultTheme: lnbitsDefaultTheme ?? this.lnbitsDefaultTheme,
      lnbitsDefaultBorder: lnbitsDefaultBorder ?? this.lnbitsDefaultBorder,
      lnbitsDefaultGradient:
          lnbitsDefaultGradient ?? this.lnbitsDefaultGradient,
      lnbitsDefaultBgimage: lnbitsDefaultBgimage ?? this.lnbitsDefaultBgimage,
      lnbitsAdminExtensions:
          lnbitsAdminExtensions ?? this.lnbitsAdminExtensions,
      lnbitsUserDefaultExtensions:
          lnbitsUserDefaultExtensions ?? this.lnbitsUserDefaultExtensions,
      lnbitsExtensionsDeactivateAll:
          lnbitsExtensionsDeactivateAll ?? this.lnbitsExtensionsDeactivateAll,
      lnbitsExtensionsBuilderActivateNonAdmins:
          lnbitsExtensionsBuilderActivateNonAdmins ??
          this.lnbitsExtensionsBuilderActivateNonAdmins,
      lnbitsExtensionsReviewsUrl:
          lnbitsExtensionsReviewsUrl ?? this.lnbitsExtensionsReviewsUrl,
      lnbitsExtensionsManifests:
          lnbitsExtensionsManifests ?? this.lnbitsExtensionsManifests,
      lnbitsExtensionsBuilderManifestUrl:
          lnbitsExtensionsBuilderManifestUrl ??
          this.lnbitsExtensionsBuilderManifestUrl,
      lnbitsAdminUsers: lnbitsAdminUsers ?? this.lnbitsAdminUsers,
      lnbitsAllowedUsers: lnbitsAllowedUsers ?? this.lnbitsAllowedUsers,
      lnbitsAllowNewAccounts:
          lnbitsAllowNewAccounts ?? this.lnbitsAllowNewAccounts,
      isSuperUser: isSuperUser ?? this.isSuperUser,
      lnbitsAllowedFundingSources:
          lnbitsAllowedFundingSources ?? this.lnbitsAllowedFundingSources,
    );
  }

  AdminSettings copyWithWrapped({
    Wrapped<String?>? keycloakDiscoveryUrl,
    Wrapped<String?>? keycloakClientId,
    Wrapped<String?>? keycloakClientSecret,
    Wrapped<String?>? keycloakClientCustomOrg,
    Wrapped<String?>? keycloakClientCustomIcon,
    Wrapped<String?>? githubClientId,
    Wrapped<String?>? githubClientSecret,
    Wrapped<String?>? googleClientId,
    Wrapped<String?>? googleClientSecret,
    Wrapped<List<String>?>? nostrAbsoluteRequestUrls,
    Wrapped<int?>? authTokenExpireMinutes,
    Wrapped<List<String>?>? authAllMethods,
    Wrapped<List<String>?>? authAllowedMethods,
    Wrapped<int?>? authCredetialsUpdateThreshold,
    Wrapped<int?>? authAuthenticationCacheMinutes,
    Wrapped<bool?>? lnbitsAuditEnabled,
    Wrapped<int?>? lnbitsAuditRetentionDays,
    Wrapped<bool?>? lnbitsAuditLogIpAddress,
    Wrapped<bool?>? lnbitsAuditLogPathParams,
    Wrapped<bool?>? lnbitsAuditLogQueryParams,
    Wrapped<bool?>? lnbitsAuditLogRequestBody,
    Wrapped<List<String>?>? lnbitsAuditIncludePaths,
    Wrapped<List<String>?>? lnbitsAuditExcludePaths,
    Wrapped<List<String>?>? lnbitsAuditHttpMethods,
    Wrapped<List<String>?>? lnbitsAuditHttpResponseCodes,
    Wrapped<bool?>? lnbitsNodeUi,
    Wrapped<bool?>? lnbitsPublicNodeUi,
    Wrapped<bool?>? lnbitsNodeUiTransactions,
    Wrapped<String?>? lnbitsWebpushPubkey,
    Wrapped<String?>? lnbitsWebpushPrivkey,
    Wrapped<int?>? lightningInvoiceExpiry,
    Wrapped<bool?>? paypalEnabled,
    Wrapped<String?>? paypalApiEndpoint,
    Wrapped<String?>? paypalClientId,
    Wrapped<String?>? paypalClientSecret,
    Wrapped<String?>? paypalPaymentSuccessUrl,
    Wrapped<String?>? paypalPaymentWebhookUrl,
    Wrapped<String?>? paypalWebhookId,
    Wrapped<FiatProviderLimits?>? paypalLimits,
    Wrapped<bool?>? stripeEnabled,
    Wrapped<String?>? stripeApiEndpoint,
    Wrapped<String?>? stripeApiSecretKey,
    Wrapped<String?>? stripePaymentSuccessUrl,
    Wrapped<String?>? stripePaymentWebhookUrl,
    Wrapped<String?>? stripeWebhookSigningSecret,
    Wrapped<FiatProviderLimits?>? stripeLimits,
    Wrapped<String?>? breezLiquidApiKey,
    Wrapped<String?>? breezLiquidSeed,
    Wrapped<int?>? breezLiquidFeeOffsetSat,
    Wrapped<String?>? strikeApiEndpoint,
    Wrapped<String?>? strikeApiKey,
    Wrapped<String?>? breezApiKey,
    Wrapped<String?>? breezGreenlightSeed,
    Wrapped<String?>? breezGreenlightInviteCode,
    Wrapped<String?>? breezGreenlightDeviceKey,
    Wrapped<String?>? breezGreenlightDeviceCert,
    Wrapped<bool?>? breezUseTrampoline,
    Wrapped<String?>? nwcPairingUrl,
    Wrapped<String?>? lntipsApiEndpoint,
    Wrapped<String?>? lntipsApiKey,
    Wrapped<String?>? lntipsAdminKey,
    Wrapped<String?>? lntipsInvoiceKey,
    Wrapped<String?>? sparkUrl,
    Wrapped<String?>? sparkToken,
    Wrapped<String?>? opennodeApiEndpoint,
    Wrapped<String?>? opennodeKey,
    Wrapped<String?>? opennodeAdminKey,
    Wrapped<String?>? opennodeInvoiceKey,
    Wrapped<String?>? phoenixdApiEndpoint,
    Wrapped<String?>? phoenixdApiPassword,
    Wrapped<String?>? zbdApiEndpoint,
    Wrapped<String?>? zbdApiKey,
    Wrapped<String?>? boltzClientEndpoint,
    Wrapped<String?>? boltzClientMacaroon,
    Wrapped<String?>? boltzClientPassword,
    Wrapped<String?>? boltzClientCert,
    Wrapped<String?>? boltzMnemonic,
    Wrapped<String?>? albyApiEndpoint,
    Wrapped<String?>? albyAccessToken,
    Wrapped<String?>? blinkApiEndpoint,
    Wrapped<String?>? blinkWsEndpoint,
    Wrapped<String?>? blinkToken,
    Wrapped<String?>? lnpayApiEndpoint,
    Wrapped<String?>? lnpayApiKey,
    Wrapped<String?>? lnpayWalletKey,
    Wrapped<String?>? lnpayAdminKey,
    Wrapped<String?>? lndGrpcEndpoint,
    Wrapped<String?>? lndGrpcCert,
    Wrapped<int?>? lndGrpcPort,
    Wrapped<String?>? lndGrpcAdminMacaroon,
    Wrapped<String?>? lndGrpcInvoiceMacaroon,
    Wrapped<String?>? lndGrpcMacaroon,
    Wrapped<String?>? lndGrpcMacaroonEncrypted,
    Wrapped<String?>? lndRestEndpoint,
    Wrapped<String?>? lndRestCert,
    Wrapped<String?>? lndRestMacaroon,
    Wrapped<String?>? lndRestMacaroonEncrypted,
    Wrapped<bool?>? lndRestRouteHints,
    Wrapped<bool?>? lndRestAllowSelfPayment,
    Wrapped<String?>? lndCert,
    Wrapped<String?>? lndAdminMacaroon,
    Wrapped<String?>? lndInvoiceMacaroon,
    Wrapped<String?>? lndRestAdminMacaroon,
    Wrapped<String?>? lndRestInvoiceMacaroon,
    Wrapped<String?>? eclairUrl,
    Wrapped<String?>? eclairPass,
    Wrapped<String?>? corelightningRestUrl,
    Wrapped<String?>? corelightningRestMacaroon,
    Wrapped<String?>? corelightningRestCert,
    Wrapped<String?>? corelightningRpc,
    Wrapped<String?>? corelightningPayCommand,
    Wrapped<String?>? clightningRpc,
    Wrapped<String?>? clnrestUrl,
    Wrapped<String?>? clnrestCa,
    Wrapped<String?>? clnrestCert,
    Wrapped<String?>? clnrestReadonlyRune,
    Wrapped<String?>? clnrestInvoiceRune,
    Wrapped<String?>? clnrestPayRune,
    Wrapped<String?>? clnrestRenepayRune,
    Wrapped<String?>? clnrestLastPayIndex,
    Wrapped<String?>? clnrestNodeid,
    Wrapped<String?>? clicheEndpoint,
    Wrapped<String?>? lnbitsEndpoint,
    Wrapped<String?>? lnbitsKey,
    Wrapped<String?>? lnbitsAdminKey,
    Wrapped<String?>? lnbitsInvoiceKey,
    Wrapped<String?>? fakeWalletSecret,
    Wrapped<String?>? lnbitsDenomination,
    Wrapped<String?>? lnbitsBackendWalletClass,
    Wrapped<int?>? lnbitsFundingSourcePayInvoiceWaitSeconds,
    Wrapped<int?>? fundingSourceMaxRetries,
    Wrapped<bool?>? lnbitsNostrNotificationsEnabled,
    Wrapped<String?>? lnbitsNostrNotificationsPrivateKey,
    Wrapped<List<String>?>? lnbitsNostrNotificationsIdentifiers,
    Wrapped<bool?>? lnbitsTelegramNotificationsEnabled,
    Wrapped<String?>? lnbitsTelegramNotificationsAccessToken,
    Wrapped<String?>? lnbitsTelegramNotificationsChatId,
    Wrapped<bool?>? lnbitsEmailNotificationsEnabled,
    Wrapped<String?>? lnbitsEmailNotificationsEmail,
    Wrapped<String?>? lnbitsEmailNotificationsUsername,
    Wrapped<String?>? lnbitsEmailNotificationsPassword,
    Wrapped<String?>? lnbitsEmailNotificationsServer,
    Wrapped<int?>? lnbitsEmailNotificationsPort,
    Wrapped<List<String>?>? lnbitsEmailNotificationsToEmails,
    Wrapped<bool?>? lnbitsNotificationSettingsUpdate,
    Wrapped<bool?>? lnbitsNotificationCreditDebit,
    Wrapped<int?>? notificationBalanceDeltaThresholdSats,
    Wrapped<bool?>? lnbitsNotificationServerStartStop,
    Wrapped<bool?>? lnbitsNotificationWatchdog,
    Wrapped<int?>? lnbitsNotificationServerStatusHours,
    Wrapped<int?>? lnbitsNotificationIncomingPaymentAmountSats,
    Wrapped<int?>? lnbitsNotificationOutgoingPaymentAmountSats,
    Wrapped<int?>? lnbitsRateLimitNo,
    Wrapped<String?>? lnbitsRateLimitUnit,
    Wrapped<List<String>?>? lnbitsAllowedIps,
    Wrapped<List<String>?>? lnbitsBlockedIps,
    Wrapped<List<String>?>? lnbitsCallbackUrlRules,
    Wrapped<int?>? lnbitsWalletLimitMaxBalance,
    Wrapped<int?>? lnbitsWalletLimitDailyMaxWithdraw,
    Wrapped<int?>? lnbitsWalletLimitSecsBetweenTrans,
    Wrapped<bool?>? lnbitsOnlyAllowIncomingPayments,
    Wrapped<bool?>? lnbitsWatchdogSwitchToVoidwallet,
    Wrapped<int?>? lnbitsWatchdogIntervalMinutes,
    Wrapped<int?>? lnbitsWatchdogDelta,
    Wrapped<int?>? lnbitsMaxOutgoingPaymentAmountSats,
    Wrapped<int?>? lnbitsMaxIncomingPaymentAmountSats,
    Wrapped<int?>? lnbitsExchangeRateCacheSeconds,
    Wrapped<int?>? lnbitsExchangeHistorySize,
    Wrapped<int?>? lnbitsExchangeHistoryRefreshIntervalSeconds,
    Wrapped<List<ExchangeRateProvider>?>? lnbitsExchangeRateProviders,
    Wrapped<int?>? lnbitsReserveFeeMin,
    Wrapped<double?>? lnbitsReserveFeePercent,
    Wrapped<double?>? lnbitsServiceFee,
    Wrapped<bool?>? lnbitsServiceFeeIgnoreInternal,
    Wrapped<int?>? lnbitsServiceFeeMax,
    Wrapped<String?>? lnbitsServiceFeeWallet,
    Wrapped<double?>? lnbitsMaxAssetSizeMb,
    Wrapped<List<String>?>? lnbitsAssetsAllowedMimeTypes,
    Wrapped<int?>? lnbitsAssetThumbnailWidth,
    Wrapped<int?>? lnbitsAssetThumbnailHeight,
    Wrapped<String?>? lnbitsAssetThumbnailFormat,
    Wrapped<int?>? lnbitsMaxAssetsPerUser,
    Wrapped<List<String>?>? lnbitsAssetsNoLimitUsers,
    Wrapped<String?>? lnbitsBaseurl,
    Wrapped<bool?>? lnbitsHideApi,
    Wrapped<String?>? lnbitsSiteTitle,
    Wrapped<String?>? lnbitsSiteTagline,
    Wrapped<String?>? lnbitsSiteDescription,
    Wrapped<bool?>? lnbitsShowHomePageElements,
    Wrapped<String?>? lnbitsDefaultWalletName,
    Wrapped<String?>? lnbitsCustomBadge,
    Wrapped<String?>? lnbitsCustomBadgeColor,
    Wrapped<List<String>?>? lnbitsThemeOptions,
    Wrapped<String?>? lnbitsCustomLogo,
    Wrapped<String?>? lnbitsCustomImage,
    Wrapped<String?>? lnbitsAdSpaceTitle,
    Wrapped<String?>? lnbitsAdSpace,
    Wrapped<bool?>? lnbitsAdSpaceEnabled,
    Wrapped<List<String>?>? lnbitsAllowedCurrencies,
    Wrapped<String?>? lnbitsDefaultAccountingCurrency,
    Wrapped<String?>? lnbitsQrLogo,
    Wrapped<String?>? lnbitsAppleTouchIcon,
    Wrapped<String?>? lnbitsDefaultReaction,
    Wrapped<String?>? lnbitsDefaultTheme,
    Wrapped<String?>? lnbitsDefaultBorder,
    Wrapped<bool?>? lnbitsDefaultGradient,
    Wrapped<String?>? lnbitsDefaultBgimage,
    Wrapped<List<String>?>? lnbitsAdminExtensions,
    Wrapped<List<String>?>? lnbitsUserDefaultExtensions,
    Wrapped<bool?>? lnbitsExtensionsDeactivateAll,
    Wrapped<bool?>? lnbitsExtensionsBuilderActivateNonAdmins,
    Wrapped<String?>? lnbitsExtensionsReviewsUrl,
    Wrapped<List<String>?>? lnbitsExtensionsManifests,
    Wrapped<String?>? lnbitsExtensionsBuilderManifestUrl,
    Wrapped<List<String>?>? lnbitsAdminUsers,
    Wrapped<List<String>?>? lnbitsAllowedUsers,
    Wrapped<bool?>? lnbitsAllowNewAccounts,
    Wrapped<bool>? isSuperUser,
    Wrapped<List<String>?>? lnbitsAllowedFundingSources,
  }) {
    return AdminSettings(
      keycloakDiscoveryUrl: (keycloakDiscoveryUrl != null
          ? keycloakDiscoveryUrl.value
          : this.keycloakDiscoveryUrl),
      keycloakClientId: (keycloakClientId != null
          ? keycloakClientId.value
          : this.keycloakClientId),
      keycloakClientSecret: (keycloakClientSecret != null
          ? keycloakClientSecret.value
          : this.keycloakClientSecret),
      keycloakClientCustomOrg: (keycloakClientCustomOrg != null
          ? keycloakClientCustomOrg.value
          : this.keycloakClientCustomOrg),
      keycloakClientCustomIcon: (keycloakClientCustomIcon != null
          ? keycloakClientCustomIcon.value
          : this.keycloakClientCustomIcon),
      githubClientId: (githubClientId != null
          ? githubClientId.value
          : this.githubClientId),
      githubClientSecret: (githubClientSecret != null
          ? githubClientSecret.value
          : this.githubClientSecret),
      googleClientId: (googleClientId != null
          ? googleClientId.value
          : this.googleClientId),
      googleClientSecret: (googleClientSecret != null
          ? googleClientSecret.value
          : this.googleClientSecret),
      nostrAbsoluteRequestUrls: (nostrAbsoluteRequestUrls != null
          ? nostrAbsoluteRequestUrls.value
          : this.nostrAbsoluteRequestUrls),
      authTokenExpireMinutes: (authTokenExpireMinutes != null
          ? authTokenExpireMinutes.value
          : this.authTokenExpireMinutes),
      authAllMethods: (authAllMethods != null
          ? authAllMethods.value
          : this.authAllMethods),
      authAllowedMethods: (authAllowedMethods != null
          ? authAllowedMethods.value
          : this.authAllowedMethods),
      authCredetialsUpdateThreshold: (authCredetialsUpdateThreshold != null
          ? authCredetialsUpdateThreshold.value
          : this.authCredetialsUpdateThreshold),
      authAuthenticationCacheMinutes: (authAuthenticationCacheMinutes != null
          ? authAuthenticationCacheMinutes.value
          : this.authAuthenticationCacheMinutes),
      lnbitsAuditEnabled: (lnbitsAuditEnabled != null
          ? lnbitsAuditEnabled.value
          : this.lnbitsAuditEnabled),
      lnbitsAuditRetentionDays: (lnbitsAuditRetentionDays != null
          ? lnbitsAuditRetentionDays.value
          : this.lnbitsAuditRetentionDays),
      lnbitsAuditLogIpAddress: (lnbitsAuditLogIpAddress != null
          ? lnbitsAuditLogIpAddress.value
          : this.lnbitsAuditLogIpAddress),
      lnbitsAuditLogPathParams: (lnbitsAuditLogPathParams != null
          ? lnbitsAuditLogPathParams.value
          : this.lnbitsAuditLogPathParams),
      lnbitsAuditLogQueryParams: (lnbitsAuditLogQueryParams != null
          ? lnbitsAuditLogQueryParams.value
          : this.lnbitsAuditLogQueryParams),
      lnbitsAuditLogRequestBody: (lnbitsAuditLogRequestBody != null
          ? lnbitsAuditLogRequestBody.value
          : this.lnbitsAuditLogRequestBody),
      lnbitsAuditIncludePaths: (lnbitsAuditIncludePaths != null
          ? lnbitsAuditIncludePaths.value
          : this.lnbitsAuditIncludePaths),
      lnbitsAuditExcludePaths: (lnbitsAuditExcludePaths != null
          ? lnbitsAuditExcludePaths.value
          : this.lnbitsAuditExcludePaths),
      lnbitsAuditHttpMethods: (lnbitsAuditHttpMethods != null
          ? lnbitsAuditHttpMethods.value
          : this.lnbitsAuditHttpMethods),
      lnbitsAuditHttpResponseCodes: (lnbitsAuditHttpResponseCodes != null
          ? lnbitsAuditHttpResponseCodes.value
          : this.lnbitsAuditHttpResponseCodes),
      lnbitsNodeUi: (lnbitsNodeUi != null
          ? lnbitsNodeUi.value
          : this.lnbitsNodeUi),
      lnbitsPublicNodeUi: (lnbitsPublicNodeUi != null
          ? lnbitsPublicNodeUi.value
          : this.lnbitsPublicNodeUi),
      lnbitsNodeUiTransactions: (lnbitsNodeUiTransactions != null
          ? lnbitsNodeUiTransactions.value
          : this.lnbitsNodeUiTransactions),
      lnbitsWebpushPubkey: (lnbitsWebpushPubkey != null
          ? lnbitsWebpushPubkey.value
          : this.lnbitsWebpushPubkey),
      lnbitsWebpushPrivkey: (lnbitsWebpushPrivkey != null
          ? lnbitsWebpushPrivkey.value
          : this.lnbitsWebpushPrivkey),
      lightningInvoiceExpiry: (lightningInvoiceExpiry != null
          ? lightningInvoiceExpiry.value
          : this.lightningInvoiceExpiry),
      paypalEnabled: (paypalEnabled != null
          ? paypalEnabled.value
          : this.paypalEnabled),
      paypalApiEndpoint: (paypalApiEndpoint != null
          ? paypalApiEndpoint.value
          : this.paypalApiEndpoint),
      paypalClientId: (paypalClientId != null
          ? paypalClientId.value
          : this.paypalClientId),
      paypalClientSecret: (paypalClientSecret != null
          ? paypalClientSecret.value
          : this.paypalClientSecret),
      paypalPaymentSuccessUrl: (paypalPaymentSuccessUrl != null
          ? paypalPaymentSuccessUrl.value
          : this.paypalPaymentSuccessUrl),
      paypalPaymentWebhookUrl: (paypalPaymentWebhookUrl != null
          ? paypalPaymentWebhookUrl.value
          : this.paypalPaymentWebhookUrl),
      paypalWebhookId: (paypalWebhookId != null
          ? paypalWebhookId.value
          : this.paypalWebhookId),
      paypalLimits: (paypalLimits != null
          ? paypalLimits.value
          : this.paypalLimits),
      stripeEnabled: (stripeEnabled != null
          ? stripeEnabled.value
          : this.stripeEnabled),
      stripeApiEndpoint: (stripeApiEndpoint != null
          ? stripeApiEndpoint.value
          : this.stripeApiEndpoint),
      stripeApiSecretKey: (stripeApiSecretKey != null
          ? stripeApiSecretKey.value
          : this.stripeApiSecretKey),
      stripePaymentSuccessUrl: (stripePaymentSuccessUrl != null
          ? stripePaymentSuccessUrl.value
          : this.stripePaymentSuccessUrl),
      stripePaymentWebhookUrl: (stripePaymentWebhookUrl != null
          ? stripePaymentWebhookUrl.value
          : this.stripePaymentWebhookUrl),
      stripeWebhookSigningSecret: (stripeWebhookSigningSecret != null
          ? stripeWebhookSigningSecret.value
          : this.stripeWebhookSigningSecret),
      stripeLimits: (stripeLimits != null
          ? stripeLimits.value
          : this.stripeLimits),
      breezLiquidApiKey: (breezLiquidApiKey != null
          ? breezLiquidApiKey.value
          : this.breezLiquidApiKey),
      breezLiquidSeed: (breezLiquidSeed != null
          ? breezLiquidSeed.value
          : this.breezLiquidSeed),
      breezLiquidFeeOffsetSat: (breezLiquidFeeOffsetSat != null
          ? breezLiquidFeeOffsetSat.value
          : this.breezLiquidFeeOffsetSat),
      strikeApiEndpoint: (strikeApiEndpoint != null
          ? strikeApiEndpoint.value
          : this.strikeApiEndpoint),
      strikeApiKey: (strikeApiKey != null
          ? strikeApiKey.value
          : this.strikeApiKey),
      breezApiKey: (breezApiKey != null ? breezApiKey.value : this.breezApiKey),
      breezGreenlightSeed: (breezGreenlightSeed != null
          ? breezGreenlightSeed.value
          : this.breezGreenlightSeed),
      breezGreenlightInviteCode: (breezGreenlightInviteCode != null
          ? breezGreenlightInviteCode.value
          : this.breezGreenlightInviteCode),
      breezGreenlightDeviceKey: (breezGreenlightDeviceKey != null
          ? breezGreenlightDeviceKey.value
          : this.breezGreenlightDeviceKey),
      breezGreenlightDeviceCert: (breezGreenlightDeviceCert != null
          ? breezGreenlightDeviceCert.value
          : this.breezGreenlightDeviceCert),
      breezUseTrampoline: (breezUseTrampoline != null
          ? breezUseTrampoline.value
          : this.breezUseTrampoline),
      nwcPairingUrl: (nwcPairingUrl != null
          ? nwcPairingUrl.value
          : this.nwcPairingUrl),
      lntipsApiEndpoint: (lntipsApiEndpoint != null
          ? lntipsApiEndpoint.value
          : this.lntipsApiEndpoint),
      lntipsApiKey: (lntipsApiKey != null
          ? lntipsApiKey.value
          : this.lntipsApiKey),
      lntipsAdminKey: (lntipsAdminKey != null
          ? lntipsAdminKey.value
          : this.lntipsAdminKey),
      lntipsInvoiceKey: (lntipsInvoiceKey != null
          ? lntipsInvoiceKey.value
          : this.lntipsInvoiceKey),
      sparkUrl: (sparkUrl != null ? sparkUrl.value : this.sparkUrl),
      sparkToken: (sparkToken != null ? sparkToken.value : this.sparkToken),
      opennodeApiEndpoint: (opennodeApiEndpoint != null
          ? opennodeApiEndpoint.value
          : this.opennodeApiEndpoint),
      opennodeKey: (opennodeKey != null ? opennodeKey.value : this.opennodeKey),
      opennodeAdminKey: (opennodeAdminKey != null
          ? opennodeAdminKey.value
          : this.opennodeAdminKey),
      opennodeInvoiceKey: (opennodeInvoiceKey != null
          ? opennodeInvoiceKey.value
          : this.opennodeInvoiceKey),
      phoenixdApiEndpoint: (phoenixdApiEndpoint != null
          ? phoenixdApiEndpoint.value
          : this.phoenixdApiEndpoint),
      phoenixdApiPassword: (phoenixdApiPassword != null
          ? phoenixdApiPassword.value
          : this.phoenixdApiPassword),
      zbdApiEndpoint: (zbdApiEndpoint != null
          ? zbdApiEndpoint.value
          : this.zbdApiEndpoint),
      zbdApiKey: (zbdApiKey != null ? zbdApiKey.value : this.zbdApiKey),
      boltzClientEndpoint: (boltzClientEndpoint != null
          ? boltzClientEndpoint.value
          : this.boltzClientEndpoint),
      boltzClientMacaroon: (boltzClientMacaroon != null
          ? boltzClientMacaroon.value
          : this.boltzClientMacaroon),
      boltzClientPassword: (boltzClientPassword != null
          ? boltzClientPassword.value
          : this.boltzClientPassword),
      boltzClientCert: (boltzClientCert != null
          ? boltzClientCert.value
          : this.boltzClientCert),
      boltzMnemonic: (boltzMnemonic != null
          ? boltzMnemonic.value
          : this.boltzMnemonic),
      albyApiEndpoint: (albyApiEndpoint != null
          ? albyApiEndpoint.value
          : this.albyApiEndpoint),
      albyAccessToken: (albyAccessToken != null
          ? albyAccessToken.value
          : this.albyAccessToken),
      blinkApiEndpoint: (blinkApiEndpoint != null
          ? blinkApiEndpoint.value
          : this.blinkApiEndpoint),
      blinkWsEndpoint: (blinkWsEndpoint != null
          ? blinkWsEndpoint.value
          : this.blinkWsEndpoint),
      blinkToken: (blinkToken != null ? blinkToken.value : this.blinkToken),
      lnpayApiEndpoint: (lnpayApiEndpoint != null
          ? lnpayApiEndpoint.value
          : this.lnpayApiEndpoint),
      lnpayApiKey: (lnpayApiKey != null ? lnpayApiKey.value : this.lnpayApiKey),
      lnpayWalletKey: (lnpayWalletKey != null
          ? lnpayWalletKey.value
          : this.lnpayWalletKey),
      lnpayAdminKey: (lnpayAdminKey != null
          ? lnpayAdminKey.value
          : this.lnpayAdminKey),
      lndGrpcEndpoint: (lndGrpcEndpoint != null
          ? lndGrpcEndpoint.value
          : this.lndGrpcEndpoint),
      lndGrpcCert: (lndGrpcCert != null ? lndGrpcCert.value : this.lndGrpcCert),
      lndGrpcPort: (lndGrpcPort != null ? lndGrpcPort.value : this.lndGrpcPort),
      lndGrpcAdminMacaroon: (lndGrpcAdminMacaroon != null
          ? lndGrpcAdminMacaroon.value
          : this.lndGrpcAdminMacaroon),
      lndGrpcInvoiceMacaroon: (lndGrpcInvoiceMacaroon != null
          ? lndGrpcInvoiceMacaroon.value
          : this.lndGrpcInvoiceMacaroon),
      lndGrpcMacaroon: (lndGrpcMacaroon != null
          ? lndGrpcMacaroon.value
          : this.lndGrpcMacaroon),
      lndGrpcMacaroonEncrypted: (lndGrpcMacaroonEncrypted != null
          ? lndGrpcMacaroonEncrypted.value
          : this.lndGrpcMacaroonEncrypted),
      lndRestEndpoint: (lndRestEndpoint != null
          ? lndRestEndpoint.value
          : this.lndRestEndpoint),
      lndRestCert: (lndRestCert != null ? lndRestCert.value : this.lndRestCert),
      lndRestMacaroon: (lndRestMacaroon != null
          ? lndRestMacaroon.value
          : this.lndRestMacaroon),
      lndRestMacaroonEncrypted: (lndRestMacaroonEncrypted != null
          ? lndRestMacaroonEncrypted.value
          : this.lndRestMacaroonEncrypted),
      lndRestRouteHints: (lndRestRouteHints != null
          ? lndRestRouteHints.value
          : this.lndRestRouteHints),
      lndRestAllowSelfPayment: (lndRestAllowSelfPayment != null
          ? lndRestAllowSelfPayment.value
          : this.lndRestAllowSelfPayment),
      lndCert: (lndCert != null ? lndCert.value : this.lndCert),
      lndAdminMacaroon: (lndAdminMacaroon != null
          ? lndAdminMacaroon.value
          : this.lndAdminMacaroon),
      lndInvoiceMacaroon: (lndInvoiceMacaroon != null
          ? lndInvoiceMacaroon.value
          : this.lndInvoiceMacaroon),
      lndRestAdminMacaroon: (lndRestAdminMacaroon != null
          ? lndRestAdminMacaroon.value
          : this.lndRestAdminMacaroon),
      lndRestInvoiceMacaroon: (lndRestInvoiceMacaroon != null
          ? lndRestInvoiceMacaroon.value
          : this.lndRestInvoiceMacaroon),
      eclairUrl: (eclairUrl != null ? eclairUrl.value : this.eclairUrl),
      eclairPass: (eclairPass != null ? eclairPass.value : this.eclairPass),
      corelightningRestUrl: (corelightningRestUrl != null
          ? corelightningRestUrl.value
          : this.corelightningRestUrl),
      corelightningRestMacaroon: (corelightningRestMacaroon != null
          ? corelightningRestMacaroon.value
          : this.corelightningRestMacaroon),
      corelightningRestCert: (corelightningRestCert != null
          ? corelightningRestCert.value
          : this.corelightningRestCert),
      corelightningRpc: (corelightningRpc != null
          ? corelightningRpc.value
          : this.corelightningRpc),
      corelightningPayCommand: (corelightningPayCommand != null
          ? corelightningPayCommand.value
          : this.corelightningPayCommand),
      clightningRpc: (clightningRpc != null
          ? clightningRpc.value
          : this.clightningRpc),
      clnrestUrl: (clnrestUrl != null ? clnrestUrl.value : this.clnrestUrl),
      clnrestCa: (clnrestCa != null ? clnrestCa.value : this.clnrestCa),
      clnrestCert: (clnrestCert != null ? clnrestCert.value : this.clnrestCert),
      clnrestReadonlyRune: (clnrestReadonlyRune != null
          ? clnrestReadonlyRune.value
          : this.clnrestReadonlyRune),
      clnrestInvoiceRune: (clnrestInvoiceRune != null
          ? clnrestInvoiceRune.value
          : this.clnrestInvoiceRune),
      clnrestPayRune: (clnrestPayRune != null
          ? clnrestPayRune.value
          : this.clnrestPayRune),
      clnrestRenepayRune: (clnrestRenepayRune != null
          ? clnrestRenepayRune.value
          : this.clnrestRenepayRune),
      clnrestLastPayIndex: (clnrestLastPayIndex != null
          ? clnrestLastPayIndex.value
          : this.clnrestLastPayIndex),
      clnrestNodeid: (clnrestNodeid != null
          ? clnrestNodeid.value
          : this.clnrestNodeid),
      clicheEndpoint: (clicheEndpoint != null
          ? clicheEndpoint.value
          : this.clicheEndpoint),
      lnbitsEndpoint: (lnbitsEndpoint != null
          ? lnbitsEndpoint.value
          : this.lnbitsEndpoint),
      lnbitsKey: (lnbitsKey != null ? lnbitsKey.value : this.lnbitsKey),
      lnbitsAdminKey: (lnbitsAdminKey != null
          ? lnbitsAdminKey.value
          : this.lnbitsAdminKey),
      lnbitsInvoiceKey: (lnbitsInvoiceKey != null
          ? lnbitsInvoiceKey.value
          : this.lnbitsInvoiceKey),
      fakeWalletSecret: (fakeWalletSecret != null
          ? fakeWalletSecret.value
          : this.fakeWalletSecret),
      lnbitsDenomination: (lnbitsDenomination != null
          ? lnbitsDenomination.value
          : this.lnbitsDenomination),
      lnbitsBackendWalletClass: (lnbitsBackendWalletClass != null
          ? lnbitsBackendWalletClass.value
          : this.lnbitsBackendWalletClass),
      lnbitsFundingSourcePayInvoiceWaitSeconds:
          (lnbitsFundingSourcePayInvoiceWaitSeconds != null
          ? lnbitsFundingSourcePayInvoiceWaitSeconds.value
          : this.lnbitsFundingSourcePayInvoiceWaitSeconds),
      fundingSourceMaxRetries: (fundingSourceMaxRetries != null
          ? fundingSourceMaxRetries.value
          : this.fundingSourceMaxRetries),
      lnbitsNostrNotificationsEnabled: (lnbitsNostrNotificationsEnabled != null
          ? lnbitsNostrNotificationsEnabled.value
          : this.lnbitsNostrNotificationsEnabled),
      lnbitsNostrNotificationsPrivateKey:
          (lnbitsNostrNotificationsPrivateKey != null
          ? lnbitsNostrNotificationsPrivateKey.value
          : this.lnbitsNostrNotificationsPrivateKey),
      lnbitsNostrNotificationsIdentifiers:
          (lnbitsNostrNotificationsIdentifiers != null
          ? lnbitsNostrNotificationsIdentifiers.value
          : this.lnbitsNostrNotificationsIdentifiers),
      lnbitsTelegramNotificationsEnabled:
          (lnbitsTelegramNotificationsEnabled != null
          ? lnbitsTelegramNotificationsEnabled.value
          : this.lnbitsTelegramNotificationsEnabled),
      lnbitsTelegramNotificationsAccessToken:
          (lnbitsTelegramNotificationsAccessToken != null
          ? lnbitsTelegramNotificationsAccessToken.value
          : this.lnbitsTelegramNotificationsAccessToken),
      lnbitsTelegramNotificationsChatId:
          (lnbitsTelegramNotificationsChatId != null
          ? lnbitsTelegramNotificationsChatId.value
          : this.lnbitsTelegramNotificationsChatId),
      lnbitsEmailNotificationsEnabled: (lnbitsEmailNotificationsEnabled != null
          ? lnbitsEmailNotificationsEnabled.value
          : this.lnbitsEmailNotificationsEnabled),
      lnbitsEmailNotificationsEmail: (lnbitsEmailNotificationsEmail != null
          ? lnbitsEmailNotificationsEmail.value
          : this.lnbitsEmailNotificationsEmail),
      lnbitsEmailNotificationsUsername:
          (lnbitsEmailNotificationsUsername != null
          ? lnbitsEmailNotificationsUsername.value
          : this.lnbitsEmailNotificationsUsername),
      lnbitsEmailNotificationsPassword:
          (lnbitsEmailNotificationsPassword != null
          ? lnbitsEmailNotificationsPassword.value
          : this.lnbitsEmailNotificationsPassword),
      lnbitsEmailNotificationsServer: (lnbitsEmailNotificationsServer != null
          ? lnbitsEmailNotificationsServer.value
          : this.lnbitsEmailNotificationsServer),
      lnbitsEmailNotificationsPort: (lnbitsEmailNotificationsPort != null
          ? lnbitsEmailNotificationsPort.value
          : this.lnbitsEmailNotificationsPort),
      lnbitsEmailNotificationsToEmails:
          (lnbitsEmailNotificationsToEmails != null
          ? lnbitsEmailNotificationsToEmails.value
          : this.lnbitsEmailNotificationsToEmails),
      lnbitsNotificationSettingsUpdate:
          (lnbitsNotificationSettingsUpdate != null
          ? lnbitsNotificationSettingsUpdate.value
          : this.lnbitsNotificationSettingsUpdate),
      lnbitsNotificationCreditDebit: (lnbitsNotificationCreditDebit != null
          ? lnbitsNotificationCreditDebit.value
          : this.lnbitsNotificationCreditDebit),
      notificationBalanceDeltaThresholdSats:
          (notificationBalanceDeltaThresholdSats != null
          ? notificationBalanceDeltaThresholdSats.value
          : this.notificationBalanceDeltaThresholdSats),
      lnbitsNotificationServerStartStop:
          (lnbitsNotificationServerStartStop != null
          ? lnbitsNotificationServerStartStop.value
          : this.lnbitsNotificationServerStartStop),
      lnbitsNotificationWatchdog: (lnbitsNotificationWatchdog != null
          ? lnbitsNotificationWatchdog.value
          : this.lnbitsNotificationWatchdog),
      lnbitsNotificationServerStatusHours:
          (lnbitsNotificationServerStatusHours != null
          ? lnbitsNotificationServerStatusHours.value
          : this.lnbitsNotificationServerStatusHours),
      lnbitsNotificationIncomingPaymentAmountSats:
          (lnbitsNotificationIncomingPaymentAmountSats != null
          ? lnbitsNotificationIncomingPaymentAmountSats.value
          : this.lnbitsNotificationIncomingPaymentAmountSats),
      lnbitsNotificationOutgoingPaymentAmountSats:
          (lnbitsNotificationOutgoingPaymentAmountSats != null
          ? lnbitsNotificationOutgoingPaymentAmountSats.value
          : this.lnbitsNotificationOutgoingPaymentAmountSats),
      lnbitsRateLimitNo: (lnbitsRateLimitNo != null
          ? lnbitsRateLimitNo.value
          : this.lnbitsRateLimitNo),
      lnbitsRateLimitUnit: (lnbitsRateLimitUnit != null
          ? lnbitsRateLimitUnit.value
          : this.lnbitsRateLimitUnit),
      lnbitsAllowedIps: (lnbitsAllowedIps != null
          ? lnbitsAllowedIps.value
          : this.lnbitsAllowedIps),
      lnbitsBlockedIps: (lnbitsBlockedIps != null
          ? lnbitsBlockedIps.value
          : this.lnbitsBlockedIps),
      lnbitsCallbackUrlRules: (lnbitsCallbackUrlRules != null
          ? lnbitsCallbackUrlRules.value
          : this.lnbitsCallbackUrlRules),
      lnbitsWalletLimitMaxBalance: (lnbitsWalletLimitMaxBalance != null
          ? lnbitsWalletLimitMaxBalance.value
          : this.lnbitsWalletLimitMaxBalance),
      lnbitsWalletLimitDailyMaxWithdraw:
          (lnbitsWalletLimitDailyMaxWithdraw != null
          ? lnbitsWalletLimitDailyMaxWithdraw.value
          : this.lnbitsWalletLimitDailyMaxWithdraw),
      lnbitsWalletLimitSecsBetweenTrans:
          (lnbitsWalletLimitSecsBetweenTrans != null
          ? lnbitsWalletLimitSecsBetweenTrans.value
          : this.lnbitsWalletLimitSecsBetweenTrans),
      lnbitsOnlyAllowIncomingPayments: (lnbitsOnlyAllowIncomingPayments != null
          ? lnbitsOnlyAllowIncomingPayments.value
          : this.lnbitsOnlyAllowIncomingPayments),
      lnbitsWatchdogSwitchToVoidwallet:
          (lnbitsWatchdogSwitchToVoidwallet != null
          ? lnbitsWatchdogSwitchToVoidwallet.value
          : this.lnbitsWatchdogSwitchToVoidwallet),
      lnbitsWatchdogIntervalMinutes: (lnbitsWatchdogIntervalMinutes != null
          ? lnbitsWatchdogIntervalMinutes.value
          : this.lnbitsWatchdogIntervalMinutes),
      lnbitsWatchdogDelta: (lnbitsWatchdogDelta != null
          ? lnbitsWatchdogDelta.value
          : this.lnbitsWatchdogDelta),
      lnbitsMaxOutgoingPaymentAmountSats:
          (lnbitsMaxOutgoingPaymentAmountSats != null
          ? lnbitsMaxOutgoingPaymentAmountSats.value
          : this.lnbitsMaxOutgoingPaymentAmountSats),
      lnbitsMaxIncomingPaymentAmountSats:
          (lnbitsMaxIncomingPaymentAmountSats != null
          ? lnbitsMaxIncomingPaymentAmountSats.value
          : this.lnbitsMaxIncomingPaymentAmountSats),
      lnbitsExchangeRateCacheSeconds: (lnbitsExchangeRateCacheSeconds != null
          ? lnbitsExchangeRateCacheSeconds.value
          : this.lnbitsExchangeRateCacheSeconds),
      lnbitsExchangeHistorySize: (lnbitsExchangeHistorySize != null
          ? lnbitsExchangeHistorySize.value
          : this.lnbitsExchangeHistorySize),
      lnbitsExchangeHistoryRefreshIntervalSeconds:
          (lnbitsExchangeHistoryRefreshIntervalSeconds != null
          ? lnbitsExchangeHistoryRefreshIntervalSeconds.value
          : this.lnbitsExchangeHistoryRefreshIntervalSeconds),
      lnbitsExchangeRateProviders: (lnbitsExchangeRateProviders != null
          ? lnbitsExchangeRateProviders.value
          : this.lnbitsExchangeRateProviders),
      lnbitsReserveFeeMin: (lnbitsReserveFeeMin != null
          ? lnbitsReserveFeeMin.value
          : this.lnbitsReserveFeeMin),
      lnbitsReserveFeePercent: (lnbitsReserveFeePercent != null
          ? lnbitsReserveFeePercent.value
          : this.lnbitsReserveFeePercent),
      lnbitsServiceFee: (lnbitsServiceFee != null
          ? lnbitsServiceFee.value
          : this.lnbitsServiceFee),
      lnbitsServiceFeeIgnoreInternal: (lnbitsServiceFeeIgnoreInternal != null
          ? lnbitsServiceFeeIgnoreInternal.value
          : this.lnbitsServiceFeeIgnoreInternal),
      lnbitsServiceFeeMax: (lnbitsServiceFeeMax != null
          ? lnbitsServiceFeeMax.value
          : this.lnbitsServiceFeeMax),
      lnbitsServiceFeeWallet: (lnbitsServiceFeeWallet != null
          ? lnbitsServiceFeeWallet.value
          : this.lnbitsServiceFeeWallet),
      lnbitsMaxAssetSizeMb: (lnbitsMaxAssetSizeMb != null
          ? lnbitsMaxAssetSizeMb.value
          : this.lnbitsMaxAssetSizeMb),
      lnbitsAssetsAllowedMimeTypes: (lnbitsAssetsAllowedMimeTypes != null
          ? lnbitsAssetsAllowedMimeTypes.value
          : this.lnbitsAssetsAllowedMimeTypes),
      lnbitsAssetThumbnailWidth: (lnbitsAssetThumbnailWidth != null
          ? lnbitsAssetThumbnailWidth.value
          : this.lnbitsAssetThumbnailWidth),
      lnbitsAssetThumbnailHeight: (lnbitsAssetThumbnailHeight != null
          ? lnbitsAssetThumbnailHeight.value
          : this.lnbitsAssetThumbnailHeight),
      lnbitsAssetThumbnailFormat: (lnbitsAssetThumbnailFormat != null
          ? lnbitsAssetThumbnailFormat.value
          : this.lnbitsAssetThumbnailFormat),
      lnbitsMaxAssetsPerUser: (lnbitsMaxAssetsPerUser != null
          ? lnbitsMaxAssetsPerUser.value
          : this.lnbitsMaxAssetsPerUser),
      lnbitsAssetsNoLimitUsers: (lnbitsAssetsNoLimitUsers != null
          ? lnbitsAssetsNoLimitUsers.value
          : this.lnbitsAssetsNoLimitUsers),
      lnbitsBaseurl: (lnbitsBaseurl != null
          ? lnbitsBaseurl.value
          : this.lnbitsBaseurl),
      lnbitsHideApi: (lnbitsHideApi != null
          ? lnbitsHideApi.value
          : this.lnbitsHideApi),
      lnbitsSiteTitle: (lnbitsSiteTitle != null
          ? lnbitsSiteTitle.value
          : this.lnbitsSiteTitle),
      lnbitsSiteTagline: (lnbitsSiteTagline != null
          ? lnbitsSiteTagline.value
          : this.lnbitsSiteTagline),
      lnbitsSiteDescription: (lnbitsSiteDescription != null
          ? lnbitsSiteDescription.value
          : this.lnbitsSiteDescription),
      lnbitsShowHomePageElements: (lnbitsShowHomePageElements != null
          ? lnbitsShowHomePageElements.value
          : this.lnbitsShowHomePageElements),
      lnbitsDefaultWalletName: (lnbitsDefaultWalletName != null
          ? lnbitsDefaultWalletName.value
          : this.lnbitsDefaultWalletName),
      lnbitsCustomBadge: (lnbitsCustomBadge != null
          ? lnbitsCustomBadge.value
          : this.lnbitsCustomBadge),
      lnbitsCustomBadgeColor: (lnbitsCustomBadgeColor != null
          ? lnbitsCustomBadgeColor.value
          : this.lnbitsCustomBadgeColor),
      lnbitsThemeOptions: (lnbitsThemeOptions != null
          ? lnbitsThemeOptions.value
          : this.lnbitsThemeOptions),
      lnbitsCustomLogo: (lnbitsCustomLogo != null
          ? lnbitsCustomLogo.value
          : this.lnbitsCustomLogo),
      lnbitsCustomImage: (lnbitsCustomImage != null
          ? lnbitsCustomImage.value
          : this.lnbitsCustomImage),
      lnbitsAdSpaceTitle: (lnbitsAdSpaceTitle != null
          ? lnbitsAdSpaceTitle.value
          : this.lnbitsAdSpaceTitle),
      lnbitsAdSpace: (lnbitsAdSpace != null
          ? lnbitsAdSpace.value
          : this.lnbitsAdSpace),
      lnbitsAdSpaceEnabled: (lnbitsAdSpaceEnabled != null
          ? lnbitsAdSpaceEnabled.value
          : this.lnbitsAdSpaceEnabled),
      lnbitsAllowedCurrencies: (lnbitsAllowedCurrencies != null
          ? lnbitsAllowedCurrencies.value
          : this.lnbitsAllowedCurrencies),
      lnbitsDefaultAccountingCurrency: (lnbitsDefaultAccountingCurrency != null
          ? lnbitsDefaultAccountingCurrency.value
          : this.lnbitsDefaultAccountingCurrency),
      lnbitsQrLogo: (lnbitsQrLogo != null
          ? lnbitsQrLogo.value
          : this.lnbitsQrLogo),
      lnbitsAppleTouchIcon: (lnbitsAppleTouchIcon != null
          ? lnbitsAppleTouchIcon.value
          : this.lnbitsAppleTouchIcon),
      lnbitsDefaultReaction: (lnbitsDefaultReaction != null
          ? lnbitsDefaultReaction.value
          : this.lnbitsDefaultReaction),
      lnbitsDefaultTheme: (lnbitsDefaultTheme != null
          ? lnbitsDefaultTheme.value
          : this.lnbitsDefaultTheme),
      lnbitsDefaultBorder: (lnbitsDefaultBorder != null
          ? lnbitsDefaultBorder.value
          : this.lnbitsDefaultBorder),
      lnbitsDefaultGradient: (lnbitsDefaultGradient != null
          ? lnbitsDefaultGradient.value
          : this.lnbitsDefaultGradient),
      lnbitsDefaultBgimage: (lnbitsDefaultBgimage != null
          ? lnbitsDefaultBgimage.value
          : this.lnbitsDefaultBgimage),
      lnbitsAdminExtensions: (lnbitsAdminExtensions != null
          ? lnbitsAdminExtensions.value
          : this.lnbitsAdminExtensions),
      lnbitsUserDefaultExtensions: (lnbitsUserDefaultExtensions != null
          ? lnbitsUserDefaultExtensions.value
          : this.lnbitsUserDefaultExtensions),
      lnbitsExtensionsDeactivateAll: (lnbitsExtensionsDeactivateAll != null
          ? lnbitsExtensionsDeactivateAll.value
          : this.lnbitsExtensionsDeactivateAll),
      lnbitsExtensionsBuilderActivateNonAdmins:
          (lnbitsExtensionsBuilderActivateNonAdmins != null
          ? lnbitsExtensionsBuilderActivateNonAdmins.value
          : this.lnbitsExtensionsBuilderActivateNonAdmins),
      lnbitsExtensionsReviewsUrl: (lnbitsExtensionsReviewsUrl != null
          ? lnbitsExtensionsReviewsUrl.value
          : this.lnbitsExtensionsReviewsUrl),
      lnbitsExtensionsManifests: (lnbitsExtensionsManifests != null
          ? lnbitsExtensionsManifests.value
          : this.lnbitsExtensionsManifests),
      lnbitsExtensionsBuilderManifestUrl:
          (lnbitsExtensionsBuilderManifestUrl != null
          ? lnbitsExtensionsBuilderManifestUrl.value
          : this.lnbitsExtensionsBuilderManifestUrl),
      lnbitsAdminUsers: (lnbitsAdminUsers != null
          ? lnbitsAdminUsers.value
          : this.lnbitsAdminUsers),
      lnbitsAllowedUsers: (lnbitsAllowedUsers != null
          ? lnbitsAllowedUsers.value
          : this.lnbitsAllowedUsers),
      lnbitsAllowNewAccounts: (lnbitsAllowNewAccounts != null
          ? lnbitsAllowNewAccounts.value
          : this.lnbitsAllowNewAccounts),
      isSuperUser: (isSuperUser != null ? isSuperUser.value : this.isSuperUser),
      lnbitsAllowedFundingSources: (lnbitsAllowedFundingSources != null
          ? lnbitsAllowedFundingSources.value
          : this.lnbitsAllowedFundingSources),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ApiTokenRequest {
  const ApiTokenRequest({
    required this.aclId,
    required this.tokenName,
    required this.password,
    required this.expirationTimeMinutes,
  });

  factory ApiTokenRequest.fromJson(Map<String, dynamic> json) =>
      _$ApiTokenRequestFromJson(json);

  static const toJsonFactory = _$ApiTokenRequestToJson;
  Map<String, dynamic> toJson() => _$ApiTokenRequestToJson(this);

  @JsonKey(name: 'acl_id', includeIfNull: false)
  final String aclId;
  @JsonKey(name: 'token_name', includeIfNull: false)
  final String tokenName;
  @JsonKey(name: 'password', includeIfNull: false)
  final String password;
  @JsonKey(name: 'expiration_time_minutes', includeIfNull: false)
  final int expirationTimeMinutes;
  static const fromJsonFactory = _$ApiTokenRequestFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ApiTokenRequest &&
            (identical(other.aclId, aclId) ||
                const DeepCollectionEquality().equals(other.aclId, aclId)) &&
            (identical(other.tokenName, tokenName) ||
                const DeepCollectionEquality().equals(
                  other.tokenName,
                  tokenName,
                )) &&
            (identical(other.password, password) ||
                const DeepCollectionEquality().equals(
                  other.password,
                  password,
                )) &&
            (identical(other.expirationTimeMinutes, expirationTimeMinutes) ||
                const DeepCollectionEquality().equals(
                  other.expirationTimeMinutes,
                  expirationTimeMinutes,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(aclId) ^
      const DeepCollectionEquality().hash(tokenName) ^
      const DeepCollectionEquality().hash(password) ^
      const DeepCollectionEquality().hash(expirationTimeMinutes) ^
      runtimeType.hashCode;
}

extension $ApiTokenRequestExtension on ApiTokenRequest {
  ApiTokenRequest copyWith({
    String? aclId,
    String? tokenName,
    String? password,
    int? expirationTimeMinutes,
  }) {
    return ApiTokenRequest(
      aclId: aclId ?? this.aclId,
      tokenName: tokenName ?? this.tokenName,
      password: password ?? this.password,
      expirationTimeMinutes:
          expirationTimeMinutes ?? this.expirationTimeMinutes,
    );
  }

  ApiTokenRequest copyWithWrapped({
    Wrapped<String>? aclId,
    Wrapped<String>? tokenName,
    Wrapped<String>? password,
    Wrapped<int>? expirationTimeMinutes,
  }) {
    return ApiTokenRequest(
      aclId: (aclId != null ? aclId.value : this.aclId),
      tokenName: (tokenName != null ? tokenName.value : this.tokenName),
      password: (password != null ? password.value : this.password),
      expirationTimeMinutes: (expirationTimeMinutes != null
          ? expirationTimeMinutes.value
          : this.expirationTimeMinutes),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ApiTokenResponse {
  const ApiTokenResponse({required this.id, required this.apiToken});

  factory ApiTokenResponse.fromJson(Map<String, dynamic> json) =>
      _$ApiTokenResponseFromJson(json);

  static const toJsonFactory = _$ApiTokenResponseToJson;
  Map<String, dynamic> toJson() => _$ApiTokenResponseToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'api_token', includeIfNull: false)
  final String apiToken;
  static const fromJsonFactory = _$ApiTokenResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ApiTokenResponse &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.apiToken, apiToken) ||
                const DeepCollectionEquality().equals(
                  other.apiToken,
                  apiToken,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(apiToken) ^
      runtimeType.hashCode;
}

extension $ApiTokenResponseExtension on ApiTokenResponse {
  ApiTokenResponse copyWith({String? id, String? apiToken}) {
    return ApiTokenResponse(
      id: id ?? this.id,
      apiToken: apiToken ?? this.apiToken,
    );
  }

  ApiTokenResponse copyWithWrapped({
    Wrapped<String>? id,
    Wrapped<String>? apiToken,
  }) {
    return ApiTokenResponse(
      id: (id != null ? id.value : this.id),
      apiToken: (apiToken != null ? apiToken.value : this.apiToken),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class AssetInfo {
  const AssetInfo({
    required this.id,
    required this.mimeType,
    required this.name,
    this.isPublic,
    required this.sizeBytes,
    this.thumbnailBase64,
    this.createdAt,
  });

  factory AssetInfo.fromJson(Map<String, dynamic> json) =>
      _$AssetInfoFromJson(json);

  static const toJsonFactory = _$AssetInfoToJson;
  Map<String, dynamic> toJson() => _$AssetInfoToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'mime_type', includeIfNull: false)
  final String mimeType;
  @JsonKey(name: 'name', includeIfNull: false)
  final String name;
  @JsonKey(name: 'is_public', includeIfNull: false, defaultValue: false)
  final bool? isPublic;
  @JsonKey(name: 'size_bytes', includeIfNull: false)
  final int sizeBytes;
  @JsonKey(name: 'thumbnail_base64', includeIfNull: false)
  final String? thumbnailBase64;
  @JsonKey(name: 'created_at', includeIfNull: false)
  final DateTime? createdAt;
  static const fromJsonFactory = _$AssetInfoFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AssetInfo &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.mimeType, mimeType) ||
                const DeepCollectionEquality().equals(
                  other.mimeType,
                  mimeType,
                )) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.isPublic, isPublic) ||
                const DeepCollectionEquality().equals(
                  other.isPublic,
                  isPublic,
                )) &&
            (identical(other.sizeBytes, sizeBytes) ||
                const DeepCollectionEquality().equals(
                  other.sizeBytes,
                  sizeBytes,
                )) &&
            (identical(other.thumbnailBase64, thumbnailBase64) ||
                const DeepCollectionEquality().equals(
                  other.thumbnailBase64,
                  thumbnailBase64,
                )) &&
            (identical(other.createdAt, createdAt) ||
                const DeepCollectionEquality().equals(
                  other.createdAt,
                  createdAt,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(mimeType) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(isPublic) ^
      const DeepCollectionEquality().hash(sizeBytes) ^
      const DeepCollectionEquality().hash(thumbnailBase64) ^
      const DeepCollectionEquality().hash(createdAt) ^
      runtimeType.hashCode;
}

extension $AssetInfoExtension on AssetInfo {
  AssetInfo copyWith({
    String? id,
    String? mimeType,
    String? name,
    bool? isPublic,
    int? sizeBytes,
    String? thumbnailBase64,
    DateTime? createdAt,
  }) {
    return AssetInfo(
      id: id ?? this.id,
      mimeType: mimeType ?? this.mimeType,
      name: name ?? this.name,
      isPublic: isPublic ?? this.isPublic,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      thumbnailBase64: thumbnailBase64 ?? this.thumbnailBase64,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  AssetInfo copyWithWrapped({
    Wrapped<String>? id,
    Wrapped<String>? mimeType,
    Wrapped<String>? name,
    Wrapped<bool?>? isPublic,
    Wrapped<int>? sizeBytes,
    Wrapped<String?>? thumbnailBase64,
    Wrapped<DateTime?>? createdAt,
  }) {
    return AssetInfo(
      id: (id != null ? id.value : this.id),
      mimeType: (mimeType != null ? mimeType.value : this.mimeType),
      name: (name != null ? name.value : this.name),
      isPublic: (isPublic != null ? isPublic.value : this.isPublic),
      sizeBytes: (sizeBytes != null ? sizeBytes.value : this.sizeBytes),
      thumbnailBase64: (thumbnailBase64 != null
          ? thumbnailBase64.value
          : this.thumbnailBase64),
      createdAt: (createdAt != null ? createdAt.value : this.createdAt),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class AssetUpdate {
  const AssetUpdate({this.name, this.isPublic});

  factory AssetUpdate.fromJson(Map<String, dynamic> json) =>
      _$AssetUpdateFromJson(json);

  static const toJsonFactory = _$AssetUpdateToJson;
  Map<String, dynamic> toJson() => _$AssetUpdateToJson(this);

  @JsonKey(name: 'name', includeIfNull: false)
  final String? name;
  @JsonKey(name: 'is_public', includeIfNull: false)
  final bool? isPublic;
  static const fromJsonFactory = _$AssetUpdateFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AssetUpdate &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.isPublic, isPublic) ||
                const DeepCollectionEquality().equals(
                  other.isPublic,
                  isPublic,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(isPublic) ^
      runtimeType.hashCode;
}

extension $AssetUpdateExtension on AssetUpdate {
  AssetUpdate copyWith({String? name, bool? isPublic}) {
    return AssetUpdate(
      name: name ?? this.name,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  AssetUpdate copyWithWrapped({
    Wrapped<String?>? name,
    Wrapped<bool?>? isPublic,
  }) {
    return AssetUpdate(
      name: (name != null ? name.value : this.name),
      isPublic: (isPublic != null ? isPublic.value : this.isPublic),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class AuditCountStat {
  const AuditCountStat({this.field, this.total});

  factory AuditCountStat.fromJson(Map<String, dynamic> json) =>
      _$AuditCountStatFromJson(json);

  static const toJsonFactory = _$AuditCountStatToJson;
  Map<String, dynamic> toJson() => _$AuditCountStatToJson(this);

  @JsonKey(name: 'field', includeIfNull: false)
  final String? field;
  @JsonKey(name: 'total', includeIfNull: false)
  final double? total;
  static const fromJsonFactory = _$AuditCountStatFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AuditCountStat &&
            (identical(other.field, field) ||
                const DeepCollectionEquality().equals(other.field, field)) &&
            (identical(other.total, total) ||
                const DeepCollectionEquality().equals(other.total, total)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(field) ^
      const DeepCollectionEquality().hash(total) ^
      runtimeType.hashCode;
}

extension $AuditCountStatExtension on AuditCountStat {
  AuditCountStat copyWith({String? field, double? total}) {
    return AuditCountStat(
      field: field ?? this.field,
      total: total ?? this.total,
    );
  }

  AuditCountStat copyWithWrapped({
    Wrapped<String?>? field,
    Wrapped<double?>? total,
  }) {
    return AuditCountStat(
      field: (field != null ? field.value : this.field),
      total: (total != null ? total.value : this.total),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class AuditStats {
  const AuditStats({
    this.requestMethod,
    this.responseCode,
    this.component,
    this.longDuration,
  });

  factory AuditStats.fromJson(Map<String, dynamic> json) =>
      _$AuditStatsFromJson(json);

  static const toJsonFactory = _$AuditStatsToJson;
  Map<String, dynamic> toJson() => _$AuditStatsToJson(this);

  @JsonKey(
    name: 'request_method',
    includeIfNull: false,
    defaultValue: <AuditCountStat>[],
  )
  final List<AuditCountStat>? requestMethod;
  @JsonKey(
    name: 'response_code',
    includeIfNull: false,
    defaultValue: <AuditCountStat>[],
  )
  final List<AuditCountStat>? responseCode;
  @JsonKey(
    name: 'component',
    includeIfNull: false,
    defaultValue: <AuditCountStat>[],
  )
  final List<AuditCountStat>? component;
  @JsonKey(
    name: 'long_duration',
    includeIfNull: false,
    defaultValue: <AuditCountStat>[],
  )
  final List<AuditCountStat>? longDuration;
  static const fromJsonFactory = _$AuditStatsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AuditStats &&
            (identical(other.requestMethod, requestMethod) ||
                const DeepCollectionEquality().equals(
                  other.requestMethod,
                  requestMethod,
                )) &&
            (identical(other.responseCode, responseCode) ||
                const DeepCollectionEquality().equals(
                  other.responseCode,
                  responseCode,
                )) &&
            (identical(other.component, component) ||
                const DeepCollectionEquality().equals(
                  other.component,
                  component,
                )) &&
            (identical(other.longDuration, longDuration) ||
                const DeepCollectionEquality().equals(
                  other.longDuration,
                  longDuration,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(requestMethod) ^
      const DeepCollectionEquality().hash(responseCode) ^
      const DeepCollectionEquality().hash(component) ^
      const DeepCollectionEquality().hash(longDuration) ^
      runtimeType.hashCode;
}

extension $AuditStatsExtension on AuditStats {
  AuditStats copyWith({
    List<AuditCountStat>? requestMethod,
    List<AuditCountStat>? responseCode,
    List<AuditCountStat>? component,
    List<AuditCountStat>? longDuration,
  }) {
    return AuditStats(
      requestMethod: requestMethod ?? this.requestMethod,
      responseCode: responseCode ?? this.responseCode,
      component: component ?? this.component,
      longDuration: longDuration ?? this.longDuration,
    );
  }

  AuditStats copyWithWrapped({
    Wrapped<List<AuditCountStat>?>? requestMethod,
    Wrapped<List<AuditCountStat>?>? responseCode,
    Wrapped<List<AuditCountStat>?>? component,
    Wrapped<List<AuditCountStat>?>? longDuration,
  }) {
    return AuditStats(
      requestMethod: (requestMethod != null
          ? requestMethod.value
          : this.requestMethod),
      responseCode: (responseCode != null
          ? responseCode.value
          : this.responseCode),
      component: (component != null ? component.value : this.component),
      longDuration: (longDuration != null
          ? longDuration.value
          : this.longDuration),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class BodyCreateANewWalletForUserUsersApiV1UserUserIdWalletPost {
  const BodyCreateANewWalletForUserUsersApiV1UserUserIdWalletPost({
    this.name,
    this.currency,
  });

  factory BodyCreateANewWalletForUserUsersApiV1UserUserIdWalletPost.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$BodyCreateANewWalletForUserUsersApiV1UserUserIdWalletPostFromJson(json);

  static const toJsonFactory =
      _$BodyCreateANewWalletForUserUsersApiV1UserUserIdWalletPostToJson;
  Map<String, dynamic> toJson() =>
      _$BodyCreateANewWalletForUserUsersApiV1UserUserIdWalletPostToJson(this);

  @JsonKey(name: 'name', includeIfNull: false)
  final String? name;
  @JsonKey(name: 'currency', includeIfNull: false)
  final String? currency;
  static const fromJsonFactory =
      _$BodyCreateANewWalletForUserUsersApiV1UserUserIdWalletPostFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is BodyCreateANewWalletForUserUsersApiV1UserUserIdWalletPost &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.currency, currency) ||
                const DeepCollectionEquality().equals(
                  other.currency,
                  currency,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(currency) ^
      runtimeType.hashCode;
}

extension $BodyCreateANewWalletForUserUsersApiV1UserUserIdWalletPostExtension
    on BodyCreateANewWalletForUserUsersApiV1UserUserIdWalletPost {
  BodyCreateANewWalletForUserUsersApiV1UserUserIdWalletPost copyWith({
    String? name,
    String? currency,
  }) {
    return BodyCreateANewWalletForUserUsersApiV1UserUserIdWalletPost(
      name: name ?? this.name,
      currency: currency ?? this.currency,
    );
  }

  BodyCreateANewWalletForUserUsersApiV1UserUserIdWalletPost copyWithWrapped({
    Wrapped<String?>? name,
    Wrapped<String?>? currency,
  }) {
    return BodyCreateANewWalletForUserUsersApiV1UserUserIdWalletPost(
      name: (name != null ? name.value : this.name),
      currency: (currency != null ? currency.value : this.currency),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class BodyUploadApiV1AssetsPost {
  const BodyUploadApiV1AssetsPost({required this.file});

  factory BodyUploadApiV1AssetsPost.fromJson(Map<String, dynamic> json) =>
      _$BodyUploadApiV1AssetsPostFromJson(json);

  static const toJsonFactory = _$BodyUploadApiV1AssetsPostToJson;
  Map<String, dynamic> toJson() => _$BodyUploadApiV1AssetsPostToJson(this);

  @JsonKey(name: 'file', includeIfNull: false)
  final String file;
  static const fromJsonFactory = _$BodyUploadApiV1AssetsPostFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is BodyUploadApiV1AssetsPost &&
            (identical(other.file, file) ||
                const DeepCollectionEquality().equals(other.file, file)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(file) ^ runtimeType.hashCode;
}

extension $BodyUploadApiV1AssetsPostExtension on BodyUploadApiV1AssetsPost {
  BodyUploadApiV1AssetsPost copyWith({String? file}) {
    return BodyUploadApiV1AssetsPost(file: file ?? this.file);
  }

  BodyUploadApiV1AssetsPost copyWithWrapped({Wrapped<String>? file}) {
    return BodyUploadApiV1AssetsPost(
      file: (file != null ? file.value : this.file),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class BodyApiConnectPeerNodeApiV1PeersPost {
  const BodyApiConnectPeerNodeApiV1PeersPost({required this.uri});

  factory BodyApiConnectPeerNodeApiV1PeersPost.fromJson(
    Map<String, dynamic> json,
  ) => _$BodyApiConnectPeerNodeApiV1PeersPostFromJson(json);

  static const toJsonFactory = _$BodyApiConnectPeerNodeApiV1PeersPostToJson;
  Map<String, dynamic> toJson() =>
      _$BodyApiConnectPeerNodeApiV1PeersPostToJson(this);

  @JsonKey(name: 'uri', includeIfNull: false)
  final String uri;
  static const fromJsonFactory = _$BodyApiConnectPeerNodeApiV1PeersPostFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is BodyApiConnectPeerNodeApiV1PeersPost &&
            (identical(other.uri, uri) ||
                const DeepCollectionEquality().equals(other.uri, uri)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(uri) ^ runtimeType.hashCode;
}

extension $BodyApiConnectPeerNodeApiV1PeersPostExtension
    on BodyApiConnectPeerNodeApiV1PeersPost {
  BodyApiConnectPeerNodeApiV1PeersPost copyWith({String? uri}) {
    return BodyApiConnectPeerNodeApiV1PeersPost(uri: uri ?? this.uri);
  }

  BodyApiConnectPeerNodeApiV1PeersPost copyWithWrapped({Wrapped<String>? uri}) {
    return BodyApiConnectPeerNodeApiV1PeersPost(
      uri: (uri != null ? uri.value : this.uri),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class BodyApiCreateChannelNodeApiV1ChannelsPost {
  const BodyApiCreateChannelNodeApiV1ChannelsPost({
    required this.peerId,
    required this.fundingAmount,
    this.pushAmount,
    this.feeRate,
  });

  factory BodyApiCreateChannelNodeApiV1ChannelsPost.fromJson(
    Map<String, dynamic> json,
  ) => _$BodyApiCreateChannelNodeApiV1ChannelsPostFromJson(json);

  static const toJsonFactory =
      _$BodyApiCreateChannelNodeApiV1ChannelsPostToJson;
  Map<String, dynamic> toJson() =>
      _$BodyApiCreateChannelNodeApiV1ChannelsPostToJson(this);

  @JsonKey(name: 'peer_id', includeIfNull: false)
  final String peerId;
  @JsonKey(name: 'funding_amount', includeIfNull: false)
  final int fundingAmount;
  @JsonKey(name: 'push_amount', includeIfNull: false)
  final int? pushAmount;
  @JsonKey(name: 'fee_rate', includeIfNull: false)
  final int? feeRate;
  static const fromJsonFactory =
      _$BodyApiCreateChannelNodeApiV1ChannelsPostFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is BodyApiCreateChannelNodeApiV1ChannelsPost &&
            (identical(other.peerId, peerId) ||
                const DeepCollectionEquality().equals(other.peerId, peerId)) &&
            (identical(other.fundingAmount, fundingAmount) ||
                const DeepCollectionEquality().equals(
                  other.fundingAmount,
                  fundingAmount,
                )) &&
            (identical(other.pushAmount, pushAmount) ||
                const DeepCollectionEquality().equals(
                  other.pushAmount,
                  pushAmount,
                )) &&
            (identical(other.feeRate, feeRate) ||
                const DeepCollectionEquality().equals(other.feeRate, feeRate)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(peerId) ^
      const DeepCollectionEquality().hash(fundingAmount) ^
      const DeepCollectionEquality().hash(pushAmount) ^
      const DeepCollectionEquality().hash(feeRate) ^
      runtimeType.hashCode;
}

extension $BodyApiCreateChannelNodeApiV1ChannelsPostExtension
    on BodyApiCreateChannelNodeApiV1ChannelsPost {
  BodyApiCreateChannelNodeApiV1ChannelsPost copyWith({
    String? peerId,
    int? fundingAmount,
    int? pushAmount,
    int? feeRate,
  }) {
    return BodyApiCreateChannelNodeApiV1ChannelsPost(
      peerId: peerId ?? this.peerId,
      fundingAmount: fundingAmount ?? this.fundingAmount,
      pushAmount: pushAmount ?? this.pushAmount,
      feeRate: feeRate ?? this.feeRate,
    );
  }

  BodyApiCreateChannelNodeApiV1ChannelsPost copyWithWrapped({
    Wrapped<String>? peerId,
    Wrapped<int>? fundingAmount,
    Wrapped<int?>? pushAmount,
    Wrapped<int?>? feeRate,
  }) {
    return BodyApiCreateChannelNodeApiV1ChannelsPost(
      peerId: (peerId != null ? peerId.value : this.peerId),
      fundingAmount: (fundingAmount != null
          ? fundingAmount.value
          : this.fundingAmount),
      pushAmount: (pushAmount != null ? pushAmount.value : this.pushAmount),
      feeRate: (feeRate != null ? feeRate.value : this.feeRate),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class BodyApiSetChannelFeesNodeApiV1ChannelsChannelIdPut {
  const BodyApiSetChannelFeesNodeApiV1ChannelsChannelIdPut({
    this.feePpm,
    this.feeBaseMsat,
  });

  factory BodyApiSetChannelFeesNodeApiV1ChannelsChannelIdPut.fromJson(
    Map<String, dynamic> json,
  ) => _$BodyApiSetChannelFeesNodeApiV1ChannelsChannelIdPutFromJson(json);

  static const toJsonFactory =
      _$BodyApiSetChannelFeesNodeApiV1ChannelsChannelIdPutToJson;
  Map<String, dynamic> toJson() =>
      _$BodyApiSetChannelFeesNodeApiV1ChannelsChannelIdPutToJson(this);

  @JsonKey(name: 'fee_ppm', includeIfNull: false)
  final int? feePpm;
  @JsonKey(name: 'fee_base_msat', includeIfNull: false)
  final int? feeBaseMsat;
  static const fromJsonFactory =
      _$BodyApiSetChannelFeesNodeApiV1ChannelsChannelIdPutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is BodyApiSetChannelFeesNodeApiV1ChannelsChannelIdPut &&
            (identical(other.feePpm, feePpm) ||
                const DeepCollectionEquality().equals(other.feePpm, feePpm)) &&
            (identical(other.feeBaseMsat, feeBaseMsat) ||
                const DeepCollectionEquality().equals(
                  other.feeBaseMsat,
                  feeBaseMsat,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(feePpm) ^
      const DeepCollectionEquality().hash(feeBaseMsat) ^
      runtimeType.hashCode;
}

extension $BodyApiSetChannelFeesNodeApiV1ChannelsChannelIdPutExtension
    on BodyApiSetChannelFeesNodeApiV1ChannelsChannelIdPut {
  BodyApiSetChannelFeesNodeApiV1ChannelsChannelIdPut copyWith({
    int? feePpm,
    int? feeBaseMsat,
  }) {
    return BodyApiSetChannelFeesNodeApiV1ChannelsChannelIdPut(
      feePpm: feePpm ?? this.feePpm,
      feeBaseMsat: feeBaseMsat ?? this.feeBaseMsat,
    );
  }

  BodyApiSetChannelFeesNodeApiV1ChannelsChannelIdPut copyWithWrapped({
    Wrapped<int?>? feePpm,
    Wrapped<int?>? feeBaseMsat,
  }) {
    return BodyApiSetChannelFeesNodeApiV1ChannelsChannelIdPut(
      feePpm: (feePpm != null ? feePpm.value : this.feePpm),
      feeBaseMsat: (feeBaseMsat != null ? feeBaseMsat.value : this.feeBaseMsat),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class BodyApiUpdateWalletApiV1WalletPatch {
  const BodyApiUpdateWalletApiV1WalletPatch({
    this.name,
    this.icon,
    this.color,
    this.currency,
    this.pinned,
  });

  factory BodyApiUpdateWalletApiV1WalletPatch.fromJson(
    Map<String, dynamic> json,
  ) => _$BodyApiUpdateWalletApiV1WalletPatchFromJson(json);

  static const toJsonFactory = _$BodyApiUpdateWalletApiV1WalletPatchToJson;
  Map<String, dynamic> toJson() =>
      _$BodyApiUpdateWalletApiV1WalletPatchToJson(this);

  @JsonKey(name: 'name', includeIfNull: false)
  final String? name;
  @JsonKey(name: 'icon', includeIfNull: false)
  final String? icon;
  @JsonKey(name: 'color', includeIfNull: false)
  final String? color;
  @JsonKey(name: 'currency', includeIfNull: false)
  final String? currency;
  @JsonKey(name: 'pinned', includeIfNull: false)
  final bool? pinned;
  static const fromJsonFactory = _$BodyApiUpdateWalletApiV1WalletPatchFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is BodyApiUpdateWalletApiV1WalletPatch &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.icon, icon) ||
                const DeepCollectionEquality().equals(other.icon, icon)) &&
            (identical(other.color, color) ||
                const DeepCollectionEquality().equals(other.color, color)) &&
            (identical(other.currency, currency) ||
                const DeepCollectionEquality().equals(
                  other.currency,
                  currency,
                )) &&
            (identical(other.pinned, pinned) ||
                const DeepCollectionEquality().equals(other.pinned, pinned)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(icon) ^
      const DeepCollectionEquality().hash(color) ^
      const DeepCollectionEquality().hash(currency) ^
      const DeepCollectionEquality().hash(pinned) ^
      runtimeType.hashCode;
}

extension $BodyApiUpdateWalletApiV1WalletPatchExtension
    on BodyApiUpdateWalletApiV1WalletPatch {
  BodyApiUpdateWalletApiV1WalletPatch copyWith({
    String? name,
    String? icon,
    String? color,
    String? currency,
    bool? pinned,
  }) {
    return BodyApiUpdateWalletApiV1WalletPatch(
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      currency: currency ?? this.currency,
      pinned: pinned ?? this.pinned,
    );
  }

  BodyApiUpdateWalletApiV1WalletPatch copyWithWrapped({
    Wrapped<String?>? name,
    Wrapped<String?>? icon,
    Wrapped<String?>? color,
    Wrapped<String?>? currency,
    Wrapped<bool?>? pinned,
  }) {
    return BodyApiUpdateWalletApiV1WalletPatch(
      name: (name != null ? name.value : this.name),
      icon: (icon != null ? icon.value : this.icon),
      color: (color != null ? color.value : this.color),
      currency: (currency != null ? currency.value : this.currency),
      pinned: (pinned != null ? pinned.value : this.pinned),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class CancelInvoice {
  const CancelInvoice({required this.paymentHash});

  factory CancelInvoice.fromJson(Map<String, dynamic> json) =>
      _$CancelInvoiceFromJson(json);

  static const toJsonFactory = _$CancelInvoiceToJson;
  Map<String, dynamic> toJson() => _$CancelInvoiceToJson(this);

  @JsonKey(name: 'payment_hash', includeIfNull: false)
  final String paymentHash;
  static const fromJsonFactory = _$CancelInvoiceFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CancelInvoice &&
            (identical(other.paymentHash, paymentHash) ||
                const DeepCollectionEquality().equals(
                  other.paymentHash,
                  paymentHash,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(paymentHash) ^ runtimeType.hashCode;
}

extension $CancelInvoiceExtension on CancelInvoice {
  CancelInvoice copyWith({String? paymentHash}) {
    return CancelInvoice(paymentHash: paymentHash ?? this.paymentHash);
  }

  CancelInvoice copyWithWrapped({Wrapped<String>? paymentHash}) {
    return CancelInvoice(
      paymentHash: (paymentHash != null ? paymentHash.value : this.paymentHash),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ChannelBalance {
  const ChannelBalance({
    required this.localMsat,
    required this.remoteMsat,
    required this.totalMsat,
  });

  factory ChannelBalance.fromJson(Map<String, dynamic> json) =>
      _$ChannelBalanceFromJson(json);

  static const toJsonFactory = _$ChannelBalanceToJson;
  Map<String, dynamic> toJson() => _$ChannelBalanceToJson(this);

  @JsonKey(name: 'local_msat', includeIfNull: false)
  final int localMsat;
  @JsonKey(name: 'remote_msat', includeIfNull: false)
  final int remoteMsat;
  @JsonKey(name: 'total_msat', includeIfNull: false)
  final int totalMsat;
  static const fromJsonFactory = _$ChannelBalanceFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChannelBalance &&
            (identical(other.localMsat, localMsat) ||
                const DeepCollectionEquality().equals(
                  other.localMsat,
                  localMsat,
                )) &&
            (identical(other.remoteMsat, remoteMsat) ||
                const DeepCollectionEquality().equals(
                  other.remoteMsat,
                  remoteMsat,
                )) &&
            (identical(other.totalMsat, totalMsat) ||
                const DeepCollectionEquality().equals(
                  other.totalMsat,
                  totalMsat,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(localMsat) ^
      const DeepCollectionEquality().hash(remoteMsat) ^
      const DeepCollectionEquality().hash(totalMsat) ^
      runtimeType.hashCode;
}

extension $ChannelBalanceExtension on ChannelBalance {
  ChannelBalance copyWith({int? localMsat, int? remoteMsat, int? totalMsat}) {
    return ChannelBalance(
      localMsat: localMsat ?? this.localMsat,
      remoteMsat: remoteMsat ?? this.remoteMsat,
      totalMsat: totalMsat ?? this.totalMsat,
    );
  }

  ChannelBalance copyWithWrapped({
    Wrapped<int>? localMsat,
    Wrapped<int>? remoteMsat,
    Wrapped<int>? totalMsat,
  }) {
    return ChannelBalance(
      localMsat: (localMsat != null ? localMsat.value : this.localMsat),
      remoteMsat: (remoteMsat != null ? remoteMsat.value : this.remoteMsat),
      totalMsat: (totalMsat != null ? totalMsat.value : this.totalMsat),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ChannelPoint {
  const ChannelPoint({required this.fundingTxid, required this.outputIndex});

  factory ChannelPoint.fromJson(Map<String, dynamic> json) =>
      _$ChannelPointFromJson(json);

  static const toJsonFactory = _$ChannelPointToJson;
  Map<String, dynamic> toJson() => _$ChannelPointToJson(this);

  @JsonKey(name: 'funding_txid', includeIfNull: false)
  final String fundingTxid;
  @JsonKey(name: 'output_index', includeIfNull: false)
  final int outputIndex;
  static const fromJsonFactory = _$ChannelPointFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChannelPoint &&
            (identical(other.fundingTxid, fundingTxid) ||
                const DeepCollectionEquality().equals(
                  other.fundingTxid,
                  fundingTxid,
                )) &&
            (identical(other.outputIndex, outputIndex) ||
                const DeepCollectionEquality().equals(
                  other.outputIndex,
                  outputIndex,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(fundingTxid) ^
      const DeepCollectionEquality().hash(outputIndex) ^
      runtimeType.hashCode;
}

extension $ChannelPointExtension on ChannelPoint {
  ChannelPoint copyWith({String? fundingTxid, int? outputIndex}) {
    return ChannelPoint(
      fundingTxid: fundingTxid ?? this.fundingTxid,
      outputIndex: outputIndex ?? this.outputIndex,
    );
  }

  ChannelPoint copyWithWrapped({
    Wrapped<String>? fundingTxid,
    Wrapped<int>? outputIndex,
  }) {
    return ChannelPoint(
      fundingTxid: (fundingTxid != null ? fundingTxid.value : this.fundingTxid),
      outputIndex: (outputIndex != null ? outputIndex.value : this.outputIndex),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ChannelStats {
  const ChannelStats({
    required this.counts,
    required this.avgSize,
    this.biggestSize,
    this.smallestSize,
    required this.totalCapacity,
  });

  factory ChannelStats.fromJson(Map<String, dynamic> json) =>
      _$ChannelStatsFromJson(json);

  static const toJsonFactory = _$ChannelStatsToJson;
  Map<String, dynamic> toJson() => _$ChannelStatsToJson(this);

  @JsonKey(name: 'counts', includeIfNull: false)
  final Map<String, dynamic> counts;
  @JsonKey(name: 'avg_size', includeIfNull: false)
  final int avgSize;
  @JsonKey(name: 'biggest_size', includeIfNull: false)
  final int? biggestSize;
  @JsonKey(name: 'smallest_size', includeIfNull: false)
  final int? smallestSize;
  @JsonKey(name: 'total_capacity', includeIfNull: false)
  final int totalCapacity;
  static const fromJsonFactory = _$ChannelStatsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChannelStats &&
            (identical(other.counts, counts) ||
                const DeepCollectionEquality().equals(other.counts, counts)) &&
            (identical(other.avgSize, avgSize) ||
                const DeepCollectionEquality().equals(
                  other.avgSize,
                  avgSize,
                )) &&
            (identical(other.biggestSize, biggestSize) ||
                const DeepCollectionEquality().equals(
                  other.biggestSize,
                  biggestSize,
                )) &&
            (identical(other.smallestSize, smallestSize) ||
                const DeepCollectionEquality().equals(
                  other.smallestSize,
                  smallestSize,
                )) &&
            (identical(other.totalCapacity, totalCapacity) ||
                const DeepCollectionEquality().equals(
                  other.totalCapacity,
                  totalCapacity,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(counts) ^
      const DeepCollectionEquality().hash(avgSize) ^
      const DeepCollectionEquality().hash(biggestSize) ^
      const DeepCollectionEquality().hash(smallestSize) ^
      const DeepCollectionEquality().hash(totalCapacity) ^
      runtimeType.hashCode;
}

extension $ChannelStatsExtension on ChannelStats {
  ChannelStats copyWith({
    Map<String, dynamic>? counts,
    int? avgSize,
    int? biggestSize,
    int? smallestSize,
    int? totalCapacity,
  }) {
    return ChannelStats(
      counts: counts ?? this.counts,
      avgSize: avgSize ?? this.avgSize,
      biggestSize: biggestSize ?? this.biggestSize,
      smallestSize: smallestSize ?? this.smallestSize,
      totalCapacity: totalCapacity ?? this.totalCapacity,
    );
  }

  ChannelStats copyWithWrapped({
    Wrapped<Map<String, dynamic>>? counts,
    Wrapped<int>? avgSize,
    Wrapped<int?>? biggestSize,
    Wrapped<int?>? smallestSize,
    Wrapped<int>? totalCapacity,
  }) {
    return ChannelStats(
      counts: (counts != null ? counts.value : this.counts),
      avgSize: (avgSize != null ? avgSize.value : this.avgSize),
      biggestSize: (biggestSize != null ? biggestSize.value : this.biggestSize),
      smallestSize: (smallestSize != null
          ? smallestSize.value
          : this.smallestSize),
      totalCapacity: (totalCapacity != null
          ? totalCapacity.value
          : this.totalCapacity),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ClientDataFields {
  const ClientDataFields({this.publicInputs});

  factory ClientDataFields.fromJson(Map<String, dynamic> json) =>
      _$ClientDataFieldsFromJson(json);

  static const toJsonFactory = _$ClientDataFieldsToJson;
  Map<String, dynamic> toJson() => _$ClientDataFieldsToJson(this);

  @JsonKey(
    name: 'public_inputs',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? publicInputs;
  static const fromJsonFactory = _$ClientDataFieldsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ClientDataFields &&
            (identical(other.publicInputs, publicInputs) ||
                const DeepCollectionEquality().equals(
                  other.publicInputs,
                  publicInputs,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(publicInputs) ^ runtimeType.hashCode;
}

extension $ClientDataFieldsExtension on ClientDataFields {
  ClientDataFields copyWith({List<String>? publicInputs}) {
    return ClientDataFields(publicInputs: publicInputs ?? this.publicInputs);
  }

  ClientDataFields copyWithWrapped({Wrapped<List<String>?>? publicInputs}) {
    return ClientDataFields(
      publicInputs: (publicInputs != null
          ? publicInputs.value
          : this.publicInputs),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ConversionData {
  const ConversionData({this.from, required this.amount, this.to});

  factory ConversionData.fromJson(Map<String, dynamic> json) =>
      _$ConversionDataFromJson(json);

  static const toJsonFactory = _$ConversionDataToJson;
  Map<String, dynamic> toJson() => _$ConversionDataToJson(this);

  @JsonKey(name: 'from_', includeIfNull: false)
  final String? from;
  @JsonKey(name: 'amount', includeIfNull: false)
  final double amount;
  @JsonKey(name: 'to', includeIfNull: false)
  final String? to;
  static const fromJsonFactory = _$ConversionDataFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ConversionData &&
            (identical(other.from, from) ||
                const DeepCollectionEquality().equals(other.from, from)) &&
            (identical(other.amount, amount) ||
                const DeepCollectionEquality().equals(other.amount, amount)) &&
            (identical(other.to, to) ||
                const DeepCollectionEquality().equals(other.to, to)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(from) ^
      const DeepCollectionEquality().hash(amount) ^
      const DeepCollectionEquality().hash(to) ^
      runtimeType.hashCode;
}

extension $ConversionDataExtension on ConversionData {
  ConversionData copyWith({String? from, double? amount, String? to}) {
    return ConversionData(
      from: from ?? this.from,
      amount: amount ?? this.amount,
      to: to ?? this.to,
    );
  }

  ConversionData copyWithWrapped({
    Wrapped<String?>? from,
    Wrapped<double>? amount,
    Wrapped<String?>? to,
  }) {
    return ConversionData(
      from: (from != null ? from.value : this.from),
      amount: (amount != null ? amount.value : this.amount),
      to: (to != null ? to.value : this.to),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class CreateExtension {
  const CreateExtension({
    required this.extId,
    required this.archive,
    required this.sourceRepo,
    required this.version,
    this.costSats,
    this.paymentHash,
  });

  factory CreateExtension.fromJson(Map<String, dynamic> json) =>
      _$CreateExtensionFromJson(json);

  static const toJsonFactory = _$CreateExtensionToJson;
  Map<String, dynamic> toJson() => _$CreateExtensionToJson(this);

  @JsonKey(name: 'ext_id', includeIfNull: false)
  final String extId;
  @JsonKey(name: 'archive', includeIfNull: false)
  final String archive;
  @JsonKey(name: 'source_repo', includeIfNull: false)
  final String sourceRepo;
  @JsonKey(name: 'version', includeIfNull: false)
  final String version;
  @JsonKey(name: 'cost_sats', includeIfNull: false)
  final int? costSats;
  @JsonKey(name: 'payment_hash', includeIfNull: false)
  final String? paymentHash;
  static const fromJsonFactory = _$CreateExtensionFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CreateExtension &&
            (identical(other.extId, extId) ||
                const DeepCollectionEquality().equals(other.extId, extId)) &&
            (identical(other.archive, archive) ||
                const DeepCollectionEquality().equals(
                  other.archive,
                  archive,
                )) &&
            (identical(other.sourceRepo, sourceRepo) ||
                const DeepCollectionEquality().equals(
                  other.sourceRepo,
                  sourceRepo,
                )) &&
            (identical(other.version, version) ||
                const DeepCollectionEquality().equals(
                  other.version,
                  version,
                )) &&
            (identical(other.costSats, costSats) ||
                const DeepCollectionEquality().equals(
                  other.costSats,
                  costSats,
                )) &&
            (identical(other.paymentHash, paymentHash) ||
                const DeepCollectionEquality().equals(
                  other.paymentHash,
                  paymentHash,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(extId) ^
      const DeepCollectionEquality().hash(archive) ^
      const DeepCollectionEquality().hash(sourceRepo) ^
      const DeepCollectionEquality().hash(version) ^
      const DeepCollectionEquality().hash(costSats) ^
      const DeepCollectionEquality().hash(paymentHash) ^
      runtimeType.hashCode;
}

extension $CreateExtensionExtension on CreateExtension {
  CreateExtension copyWith({
    String? extId,
    String? archive,
    String? sourceRepo,
    String? version,
    int? costSats,
    String? paymentHash,
  }) {
    return CreateExtension(
      extId: extId ?? this.extId,
      archive: archive ?? this.archive,
      sourceRepo: sourceRepo ?? this.sourceRepo,
      version: version ?? this.version,
      costSats: costSats ?? this.costSats,
      paymentHash: paymentHash ?? this.paymentHash,
    );
  }

  CreateExtension copyWithWrapped({
    Wrapped<String>? extId,
    Wrapped<String>? archive,
    Wrapped<String>? sourceRepo,
    Wrapped<String>? version,
    Wrapped<int?>? costSats,
    Wrapped<String?>? paymentHash,
  }) {
    return CreateExtension(
      extId: (extId != null ? extId.value : this.extId),
      archive: (archive != null ? archive.value : this.archive),
      sourceRepo: (sourceRepo != null ? sourceRepo.value : this.sourceRepo),
      version: (version != null ? version.value : this.version),
      costSats: (costSats != null ? costSats.value : this.costSats),
      paymentHash: (paymentHash != null ? paymentHash.value : this.paymentHash),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class CreateExtensionReview {
  const CreateExtensionReview({
    required this.tag,
    this.name,
    required this.rating,
    this.comment,
  });

  factory CreateExtensionReview.fromJson(Map<String, dynamic> json) =>
      _$CreateExtensionReviewFromJson(json);

  static const toJsonFactory = _$CreateExtensionReviewToJson;
  Map<String, dynamic> toJson() => _$CreateExtensionReviewToJson(this);

  @JsonKey(name: 'tag', includeIfNull: false)
  final String tag;
  @JsonKey(name: 'name', includeIfNull: false)
  final String? name;
  @JsonKey(name: 'rating', includeIfNull: false)
  final int rating;
  @JsonKey(name: 'comment', includeIfNull: false)
  final String? comment;
  static const fromJsonFactory = _$CreateExtensionReviewFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CreateExtensionReview &&
            (identical(other.tag, tag) ||
                const DeepCollectionEquality().equals(other.tag, tag)) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.rating, rating) ||
                const DeepCollectionEquality().equals(other.rating, rating)) &&
            (identical(other.comment, comment) ||
                const DeepCollectionEquality().equals(other.comment, comment)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(tag) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(rating) ^
      const DeepCollectionEquality().hash(comment) ^
      runtimeType.hashCode;
}

extension $CreateExtensionReviewExtension on CreateExtensionReview {
  CreateExtensionReview copyWith({
    String? tag,
    String? name,
    int? rating,
    String? comment,
  }) {
    return CreateExtensionReview(
      tag: tag ?? this.tag,
      name: name ?? this.name,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
    );
  }

  CreateExtensionReview copyWithWrapped({
    Wrapped<String>? tag,
    Wrapped<String?>? name,
    Wrapped<int>? rating,
    Wrapped<String?>? comment,
  }) {
    return CreateExtensionReview(
      tag: (tag != null ? tag.value : this.tag),
      name: (name != null ? name.value : this.name),
      rating: (rating != null ? rating.value : this.rating),
      comment: (comment != null ? comment.value : this.comment),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class CreateFiatSubscription {
  const CreateFiatSubscription({
    required this.subscriptionId,
    required this.quantity,
    required this.paymentOptions,
  });

  factory CreateFiatSubscription.fromJson(Map<String, dynamic> json) =>
      _$CreateFiatSubscriptionFromJson(json);

  static const toJsonFactory = _$CreateFiatSubscriptionToJson;
  Map<String, dynamic> toJson() => _$CreateFiatSubscriptionToJson(this);

  @JsonKey(name: 'subscription_id', includeIfNull: false)
  final String subscriptionId;
  @JsonKey(name: 'quantity', includeIfNull: false)
  final int quantity;
  @JsonKey(name: 'payment_options', includeIfNull: false)
  final FiatSubscriptionPaymentOptions paymentOptions;
  static const fromJsonFactory = _$CreateFiatSubscriptionFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CreateFiatSubscription &&
            (identical(other.subscriptionId, subscriptionId) ||
                const DeepCollectionEquality().equals(
                  other.subscriptionId,
                  subscriptionId,
                )) &&
            (identical(other.quantity, quantity) ||
                const DeepCollectionEquality().equals(
                  other.quantity,
                  quantity,
                )) &&
            (identical(other.paymentOptions, paymentOptions) ||
                const DeepCollectionEquality().equals(
                  other.paymentOptions,
                  paymentOptions,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(subscriptionId) ^
      const DeepCollectionEquality().hash(quantity) ^
      const DeepCollectionEquality().hash(paymentOptions) ^
      runtimeType.hashCode;
}

extension $CreateFiatSubscriptionExtension on CreateFiatSubscription {
  CreateFiatSubscription copyWith({
    String? subscriptionId,
    int? quantity,
    FiatSubscriptionPaymentOptions? paymentOptions,
  }) {
    return CreateFiatSubscription(
      subscriptionId: subscriptionId ?? this.subscriptionId,
      quantity: quantity ?? this.quantity,
      paymentOptions: paymentOptions ?? this.paymentOptions,
    );
  }

  CreateFiatSubscription copyWithWrapped({
    Wrapped<String>? subscriptionId,
    Wrapped<int>? quantity,
    Wrapped<FiatSubscriptionPaymentOptions>? paymentOptions,
  }) {
    return CreateFiatSubscription(
      subscriptionId: (subscriptionId != null
          ? subscriptionId.value
          : this.subscriptionId),
      quantity: (quantity != null ? quantity.value : this.quantity),
      paymentOptions: (paymentOptions != null
          ? paymentOptions.value
          : this.paymentOptions),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class CreateInvoice {
  const CreateInvoice({
    this.unit,
    this.internal,
    this.out,
    this.amount,
    this.memo,
    this.descriptionHash,
    this.unhashedDescription,
    this.paymentHash,
    this.expiry,
    this.extra,
    this.webhook,
    this.bolt11,
    this.lnurlWithdraw,
    this.fiatProvider,
    this.labels,
  });

  factory CreateInvoice.fromJson(Map<String, dynamic> json) =>
      _$CreateInvoiceFromJson(json);

  static const toJsonFactory = _$CreateInvoiceToJson;
  Map<String, dynamic> toJson() => _$CreateInvoiceToJson(this);

  @JsonKey(name: 'unit', includeIfNull: false)
  final String? unit;
  @JsonKey(name: 'internal', includeIfNull: false, defaultValue: false)
  final bool? internal;
  @JsonKey(name: 'out', includeIfNull: false, defaultValue: true)
  final bool? out;
  @JsonKey(name: 'amount', includeIfNull: false)
  final double? amount;
  @JsonKey(name: 'memo', includeIfNull: false)
  final String? memo;
  @JsonKey(name: 'description_hash', includeIfNull: false)
  final String? descriptionHash;
  @JsonKey(name: 'unhashed_description', includeIfNull: false)
  final String? unhashedDescription;
  @JsonKey(name: 'payment_hash', includeIfNull: false)
  final String? paymentHash;
  @JsonKey(name: 'expiry', includeIfNull: false)
  final int? expiry;
  @JsonKey(name: 'extra', includeIfNull: false)
  final Object? extra;
  @JsonKey(name: 'webhook', includeIfNull: false)
  final String? webhook;
  @JsonKey(name: 'bolt11', includeIfNull: false)
  final String? bolt11;
  @JsonKey(name: 'lnurl_withdraw', includeIfNull: false)
  final LnurlWithdrawResponse? lnurlWithdraw;
  @JsonKey(name: 'fiat_provider', includeIfNull: false)
  final String? fiatProvider;
  @JsonKey(name: 'labels', includeIfNull: false, defaultValue: <String>[])
  final List<String>? labels;
  static const fromJsonFactory = _$CreateInvoiceFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CreateInvoice &&
            (identical(other.unit, unit) ||
                const DeepCollectionEquality().equals(other.unit, unit)) &&
            (identical(other.internal, internal) ||
                const DeepCollectionEquality().equals(
                  other.internal,
                  internal,
                )) &&
            (identical(other.out, out) ||
                const DeepCollectionEquality().equals(other.out, out)) &&
            (identical(other.amount, amount) ||
                const DeepCollectionEquality().equals(other.amount, amount)) &&
            (identical(other.memo, memo) ||
                const DeepCollectionEquality().equals(other.memo, memo)) &&
            (identical(other.descriptionHash, descriptionHash) ||
                const DeepCollectionEquality().equals(
                  other.descriptionHash,
                  descriptionHash,
                )) &&
            (identical(other.unhashedDescription, unhashedDescription) ||
                const DeepCollectionEquality().equals(
                  other.unhashedDescription,
                  unhashedDescription,
                )) &&
            (identical(other.paymentHash, paymentHash) ||
                const DeepCollectionEquality().equals(
                  other.paymentHash,
                  paymentHash,
                )) &&
            (identical(other.expiry, expiry) ||
                const DeepCollectionEquality().equals(other.expiry, expiry)) &&
            (identical(other.extra, extra) ||
                const DeepCollectionEquality().equals(other.extra, extra)) &&
            (identical(other.webhook, webhook) ||
                const DeepCollectionEquality().equals(
                  other.webhook,
                  webhook,
                )) &&
            (identical(other.bolt11, bolt11) ||
                const DeepCollectionEquality().equals(other.bolt11, bolt11)) &&
            (identical(other.lnurlWithdraw, lnurlWithdraw) ||
                const DeepCollectionEquality().equals(
                  other.lnurlWithdraw,
                  lnurlWithdraw,
                )) &&
            (identical(other.fiatProvider, fiatProvider) ||
                const DeepCollectionEquality().equals(
                  other.fiatProvider,
                  fiatProvider,
                )) &&
            (identical(other.labels, labels) ||
                const DeepCollectionEquality().equals(other.labels, labels)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(unit) ^
      const DeepCollectionEquality().hash(internal) ^
      const DeepCollectionEquality().hash(out) ^
      const DeepCollectionEquality().hash(amount) ^
      const DeepCollectionEquality().hash(memo) ^
      const DeepCollectionEquality().hash(descriptionHash) ^
      const DeepCollectionEquality().hash(unhashedDescription) ^
      const DeepCollectionEquality().hash(paymentHash) ^
      const DeepCollectionEquality().hash(expiry) ^
      const DeepCollectionEquality().hash(extra) ^
      const DeepCollectionEquality().hash(webhook) ^
      const DeepCollectionEquality().hash(bolt11) ^
      const DeepCollectionEquality().hash(lnurlWithdraw) ^
      const DeepCollectionEquality().hash(fiatProvider) ^
      const DeepCollectionEquality().hash(labels) ^
      runtimeType.hashCode;
}

extension $CreateInvoiceExtension on CreateInvoice {
  CreateInvoice copyWith({
    String? unit,
    bool? internal,
    bool? out,
    double? amount,
    String? memo,
    String? descriptionHash,
    String? unhashedDescription,
    String? paymentHash,
    int? expiry,
    Object? extra,
    String? webhook,
    String? bolt11,
    LnurlWithdrawResponse? lnurlWithdraw,
    String? fiatProvider,
    List<String>? labels,
  }) {
    return CreateInvoice(
      unit: unit ?? this.unit,
      internal: internal ?? this.internal,
      out: out ?? this.out,
      amount: amount ?? this.amount,
      memo: memo ?? this.memo,
      descriptionHash: descriptionHash ?? this.descriptionHash,
      unhashedDescription: unhashedDescription ?? this.unhashedDescription,
      paymentHash: paymentHash ?? this.paymentHash,
      expiry: expiry ?? this.expiry,
      extra: extra ?? this.extra,
      webhook: webhook ?? this.webhook,
      bolt11: bolt11 ?? this.bolt11,
      lnurlWithdraw: lnurlWithdraw ?? this.lnurlWithdraw,
      fiatProvider: fiatProvider ?? this.fiatProvider,
      labels: labels ?? this.labels,
    );
  }

  CreateInvoice copyWithWrapped({
    Wrapped<String?>? unit,
    Wrapped<bool?>? internal,
    Wrapped<bool?>? out,
    Wrapped<double?>? amount,
    Wrapped<String?>? memo,
    Wrapped<String?>? descriptionHash,
    Wrapped<String?>? unhashedDescription,
    Wrapped<String?>? paymentHash,
    Wrapped<int?>? expiry,
    Wrapped<Object?>? extra,
    Wrapped<String?>? webhook,
    Wrapped<String?>? bolt11,
    Wrapped<LnurlWithdrawResponse?>? lnurlWithdraw,
    Wrapped<String?>? fiatProvider,
    Wrapped<List<String>?>? labels,
  }) {
    return CreateInvoice(
      unit: (unit != null ? unit.value : this.unit),
      internal: (internal != null ? internal.value : this.internal),
      out: (out != null ? out.value : this.out),
      amount: (amount != null ? amount.value : this.amount),
      memo: (memo != null ? memo.value : this.memo),
      descriptionHash: (descriptionHash != null
          ? descriptionHash.value
          : this.descriptionHash),
      unhashedDescription: (unhashedDescription != null
          ? unhashedDescription.value
          : this.unhashedDescription),
      paymentHash: (paymentHash != null ? paymentHash.value : this.paymentHash),
      expiry: (expiry != null ? expiry.value : this.expiry),
      extra: (extra != null ? extra.value : this.extra),
      webhook: (webhook != null ? webhook.value : this.webhook),
      bolt11: (bolt11 != null ? bolt11.value : this.bolt11),
      lnurlWithdraw: (lnurlWithdraw != null
          ? lnurlWithdraw.value
          : this.lnurlWithdraw),
      fiatProvider: (fiatProvider != null
          ? fiatProvider.value
          : this.fiatProvider),
      labels: (labels != null ? labels.value : this.labels),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class CreateLnurlPayment {
  const CreateLnurlPayment({
    this.res,
    this.lnurl,
    required this.amount,
    this.comment,
    this.unit,
    this.internalMemo,
  });

  factory CreateLnurlPayment.fromJson(Map<String, dynamic> json) =>
      _$CreateLnurlPaymentFromJson(json);

  static const toJsonFactory = _$CreateLnurlPaymentToJson;
  Map<String, dynamic> toJson() => _$CreateLnurlPaymentToJson(this);

  @JsonKey(name: 'res', includeIfNull: false)
  final LnurlPayResponse? res;
  @JsonKey(name: 'lnurl', includeIfNull: false)
  final dynamic lnurl;
  @JsonKey(name: 'amount', includeIfNull: false)
  final int amount;
  @JsonKey(name: 'comment', includeIfNull: false)
  final String? comment;
  @JsonKey(name: 'unit', includeIfNull: false)
  final String? unit;
  @JsonKey(name: 'internal_memo', includeIfNull: false)
  final String? internalMemo;
  static const fromJsonFactory = _$CreateLnurlPaymentFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CreateLnurlPayment &&
            (identical(other.res, res) ||
                const DeepCollectionEquality().equals(other.res, res)) &&
            (identical(other.lnurl, lnurl) ||
                const DeepCollectionEquality().equals(other.lnurl, lnurl)) &&
            (identical(other.amount, amount) ||
                const DeepCollectionEquality().equals(other.amount, amount)) &&
            (identical(other.comment, comment) ||
                const DeepCollectionEquality().equals(
                  other.comment,
                  comment,
                )) &&
            (identical(other.unit, unit) ||
                const DeepCollectionEquality().equals(other.unit, unit)) &&
            (identical(other.internalMemo, internalMemo) ||
                const DeepCollectionEquality().equals(
                  other.internalMemo,
                  internalMemo,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(res) ^
      const DeepCollectionEquality().hash(lnurl) ^
      const DeepCollectionEquality().hash(amount) ^
      const DeepCollectionEquality().hash(comment) ^
      const DeepCollectionEquality().hash(unit) ^
      const DeepCollectionEquality().hash(internalMemo) ^
      runtimeType.hashCode;
}

extension $CreateLnurlPaymentExtension on CreateLnurlPayment {
  CreateLnurlPayment copyWith({
    LnurlPayResponse? res,
    dynamic lnurl,
    int? amount,
    String? comment,
    String? unit,
    String? internalMemo,
  }) {
    return CreateLnurlPayment(
      res: res ?? this.res,
      lnurl: lnurl ?? this.lnurl,
      amount: amount ?? this.amount,
      comment: comment ?? this.comment,
      unit: unit ?? this.unit,
      internalMemo: internalMemo ?? this.internalMemo,
    );
  }

  CreateLnurlPayment copyWithWrapped({
    Wrapped<LnurlPayResponse?>? res,
    Wrapped<dynamic>? lnurl,
    Wrapped<int>? amount,
    Wrapped<String?>? comment,
    Wrapped<String?>? unit,
    Wrapped<String?>? internalMemo,
  }) {
    return CreateLnurlPayment(
      res: (res != null ? res.value : this.res),
      lnurl: (lnurl != null ? lnurl.value : this.lnurl),
      amount: (amount != null ? amount.value : this.amount),
      comment: (comment != null ? comment.value : this.comment),
      unit: (unit != null ? unit.value : this.unit),
      internalMemo: (internalMemo != null
          ? internalMemo.value
          : this.internalMemo),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class CreateLnurlWithdraw {
  const CreateLnurlWithdraw({required this.lnurlW});

  factory CreateLnurlWithdraw.fromJson(Map<String, dynamic> json) =>
      _$CreateLnurlWithdrawFromJson(json);

  static const toJsonFactory = _$CreateLnurlWithdrawToJson;
  Map<String, dynamic> toJson() => _$CreateLnurlWithdrawToJson(this);

  @JsonKey(name: 'lnurl_w', includeIfNull: false)
  final String lnurlW;
  static const fromJsonFactory = _$CreateLnurlWithdrawFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CreateLnurlWithdraw &&
            (identical(other.lnurlW, lnurlW) ||
                const DeepCollectionEquality().equals(other.lnurlW, lnurlW)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(lnurlW) ^ runtimeType.hashCode;
}

extension $CreateLnurlWithdrawExtension on CreateLnurlWithdraw {
  CreateLnurlWithdraw copyWith({String? lnurlW}) {
    return CreateLnurlWithdraw(lnurlW: lnurlW ?? this.lnurlW);
  }

  CreateLnurlWithdraw copyWithWrapped({Wrapped<String>? lnurlW}) {
    return CreateLnurlWithdraw(
      lnurlW: (lnurlW != null ? lnurlW.value : this.lnurlW),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class CreateUser {
  const CreateUser({
    this.id,
    this.email,
    this.username,
    this.password,
    this.passwordRepeat,
    this.pubkey,
    this.externalId,
    this.extensions,
    this.extra,
  });

  factory CreateUser.fromJson(Map<String, dynamic> json) =>
      _$CreateUserFromJson(json);

  static const toJsonFactory = _$CreateUserToJson;
  Map<String, dynamic> toJson() => _$CreateUserToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String? id;
  @JsonKey(name: 'email', includeIfNull: false)
  final String? email;
  @JsonKey(name: 'username', includeIfNull: false)
  final String? username;
  @JsonKey(name: 'password', includeIfNull: false)
  final String? password;
  @JsonKey(name: 'password_repeat', includeIfNull: false)
  final String? passwordRepeat;
  @JsonKey(name: 'pubkey', includeIfNull: false)
  final String? pubkey;
  @JsonKey(name: 'external_id', includeIfNull: false)
  final String? externalId;
  @JsonKey(name: 'extensions', includeIfNull: false, defaultValue: <String>[])
  final List<String>? extensions;
  @JsonKey(name: 'extra', includeIfNull: false)
  final UserExtra? extra;
  static const fromJsonFactory = _$CreateUserFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CreateUser &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.email, email) ||
                const DeepCollectionEquality().equals(other.email, email)) &&
            (identical(other.username, username) ||
                const DeepCollectionEquality().equals(
                  other.username,
                  username,
                )) &&
            (identical(other.password, password) ||
                const DeepCollectionEquality().equals(
                  other.password,
                  password,
                )) &&
            (identical(other.passwordRepeat, passwordRepeat) ||
                const DeepCollectionEquality().equals(
                  other.passwordRepeat,
                  passwordRepeat,
                )) &&
            (identical(other.pubkey, pubkey) ||
                const DeepCollectionEquality().equals(other.pubkey, pubkey)) &&
            (identical(other.externalId, externalId) ||
                const DeepCollectionEquality().equals(
                  other.externalId,
                  externalId,
                )) &&
            (identical(other.extensions, extensions) ||
                const DeepCollectionEquality().equals(
                  other.extensions,
                  extensions,
                )) &&
            (identical(other.extra, extra) ||
                const DeepCollectionEquality().equals(other.extra, extra)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(email) ^
      const DeepCollectionEquality().hash(username) ^
      const DeepCollectionEquality().hash(password) ^
      const DeepCollectionEquality().hash(passwordRepeat) ^
      const DeepCollectionEquality().hash(pubkey) ^
      const DeepCollectionEquality().hash(externalId) ^
      const DeepCollectionEquality().hash(extensions) ^
      const DeepCollectionEquality().hash(extra) ^
      runtimeType.hashCode;
}

extension $CreateUserExtension on CreateUser {
  CreateUser copyWith({
    String? id,
    String? email,
    String? username,
    String? password,
    String? passwordRepeat,
    String? pubkey,
    String? externalId,
    List<String>? extensions,
    UserExtra? extra,
  }) {
    return CreateUser(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      password: password ?? this.password,
      passwordRepeat: passwordRepeat ?? this.passwordRepeat,
      pubkey: pubkey ?? this.pubkey,
      externalId: externalId ?? this.externalId,
      extensions: extensions ?? this.extensions,
      extra: extra ?? this.extra,
    );
  }

  CreateUser copyWithWrapped({
    Wrapped<String?>? id,
    Wrapped<String?>? email,
    Wrapped<String?>? username,
    Wrapped<String?>? password,
    Wrapped<String?>? passwordRepeat,
    Wrapped<String?>? pubkey,
    Wrapped<String?>? externalId,
    Wrapped<List<String>?>? extensions,
    Wrapped<UserExtra?>? extra,
  }) {
    return CreateUser(
      id: (id != null ? id.value : this.id),
      email: (email != null ? email.value : this.email),
      username: (username != null ? username.value : this.username),
      password: (password != null ? password.value : this.password),
      passwordRepeat: (passwordRepeat != null
          ? passwordRepeat.value
          : this.passwordRepeat),
      pubkey: (pubkey != null ? pubkey.value : this.pubkey),
      externalId: (externalId != null ? externalId.value : this.externalId),
      extensions: (extensions != null ? extensions.value : this.extensions),
      extra: (extra != null ? extra.value : this.extra),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class CreateWallet {
  const CreateWallet({this.name, this.walletType, this.sharedWalletId});

  factory CreateWallet.fromJson(Map<String, dynamic> json) =>
      _$CreateWalletFromJson(json);

  static const toJsonFactory = _$CreateWalletToJson;
  Map<String, dynamic> toJson() => _$CreateWalletToJson(this);

  @JsonKey(name: 'name', includeIfNull: false)
  final String? name;
  @JsonKey(
    name: 'wallet_type',
    includeIfNull: false,
    toJson: walletTypeNullableToJson,
    fromJson: walletTypeWalletTypeNullableFromJson,
  )
  final enums.WalletType? walletType;
  static enums.WalletType? walletTypeWalletTypeNullableFromJson(
    Object? value,
  ) => walletTypeNullableFromJson(value, enums.WalletType.lightning);

  @JsonKey(name: 'shared_wallet_id', includeIfNull: false)
  final String? sharedWalletId;
  static const fromJsonFactory = _$CreateWalletFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CreateWallet &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.walletType, walletType) ||
                const DeepCollectionEquality().equals(
                  other.walletType,
                  walletType,
                )) &&
            (identical(other.sharedWalletId, sharedWalletId) ||
                const DeepCollectionEquality().equals(
                  other.sharedWalletId,
                  sharedWalletId,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(walletType) ^
      const DeepCollectionEquality().hash(sharedWalletId) ^
      runtimeType.hashCode;
}

extension $CreateWalletExtension on CreateWallet {
  CreateWallet copyWith({
    String? name,
    enums.WalletType? walletType,
    String? sharedWalletId,
  }) {
    return CreateWallet(
      name: name ?? this.name,
      walletType: walletType ?? this.walletType,
      sharedWalletId: sharedWalletId ?? this.sharedWalletId,
    );
  }

  CreateWallet copyWithWrapped({
    Wrapped<String?>? name,
    Wrapped<enums.WalletType?>? walletType,
    Wrapped<String?>? sharedWalletId,
  }) {
    return CreateWallet(
      name: (name != null ? name.value : this.name),
      walletType: (walletType != null ? walletType.value : this.walletType),
      sharedWalletId: (sharedWalletId != null
          ? sharedWalletId.value
          : this.sharedWalletId),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class CreateWebPushSubscription {
  const CreateWebPushSubscription({required this.subscription});

  factory CreateWebPushSubscription.fromJson(Map<String, dynamic> json) =>
      _$CreateWebPushSubscriptionFromJson(json);

  static const toJsonFactory = _$CreateWebPushSubscriptionToJson;
  Map<String, dynamic> toJson() => _$CreateWebPushSubscriptionToJson(this);

  @JsonKey(name: 'subscription', includeIfNull: false)
  final String subscription;
  static const fromJsonFactory = _$CreateWebPushSubscriptionFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CreateWebPushSubscription &&
            (identical(other.subscription, subscription) ||
                const DeepCollectionEquality().equals(
                  other.subscription,
                  subscription,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(subscription) ^ runtimeType.hashCode;
}

extension $CreateWebPushSubscriptionExtension on CreateWebPushSubscription {
  CreateWebPushSubscription copyWith({String? subscription}) {
    return CreateWebPushSubscription(
      subscription: subscription ?? this.subscription,
    );
  }

  CreateWebPushSubscription copyWithWrapped({Wrapped<String>? subscription}) {
    return CreateWebPushSubscription(
      subscription: (subscription != null
          ? subscription.value
          : this.subscription),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class DataField {
  const DataField({
    required this.name,
    required this.type,
    this.label,
    this.hint,
    this.optional,
    this.editable,
    this.searchable,
    this.sortable,
    this.fields,
  });

  factory DataField.fromJson(Map<String, dynamic> json) =>
      _$DataFieldFromJson(json);

  static const toJsonFactory = _$DataFieldToJson;
  Map<String, dynamic> toJson() => _$DataFieldToJson(this);

  @JsonKey(name: 'name', includeIfNull: false)
  final String name;
  @JsonKey(name: 'type', includeIfNull: false)
  final String type;
  @JsonKey(name: 'label', includeIfNull: false)
  final String? label;
  @JsonKey(name: 'hint', includeIfNull: false)
  final String? hint;
  @JsonKey(name: 'optional', includeIfNull: false, defaultValue: false)
  final bool? optional;
  @JsonKey(name: 'editable', includeIfNull: false, defaultValue: false)
  final bool? editable;
  @JsonKey(name: 'searchable', includeIfNull: false, defaultValue: false)
  final bool? searchable;
  @JsonKey(name: 'sortable', includeIfNull: false, defaultValue: false)
  final bool? sortable;
  @JsonKey(name: 'fields', includeIfNull: false, defaultValue: <DataField>[])
  final List<DataField>? fields;
  static const fromJsonFactory = _$DataFieldFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is DataField &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.type, type) ||
                const DeepCollectionEquality().equals(other.type, type)) &&
            (identical(other.label, label) ||
                const DeepCollectionEquality().equals(other.label, label)) &&
            (identical(other.hint, hint) ||
                const DeepCollectionEquality().equals(other.hint, hint)) &&
            (identical(other.optional, optional) ||
                const DeepCollectionEquality().equals(
                  other.optional,
                  optional,
                )) &&
            (identical(other.editable, editable) ||
                const DeepCollectionEquality().equals(
                  other.editable,
                  editable,
                )) &&
            (identical(other.searchable, searchable) ||
                const DeepCollectionEquality().equals(
                  other.searchable,
                  searchable,
                )) &&
            (identical(other.sortable, sortable) ||
                const DeepCollectionEquality().equals(
                  other.sortable,
                  sortable,
                )) &&
            (identical(other.fields, fields) ||
                const DeepCollectionEquality().equals(other.fields, fields)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(type) ^
      const DeepCollectionEquality().hash(label) ^
      const DeepCollectionEquality().hash(hint) ^
      const DeepCollectionEquality().hash(optional) ^
      const DeepCollectionEquality().hash(editable) ^
      const DeepCollectionEquality().hash(searchable) ^
      const DeepCollectionEquality().hash(sortable) ^
      const DeepCollectionEquality().hash(fields) ^
      runtimeType.hashCode;
}

extension $DataFieldExtension on DataField {
  DataField copyWith({
    String? name,
    String? type,
    String? label,
    String? hint,
    bool? optional,
    bool? editable,
    bool? searchable,
    bool? sortable,
    List<DataField>? fields,
  }) {
    return DataField(
      name: name ?? this.name,
      type: type ?? this.type,
      label: label ?? this.label,
      hint: hint ?? this.hint,
      optional: optional ?? this.optional,
      editable: editable ?? this.editable,
      searchable: searchable ?? this.searchable,
      sortable: sortable ?? this.sortable,
      fields: fields ?? this.fields,
    );
  }

  DataField copyWithWrapped({
    Wrapped<String>? name,
    Wrapped<String>? type,
    Wrapped<String?>? label,
    Wrapped<String?>? hint,
    Wrapped<bool?>? optional,
    Wrapped<bool?>? editable,
    Wrapped<bool?>? searchable,
    Wrapped<bool?>? sortable,
    Wrapped<List<DataField>?>? fields,
  }) {
    return DataField(
      name: (name != null ? name.value : this.name),
      type: (type != null ? type.value : this.type),
      label: (label != null ? label.value : this.label),
      hint: (hint != null ? hint.value : this.hint),
      optional: (optional != null ? optional.value : this.optional),
      editable: (editable != null ? editable.value : this.editable),
      searchable: (searchable != null ? searchable.value : this.searchable),
      sortable: (sortable != null ? sortable.value : this.sortable),
      fields: (fields != null ? fields.value : this.fields),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class DataFields {
  const DataFields({required this.name, this.editable, this.fields});

  factory DataFields.fromJson(Map<String, dynamic> json) =>
      _$DataFieldsFromJson(json);

  static const toJsonFactory = _$DataFieldsToJson;
  Map<String, dynamic> toJson() => _$DataFieldsToJson(this);

  @JsonKey(name: 'name', includeIfNull: false)
  final String name;
  @JsonKey(name: 'editable', includeIfNull: false, defaultValue: true)
  final bool? editable;
  @JsonKey(name: 'fields', includeIfNull: false, defaultValue: <DataField>[])
  final List<DataField>? fields;
  static const fromJsonFactory = _$DataFieldsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is DataFields &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.editable, editable) ||
                const DeepCollectionEquality().equals(
                  other.editable,
                  editable,
                )) &&
            (identical(other.fields, fields) ||
                const DeepCollectionEquality().equals(other.fields, fields)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(editable) ^
      const DeepCollectionEquality().hash(fields) ^
      runtimeType.hashCode;
}

extension $DataFieldsExtension on DataFields {
  DataFields copyWith({String? name, bool? editable, List<DataField>? fields}) {
    return DataFields(
      name: name ?? this.name,
      editable: editable ?? this.editable,
      fields: fields ?? this.fields,
    );
  }

  DataFields copyWithWrapped({
    Wrapped<String>? name,
    Wrapped<bool?>? editable,
    Wrapped<List<DataField>?>? fields,
  }) {
    return DataFields(
      name: (name != null ? name.value : this.name),
      editable: (editable != null ? editable.value : this.editable),
      fields: (fields != null ? fields.value : this.fields),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class DecodePayment {
  const DecodePayment({required this.data, this.filterFields});

  factory DecodePayment.fromJson(Map<String, dynamic> json) =>
      _$DecodePaymentFromJson(json);

  static const toJsonFactory = _$DecodePaymentToJson;
  Map<String, dynamic> toJson() => _$DecodePaymentToJson(this);

  @JsonKey(name: 'data', includeIfNull: false)
  final String data;
  @JsonKey(
    name: 'filter_fields',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? filterFields;
  static const fromJsonFactory = _$DecodePaymentFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is DecodePayment &&
            (identical(other.data, data) ||
                const DeepCollectionEquality().equals(other.data, data)) &&
            (identical(other.filterFields, filterFields) ||
                const DeepCollectionEquality().equals(
                  other.filterFields,
                  filterFields,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(data) ^
      const DeepCollectionEquality().hash(filterFields) ^
      runtimeType.hashCode;
}

extension $DecodePaymentExtension on DecodePayment {
  DecodePayment copyWith({String? data, List<String>? filterFields}) {
    return DecodePayment(
      data: data ?? this.data,
      filterFields: filterFields ?? this.filterFields,
    );
  }

  DecodePayment copyWithWrapped({
    Wrapped<String>? data,
    Wrapped<List<String>?>? filterFields,
  }) {
    return DecodePayment(
      data: (data != null ? data.value : this.data),
      filterFields: (filterFields != null
          ? filterFields.value
          : this.filterFields),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class DeleteAccessControlList {
  const DeleteAccessControlList({required this.id, required this.password});

  factory DeleteAccessControlList.fromJson(Map<String, dynamic> json) =>
      _$DeleteAccessControlListFromJson(json);

  static const toJsonFactory = _$DeleteAccessControlListToJson;
  Map<String, dynamic> toJson() => _$DeleteAccessControlListToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'password', includeIfNull: false)
  final String password;
  static const fromJsonFactory = _$DeleteAccessControlListFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is DeleteAccessControlList &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.password, password) ||
                const DeepCollectionEquality().equals(
                  other.password,
                  password,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(password) ^
      runtimeType.hashCode;
}

extension $DeleteAccessControlListExtension on DeleteAccessControlList {
  DeleteAccessControlList copyWith({String? id, String? password}) {
    return DeleteAccessControlList(
      id: id ?? this.id,
      password: password ?? this.password,
    );
  }

  DeleteAccessControlList copyWithWrapped({
    Wrapped<String>? id,
    Wrapped<String>? password,
  }) {
    return DeleteAccessControlList(
      id: (id != null ? id.value : this.id),
      password: (password != null ? password.value : this.password),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class DeleteTokenRequest {
  const DeleteTokenRequest({
    required this.id,
    required this.aclId,
    required this.password,
  });

  factory DeleteTokenRequest.fromJson(Map<String, dynamic> json) =>
      _$DeleteTokenRequestFromJson(json);

  static const toJsonFactory = _$DeleteTokenRequestToJson;
  Map<String, dynamic> toJson() => _$DeleteTokenRequestToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'acl_id', includeIfNull: false)
  final String aclId;
  @JsonKey(name: 'password', includeIfNull: false)
  final String password;
  static const fromJsonFactory = _$DeleteTokenRequestFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is DeleteTokenRequest &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.aclId, aclId) ||
                const DeepCollectionEquality().equals(other.aclId, aclId)) &&
            (identical(other.password, password) ||
                const DeepCollectionEquality().equals(
                  other.password,
                  password,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(aclId) ^
      const DeepCollectionEquality().hash(password) ^
      runtimeType.hashCode;
}

extension $DeleteTokenRequestExtension on DeleteTokenRequest {
  DeleteTokenRequest copyWith({String? id, String? aclId, String? password}) {
    return DeleteTokenRequest(
      id: id ?? this.id,
      aclId: aclId ?? this.aclId,
      password: password ?? this.password,
    );
  }

  DeleteTokenRequest copyWithWrapped({
    Wrapped<String>? id,
    Wrapped<String>? aclId,
    Wrapped<String>? password,
  }) {
    return DeleteTokenRequest(
      id: (id != null ? id.value : this.id),
      aclId: (aclId != null ? aclId.value : this.aclId),
      password: (password != null ? password.value : this.password),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class EndpointAccess {
  const EndpointAccess({
    required this.path,
    required this.name,
    this.read,
    this.write,
  });

  factory EndpointAccess.fromJson(Map<String, dynamic> json) =>
      _$EndpointAccessFromJson(json);

  static const toJsonFactory = _$EndpointAccessToJson;
  Map<String, dynamic> toJson() => _$EndpointAccessToJson(this);

  @JsonKey(name: 'path', includeIfNull: false)
  final String path;
  @JsonKey(name: 'name', includeIfNull: false)
  final String name;
  @JsonKey(name: 'read', includeIfNull: false, defaultValue: false)
  final bool? read;
  @JsonKey(name: 'write', includeIfNull: false, defaultValue: false)
  final bool? write;
  static const fromJsonFactory = _$EndpointAccessFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is EndpointAccess &&
            (identical(other.path, path) ||
                const DeepCollectionEquality().equals(other.path, path)) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.read, read) ||
                const DeepCollectionEquality().equals(other.read, read)) &&
            (identical(other.write, write) ||
                const DeepCollectionEquality().equals(other.write, write)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(path) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(read) ^
      const DeepCollectionEquality().hash(write) ^
      runtimeType.hashCode;
}

extension $EndpointAccessExtension on EndpointAccess {
  EndpointAccess copyWith({
    String? path,
    String? name,
    bool? read,
    bool? write,
  }) {
    return EndpointAccess(
      path: path ?? this.path,
      name: name ?? this.name,
      read: read ?? this.read,
      write: write ?? this.write,
    );
  }

  EndpointAccess copyWithWrapped({
    Wrapped<String>? path,
    Wrapped<String>? name,
    Wrapped<bool?>? read,
    Wrapped<bool?>? write,
  }) {
    return EndpointAccess(
      path: (path != null ? path.value : this.path),
      name: (name != null ? name.value : this.name),
      read: (read != null ? read.value : this.read),
      write: (write != null ? write.value : this.write),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ExchangeRateProvider {
  const ExchangeRateProvider({
    required this.name,
    required this.apiUrl,
    required this.path,
    this.excludeTo,
    this.tickerConversion,
  });

  factory ExchangeRateProvider.fromJson(Map<String, dynamic> json) =>
      _$ExchangeRateProviderFromJson(json);

  static const toJsonFactory = _$ExchangeRateProviderToJson;
  Map<String, dynamic> toJson() => _$ExchangeRateProviderToJson(this);

  @JsonKey(name: 'name', includeIfNull: false)
  final String name;
  @JsonKey(name: 'api_url', includeIfNull: false)
  final String apiUrl;
  @JsonKey(name: 'path', includeIfNull: false)
  final String path;
  @JsonKey(name: 'exclude_to', includeIfNull: false, defaultValue: <String>[])
  final List<String>? excludeTo;
  @JsonKey(
    name: 'ticker_conversion',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? tickerConversion;
  static const fromJsonFactory = _$ExchangeRateProviderFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExchangeRateProvider &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.apiUrl, apiUrl) ||
                const DeepCollectionEquality().equals(other.apiUrl, apiUrl)) &&
            (identical(other.path, path) ||
                const DeepCollectionEquality().equals(other.path, path)) &&
            (identical(other.excludeTo, excludeTo) ||
                const DeepCollectionEquality().equals(
                  other.excludeTo,
                  excludeTo,
                )) &&
            (identical(other.tickerConversion, tickerConversion) ||
                const DeepCollectionEquality().equals(
                  other.tickerConversion,
                  tickerConversion,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(apiUrl) ^
      const DeepCollectionEquality().hash(path) ^
      const DeepCollectionEquality().hash(excludeTo) ^
      const DeepCollectionEquality().hash(tickerConversion) ^
      runtimeType.hashCode;
}

extension $ExchangeRateProviderExtension on ExchangeRateProvider {
  ExchangeRateProvider copyWith({
    String? name,
    String? apiUrl,
    String? path,
    List<String>? excludeTo,
    List<String>? tickerConversion,
  }) {
    return ExchangeRateProvider(
      name: name ?? this.name,
      apiUrl: apiUrl ?? this.apiUrl,
      path: path ?? this.path,
      excludeTo: excludeTo ?? this.excludeTo,
      tickerConversion: tickerConversion ?? this.tickerConversion,
    );
  }

  ExchangeRateProvider copyWithWrapped({
    Wrapped<String>? name,
    Wrapped<String>? apiUrl,
    Wrapped<String>? path,
    Wrapped<List<String>?>? excludeTo,
    Wrapped<List<String>?>? tickerConversion,
  }) {
    return ExchangeRateProvider(
      name: (name != null ? name.value : this.name),
      apiUrl: (apiUrl != null ? apiUrl.value : this.apiUrl),
      path: (path != null ? path.value : this.path),
      excludeTo: (excludeTo != null ? excludeTo.value : this.excludeTo),
      tickerConversion: (tickerConversion != null
          ? tickerConversion.value
          : this.tickerConversion),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class Extension {
  const Extension({
    required this.code,
    required this.isValid,
    this.name,
    this.shortDescription,
    this.tile,
    this.upgradeHash,
  });

  factory Extension.fromJson(Map<String, dynamic> json) =>
      _$ExtensionFromJson(json);

  static const toJsonFactory = _$ExtensionToJson;
  Map<String, dynamic> toJson() => _$ExtensionToJson(this);

  @JsonKey(name: 'code', includeIfNull: false)
  final String code;
  @JsonKey(name: 'is_valid', includeIfNull: false)
  final bool isValid;
  @JsonKey(name: 'name', includeIfNull: false)
  final String? name;
  @JsonKey(name: 'short_description', includeIfNull: false)
  final String? shortDescription;
  @JsonKey(name: 'tile', includeIfNull: false)
  final String? tile;
  @JsonKey(name: 'upgrade_hash', includeIfNull: false)
  final String? upgradeHash;
  static const fromJsonFactory = _$ExtensionFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Extension &&
            (identical(other.code, code) ||
                const DeepCollectionEquality().equals(other.code, code)) &&
            (identical(other.isValid, isValid) ||
                const DeepCollectionEquality().equals(
                  other.isValid,
                  isValid,
                )) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.shortDescription, shortDescription) ||
                const DeepCollectionEquality().equals(
                  other.shortDescription,
                  shortDescription,
                )) &&
            (identical(other.tile, tile) ||
                const DeepCollectionEquality().equals(other.tile, tile)) &&
            (identical(other.upgradeHash, upgradeHash) ||
                const DeepCollectionEquality().equals(
                  other.upgradeHash,
                  upgradeHash,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(code) ^
      const DeepCollectionEquality().hash(isValid) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(shortDescription) ^
      const DeepCollectionEquality().hash(tile) ^
      const DeepCollectionEquality().hash(upgradeHash) ^
      runtimeType.hashCode;
}

extension $ExtensionExtension on Extension {
  Extension copyWith({
    String? code,
    bool? isValid,
    String? name,
    String? shortDescription,
    String? tile,
    String? upgradeHash,
  }) {
    return Extension(
      code: code ?? this.code,
      isValid: isValid ?? this.isValid,
      name: name ?? this.name,
      shortDescription: shortDescription ?? this.shortDescription,
      tile: tile ?? this.tile,
      upgradeHash: upgradeHash ?? this.upgradeHash,
    );
  }

  Extension copyWithWrapped({
    Wrapped<String>? code,
    Wrapped<bool>? isValid,
    Wrapped<String?>? name,
    Wrapped<String?>? shortDescription,
    Wrapped<String?>? tile,
    Wrapped<String?>? upgradeHash,
  }) {
    return Extension(
      code: (code != null ? code.value : this.code),
      isValid: (isValid != null ? isValid.value : this.isValid),
      name: (name != null ? name.value : this.name),
      shortDescription: (shortDescription != null
          ? shortDescription.value
          : this.shortDescription),
      tile: (tile != null ? tile.value : this.tile),
      upgradeHash: (upgradeHash != null ? upgradeHash.value : this.upgradeHash),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ExtensionData {
  const ExtensionData({
    required this.id,
    required this.name,
    this.stubVersion,
    this.shortDescription,
    this.description,
    required this.ownerData,
    required this.clientData,
    required this.settingsData,
    required this.publicPage,
    this.previewAction,
  });

  factory ExtensionData.fromJson(Map<String, dynamic> json) =>
      _$ExtensionDataFromJson(json);

  static const toJsonFactory = _$ExtensionDataToJson;
  Map<String, dynamic> toJson() => _$ExtensionDataToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'name', includeIfNull: false)
  final String name;
  @JsonKey(name: 'stub_version', includeIfNull: false)
  final String? stubVersion;
  @JsonKey(name: 'short_description', includeIfNull: false)
  final String? shortDescription;
  @JsonKey(name: 'description', includeIfNull: false)
  final String? description;
  @JsonKey(name: 'owner_data', includeIfNull: false)
  final DataFields ownerData;
  @JsonKey(name: 'client_data', includeIfNull: false)
  final DataFields clientData;
  @JsonKey(name: 'settings_data', includeIfNull: false)
  final SettingsFields settingsData;
  @JsonKey(name: 'public_page', includeIfNull: false)
  final PublicPageFields publicPage;
  @JsonKey(name: 'preview_action', includeIfNull: false)
  final PreviewAction? previewAction;
  static const fromJsonFactory = _$ExtensionDataFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionData &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.stubVersion, stubVersion) ||
                const DeepCollectionEquality().equals(
                  other.stubVersion,
                  stubVersion,
                )) &&
            (identical(other.shortDescription, shortDescription) ||
                const DeepCollectionEquality().equals(
                  other.shortDescription,
                  shortDescription,
                )) &&
            (identical(other.description, description) ||
                const DeepCollectionEquality().equals(
                  other.description,
                  description,
                )) &&
            (identical(other.ownerData, ownerData) ||
                const DeepCollectionEquality().equals(
                  other.ownerData,
                  ownerData,
                )) &&
            (identical(other.clientData, clientData) ||
                const DeepCollectionEquality().equals(
                  other.clientData,
                  clientData,
                )) &&
            (identical(other.settingsData, settingsData) ||
                const DeepCollectionEquality().equals(
                  other.settingsData,
                  settingsData,
                )) &&
            (identical(other.publicPage, publicPage) ||
                const DeepCollectionEquality().equals(
                  other.publicPage,
                  publicPage,
                )) &&
            (identical(other.previewAction, previewAction) ||
                const DeepCollectionEquality().equals(
                  other.previewAction,
                  previewAction,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(stubVersion) ^
      const DeepCollectionEquality().hash(shortDescription) ^
      const DeepCollectionEquality().hash(description) ^
      const DeepCollectionEquality().hash(ownerData) ^
      const DeepCollectionEquality().hash(clientData) ^
      const DeepCollectionEquality().hash(settingsData) ^
      const DeepCollectionEquality().hash(publicPage) ^
      const DeepCollectionEquality().hash(previewAction) ^
      runtimeType.hashCode;
}

extension $ExtensionDataExtension on ExtensionData {
  ExtensionData copyWith({
    String? id,
    String? name,
    String? stubVersion,
    String? shortDescription,
    String? description,
    DataFields? ownerData,
    DataFields? clientData,
    SettingsFields? settingsData,
    PublicPageFields? publicPage,
    PreviewAction? previewAction,
  }) {
    return ExtensionData(
      id: id ?? this.id,
      name: name ?? this.name,
      stubVersion: stubVersion ?? this.stubVersion,
      shortDescription: shortDescription ?? this.shortDescription,
      description: description ?? this.description,
      ownerData: ownerData ?? this.ownerData,
      clientData: clientData ?? this.clientData,
      settingsData: settingsData ?? this.settingsData,
      publicPage: publicPage ?? this.publicPage,
      previewAction: previewAction ?? this.previewAction,
    );
  }

  ExtensionData copyWithWrapped({
    Wrapped<String>? id,
    Wrapped<String>? name,
    Wrapped<String?>? stubVersion,
    Wrapped<String?>? shortDescription,
    Wrapped<String?>? description,
    Wrapped<DataFields>? ownerData,
    Wrapped<DataFields>? clientData,
    Wrapped<SettingsFields>? settingsData,
    Wrapped<PublicPageFields>? publicPage,
    Wrapped<PreviewAction?>? previewAction,
  }) {
    return ExtensionData(
      id: (id != null ? id.value : this.id),
      name: (name != null ? name.value : this.name),
      stubVersion: (stubVersion != null ? stubVersion.value : this.stubVersion),
      shortDescription: (shortDescription != null
          ? shortDescription.value
          : this.shortDescription),
      description: (description != null ? description.value : this.description),
      ownerData: (ownerData != null ? ownerData.value : this.ownerData),
      clientData: (clientData != null ? clientData.value : this.clientData),
      settingsData: (settingsData != null
          ? settingsData.value
          : this.settingsData),
      publicPage: (publicPage != null ? publicPage.value : this.publicPage),
      previewAction: (previewAction != null
          ? previewAction.value
          : this.previewAction),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ExtensionRelease {
  const ExtensionRelease({
    required this.name,
    required this.version,
    required this.archive,
    required this.sourceRepo,
    this.isGithubRelease,
    this.hash,
    this.minLnbitsVersion,
    this.maxLnbitsVersion,
    this.isVersionCompatible,
    this.htmlUrl,
    this.description,
    this.warning,
    this.repo,
    this.icon,
    this.detailsLink,
    this.paidFeatures,
    this.payLink,
    this.costSats,
    this.paidSats,
    this.paymentHash,
  });

  factory ExtensionRelease.fromJson(Map<String, dynamic> json) =>
      _$ExtensionReleaseFromJson(json);

  static const toJsonFactory = _$ExtensionReleaseToJson;
  Map<String, dynamic> toJson() => _$ExtensionReleaseToJson(this);

  @JsonKey(name: 'name', includeIfNull: false)
  final String name;
  @JsonKey(name: 'version', includeIfNull: false)
  final String version;
  @JsonKey(name: 'archive', includeIfNull: false)
  final String archive;
  @JsonKey(name: 'source_repo', includeIfNull: false)
  final String sourceRepo;
  @JsonKey(name: 'is_github_release', includeIfNull: false, defaultValue: false)
  final bool? isGithubRelease;
  @JsonKey(name: 'hash', includeIfNull: false)
  final String? hash;
  @JsonKey(name: 'min_lnbits_version', includeIfNull: false)
  final String? minLnbitsVersion;
  @JsonKey(name: 'max_lnbits_version', includeIfNull: false)
  final String? maxLnbitsVersion;
  @JsonKey(
    name: 'is_version_compatible',
    includeIfNull: false,
    defaultValue: true,
  )
  final bool? isVersionCompatible;
  @JsonKey(name: 'html_url', includeIfNull: false)
  final String? htmlUrl;
  @JsonKey(name: 'description', includeIfNull: false)
  final String? description;
  @JsonKey(name: 'warning', includeIfNull: false)
  final String? warning;
  @JsonKey(name: 'repo', includeIfNull: false)
  final String? repo;
  @JsonKey(name: 'icon', includeIfNull: false)
  final String? icon;
  @JsonKey(name: 'details_link', includeIfNull: false)
  final String? detailsLink;
  @JsonKey(name: 'paid_features', includeIfNull: false)
  final String? paidFeatures;
  @JsonKey(name: 'pay_link', includeIfNull: false)
  final String? payLink;
  @JsonKey(name: 'cost_sats', includeIfNull: false)
  final int? costSats;
  @JsonKey(name: 'paid_sats', includeIfNull: false)
  final int? paidSats;
  @JsonKey(name: 'payment_hash', includeIfNull: false)
  final String? paymentHash;
  static const fromJsonFactory = _$ExtensionReleaseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionRelease &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.version, version) ||
                const DeepCollectionEquality().equals(
                  other.version,
                  version,
                )) &&
            (identical(other.archive, archive) ||
                const DeepCollectionEquality().equals(
                  other.archive,
                  archive,
                )) &&
            (identical(other.sourceRepo, sourceRepo) ||
                const DeepCollectionEquality().equals(
                  other.sourceRepo,
                  sourceRepo,
                )) &&
            (identical(other.isGithubRelease, isGithubRelease) ||
                const DeepCollectionEquality().equals(
                  other.isGithubRelease,
                  isGithubRelease,
                )) &&
            (identical(other.hash, hash) ||
                const DeepCollectionEquality().equals(other.hash, hash)) &&
            (identical(other.minLnbitsVersion, minLnbitsVersion) ||
                const DeepCollectionEquality().equals(
                  other.minLnbitsVersion,
                  minLnbitsVersion,
                )) &&
            (identical(other.maxLnbitsVersion, maxLnbitsVersion) ||
                const DeepCollectionEquality().equals(
                  other.maxLnbitsVersion,
                  maxLnbitsVersion,
                )) &&
            (identical(other.isVersionCompatible, isVersionCompatible) ||
                const DeepCollectionEquality().equals(
                  other.isVersionCompatible,
                  isVersionCompatible,
                )) &&
            (identical(other.htmlUrl, htmlUrl) ||
                const DeepCollectionEquality().equals(
                  other.htmlUrl,
                  htmlUrl,
                )) &&
            (identical(other.description, description) ||
                const DeepCollectionEquality().equals(
                  other.description,
                  description,
                )) &&
            (identical(other.warning, warning) ||
                const DeepCollectionEquality().equals(
                  other.warning,
                  warning,
                )) &&
            (identical(other.repo, repo) ||
                const DeepCollectionEquality().equals(other.repo, repo)) &&
            (identical(other.icon, icon) ||
                const DeepCollectionEquality().equals(other.icon, icon)) &&
            (identical(other.detailsLink, detailsLink) ||
                const DeepCollectionEquality().equals(
                  other.detailsLink,
                  detailsLink,
                )) &&
            (identical(other.paidFeatures, paidFeatures) ||
                const DeepCollectionEquality().equals(
                  other.paidFeatures,
                  paidFeatures,
                )) &&
            (identical(other.payLink, payLink) ||
                const DeepCollectionEquality().equals(
                  other.payLink,
                  payLink,
                )) &&
            (identical(other.costSats, costSats) ||
                const DeepCollectionEquality().equals(
                  other.costSats,
                  costSats,
                )) &&
            (identical(other.paidSats, paidSats) ||
                const DeepCollectionEquality().equals(
                  other.paidSats,
                  paidSats,
                )) &&
            (identical(other.paymentHash, paymentHash) ||
                const DeepCollectionEquality().equals(
                  other.paymentHash,
                  paymentHash,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(version) ^
      const DeepCollectionEquality().hash(archive) ^
      const DeepCollectionEquality().hash(sourceRepo) ^
      const DeepCollectionEquality().hash(isGithubRelease) ^
      const DeepCollectionEquality().hash(hash) ^
      const DeepCollectionEquality().hash(minLnbitsVersion) ^
      const DeepCollectionEquality().hash(maxLnbitsVersion) ^
      const DeepCollectionEquality().hash(isVersionCompatible) ^
      const DeepCollectionEquality().hash(htmlUrl) ^
      const DeepCollectionEquality().hash(description) ^
      const DeepCollectionEquality().hash(warning) ^
      const DeepCollectionEquality().hash(repo) ^
      const DeepCollectionEquality().hash(icon) ^
      const DeepCollectionEquality().hash(detailsLink) ^
      const DeepCollectionEquality().hash(paidFeatures) ^
      const DeepCollectionEquality().hash(payLink) ^
      const DeepCollectionEquality().hash(costSats) ^
      const DeepCollectionEquality().hash(paidSats) ^
      const DeepCollectionEquality().hash(paymentHash) ^
      runtimeType.hashCode;
}

extension $ExtensionReleaseExtension on ExtensionRelease {
  ExtensionRelease copyWith({
    String? name,
    String? version,
    String? archive,
    String? sourceRepo,
    bool? isGithubRelease,
    String? hash,
    String? minLnbitsVersion,
    String? maxLnbitsVersion,
    bool? isVersionCompatible,
    String? htmlUrl,
    String? description,
    String? warning,
    String? repo,
    String? icon,
    String? detailsLink,
    String? paidFeatures,
    String? payLink,
    int? costSats,
    int? paidSats,
    String? paymentHash,
  }) {
    return ExtensionRelease(
      name: name ?? this.name,
      version: version ?? this.version,
      archive: archive ?? this.archive,
      sourceRepo: sourceRepo ?? this.sourceRepo,
      isGithubRelease: isGithubRelease ?? this.isGithubRelease,
      hash: hash ?? this.hash,
      minLnbitsVersion: minLnbitsVersion ?? this.minLnbitsVersion,
      maxLnbitsVersion: maxLnbitsVersion ?? this.maxLnbitsVersion,
      isVersionCompatible: isVersionCompatible ?? this.isVersionCompatible,
      htmlUrl: htmlUrl ?? this.htmlUrl,
      description: description ?? this.description,
      warning: warning ?? this.warning,
      repo: repo ?? this.repo,
      icon: icon ?? this.icon,
      detailsLink: detailsLink ?? this.detailsLink,
      paidFeatures: paidFeatures ?? this.paidFeatures,
      payLink: payLink ?? this.payLink,
      costSats: costSats ?? this.costSats,
      paidSats: paidSats ?? this.paidSats,
      paymentHash: paymentHash ?? this.paymentHash,
    );
  }

  ExtensionRelease copyWithWrapped({
    Wrapped<String>? name,
    Wrapped<String>? version,
    Wrapped<String>? archive,
    Wrapped<String>? sourceRepo,
    Wrapped<bool?>? isGithubRelease,
    Wrapped<String?>? hash,
    Wrapped<String?>? minLnbitsVersion,
    Wrapped<String?>? maxLnbitsVersion,
    Wrapped<bool?>? isVersionCompatible,
    Wrapped<String?>? htmlUrl,
    Wrapped<String?>? description,
    Wrapped<String?>? warning,
    Wrapped<String?>? repo,
    Wrapped<String?>? icon,
    Wrapped<String?>? detailsLink,
    Wrapped<String?>? paidFeatures,
    Wrapped<String?>? payLink,
    Wrapped<int?>? costSats,
    Wrapped<int?>? paidSats,
    Wrapped<String?>? paymentHash,
  }) {
    return ExtensionRelease(
      name: (name != null ? name.value : this.name),
      version: (version != null ? version.value : this.version),
      archive: (archive != null ? archive.value : this.archive),
      sourceRepo: (sourceRepo != null ? sourceRepo.value : this.sourceRepo),
      isGithubRelease: (isGithubRelease != null
          ? isGithubRelease.value
          : this.isGithubRelease),
      hash: (hash != null ? hash.value : this.hash),
      minLnbitsVersion: (minLnbitsVersion != null
          ? minLnbitsVersion.value
          : this.minLnbitsVersion),
      maxLnbitsVersion: (maxLnbitsVersion != null
          ? maxLnbitsVersion.value
          : this.maxLnbitsVersion),
      isVersionCompatible: (isVersionCompatible != null
          ? isVersionCompatible.value
          : this.isVersionCompatible),
      htmlUrl: (htmlUrl != null ? htmlUrl.value : this.htmlUrl),
      description: (description != null ? description.value : this.description),
      warning: (warning != null ? warning.value : this.warning),
      repo: (repo != null ? repo.value : this.repo),
      icon: (icon != null ? icon.value : this.icon),
      detailsLink: (detailsLink != null ? detailsLink.value : this.detailsLink),
      paidFeatures: (paidFeatures != null
          ? paidFeatures.value
          : this.paidFeatures),
      payLink: (payLink != null ? payLink.value : this.payLink),
      costSats: (costSats != null ? costSats.value : this.costSats),
      paidSats: (paidSats != null ? paidSats.value : this.paidSats),
      paymentHash: (paymentHash != null ? paymentHash.value : this.paymentHash),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ExtensionReviewPaymentRequest {
  const ExtensionReviewPaymentRequest({
    required this.paymentHash,
    required this.paymentRequest,
  });

  factory ExtensionReviewPaymentRequest.fromJson(Map<String, dynamic> json) =>
      _$ExtensionReviewPaymentRequestFromJson(json);

  static const toJsonFactory = _$ExtensionReviewPaymentRequestToJson;
  Map<String, dynamic> toJson() => _$ExtensionReviewPaymentRequestToJson(this);

  @JsonKey(name: 'payment_hash', includeIfNull: false)
  final String paymentHash;
  @JsonKey(name: 'payment_request', includeIfNull: false)
  final String paymentRequest;
  static const fromJsonFactory = _$ExtensionReviewPaymentRequestFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionReviewPaymentRequest &&
            (identical(other.paymentHash, paymentHash) ||
                const DeepCollectionEquality().equals(
                  other.paymentHash,
                  paymentHash,
                )) &&
            (identical(other.paymentRequest, paymentRequest) ||
                const DeepCollectionEquality().equals(
                  other.paymentRequest,
                  paymentRequest,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(paymentHash) ^
      const DeepCollectionEquality().hash(paymentRequest) ^
      runtimeType.hashCode;
}

extension $ExtensionReviewPaymentRequestExtension
    on ExtensionReviewPaymentRequest {
  ExtensionReviewPaymentRequest copyWith({
    String? paymentHash,
    String? paymentRequest,
  }) {
    return ExtensionReviewPaymentRequest(
      paymentHash: paymentHash ?? this.paymentHash,
      paymentRequest: paymentRequest ?? this.paymentRequest,
    );
  }

  ExtensionReviewPaymentRequest copyWithWrapped({
    Wrapped<String>? paymentHash,
    Wrapped<String>? paymentRequest,
  }) {
    return ExtensionReviewPaymentRequest(
      paymentHash: (paymentHash != null ? paymentHash.value : this.paymentHash),
      paymentRequest: (paymentRequest != null
          ? paymentRequest.value
          : this.paymentRequest),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ExtensionReviewsStatus {
  const ExtensionReviewsStatus({
    required this.tag,
    required this.avgRating,
    required this.reviewCount,
  });

  factory ExtensionReviewsStatus.fromJson(Map<String, dynamic> json) =>
      _$ExtensionReviewsStatusFromJson(json);

  static const toJsonFactory = _$ExtensionReviewsStatusToJson;
  Map<String, dynamic> toJson() => _$ExtensionReviewsStatusToJson(this);

  @JsonKey(name: 'tag', includeIfNull: false)
  final String tag;
  @JsonKey(name: 'avg_rating', includeIfNull: false)
  final double avgRating;
  @JsonKey(name: 'review_count', includeIfNull: false)
  final int reviewCount;
  static const fromJsonFactory = _$ExtensionReviewsStatusFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionReviewsStatus &&
            (identical(other.tag, tag) ||
                const DeepCollectionEquality().equals(other.tag, tag)) &&
            (identical(other.avgRating, avgRating) ||
                const DeepCollectionEquality().equals(
                  other.avgRating,
                  avgRating,
                )) &&
            (identical(other.reviewCount, reviewCount) ||
                const DeepCollectionEquality().equals(
                  other.reviewCount,
                  reviewCount,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(tag) ^
      const DeepCollectionEquality().hash(avgRating) ^
      const DeepCollectionEquality().hash(reviewCount) ^
      runtimeType.hashCode;
}

extension $ExtensionReviewsStatusExtension on ExtensionReviewsStatus {
  ExtensionReviewsStatus copyWith({
    String? tag,
    double? avgRating,
    int? reviewCount,
  }) {
    return ExtensionReviewsStatus(
      tag: tag ?? this.tag,
      avgRating: avgRating ?? this.avgRating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }

  ExtensionReviewsStatus copyWithWrapped({
    Wrapped<String>? tag,
    Wrapped<double>? avgRating,
    Wrapped<int>? reviewCount,
  }) {
    return ExtensionReviewsStatus(
      tag: (tag != null ? tag.value : this.tag),
      avgRating: (avgRating != null ? avgRating.value : this.avgRating),
      reviewCount: (reviewCount != null ? reviewCount.value : this.reviewCount),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FiatProviderLimits {
  const FiatProviderLimits({
    this.allowedUsers,
    this.serviceMaxFeeSats,
    this.serviceFeePercent,
    this.serviceFeeWalletId,
    this.serviceMinAmountSats,
    this.serviceMaxAmountSats,
    this.serviceFaucetWalletId,
  });

  factory FiatProviderLimits.fromJson(Map<String, dynamic> json) =>
      _$FiatProviderLimitsFromJson(json);

  static const toJsonFactory = _$FiatProviderLimitsToJson;
  Map<String, dynamic> toJson() => _$FiatProviderLimitsToJson(this);

  @JsonKey(
    name: 'allowed_users',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? allowedUsers;
  @JsonKey(name: 'service_max_fee_sats', includeIfNull: false)
  final int? serviceMaxFeeSats;
  @JsonKey(name: 'service_fee_percent', includeIfNull: false)
  final double? serviceFeePercent;
  @JsonKey(name: 'service_fee_wallet_id', includeIfNull: false)
  final String? serviceFeeWalletId;
  @JsonKey(name: 'service_min_amount_sats', includeIfNull: false)
  final int? serviceMinAmountSats;
  @JsonKey(name: 'service_max_amount_sats', includeIfNull: false)
  final int? serviceMaxAmountSats;
  @JsonKey(name: 'service_faucet_wallet_id', includeIfNull: false)
  final String? serviceFaucetWalletId;
  static const fromJsonFactory = _$FiatProviderLimitsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FiatProviderLimits &&
            (identical(other.allowedUsers, allowedUsers) ||
                const DeepCollectionEquality().equals(
                  other.allowedUsers,
                  allowedUsers,
                )) &&
            (identical(other.serviceMaxFeeSats, serviceMaxFeeSats) ||
                const DeepCollectionEquality().equals(
                  other.serviceMaxFeeSats,
                  serviceMaxFeeSats,
                )) &&
            (identical(other.serviceFeePercent, serviceFeePercent) ||
                const DeepCollectionEquality().equals(
                  other.serviceFeePercent,
                  serviceFeePercent,
                )) &&
            (identical(other.serviceFeeWalletId, serviceFeeWalletId) ||
                const DeepCollectionEquality().equals(
                  other.serviceFeeWalletId,
                  serviceFeeWalletId,
                )) &&
            (identical(other.serviceMinAmountSats, serviceMinAmountSats) ||
                const DeepCollectionEquality().equals(
                  other.serviceMinAmountSats,
                  serviceMinAmountSats,
                )) &&
            (identical(other.serviceMaxAmountSats, serviceMaxAmountSats) ||
                const DeepCollectionEquality().equals(
                  other.serviceMaxAmountSats,
                  serviceMaxAmountSats,
                )) &&
            (identical(other.serviceFaucetWalletId, serviceFaucetWalletId) ||
                const DeepCollectionEquality().equals(
                  other.serviceFaucetWalletId,
                  serviceFaucetWalletId,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(allowedUsers) ^
      const DeepCollectionEquality().hash(serviceMaxFeeSats) ^
      const DeepCollectionEquality().hash(serviceFeePercent) ^
      const DeepCollectionEquality().hash(serviceFeeWalletId) ^
      const DeepCollectionEquality().hash(serviceMinAmountSats) ^
      const DeepCollectionEquality().hash(serviceMaxAmountSats) ^
      const DeepCollectionEquality().hash(serviceFaucetWalletId) ^
      runtimeType.hashCode;
}

extension $FiatProviderLimitsExtension on FiatProviderLimits {
  FiatProviderLimits copyWith({
    List<String>? allowedUsers,
    int? serviceMaxFeeSats,
    double? serviceFeePercent,
    String? serviceFeeWalletId,
    int? serviceMinAmountSats,
    int? serviceMaxAmountSats,
    String? serviceFaucetWalletId,
  }) {
    return FiatProviderLimits(
      allowedUsers: allowedUsers ?? this.allowedUsers,
      serviceMaxFeeSats: serviceMaxFeeSats ?? this.serviceMaxFeeSats,
      serviceFeePercent: serviceFeePercent ?? this.serviceFeePercent,
      serviceFeeWalletId: serviceFeeWalletId ?? this.serviceFeeWalletId,
      serviceMinAmountSats: serviceMinAmountSats ?? this.serviceMinAmountSats,
      serviceMaxAmountSats: serviceMaxAmountSats ?? this.serviceMaxAmountSats,
      serviceFaucetWalletId:
          serviceFaucetWalletId ?? this.serviceFaucetWalletId,
    );
  }

  FiatProviderLimits copyWithWrapped({
    Wrapped<List<String>?>? allowedUsers,
    Wrapped<int?>? serviceMaxFeeSats,
    Wrapped<double?>? serviceFeePercent,
    Wrapped<String?>? serviceFeeWalletId,
    Wrapped<int?>? serviceMinAmountSats,
    Wrapped<int?>? serviceMaxAmountSats,
    Wrapped<String?>? serviceFaucetWalletId,
  }) {
    return FiatProviderLimits(
      allowedUsers: (allowedUsers != null
          ? allowedUsers.value
          : this.allowedUsers),
      serviceMaxFeeSats: (serviceMaxFeeSats != null
          ? serviceMaxFeeSats.value
          : this.serviceMaxFeeSats),
      serviceFeePercent: (serviceFeePercent != null
          ? serviceFeePercent.value
          : this.serviceFeePercent),
      serviceFeeWalletId: (serviceFeeWalletId != null
          ? serviceFeeWalletId.value
          : this.serviceFeeWalletId),
      serviceMinAmountSats: (serviceMinAmountSats != null
          ? serviceMinAmountSats.value
          : this.serviceMinAmountSats),
      serviceMaxAmountSats: (serviceMaxAmountSats != null
          ? serviceMaxAmountSats.value
          : this.serviceMaxAmountSats),
      serviceFaucetWalletId: (serviceFaucetWalletId != null
          ? serviceFaucetWalletId.value
          : this.serviceFaucetWalletId),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FiatSubscriptionPaymentOptions {
  const FiatSubscriptionPaymentOptions({
    this.memo,
    this.walletId,
    this.subscriptionRequestId,
    this.tag,
    this.extra,
    this.successUrl,
  });

  factory FiatSubscriptionPaymentOptions.fromJson(Map<String, dynamic> json) =>
      _$FiatSubscriptionPaymentOptionsFromJson(json);

  static const toJsonFactory = _$FiatSubscriptionPaymentOptionsToJson;
  Map<String, dynamic> toJson() => _$FiatSubscriptionPaymentOptionsToJson(this);

  @JsonKey(name: 'memo', includeIfNull: false)
  final String? memo;
  @JsonKey(name: 'wallet_id', includeIfNull: false)
  final String? walletId;
  @JsonKey(name: 'subscription_request_id', includeIfNull: false)
  final String? subscriptionRequestId;
  @JsonKey(name: 'tag', includeIfNull: false)
  final String? tag;
  @JsonKey(name: 'extra', includeIfNull: false)
  final Object? extra;
  @JsonKey(name: 'success_url', includeIfNull: false)
  final String? successUrl;
  static const fromJsonFactory = _$FiatSubscriptionPaymentOptionsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FiatSubscriptionPaymentOptions &&
            (identical(other.memo, memo) ||
                const DeepCollectionEquality().equals(other.memo, memo)) &&
            (identical(other.walletId, walletId) ||
                const DeepCollectionEquality().equals(
                  other.walletId,
                  walletId,
                )) &&
            (identical(other.subscriptionRequestId, subscriptionRequestId) ||
                const DeepCollectionEquality().equals(
                  other.subscriptionRequestId,
                  subscriptionRequestId,
                )) &&
            (identical(other.tag, tag) ||
                const DeepCollectionEquality().equals(other.tag, tag)) &&
            (identical(other.extra, extra) ||
                const DeepCollectionEquality().equals(other.extra, extra)) &&
            (identical(other.successUrl, successUrl) ||
                const DeepCollectionEquality().equals(
                  other.successUrl,
                  successUrl,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(memo) ^
      const DeepCollectionEquality().hash(walletId) ^
      const DeepCollectionEquality().hash(subscriptionRequestId) ^
      const DeepCollectionEquality().hash(tag) ^
      const DeepCollectionEquality().hash(extra) ^
      const DeepCollectionEquality().hash(successUrl) ^
      runtimeType.hashCode;
}

extension $FiatSubscriptionPaymentOptionsExtension
    on FiatSubscriptionPaymentOptions {
  FiatSubscriptionPaymentOptions copyWith({
    String? memo,
    String? walletId,
    String? subscriptionRequestId,
    String? tag,
    Object? extra,
    String? successUrl,
  }) {
    return FiatSubscriptionPaymentOptions(
      memo: memo ?? this.memo,
      walletId: walletId ?? this.walletId,
      subscriptionRequestId:
          subscriptionRequestId ?? this.subscriptionRequestId,
      tag: tag ?? this.tag,
      extra: extra ?? this.extra,
      successUrl: successUrl ?? this.successUrl,
    );
  }

  FiatSubscriptionPaymentOptions copyWithWrapped({
    Wrapped<String?>? memo,
    Wrapped<String?>? walletId,
    Wrapped<String?>? subscriptionRequestId,
    Wrapped<String?>? tag,
    Wrapped<Object?>? extra,
    Wrapped<String?>? successUrl,
  }) {
    return FiatSubscriptionPaymentOptions(
      memo: (memo != null ? memo.value : this.memo),
      walletId: (walletId != null ? walletId.value : this.walletId),
      subscriptionRequestId: (subscriptionRequestId != null
          ? subscriptionRequestId.value
          : this.subscriptionRequestId),
      tag: (tag != null ? tag.value : this.tag),
      extra: (extra != null ? extra.value : this.extra),
      successUrl: (successUrl != null ? successUrl.value : this.successUrl),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FiatSubscriptionResponse {
  const FiatSubscriptionResponse({
    this.ok,
    this.subscriptionRequestId,
    this.checkoutSessionUrl,
    this.errorMessage,
  });

  factory FiatSubscriptionResponse.fromJson(Map<String, dynamic> json) =>
      _$FiatSubscriptionResponseFromJson(json);

  static const toJsonFactory = _$FiatSubscriptionResponseToJson;
  Map<String, dynamic> toJson() => _$FiatSubscriptionResponseToJson(this);

  @JsonKey(name: 'ok', includeIfNull: false, defaultValue: true)
  final bool? ok;
  @JsonKey(name: 'subscription_request_id', includeIfNull: false)
  final String? subscriptionRequestId;
  @JsonKey(name: 'checkout_session_url', includeIfNull: false)
  final String? checkoutSessionUrl;
  @JsonKey(name: 'error_message', includeIfNull: false)
  final String? errorMessage;
  static const fromJsonFactory = _$FiatSubscriptionResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FiatSubscriptionResponse &&
            (identical(other.ok, ok) ||
                const DeepCollectionEquality().equals(other.ok, ok)) &&
            (identical(other.subscriptionRequestId, subscriptionRequestId) ||
                const DeepCollectionEquality().equals(
                  other.subscriptionRequestId,
                  subscriptionRequestId,
                )) &&
            (identical(other.checkoutSessionUrl, checkoutSessionUrl) ||
                const DeepCollectionEquality().equals(
                  other.checkoutSessionUrl,
                  checkoutSessionUrl,
                )) &&
            (identical(other.errorMessage, errorMessage) ||
                const DeepCollectionEquality().equals(
                  other.errorMessage,
                  errorMessage,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(ok) ^
      const DeepCollectionEquality().hash(subscriptionRequestId) ^
      const DeepCollectionEquality().hash(checkoutSessionUrl) ^
      const DeepCollectionEquality().hash(errorMessage) ^
      runtimeType.hashCode;
}

extension $FiatSubscriptionResponseExtension on FiatSubscriptionResponse {
  FiatSubscriptionResponse copyWith({
    bool? ok,
    String? subscriptionRequestId,
    String? checkoutSessionUrl,
    String? errorMessage,
  }) {
    return FiatSubscriptionResponse(
      ok: ok ?? this.ok,
      subscriptionRequestId:
          subscriptionRequestId ?? this.subscriptionRequestId,
      checkoutSessionUrl: checkoutSessionUrl ?? this.checkoutSessionUrl,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  FiatSubscriptionResponse copyWithWrapped({
    Wrapped<bool?>? ok,
    Wrapped<String?>? subscriptionRequestId,
    Wrapped<String?>? checkoutSessionUrl,
    Wrapped<String?>? errorMessage,
  }) {
    return FiatSubscriptionResponse(
      ok: (ok != null ? ok.value : this.ok),
      subscriptionRequestId: (subscriptionRequestId != null
          ? subscriptionRequestId.value
          : this.subscriptionRequestId),
      checkoutSessionUrl: (checkoutSessionUrl != null
          ? checkoutSessionUrl.value
          : this.checkoutSessionUrl),
      errorMessage: (errorMessage != null
          ? errorMessage.value
          : this.errorMessage),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class HTTPValidationError {
  const HTTPValidationError({this.detail});

  factory HTTPValidationError.fromJson(Map<String, dynamic> json) =>
      _$HTTPValidationErrorFromJson(json);

  static const toJsonFactory = _$HTTPValidationErrorToJson;
  Map<String, dynamic> toJson() => _$HTTPValidationErrorToJson(this);

  @JsonKey(
    name: 'detail',
    includeIfNull: false,
    defaultValue: <ValidationError>[],
  )
  final List<ValidationError>? detail;
  static const fromJsonFactory = _$HTTPValidationErrorFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is HTTPValidationError &&
            (identical(other.detail, detail) ||
                const DeepCollectionEquality().equals(other.detail, detail)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(detail) ^ runtimeType.hashCode;
}

extension $HTTPValidationErrorExtension on HTTPValidationError {
  HTTPValidationError copyWith({List<ValidationError>? detail}) {
    return HTTPValidationError(detail: detail ?? this.detail);
  }

  HTTPValidationError copyWithWrapped({
    Wrapped<List<ValidationError>?>? detail,
  }) {
    return HTTPValidationError(
      detail: (detail != null ? detail.value : this.detail),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class InvoiceResponse {
  const InvoiceResponse({
    required this.ok,
    required this.checkingId,
    required this.paymentRequest,
    required this.errorMessage,
    required this.preimage,
    required this.feeMsat,
  });

  factory InvoiceResponse.fromJson(Map<String, dynamic> json) =>
      _$InvoiceResponseFromJson(json);

  static const toJsonFactory = _$InvoiceResponseToJson;
  Map<String, dynamic> toJson() => _$InvoiceResponseToJson(this);

  @JsonKey(name: 'ok', includeIfNull: false)
  final bool ok;
  @JsonKey(name: 'checking_id', includeIfNull: false)
  final String checkingId;
  @JsonKey(name: 'payment_request', includeIfNull: false)
  final String paymentRequest;
  @JsonKey(name: 'error_message', includeIfNull: false)
  final String errorMessage;
  @JsonKey(name: 'preimage', includeIfNull: false)
  final String preimage;
  @JsonKey(name: 'fee_msat', includeIfNull: false)
  final int feeMsat;
  static const fromJsonFactory = _$InvoiceResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is InvoiceResponse &&
            (identical(other.ok, ok) ||
                const DeepCollectionEquality().equals(other.ok, ok)) &&
            (identical(other.checkingId, checkingId) ||
                const DeepCollectionEquality().equals(
                  other.checkingId,
                  checkingId,
                )) &&
            (identical(other.paymentRequest, paymentRequest) ||
                const DeepCollectionEquality().equals(
                  other.paymentRequest,
                  paymentRequest,
                )) &&
            (identical(other.errorMessage, errorMessage) ||
                const DeepCollectionEquality().equals(
                  other.errorMessage,
                  errorMessage,
                )) &&
            (identical(other.preimage, preimage) ||
                const DeepCollectionEquality().equals(
                  other.preimage,
                  preimage,
                )) &&
            (identical(other.feeMsat, feeMsat) ||
                const DeepCollectionEquality().equals(other.feeMsat, feeMsat)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(ok) ^
      const DeepCollectionEquality().hash(checkingId) ^
      const DeepCollectionEquality().hash(paymentRequest) ^
      const DeepCollectionEquality().hash(errorMessage) ^
      const DeepCollectionEquality().hash(preimage) ^
      const DeepCollectionEquality().hash(feeMsat) ^
      runtimeType.hashCode;
}

extension $InvoiceResponseExtension on InvoiceResponse {
  InvoiceResponse copyWith({
    bool? ok,
    String? checkingId,
    String? paymentRequest,
    String? errorMessage,
    String? preimage,
    int? feeMsat,
  }) {
    return InvoiceResponse(
      ok: ok ?? this.ok,
      checkingId: checkingId ?? this.checkingId,
      paymentRequest: paymentRequest ?? this.paymentRequest,
      errorMessage: errorMessage ?? this.errorMessage,
      preimage: preimage ?? this.preimage,
      feeMsat: feeMsat ?? this.feeMsat,
    );
  }

  InvoiceResponse copyWithWrapped({
    Wrapped<bool>? ok,
    Wrapped<String>? checkingId,
    Wrapped<String>? paymentRequest,
    Wrapped<String>? errorMessage,
    Wrapped<String>? preimage,
    Wrapped<int>? feeMsat,
  }) {
    return InvoiceResponse(
      ok: (ok != null ? ok.value : this.ok),
      checkingId: (checkingId != null ? checkingId.value : this.checkingId),
      paymentRequest: (paymentRequest != null
          ? paymentRequest.value
          : this.paymentRequest),
      errorMessage: (errorMessage != null
          ? errorMessage.value
          : this.errorMessage),
      preimage: (preimage != null ? preimage.value : this.preimage),
      feeMsat: (feeMsat != null ? feeMsat.value : this.feeMsat),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class LnurlAuthResponse {
  const LnurlAuthResponse({this.tag, required this.callback, required this.k1});

  factory LnurlAuthResponse.fromJson(Map<String, dynamic> json) =>
      _$LnurlAuthResponseFromJson(json);

  static const toJsonFactory = _$LnurlAuthResponseToJson;
  Map<String, dynamic> toJson() => _$LnurlAuthResponseToJson(this);

  @JsonKey(
    name: 'tag',
    includeIfNull: false,
    toJson: lnurlResponseTagNullableToJson,
    fromJson: lnurlResponseTagTagNullableFromJson,
  )
  final enums.LnurlResponseTag? tag;
  static enums.LnurlResponseTag? lnurlResponseTagTagNullableFromJson(
    Object? value,
  ) => lnurlResponseTagNullableFromJson(value, enums.LnurlResponseTag.login);

  @JsonKey(name: 'callback', includeIfNull: false)
  final String callback;
  @JsonKey(name: 'k1', includeIfNull: false)
  final String k1;
  static const fromJsonFactory = _$LnurlAuthResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LnurlAuthResponse &&
            (identical(other.tag, tag) ||
                const DeepCollectionEquality().equals(other.tag, tag)) &&
            (identical(other.callback, callback) ||
                const DeepCollectionEquality().equals(
                  other.callback,
                  callback,
                )) &&
            (identical(other.k1, k1) ||
                const DeepCollectionEquality().equals(other.k1, k1)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(tag) ^
      const DeepCollectionEquality().hash(callback) ^
      const DeepCollectionEquality().hash(k1) ^
      runtimeType.hashCode;
}

extension $LnurlAuthResponseExtension on LnurlAuthResponse {
  LnurlAuthResponse copyWith({
    enums.LnurlResponseTag? tag,
    String? callback,
    String? k1,
  }) {
    return LnurlAuthResponse(
      tag: tag ?? this.tag,
      callback: callback ?? this.callback,
      k1: k1 ?? this.k1,
    );
  }

  LnurlAuthResponse copyWithWrapped({
    Wrapped<enums.LnurlResponseTag?>? tag,
    Wrapped<String>? callback,
    Wrapped<String>? k1,
  }) {
    return LnurlAuthResponse(
      tag: (tag != null ? tag.value : this.tag),
      callback: (callback != null ? callback.value : this.callback),
      k1: (k1 != null ? k1.value : this.k1),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class LnurlErrorResponse {
  const LnurlErrorResponse({this.status, required this.reason});

  factory LnurlErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$LnurlErrorResponseFromJson(json);

  static const toJsonFactory = _$LnurlErrorResponseToJson;
  Map<String, dynamic> toJson() => _$LnurlErrorResponseToJson(this);

  @JsonKey(
    name: 'status',
    includeIfNull: false,
    toJson: lnurlStatusNullableToJson,
    fromJson: lnurlStatusStatusNullableFromJson,
  )
  final enums.LnurlStatus? status;
  static enums.LnurlStatus? lnurlStatusStatusNullableFromJson(Object? value) =>
      lnurlStatusNullableFromJson(value, enums.LnurlStatus.error);

  @JsonKey(name: 'reason', includeIfNull: false)
  final String reason;
  static const fromJsonFactory = _$LnurlErrorResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LnurlErrorResponse &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)) &&
            (identical(other.reason, reason) ||
                const DeepCollectionEquality().equals(other.reason, reason)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(status) ^
      const DeepCollectionEquality().hash(reason) ^
      runtimeType.hashCode;
}

extension $LnurlErrorResponseExtension on LnurlErrorResponse {
  LnurlErrorResponse copyWith({enums.LnurlStatus? status, String? reason}) {
    return LnurlErrorResponse(
      status: status ?? this.status,
      reason: reason ?? this.reason,
    );
  }

  LnurlErrorResponse copyWithWrapped({
    Wrapped<enums.LnurlStatus?>? status,
    Wrapped<String>? reason,
  }) {
    return LnurlErrorResponse(
      status: (status != null ? status.value : this.status),
      reason: (reason != null ? reason.value : this.reason),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class LnurlPayResponse {
  const LnurlPayResponse({
    this.tag,
    required this.callback,
    required this.minSendable,
    required this.maxSendable,
    required this.metadata,
    this.payerData,
    this.commentAllowed,
    this.allowsNostr,
    this.nostrPubkey,
  });

  factory LnurlPayResponse.fromJson(Map<String, dynamic> json) =>
      _$LnurlPayResponseFromJson(json);

  static const toJsonFactory = _$LnurlPayResponseToJson;
  Map<String, dynamic> toJson() => _$LnurlPayResponseToJson(this);

  @JsonKey(
    name: 'tag',
    includeIfNull: false,
    toJson: lnurlResponseTagNullableToJson,
    fromJson: lnurlResponseTagTagNullableFromJson,
  )
  final enums.LnurlResponseTag? tag;
  static enums.LnurlResponseTag? lnurlResponseTagTagNullableFromJson(
    Object? value,
  ) => lnurlResponseTagNullableFromJson(
    value,
    enums.LnurlResponseTag.payrequest,
  );

  @JsonKey(name: 'callback', includeIfNull: false)
  final String callback;
  @JsonKey(name: 'minSendable', includeIfNull: false)
  final int minSendable;
  @JsonKey(name: 'maxSendable', includeIfNull: false)
  final int maxSendable;
  @JsonKey(name: 'metadata', includeIfNull: false)
  final String metadata;
  @JsonKey(name: 'payerData', includeIfNull: false)
  final LnurlPayResponsePayerData? payerData;
  @JsonKey(name: 'commentAllowed', includeIfNull: false)
  final int? commentAllowed;
  @JsonKey(name: 'allowsNostr', includeIfNull: false)
  final bool? allowsNostr;
  @JsonKey(name: 'nostrPubkey', includeIfNull: false)
  final String? nostrPubkey;
  static const fromJsonFactory = _$LnurlPayResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LnurlPayResponse &&
            (identical(other.tag, tag) ||
                const DeepCollectionEquality().equals(other.tag, tag)) &&
            (identical(other.callback, callback) ||
                const DeepCollectionEquality().equals(
                  other.callback,
                  callback,
                )) &&
            (identical(other.minSendable, minSendable) ||
                const DeepCollectionEquality().equals(
                  other.minSendable,
                  minSendable,
                )) &&
            (identical(other.maxSendable, maxSendable) ||
                const DeepCollectionEquality().equals(
                  other.maxSendable,
                  maxSendable,
                )) &&
            (identical(other.metadata, metadata) ||
                const DeepCollectionEquality().equals(
                  other.metadata,
                  metadata,
                )) &&
            (identical(other.payerData, payerData) ||
                const DeepCollectionEquality().equals(
                  other.payerData,
                  payerData,
                )) &&
            (identical(other.commentAllowed, commentAllowed) ||
                const DeepCollectionEquality().equals(
                  other.commentAllowed,
                  commentAllowed,
                )) &&
            (identical(other.allowsNostr, allowsNostr) ||
                const DeepCollectionEquality().equals(
                  other.allowsNostr,
                  allowsNostr,
                )) &&
            (identical(other.nostrPubkey, nostrPubkey) ||
                const DeepCollectionEquality().equals(
                  other.nostrPubkey,
                  nostrPubkey,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(tag) ^
      const DeepCollectionEquality().hash(callback) ^
      const DeepCollectionEquality().hash(minSendable) ^
      const DeepCollectionEquality().hash(maxSendable) ^
      const DeepCollectionEquality().hash(metadata) ^
      const DeepCollectionEquality().hash(payerData) ^
      const DeepCollectionEquality().hash(commentAllowed) ^
      const DeepCollectionEquality().hash(allowsNostr) ^
      const DeepCollectionEquality().hash(nostrPubkey) ^
      runtimeType.hashCode;
}

extension $LnurlPayResponseExtension on LnurlPayResponse {
  LnurlPayResponse copyWith({
    enums.LnurlResponseTag? tag,
    String? callback,
    int? minSendable,
    int? maxSendable,
    String? metadata,
    LnurlPayResponsePayerData? payerData,
    int? commentAllowed,
    bool? allowsNostr,
    String? nostrPubkey,
  }) {
    return LnurlPayResponse(
      tag: tag ?? this.tag,
      callback: callback ?? this.callback,
      minSendable: minSendable ?? this.minSendable,
      maxSendable: maxSendable ?? this.maxSendable,
      metadata: metadata ?? this.metadata,
      payerData: payerData ?? this.payerData,
      commentAllowed: commentAllowed ?? this.commentAllowed,
      allowsNostr: allowsNostr ?? this.allowsNostr,
      nostrPubkey: nostrPubkey ?? this.nostrPubkey,
    );
  }

  LnurlPayResponse copyWithWrapped({
    Wrapped<enums.LnurlResponseTag?>? tag,
    Wrapped<String>? callback,
    Wrapped<int>? minSendable,
    Wrapped<int>? maxSendable,
    Wrapped<String>? metadata,
    Wrapped<LnurlPayResponsePayerData?>? payerData,
    Wrapped<int?>? commentAllowed,
    Wrapped<bool?>? allowsNostr,
    Wrapped<String?>? nostrPubkey,
  }) {
    return LnurlPayResponse(
      tag: (tag != null ? tag.value : this.tag),
      callback: (callback != null ? callback.value : this.callback),
      minSendable: (minSendable != null ? minSendable.value : this.minSendable),
      maxSendable: (maxSendable != null ? maxSendable.value : this.maxSendable),
      metadata: (metadata != null ? metadata.value : this.metadata),
      payerData: (payerData != null ? payerData.value : this.payerData),
      commentAllowed: (commentAllowed != null
          ? commentAllowed.value
          : this.commentAllowed),
      allowsNostr: (allowsNostr != null ? allowsNostr.value : this.allowsNostr),
      nostrPubkey: (nostrPubkey != null ? nostrPubkey.value : this.nostrPubkey),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class LnurlPayResponsePayerData {
  const LnurlPayResponsePayerData({
    this.name,
    this.pubkey,
    this.identifier,
    this.email,
    this.auth,
    this.extras,
  });

  factory LnurlPayResponsePayerData.fromJson(Map<String, dynamic> json) =>
      _$LnurlPayResponsePayerDataFromJson(json);

  static const toJsonFactory = _$LnurlPayResponsePayerDataToJson;
  Map<String, dynamic> toJson() => _$LnurlPayResponsePayerDataToJson(this);

  @JsonKey(name: 'name', includeIfNull: false)
  final LnurlPayResponsePayerDataOption? name;
  @JsonKey(name: 'pubkey', includeIfNull: false)
  final LnurlPayResponsePayerDataOption? pubkey;
  @JsonKey(name: 'identifier', includeIfNull: false)
  final LnurlPayResponsePayerDataOption? identifier;
  @JsonKey(name: 'email', includeIfNull: false)
  final LnurlPayResponsePayerDataOption? email;
  @JsonKey(name: 'auth', includeIfNull: false)
  final LnurlPayResponsePayerDataOptionAuth? auth;
  @JsonKey(
    name: 'extras',
    includeIfNull: false,
    defaultValue: <LnurlPayResponsePayerDataExtra>[],
  )
  final List<LnurlPayResponsePayerDataExtra>? extras;
  static const fromJsonFactory = _$LnurlPayResponsePayerDataFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LnurlPayResponsePayerData &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.pubkey, pubkey) ||
                const DeepCollectionEquality().equals(other.pubkey, pubkey)) &&
            (identical(other.identifier, identifier) ||
                const DeepCollectionEquality().equals(
                  other.identifier,
                  identifier,
                )) &&
            (identical(other.email, email) ||
                const DeepCollectionEquality().equals(other.email, email)) &&
            (identical(other.auth, auth) ||
                const DeepCollectionEquality().equals(other.auth, auth)) &&
            (identical(other.extras, extras) ||
                const DeepCollectionEquality().equals(other.extras, extras)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(pubkey) ^
      const DeepCollectionEquality().hash(identifier) ^
      const DeepCollectionEquality().hash(email) ^
      const DeepCollectionEquality().hash(auth) ^
      const DeepCollectionEquality().hash(extras) ^
      runtimeType.hashCode;
}

extension $LnurlPayResponsePayerDataExtension on LnurlPayResponsePayerData {
  LnurlPayResponsePayerData copyWith({
    LnurlPayResponsePayerDataOption? name,
    LnurlPayResponsePayerDataOption? pubkey,
    LnurlPayResponsePayerDataOption? identifier,
    LnurlPayResponsePayerDataOption? email,
    LnurlPayResponsePayerDataOptionAuth? auth,
    List<LnurlPayResponsePayerDataExtra>? extras,
  }) {
    return LnurlPayResponsePayerData(
      name: name ?? this.name,
      pubkey: pubkey ?? this.pubkey,
      identifier: identifier ?? this.identifier,
      email: email ?? this.email,
      auth: auth ?? this.auth,
      extras: extras ?? this.extras,
    );
  }

  LnurlPayResponsePayerData copyWithWrapped({
    Wrapped<LnurlPayResponsePayerDataOption?>? name,
    Wrapped<LnurlPayResponsePayerDataOption?>? pubkey,
    Wrapped<LnurlPayResponsePayerDataOption?>? identifier,
    Wrapped<LnurlPayResponsePayerDataOption?>? email,
    Wrapped<LnurlPayResponsePayerDataOptionAuth?>? auth,
    Wrapped<List<LnurlPayResponsePayerDataExtra>?>? extras,
  }) {
    return LnurlPayResponsePayerData(
      name: (name != null ? name.value : this.name),
      pubkey: (pubkey != null ? pubkey.value : this.pubkey),
      identifier: (identifier != null ? identifier.value : this.identifier),
      email: (email != null ? email.value : this.email),
      auth: (auth != null ? auth.value : this.auth),
      extras: (extras != null ? extras.value : this.extras),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class LnurlPayResponsePayerDataExtra {
  const LnurlPayResponsePayerDataExtra({
    required this.name,
    required this.field,
  });

  factory LnurlPayResponsePayerDataExtra.fromJson(Map<String, dynamic> json) =>
      _$LnurlPayResponsePayerDataExtraFromJson(json);

  static const toJsonFactory = _$LnurlPayResponsePayerDataExtraToJson;
  Map<String, dynamic> toJson() => _$LnurlPayResponsePayerDataExtraToJson(this);

  @JsonKey(name: 'name', includeIfNull: false)
  final String name;
  @JsonKey(name: 'field', includeIfNull: false)
  final LnurlPayResponsePayerDataOption field;
  static const fromJsonFactory = _$LnurlPayResponsePayerDataExtraFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LnurlPayResponsePayerDataExtra &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.field, field) ||
                const DeepCollectionEquality().equals(other.field, field)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(field) ^
      runtimeType.hashCode;
}

extension $LnurlPayResponsePayerDataExtraExtension
    on LnurlPayResponsePayerDataExtra {
  LnurlPayResponsePayerDataExtra copyWith({
    String? name,
    LnurlPayResponsePayerDataOption? field,
  }) {
    return LnurlPayResponsePayerDataExtra(
      name: name ?? this.name,
      field: field ?? this.field,
    );
  }

  LnurlPayResponsePayerDataExtra copyWithWrapped({
    Wrapped<String>? name,
    Wrapped<LnurlPayResponsePayerDataOption>? field,
  }) {
    return LnurlPayResponsePayerDataExtra(
      name: (name != null ? name.value : this.name),
      field: (field != null ? field.value : this.field),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class LnurlPayResponsePayerDataOption {
  const LnurlPayResponsePayerDataOption({required this.mandatory});

  factory LnurlPayResponsePayerDataOption.fromJson(Map<String, dynamic> json) =>
      _$LnurlPayResponsePayerDataOptionFromJson(json);

  static const toJsonFactory = _$LnurlPayResponsePayerDataOptionToJson;
  Map<String, dynamic> toJson() =>
      _$LnurlPayResponsePayerDataOptionToJson(this);

  @JsonKey(name: 'mandatory', includeIfNull: false)
  final bool mandatory;
  static const fromJsonFactory = _$LnurlPayResponsePayerDataOptionFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LnurlPayResponsePayerDataOption &&
            (identical(other.mandatory, mandatory) ||
                const DeepCollectionEquality().equals(
                  other.mandatory,
                  mandatory,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(mandatory) ^ runtimeType.hashCode;
}

extension $LnurlPayResponsePayerDataOptionExtension
    on LnurlPayResponsePayerDataOption {
  LnurlPayResponsePayerDataOption copyWith({bool? mandatory}) {
    return LnurlPayResponsePayerDataOption(
      mandatory: mandatory ?? this.mandatory,
    );
  }

  LnurlPayResponsePayerDataOption copyWithWrapped({Wrapped<bool>? mandatory}) {
    return LnurlPayResponsePayerDataOption(
      mandatory: (mandatory != null ? mandatory.value : this.mandatory),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class LnurlPayResponsePayerDataOptionAuth {
  const LnurlPayResponsePayerDataOptionAuth({
    required this.mandatory,
    required this.k1,
  });

  factory LnurlPayResponsePayerDataOptionAuth.fromJson(
    Map<String, dynamic> json,
  ) => _$LnurlPayResponsePayerDataOptionAuthFromJson(json);

  static const toJsonFactory = _$LnurlPayResponsePayerDataOptionAuthToJson;
  Map<String, dynamic> toJson() =>
      _$LnurlPayResponsePayerDataOptionAuthToJson(this);

  @JsonKey(name: 'mandatory', includeIfNull: false)
  final bool mandatory;
  @JsonKey(name: 'k1', includeIfNull: false)
  final String k1;
  static const fromJsonFactory = _$LnurlPayResponsePayerDataOptionAuthFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LnurlPayResponsePayerDataOptionAuth &&
            (identical(other.mandatory, mandatory) ||
                const DeepCollectionEquality().equals(
                  other.mandatory,
                  mandatory,
                )) &&
            (identical(other.k1, k1) ||
                const DeepCollectionEquality().equals(other.k1, k1)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(mandatory) ^
      const DeepCollectionEquality().hash(k1) ^
      runtimeType.hashCode;
}

extension $LnurlPayResponsePayerDataOptionAuthExtension
    on LnurlPayResponsePayerDataOptionAuth {
  LnurlPayResponsePayerDataOptionAuth copyWith({bool? mandatory, String? k1}) {
    return LnurlPayResponsePayerDataOptionAuth(
      mandatory: mandatory ?? this.mandatory,
      k1: k1 ?? this.k1,
    );
  }

  LnurlPayResponsePayerDataOptionAuth copyWithWrapped({
    Wrapped<bool>? mandatory,
    Wrapped<String>? k1,
  }) {
    return LnurlPayResponsePayerDataOptionAuth(
      mandatory: (mandatory != null ? mandatory.value : this.mandatory),
      k1: (k1 != null ? k1.value : this.k1),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class LnurlResponseModel {
  const LnurlResponseModel();

  factory LnurlResponseModel.fromJson(Map<String, dynamic> json) =>
      _$LnurlResponseModelFromJson(json);

  static const toJsonFactory = _$LnurlResponseModelToJson;
  Map<String, dynamic> toJson() => _$LnurlResponseModelToJson(this);

  static const fromJsonFactory = _$LnurlResponseModelFromJson;

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => runtimeType.hashCode;
}

@JsonSerializable(explicitToJson: true)
class LnurlScan {
  const LnurlScan({required this.lnurl});

  factory LnurlScan.fromJson(Map<String, dynamic> json) =>
      _$LnurlScanFromJson(json);

  static const toJsonFactory = _$LnurlScanToJson;
  Map<String, dynamic> toJson() => _$LnurlScanToJson(this);

  @JsonKey(name: 'lnurl', includeIfNull: false)
  final dynamic lnurl;
  static const fromJsonFactory = _$LnurlScanFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LnurlScan &&
            (identical(other.lnurl, lnurl) ||
                const DeepCollectionEquality().equals(other.lnurl, lnurl)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(lnurl) ^ runtimeType.hashCode;
}

extension $LnurlScanExtension on LnurlScan {
  LnurlScan copyWith({dynamic lnurl}) {
    return LnurlScan(lnurl: lnurl ?? this.lnurl);
  }

  LnurlScan copyWithWrapped({Wrapped<dynamic>? lnurl}) {
    return LnurlScan(lnurl: (lnurl != null ? lnurl.value : this.lnurl));
  }
}

@JsonSerializable(explicitToJson: true)
class LnurlWithdrawResponse {
  const LnurlWithdrawResponse({
    this.tag,
    required this.callback,
    required this.k1,
    required this.minWithdrawable,
    required this.maxWithdrawable,
    this.defaultDescription,
    this.balanceCheck,
    this.currentBalance,
    this.payLink,
  });

  factory LnurlWithdrawResponse.fromJson(Map<String, dynamic> json) =>
      _$LnurlWithdrawResponseFromJson(json);

  static const toJsonFactory = _$LnurlWithdrawResponseToJson;
  Map<String, dynamic> toJson() => _$LnurlWithdrawResponseToJson(this);

  @JsonKey(
    name: 'tag',
    includeIfNull: false,
    toJson: lnurlResponseTagNullableToJson,
    fromJson: lnurlResponseTagTagNullableFromJson,
  )
  final enums.LnurlResponseTag? tag;
  static enums.LnurlResponseTag? lnurlResponseTagTagNullableFromJson(
    Object? value,
  ) => lnurlResponseTagNullableFromJson(
    value,
    enums.LnurlResponseTag.withdrawrequest,
  );

  @JsonKey(name: 'callback', includeIfNull: false)
  final String callback;
  @JsonKey(name: 'k1', includeIfNull: false)
  final String k1;
  @JsonKey(name: 'minWithdrawable', includeIfNull: false)
  final int minWithdrawable;
  @JsonKey(name: 'maxWithdrawable', includeIfNull: false)
  final int maxWithdrawable;
  @JsonKey(name: 'defaultDescription', includeIfNull: false)
  final String? defaultDescription;
  @JsonKey(name: 'balanceCheck', includeIfNull: false)
  final String? balanceCheck;
  @JsonKey(name: 'currentBalance', includeIfNull: false)
  final int? currentBalance;
  @JsonKey(name: 'payLink', includeIfNull: false)
  final String? payLink;
  static const fromJsonFactory = _$LnurlWithdrawResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LnurlWithdrawResponse &&
            (identical(other.tag, tag) ||
                const DeepCollectionEquality().equals(other.tag, tag)) &&
            (identical(other.callback, callback) ||
                const DeepCollectionEquality().equals(
                  other.callback,
                  callback,
                )) &&
            (identical(other.k1, k1) ||
                const DeepCollectionEquality().equals(other.k1, k1)) &&
            (identical(other.minWithdrawable, minWithdrawable) ||
                const DeepCollectionEquality().equals(
                  other.minWithdrawable,
                  minWithdrawable,
                )) &&
            (identical(other.maxWithdrawable, maxWithdrawable) ||
                const DeepCollectionEquality().equals(
                  other.maxWithdrawable,
                  maxWithdrawable,
                )) &&
            (identical(other.defaultDescription, defaultDescription) ||
                const DeepCollectionEquality().equals(
                  other.defaultDescription,
                  defaultDescription,
                )) &&
            (identical(other.balanceCheck, balanceCheck) ||
                const DeepCollectionEquality().equals(
                  other.balanceCheck,
                  balanceCheck,
                )) &&
            (identical(other.currentBalance, currentBalance) ||
                const DeepCollectionEquality().equals(
                  other.currentBalance,
                  currentBalance,
                )) &&
            (identical(other.payLink, payLink) ||
                const DeepCollectionEquality().equals(other.payLink, payLink)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(tag) ^
      const DeepCollectionEquality().hash(callback) ^
      const DeepCollectionEquality().hash(k1) ^
      const DeepCollectionEquality().hash(minWithdrawable) ^
      const DeepCollectionEquality().hash(maxWithdrawable) ^
      const DeepCollectionEquality().hash(defaultDescription) ^
      const DeepCollectionEquality().hash(balanceCheck) ^
      const DeepCollectionEquality().hash(currentBalance) ^
      const DeepCollectionEquality().hash(payLink) ^
      runtimeType.hashCode;
}

extension $LnurlWithdrawResponseExtension on LnurlWithdrawResponse {
  LnurlWithdrawResponse copyWith({
    enums.LnurlResponseTag? tag,
    String? callback,
    String? k1,
    int? minWithdrawable,
    int? maxWithdrawable,
    String? defaultDescription,
    String? balanceCheck,
    int? currentBalance,
    String? payLink,
  }) {
    return LnurlWithdrawResponse(
      tag: tag ?? this.tag,
      callback: callback ?? this.callback,
      k1: k1 ?? this.k1,
      minWithdrawable: minWithdrawable ?? this.minWithdrawable,
      maxWithdrawable: maxWithdrawable ?? this.maxWithdrawable,
      defaultDescription: defaultDescription ?? this.defaultDescription,
      balanceCheck: balanceCheck ?? this.balanceCheck,
      currentBalance: currentBalance ?? this.currentBalance,
      payLink: payLink ?? this.payLink,
    );
  }

  LnurlWithdrawResponse copyWithWrapped({
    Wrapped<enums.LnurlResponseTag?>? tag,
    Wrapped<String>? callback,
    Wrapped<String>? k1,
    Wrapped<int>? minWithdrawable,
    Wrapped<int>? maxWithdrawable,
    Wrapped<String?>? defaultDescription,
    Wrapped<String?>? balanceCheck,
    Wrapped<int?>? currentBalance,
    Wrapped<String?>? payLink,
  }) {
    return LnurlWithdrawResponse(
      tag: (tag != null ? tag.value : this.tag),
      callback: (callback != null ? callback.value : this.callback),
      k1: (k1 != null ? k1.value : this.k1),
      minWithdrawable: (minWithdrawable != null
          ? minWithdrawable.value
          : this.minWithdrawable),
      maxWithdrawable: (maxWithdrawable != null
          ? maxWithdrawable.value
          : this.maxWithdrawable),
      defaultDescription: (defaultDescription != null
          ? defaultDescription.value
          : this.defaultDescription),
      balanceCheck: (balanceCheck != null
          ? balanceCheck.value
          : this.balanceCheck),
      currentBalance: (currentBalance != null
          ? currentBalance.value
          : this.currentBalance),
      payLink: (payLink != null ? payLink.value : this.payLink),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class LoginUsernamePassword {
  const LoginUsernamePassword({required this.username, required this.password});

  factory LoginUsernamePassword.fromJson(Map<String, dynamic> json) =>
      _$LoginUsernamePasswordFromJson(json);

  static const toJsonFactory = _$LoginUsernamePasswordToJson;
  Map<String, dynamic> toJson() => _$LoginUsernamePasswordToJson(this);

  @JsonKey(name: 'username', includeIfNull: false)
  final String username;
  @JsonKey(name: 'password', includeIfNull: false)
  final String password;
  static const fromJsonFactory = _$LoginUsernamePasswordFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LoginUsernamePassword &&
            (identical(other.username, username) ||
                const DeepCollectionEquality().equals(
                  other.username,
                  username,
                )) &&
            (identical(other.password, password) ||
                const DeepCollectionEquality().equals(
                  other.password,
                  password,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(username) ^
      const DeepCollectionEquality().hash(password) ^
      runtimeType.hashCode;
}

extension $LoginUsernamePasswordExtension on LoginUsernamePassword {
  LoginUsernamePassword copyWith({String? username, String? password}) {
    return LoginUsernamePassword(
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }

  LoginUsernamePassword copyWithWrapped({
    Wrapped<String>? username,
    Wrapped<String>? password,
  }) {
    return LoginUsernamePassword(
      username: (username != null ? username.value : this.username),
      password: (password != null ? password.value : this.password),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class LoginUsr {
  const LoginUsr({required this.usr});

  factory LoginUsr.fromJson(Map<String, dynamic> json) =>
      _$LoginUsrFromJson(json);

  static const toJsonFactory = _$LoginUsrToJson;
  Map<String, dynamic> toJson() => _$LoginUsrToJson(this);

  @JsonKey(name: 'usr', includeIfNull: false)
  final String usr;
  static const fromJsonFactory = _$LoginUsrFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LoginUsr &&
            (identical(other.usr, usr) ||
                const DeepCollectionEquality().equals(other.usr, usr)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(usr) ^ runtimeType.hashCode;
}

extension $LoginUsrExtension on LoginUsr {
  LoginUsr copyWith({String? usr}) {
    return LoginUsr(usr: usr ?? this.usr);
  }

  LoginUsr copyWithWrapped({Wrapped<String>? usr}) {
    return LoginUsr(usr: (usr != null ? usr.value : this.usr));
  }
}

@JsonSerializable(explicitToJson: true)
class NodeChannel {
  const NodeChannel({
    required this.peerId,
    required this.balance,
    required this.state,
    this.id,
    this.shortId,
    this.point,
    this.name,
    this.color,
    this.feePpm,
    this.feeBaseMsat,
  });

  factory NodeChannel.fromJson(Map<String, dynamic> json) =>
      _$NodeChannelFromJson(json);

  static const toJsonFactory = _$NodeChannelToJson;
  Map<String, dynamic> toJson() => _$NodeChannelToJson(this);

  @JsonKey(name: 'peer_id', includeIfNull: false)
  final String peerId;
  @JsonKey(name: 'balance', includeIfNull: false)
  final ChannelBalance balance;
  @JsonKey(
    name: 'state',
    includeIfNull: false,
    toJson: channelStateToJson,
    fromJson: channelStateFromJson,
  )
  final enums.ChannelState state;
  @JsonKey(name: 'id', includeIfNull: false)
  final String? id;
  @JsonKey(name: 'short_id', includeIfNull: false)
  final String? shortId;
  @JsonKey(name: 'point', includeIfNull: false)
  final ChannelPoint? point;
  @JsonKey(name: 'name', includeIfNull: false)
  final String? name;
  @JsonKey(name: 'color', includeIfNull: false)
  final String? color;
  @JsonKey(name: 'fee_ppm', includeIfNull: false)
  final int? feePpm;
  @JsonKey(name: 'fee_base_msat', includeIfNull: false)
  final int? feeBaseMsat;
  static const fromJsonFactory = _$NodeChannelFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is NodeChannel &&
            (identical(other.peerId, peerId) ||
                const DeepCollectionEquality().equals(other.peerId, peerId)) &&
            (identical(other.balance, balance) ||
                const DeepCollectionEquality().equals(
                  other.balance,
                  balance,
                )) &&
            (identical(other.state, state) ||
                const DeepCollectionEquality().equals(other.state, state)) &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.shortId, shortId) ||
                const DeepCollectionEquality().equals(
                  other.shortId,
                  shortId,
                )) &&
            (identical(other.point, point) ||
                const DeepCollectionEquality().equals(other.point, point)) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.color, color) ||
                const DeepCollectionEquality().equals(other.color, color)) &&
            (identical(other.feePpm, feePpm) ||
                const DeepCollectionEquality().equals(other.feePpm, feePpm)) &&
            (identical(other.feeBaseMsat, feeBaseMsat) ||
                const DeepCollectionEquality().equals(
                  other.feeBaseMsat,
                  feeBaseMsat,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(peerId) ^
      const DeepCollectionEquality().hash(balance) ^
      const DeepCollectionEquality().hash(state) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(shortId) ^
      const DeepCollectionEquality().hash(point) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(color) ^
      const DeepCollectionEquality().hash(feePpm) ^
      const DeepCollectionEquality().hash(feeBaseMsat) ^
      runtimeType.hashCode;
}

extension $NodeChannelExtension on NodeChannel {
  NodeChannel copyWith({
    String? peerId,
    ChannelBalance? balance,
    enums.ChannelState? state,
    String? id,
    String? shortId,
    ChannelPoint? point,
    String? name,
    String? color,
    int? feePpm,
    int? feeBaseMsat,
  }) {
    return NodeChannel(
      peerId: peerId ?? this.peerId,
      balance: balance ?? this.balance,
      state: state ?? this.state,
      id: id ?? this.id,
      shortId: shortId ?? this.shortId,
      point: point ?? this.point,
      name: name ?? this.name,
      color: color ?? this.color,
      feePpm: feePpm ?? this.feePpm,
      feeBaseMsat: feeBaseMsat ?? this.feeBaseMsat,
    );
  }

  NodeChannel copyWithWrapped({
    Wrapped<String>? peerId,
    Wrapped<ChannelBalance>? balance,
    Wrapped<enums.ChannelState>? state,
    Wrapped<String?>? id,
    Wrapped<String?>? shortId,
    Wrapped<ChannelPoint?>? point,
    Wrapped<String?>? name,
    Wrapped<String?>? color,
    Wrapped<int?>? feePpm,
    Wrapped<int?>? feeBaseMsat,
  }) {
    return NodeChannel(
      peerId: (peerId != null ? peerId.value : this.peerId),
      balance: (balance != null ? balance.value : this.balance),
      state: (state != null ? state.value : this.state),
      id: (id != null ? id.value : this.id),
      shortId: (shortId != null ? shortId.value : this.shortId),
      point: (point != null ? point.value : this.point),
      name: (name != null ? name.value : this.name),
      color: (color != null ? color.value : this.color),
      feePpm: (feePpm != null ? feePpm.value : this.feePpm),
      feeBaseMsat: (feeBaseMsat != null ? feeBaseMsat.value : this.feeBaseMsat),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class NodeFees {
  const NodeFees({
    required this.totalMsat,
    this.dailyMsat,
    this.weeklyMsat,
    this.monthlyMsat,
  });

  factory NodeFees.fromJson(Map<String, dynamic> json) =>
      _$NodeFeesFromJson(json);

  static const toJsonFactory = _$NodeFeesToJson;
  Map<String, dynamic> toJson() => _$NodeFeesToJson(this);

  @JsonKey(name: 'total_msat', includeIfNull: false)
  final int totalMsat;
  @JsonKey(name: 'daily_msat', includeIfNull: false)
  final int? dailyMsat;
  @JsonKey(name: 'weekly_msat', includeIfNull: false)
  final int? weeklyMsat;
  @JsonKey(name: 'monthly_msat', includeIfNull: false)
  final int? monthlyMsat;
  static const fromJsonFactory = _$NodeFeesFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is NodeFees &&
            (identical(other.totalMsat, totalMsat) ||
                const DeepCollectionEquality().equals(
                  other.totalMsat,
                  totalMsat,
                )) &&
            (identical(other.dailyMsat, dailyMsat) ||
                const DeepCollectionEquality().equals(
                  other.dailyMsat,
                  dailyMsat,
                )) &&
            (identical(other.weeklyMsat, weeklyMsat) ||
                const DeepCollectionEquality().equals(
                  other.weeklyMsat,
                  weeklyMsat,
                )) &&
            (identical(other.monthlyMsat, monthlyMsat) ||
                const DeepCollectionEquality().equals(
                  other.monthlyMsat,
                  monthlyMsat,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(totalMsat) ^
      const DeepCollectionEquality().hash(dailyMsat) ^
      const DeepCollectionEquality().hash(weeklyMsat) ^
      const DeepCollectionEquality().hash(monthlyMsat) ^
      runtimeType.hashCode;
}

extension $NodeFeesExtension on NodeFees {
  NodeFees copyWith({
    int? totalMsat,
    int? dailyMsat,
    int? weeklyMsat,
    int? monthlyMsat,
  }) {
    return NodeFees(
      totalMsat: totalMsat ?? this.totalMsat,
      dailyMsat: dailyMsat ?? this.dailyMsat,
      weeklyMsat: weeklyMsat ?? this.weeklyMsat,
      monthlyMsat: monthlyMsat ?? this.monthlyMsat,
    );
  }

  NodeFees copyWithWrapped({
    Wrapped<int>? totalMsat,
    Wrapped<int?>? dailyMsat,
    Wrapped<int?>? weeklyMsat,
    Wrapped<int?>? monthlyMsat,
  }) {
    return NodeFees(
      totalMsat: (totalMsat != null ? totalMsat.value : this.totalMsat),
      dailyMsat: (dailyMsat != null ? dailyMsat.value : this.dailyMsat),
      weeklyMsat: (weeklyMsat != null ? weeklyMsat.value : this.weeklyMsat),
      monthlyMsat: (monthlyMsat != null ? monthlyMsat.value : this.monthlyMsat),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class NodeInfoResponse {
  const NodeInfoResponse({
    required this.id,
    required this.backendName,
    required this.alias,
    required this.color,
    required this.numPeers,
    required this.blockheight,
    required this.channelStats,
    required this.addresses,
    required this.onchainBalanceSat,
    required this.onchainConfirmedSat,
    required this.fees,
    required this.balanceMsat,
  });

  factory NodeInfoResponse.fromJson(Map<String, dynamic> json) =>
      _$NodeInfoResponseFromJson(json);

  static const toJsonFactory = _$NodeInfoResponseToJson;
  Map<String, dynamic> toJson() => _$NodeInfoResponseToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'backend_name', includeIfNull: false)
  final String backendName;
  @JsonKey(name: 'alias', includeIfNull: false)
  final String alias;
  @JsonKey(name: 'color', includeIfNull: false)
  final String color;
  @JsonKey(name: 'num_peers', includeIfNull: false)
  final int numPeers;
  @JsonKey(name: 'blockheight', includeIfNull: false)
  final int blockheight;
  @JsonKey(name: 'channel_stats', includeIfNull: false)
  final ChannelStats channelStats;
  @JsonKey(name: 'addresses', includeIfNull: false, defaultValue: <String>[])
  final List<String> addresses;
  @JsonKey(name: 'onchain_balance_sat', includeIfNull: false)
  final int onchainBalanceSat;
  @JsonKey(name: 'onchain_confirmed_sat', includeIfNull: false)
  final int onchainConfirmedSat;
  @JsonKey(name: 'fees', includeIfNull: false)
  final NodeFees fees;
  @JsonKey(name: 'balance_msat', includeIfNull: false)
  final int balanceMsat;
  static const fromJsonFactory = _$NodeInfoResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is NodeInfoResponse &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.backendName, backendName) ||
                const DeepCollectionEquality().equals(
                  other.backendName,
                  backendName,
                )) &&
            (identical(other.alias, alias) ||
                const DeepCollectionEquality().equals(other.alias, alias)) &&
            (identical(other.color, color) ||
                const DeepCollectionEquality().equals(other.color, color)) &&
            (identical(other.numPeers, numPeers) ||
                const DeepCollectionEquality().equals(
                  other.numPeers,
                  numPeers,
                )) &&
            (identical(other.blockheight, blockheight) ||
                const DeepCollectionEquality().equals(
                  other.blockheight,
                  blockheight,
                )) &&
            (identical(other.channelStats, channelStats) ||
                const DeepCollectionEquality().equals(
                  other.channelStats,
                  channelStats,
                )) &&
            (identical(other.addresses, addresses) ||
                const DeepCollectionEquality().equals(
                  other.addresses,
                  addresses,
                )) &&
            (identical(other.onchainBalanceSat, onchainBalanceSat) ||
                const DeepCollectionEquality().equals(
                  other.onchainBalanceSat,
                  onchainBalanceSat,
                )) &&
            (identical(other.onchainConfirmedSat, onchainConfirmedSat) ||
                const DeepCollectionEquality().equals(
                  other.onchainConfirmedSat,
                  onchainConfirmedSat,
                )) &&
            (identical(other.fees, fees) ||
                const DeepCollectionEquality().equals(other.fees, fees)) &&
            (identical(other.balanceMsat, balanceMsat) ||
                const DeepCollectionEquality().equals(
                  other.balanceMsat,
                  balanceMsat,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(backendName) ^
      const DeepCollectionEquality().hash(alias) ^
      const DeepCollectionEquality().hash(color) ^
      const DeepCollectionEquality().hash(numPeers) ^
      const DeepCollectionEquality().hash(blockheight) ^
      const DeepCollectionEquality().hash(channelStats) ^
      const DeepCollectionEquality().hash(addresses) ^
      const DeepCollectionEquality().hash(onchainBalanceSat) ^
      const DeepCollectionEquality().hash(onchainConfirmedSat) ^
      const DeepCollectionEquality().hash(fees) ^
      const DeepCollectionEquality().hash(balanceMsat) ^
      runtimeType.hashCode;
}

extension $NodeInfoResponseExtension on NodeInfoResponse {
  NodeInfoResponse copyWith({
    String? id,
    String? backendName,
    String? alias,
    String? color,
    int? numPeers,
    int? blockheight,
    ChannelStats? channelStats,
    List<String>? addresses,
    int? onchainBalanceSat,
    int? onchainConfirmedSat,
    NodeFees? fees,
    int? balanceMsat,
  }) {
    return NodeInfoResponse(
      id: id ?? this.id,
      backendName: backendName ?? this.backendName,
      alias: alias ?? this.alias,
      color: color ?? this.color,
      numPeers: numPeers ?? this.numPeers,
      blockheight: blockheight ?? this.blockheight,
      channelStats: channelStats ?? this.channelStats,
      addresses: addresses ?? this.addresses,
      onchainBalanceSat: onchainBalanceSat ?? this.onchainBalanceSat,
      onchainConfirmedSat: onchainConfirmedSat ?? this.onchainConfirmedSat,
      fees: fees ?? this.fees,
      balanceMsat: balanceMsat ?? this.balanceMsat,
    );
  }

  NodeInfoResponse copyWithWrapped({
    Wrapped<String>? id,
    Wrapped<String>? backendName,
    Wrapped<String>? alias,
    Wrapped<String>? color,
    Wrapped<int>? numPeers,
    Wrapped<int>? blockheight,
    Wrapped<ChannelStats>? channelStats,
    Wrapped<List<String>>? addresses,
    Wrapped<int>? onchainBalanceSat,
    Wrapped<int>? onchainConfirmedSat,
    Wrapped<NodeFees>? fees,
    Wrapped<int>? balanceMsat,
  }) {
    return NodeInfoResponse(
      id: (id != null ? id.value : this.id),
      backendName: (backendName != null ? backendName.value : this.backendName),
      alias: (alias != null ? alias.value : this.alias),
      color: (color != null ? color.value : this.color),
      numPeers: (numPeers != null ? numPeers.value : this.numPeers),
      blockheight: (blockheight != null ? blockheight.value : this.blockheight),
      channelStats: (channelStats != null
          ? channelStats.value
          : this.channelStats),
      addresses: (addresses != null ? addresses.value : this.addresses),
      onchainBalanceSat: (onchainBalanceSat != null
          ? onchainBalanceSat.value
          : this.onchainBalanceSat),
      onchainConfirmedSat: (onchainConfirmedSat != null
          ? onchainConfirmedSat.value
          : this.onchainConfirmedSat),
      fees: (fees != null ? fees.value : this.fees),
      balanceMsat: (balanceMsat != null ? balanceMsat.value : this.balanceMsat),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class NodePeerInfo {
  const NodePeerInfo({
    required this.id,
    this.alias,
    this.color,
    this.lastTimestamp,
    this.addresses,
  });

  factory NodePeerInfo.fromJson(Map<String, dynamic> json) =>
      _$NodePeerInfoFromJson(json);

  static const toJsonFactory = _$NodePeerInfoToJson;
  Map<String, dynamic> toJson() => _$NodePeerInfoToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'alias', includeIfNull: false)
  final String? alias;
  @JsonKey(name: 'color', includeIfNull: false)
  final String? color;
  @JsonKey(name: 'last_timestamp', includeIfNull: false)
  final int? lastTimestamp;
  @JsonKey(name: 'addresses', includeIfNull: false, defaultValue: <String>[])
  final List<String>? addresses;
  static const fromJsonFactory = _$NodePeerInfoFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is NodePeerInfo &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.alias, alias) ||
                const DeepCollectionEquality().equals(other.alias, alias)) &&
            (identical(other.color, color) ||
                const DeepCollectionEquality().equals(other.color, color)) &&
            (identical(other.lastTimestamp, lastTimestamp) ||
                const DeepCollectionEquality().equals(
                  other.lastTimestamp,
                  lastTimestamp,
                )) &&
            (identical(other.addresses, addresses) ||
                const DeepCollectionEquality().equals(
                  other.addresses,
                  addresses,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(alias) ^
      const DeepCollectionEquality().hash(color) ^
      const DeepCollectionEquality().hash(lastTimestamp) ^
      const DeepCollectionEquality().hash(addresses) ^
      runtimeType.hashCode;
}

extension $NodePeerInfoExtension on NodePeerInfo {
  NodePeerInfo copyWith({
    String? id,
    String? alias,
    String? color,
    int? lastTimestamp,
    List<String>? addresses,
  }) {
    return NodePeerInfo(
      id: id ?? this.id,
      alias: alias ?? this.alias,
      color: color ?? this.color,
      lastTimestamp: lastTimestamp ?? this.lastTimestamp,
      addresses: addresses ?? this.addresses,
    );
  }

  NodePeerInfo copyWithWrapped({
    Wrapped<String>? id,
    Wrapped<String?>? alias,
    Wrapped<String?>? color,
    Wrapped<int?>? lastTimestamp,
    Wrapped<List<String>?>? addresses,
  }) {
    return NodePeerInfo(
      id: (id != null ? id.value : this.id),
      alias: (alias != null ? alias.value : this.alias),
      color: (color != null ? color.value : this.color),
      lastTimestamp: (lastTimestamp != null
          ? lastTimestamp.value
          : this.lastTimestamp),
      addresses: (addresses != null ? addresses.value : this.addresses),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class NodeRank {
  const NodeRank({
    this.capacity,
    this.channelcount,
    this.age,
    this.growth,
    this.availability,
  });

  factory NodeRank.fromJson(Map<String, dynamic> json) =>
      _$NodeRankFromJson(json);

  static const toJsonFactory = _$NodeRankToJson;
  Map<String, dynamic> toJson() => _$NodeRankToJson(this);

  @JsonKey(name: 'capacity', includeIfNull: false)
  final int? capacity;
  @JsonKey(name: 'channelcount', includeIfNull: false)
  final int? channelcount;
  @JsonKey(name: 'age', includeIfNull: false)
  final int? age;
  @JsonKey(name: 'growth', includeIfNull: false)
  final int? growth;
  @JsonKey(name: 'availability', includeIfNull: false)
  final int? availability;
  static const fromJsonFactory = _$NodeRankFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is NodeRank &&
            (identical(other.capacity, capacity) ||
                const DeepCollectionEquality().equals(
                  other.capacity,
                  capacity,
                )) &&
            (identical(other.channelcount, channelcount) ||
                const DeepCollectionEquality().equals(
                  other.channelcount,
                  channelcount,
                )) &&
            (identical(other.age, age) ||
                const DeepCollectionEquality().equals(other.age, age)) &&
            (identical(other.growth, growth) ||
                const DeepCollectionEquality().equals(other.growth, growth)) &&
            (identical(other.availability, availability) ||
                const DeepCollectionEquality().equals(
                  other.availability,
                  availability,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(capacity) ^
      const DeepCollectionEquality().hash(channelcount) ^
      const DeepCollectionEquality().hash(age) ^
      const DeepCollectionEquality().hash(growth) ^
      const DeepCollectionEquality().hash(availability) ^
      runtimeType.hashCode;
}

extension $NodeRankExtension on NodeRank {
  NodeRank copyWith({
    int? capacity,
    int? channelcount,
    int? age,
    int? growth,
    int? availability,
  }) {
    return NodeRank(
      capacity: capacity ?? this.capacity,
      channelcount: channelcount ?? this.channelcount,
      age: age ?? this.age,
      growth: growth ?? this.growth,
      availability: availability ?? this.availability,
    );
  }

  NodeRank copyWithWrapped({
    Wrapped<int?>? capacity,
    Wrapped<int?>? channelcount,
    Wrapped<int?>? age,
    Wrapped<int?>? growth,
    Wrapped<int?>? availability,
  }) {
    return NodeRank(
      capacity: (capacity != null ? capacity.value : this.capacity),
      channelcount: (channelcount != null
          ? channelcount.value
          : this.channelcount),
      age: (age != null ? age.value : this.age),
      growth: (growth != null ? growth.value : this.growth),
      availability: (availability != null
          ? availability.value
          : this.availability),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class OwnerDataFields {
  const OwnerDataFields({this.name, this.description});

  factory OwnerDataFields.fromJson(Map<String, dynamic> json) =>
      _$OwnerDataFieldsFromJson(json);

  static const toJsonFactory = _$OwnerDataFieldsToJson;
  Map<String, dynamic> toJson() => _$OwnerDataFieldsToJson(this);

  @JsonKey(name: 'name', includeIfNull: false)
  final String? name;
  @JsonKey(name: 'description', includeIfNull: false)
  final String? description;
  static const fromJsonFactory = _$OwnerDataFieldsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is OwnerDataFields &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.description, description) ||
                const DeepCollectionEquality().equals(
                  other.description,
                  description,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(description) ^
      runtimeType.hashCode;
}

extension $OwnerDataFieldsExtension on OwnerDataFields {
  OwnerDataFields copyWith({String? name, String? description}) {
    return OwnerDataFields(
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }

  OwnerDataFields copyWithWrapped({
    Wrapped<String?>? name,
    Wrapped<String?>? description,
  }) {
    return OwnerDataFields(
      name: (name != null ? name.value : this.name),
      description: (description != null ? description.value : this.description),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class Page {
  const Page({required this.data, required this.total});

  factory Page.fromJson(Map<String, dynamic> json) => _$PageFromJson(json);

  static const toJsonFactory = _$PageToJson;
  Map<String, dynamic> toJson() => _$PageToJson(this);

  @JsonKey(name: 'data', includeIfNull: false, defaultValue: <Object>[])
  final List<Object> data;
  @JsonKey(name: 'total', includeIfNull: false)
  final int total;
  static const fromJsonFactory = _$PageFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Page &&
            (identical(other.data, data) ||
                const DeepCollectionEquality().equals(other.data, data)) &&
            (identical(other.total, total) ||
                const DeepCollectionEquality().equals(other.total, total)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(data) ^
      const DeepCollectionEquality().hash(total) ^
      runtimeType.hashCode;
}

extension $PageExtension on Page {
  Page copyWith({List<Object>? data, int? total}) {
    return Page(data: data ?? this.data, total: total ?? this.total);
  }

  Page copyWithWrapped({Wrapped<List<Object>>? data, Wrapped<int>? total}) {
    return Page(
      data: (data != null ? data.value : this.data),
      total: (total != null ? total.value : this.total),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class PayToEnableInfo {
  const PayToEnableInfo({this.amount, this.required, this.wallet});

  factory PayToEnableInfo.fromJson(Map<String, dynamic> json) =>
      _$PayToEnableInfoFromJson(json);

  static const toJsonFactory = _$PayToEnableInfoToJson;
  Map<String, dynamic> toJson() => _$PayToEnableInfoToJson(this);

  @JsonKey(name: 'amount', includeIfNull: false)
  final int? amount;
  @JsonKey(name: 'required', includeIfNull: false, defaultValue: false)
  final bool? required;
  @JsonKey(name: 'wallet', includeIfNull: false)
  final String? wallet;
  static const fromJsonFactory = _$PayToEnableInfoFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PayToEnableInfo &&
            (identical(other.amount, amount) ||
                const DeepCollectionEquality().equals(other.amount, amount)) &&
            (identical(other.required, required) ||
                const DeepCollectionEquality().equals(
                  other.required,
                  required,
                )) &&
            (identical(other.wallet, wallet) ||
                const DeepCollectionEquality().equals(other.wallet, wallet)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(amount) ^
      const DeepCollectionEquality().hash(required) ^
      const DeepCollectionEquality().hash(wallet) ^
      runtimeType.hashCode;
}

extension $PayToEnableInfoExtension on PayToEnableInfo {
  PayToEnableInfo copyWith({int? amount, bool? required, String? wallet}) {
    return PayToEnableInfo(
      amount: amount ?? this.amount,
      required: required ?? this.required,
      wallet: wallet ?? this.wallet,
    );
  }

  PayToEnableInfo copyWithWrapped({
    Wrapped<int?>? amount,
    Wrapped<bool?>? required,
    Wrapped<String?>? wallet,
  }) {
    return PayToEnableInfo(
      amount: (amount != null ? amount.value : this.amount),
      required: (required != null ? required.value : this.required),
      wallet: (wallet != null ? wallet.value : this.wallet),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class Payment {
  const Payment({
    required this.checkingId,
    required this.paymentHash,
    required this.walletId,
    required this.amount,
    required this.fee,
    required this.bolt11,
    this.paymentRequest,
    this.fiatProvider,
    this.status,
    this.memo,
    this.expiry,
    this.webhook,
    this.webhookStatus,
    this.preimage,
    this.tag,
    this.extension,
    this.time,
    this.createdAt,
    this.updatedAt,
    this.labels,
    this.extra,
  });

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);

  static const toJsonFactory = _$PaymentToJson;
  Map<String, dynamic> toJson() => _$PaymentToJson(this);

  @JsonKey(name: 'checking_id', includeIfNull: false)
  final String checkingId;
  @JsonKey(name: 'payment_hash', includeIfNull: false)
  final String paymentHash;
  @JsonKey(name: 'wallet_id', includeIfNull: false)
  final String walletId;
  @JsonKey(name: 'amount', includeIfNull: false)
  final int amount;
  @JsonKey(name: 'fee', includeIfNull: false)
  final int fee;
  @JsonKey(name: 'bolt11', includeIfNull: false)
  final String bolt11;
  @JsonKey(name: 'payment_request', includeIfNull: false)
  final String? paymentRequest;
  @JsonKey(name: 'fiat_provider', includeIfNull: false)
  final String? fiatProvider;
  @JsonKey(name: 'status', includeIfNull: false)
  final String? status;
  @JsonKey(name: 'memo', includeIfNull: false)
  final String? memo;
  @JsonKey(name: 'expiry', includeIfNull: false)
  final DateTime? expiry;
  @JsonKey(name: 'webhook', includeIfNull: false)
  final String? webhook;
  @JsonKey(name: 'webhook_status', includeIfNull: false)
  final String? webhookStatus;
  @JsonKey(name: 'preimage', includeIfNull: false)
  final String? preimage;
  @JsonKey(name: 'tag', includeIfNull: false)
  final String? tag;
  @JsonKey(name: 'extension', includeIfNull: false)
  final String? extension;
  @JsonKey(name: 'time', includeIfNull: false)
  final DateTime? time;
  @JsonKey(name: 'created_at', includeIfNull: false)
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at', includeIfNull: false)
  final DateTime? updatedAt;
  @JsonKey(name: 'labels', includeIfNull: false, defaultValue: <String>[])
  final List<String>? labels;
  @JsonKey(name: 'extra', includeIfNull: false)
  final Object? extra;
  static const fromJsonFactory = _$PaymentFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Payment &&
            (identical(other.checkingId, checkingId) ||
                const DeepCollectionEquality().equals(
                  other.checkingId,
                  checkingId,
                )) &&
            (identical(other.paymentHash, paymentHash) ||
                const DeepCollectionEquality().equals(
                  other.paymentHash,
                  paymentHash,
                )) &&
            (identical(other.walletId, walletId) ||
                const DeepCollectionEquality().equals(
                  other.walletId,
                  walletId,
                )) &&
            (identical(other.amount, amount) ||
                const DeepCollectionEquality().equals(other.amount, amount)) &&
            (identical(other.fee, fee) ||
                const DeepCollectionEquality().equals(other.fee, fee)) &&
            (identical(other.bolt11, bolt11) ||
                const DeepCollectionEquality().equals(other.bolt11, bolt11)) &&
            (identical(other.paymentRequest, paymentRequest) ||
                const DeepCollectionEquality().equals(
                  other.paymentRequest,
                  paymentRequest,
                )) &&
            (identical(other.fiatProvider, fiatProvider) ||
                const DeepCollectionEquality().equals(
                  other.fiatProvider,
                  fiatProvider,
                )) &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)) &&
            (identical(other.memo, memo) ||
                const DeepCollectionEquality().equals(other.memo, memo)) &&
            (identical(other.expiry, expiry) ||
                const DeepCollectionEquality().equals(other.expiry, expiry)) &&
            (identical(other.webhook, webhook) ||
                const DeepCollectionEquality().equals(
                  other.webhook,
                  webhook,
                )) &&
            (identical(other.webhookStatus, webhookStatus) ||
                const DeepCollectionEquality().equals(
                  other.webhookStatus,
                  webhookStatus,
                )) &&
            (identical(other.preimage, preimage) ||
                const DeepCollectionEquality().equals(
                  other.preimage,
                  preimage,
                )) &&
            (identical(other.tag, tag) ||
                const DeepCollectionEquality().equals(other.tag, tag)) &&
            (identical(other.extension, extension) ||
                const DeepCollectionEquality().equals(
                  other.extension,
                  extension,
                )) &&
            (identical(other.time, time) ||
                const DeepCollectionEquality().equals(other.time, time)) &&
            (identical(other.createdAt, createdAt) ||
                const DeepCollectionEquality().equals(
                  other.createdAt,
                  createdAt,
                )) &&
            (identical(other.updatedAt, updatedAt) ||
                const DeepCollectionEquality().equals(
                  other.updatedAt,
                  updatedAt,
                )) &&
            (identical(other.labels, labels) ||
                const DeepCollectionEquality().equals(other.labels, labels)) &&
            (identical(other.extra, extra) ||
                const DeepCollectionEquality().equals(other.extra, extra)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(checkingId) ^
      const DeepCollectionEquality().hash(paymentHash) ^
      const DeepCollectionEquality().hash(walletId) ^
      const DeepCollectionEquality().hash(amount) ^
      const DeepCollectionEquality().hash(fee) ^
      const DeepCollectionEquality().hash(bolt11) ^
      const DeepCollectionEquality().hash(paymentRequest) ^
      const DeepCollectionEquality().hash(fiatProvider) ^
      const DeepCollectionEquality().hash(status) ^
      const DeepCollectionEquality().hash(memo) ^
      const DeepCollectionEquality().hash(expiry) ^
      const DeepCollectionEquality().hash(webhook) ^
      const DeepCollectionEquality().hash(webhookStatus) ^
      const DeepCollectionEquality().hash(preimage) ^
      const DeepCollectionEquality().hash(tag) ^
      const DeepCollectionEquality().hash(extension) ^
      const DeepCollectionEquality().hash(time) ^
      const DeepCollectionEquality().hash(createdAt) ^
      const DeepCollectionEquality().hash(updatedAt) ^
      const DeepCollectionEquality().hash(labels) ^
      const DeepCollectionEquality().hash(extra) ^
      runtimeType.hashCode;
}

extension $PaymentExtension on Payment {
  Payment copyWith({
    String? checkingId,
    String? paymentHash,
    String? walletId,
    int? amount,
    int? fee,
    String? bolt11,
    String? paymentRequest,
    String? fiatProvider,
    String? status,
    String? memo,
    DateTime? expiry,
    String? webhook,
    String? webhookStatus,
    String? preimage,
    String? tag,
    String? extension,
    DateTime? time,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? labels,
    Object? extra,
  }) {
    return Payment(
      checkingId: checkingId ?? this.checkingId,
      paymentHash: paymentHash ?? this.paymentHash,
      walletId: walletId ?? this.walletId,
      amount: amount ?? this.amount,
      fee: fee ?? this.fee,
      bolt11: bolt11 ?? this.bolt11,
      paymentRequest: paymentRequest ?? this.paymentRequest,
      fiatProvider: fiatProvider ?? this.fiatProvider,
      status: status ?? this.status,
      memo: memo ?? this.memo,
      expiry: expiry ?? this.expiry,
      webhook: webhook ?? this.webhook,
      webhookStatus: webhookStatus ?? this.webhookStatus,
      preimage: preimage ?? this.preimage,
      tag: tag ?? this.tag,
      extension: extension ?? this.extension,
      time: time ?? this.time,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      labels: labels ?? this.labels,
      extra: extra ?? this.extra,
    );
  }

  Payment copyWithWrapped({
    Wrapped<String>? checkingId,
    Wrapped<String>? paymentHash,
    Wrapped<String>? walletId,
    Wrapped<int>? amount,
    Wrapped<int>? fee,
    Wrapped<String>? bolt11,
    Wrapped<String?>? paymentRequest,
    Wrapped<String?>? fiatProvider,
    Wrapped<String?>? status,
    Wrapped<String?>? memo,
    Wrapped<DateTime?>? expiry,
    Wrapped<String?>? webhook,
    Wrapped<String?>? webhookStatus,
    Wrapped<String?>? preimage,
    Wrapped<String?>? tag,
    Wrapped<String?>? extension,
    Wrapped<DateTime?>? time,
    Wrapped<DateTime?>? createdAt,
    Wrapped<DateTime?>? updatedAt,
    Wrapped<List<String>?>? labels,
    Wrapped<Object?>? extra,
  }) {
    return Payment(
      checkingId: (checkingId != null ? checkingId.value : this.checkingId),
      paymentHash: (paymentHash != null ? paymentHash.value : this.paymentHash),
      walletId: (walletId != null ? walletId.value : this.walletId),
      amount: (amount != null ? amount.value : this.amount),
      fee: (fee != null ? fee.value : this.fee),
      bolt11: (bolt11 != null ? bolt11.value : this.bolt11),
      paymentRequest: (paymentRequest != null
          ? paymentRequest.value
          : this.paymentRequest),
      fiatProvider: (fiatProvider != null
          ? fiatProvider.value
          : this.fiatProvider),
      status: (status != null ? status.value : this.status),
      memo: (memo != null ? memo.value : this.memo),
      expiry: (expiry != null ? expiry.value : this.expiry),
      webhook: (webhook != null ? webhook.value : this.webhook),
      webhookStatus: (webhookStatus != null
          ? webhookStatus.value
          : this.webhookStatus),
      preimage: (preimage != null ? preimage.value : this.preimage),
      tag: (tag != null ? tag.value : this.tag),
      extension: (extension != null ? extension.value : this.extension),
      time: (time != null ? time.value : this.time),
      createdAt: (createdAt != null ? createdAt.value : this.createdAt),
      updatedAt: (updatedAt != null ? updatedAt.value : this.updatedAt),
      labels: (labels != null ? labels.value : this.labels),
      extra: (extra != null ? extra.value : this.extra),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class PaymentCountStat {
  const PaymentCountStat({this.field, this.total});

  factory PaymentCountStat.fromJson(Map<String, dynamic> json) =>
      _$PaymentCountStatFromJson(json);

  static const toJsonFactory = _$PaymentCountStatToJson;
  Map<String, dynamic> toJson() => _$PaymentCountStatToJson(this);

  @JsonKey(name: 'field', includeIfNull: false)
  final String? field;
  @JsonKey(name: 'total', includeIfNull: false)
  final double? total;
  static const fromJsonFactory = _$PaymentCountStatFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PaymentCountStat &&
            (identical(other.field, field) ||
                const DeepCollectionEquality().equals(other.field, field)) &&
            (identical(other.total, total) ||
                const DeepCollectionEquality().equals(other.total, total)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(field) ^
      const DeepCollectionEquality().hash(total) ^
      runtimeType.hashCode;
}

extension $PaymentCountStatExtension on PaymentCountStat {
  PaymentCountStat copyWith({String? field, double? total}) {
    return PaymentCountStat(
      field: field ?? this.field,
      total: total ?? this.total,
    );
  }

  PaymentCountStat copyWithWrapped({
    Wrapped<String?>? field,
    Wrapped<double?>? total,
  }) {
    return PaymentCountStat(
      field: (field != null ? field.value : this.field),
      total: (total != null ? total.value : this.total),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class PaymentDailyStats {
  const PaymentDailyStats({
    required this.date,
    this.balance,
    this.balanceIn,
    this.balanceOut,
    this.paymentsCount,
    this.countIn,
    this.countOut,
    this.fee,
  });

  factory PaymentDailyStats.fromJson(Map<String, dynamic> json) =>
      _$PaymentDailyStatsFromJson(json);

  static const toJsonFactory = _$PaymentDailyStatsToJson;
  Map<String, dynamic> toJson() => _$PaymentDailyStatsToJson(this);

  @JsonKey(name: 'date', includeIfNull: false)
  final DateTime date;
  @JsonKey(name: 'balance', includeIfNull: false)
  final double? balance;
  @JsonKey(name: 'balance_in', includeIfNull: false)
  final double? balanceIn;
  @JsonKey(name: 'balance_out', includeIfNull: false)
  final double? balanceOut;
  @JsonKey(name: 'payments_count', includeIfNull: false)
  final int? paymentsCount;
  @JsonKey(name: 'count_in', includeIfNull: false)
  final int? countIn;
  @JsonKey(name: 'count_out', includeIfNull: false)
  final int? countOut;
  @JsonKey(name: 'fee', includeIfNull: false)
  final double? fee;
  static const fromJsonFactory = _$PaymentDailyStatsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PaymentDailyStats &&
            (identical(other.date, date) ||
                const DeepCollectionEquality().equals(other.date, date)) &&
            (identical(other.balance, balance) ||
                const DeepCollectionEquality().equals(
                  other.balance,
                  balance,
                )) &&
            (identical(other.balanceIn, balanceIn) ||
                const DeepCollectionEquality().equals(
                  other.balanceIn,
                  balanceIn,
                )) &&
            (identical(other.balanceOut, balanceOut) ||
                const DeepCollectionEquality().equals(
                  other.balanceOut,
                  balanceOut,
                )) &&
            (identical(other.paymentsCount, paymentsCount) ||
                const DeepCollectionEquality().equals(
                  other.paymentsCount,
                  paymentsCount,
                )) &&
            (identical(other.countIn, countIn) ||
                const DeepCollectionEquality().equals(
                  other.countIn,
                  countIn,
                )) &&
            (identical(other.countOut, countOut) ||
                const DeepCollectionEquality().equals(
                  other.countOut,
                  countOut,
                )) &&
            (identical(other.fee, fee) ||
                const DeepCollectionEquality().equals(other.fee, fee)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(date) ^
      const DeepCollectionEquality().hash(balance) ^
      const DeepCollectionEquality().hash(balanceIn) ^
      const DeepCollectionEquality().hash(balanceOut) ^
      const DeepCollectionEquality().hash(paymentsCount) ^
      const DeepCollectionEquality().hash(countIn) ^
      const DeepCollectionEquality().hash(countOut) ^
      const DeepCollectionEquality().hash(fee) ^
      runtimeType.hashCode;
}

extension $PaymentDailyStatsExtension on PaymentDailyStats {
  PaymentDailyStats copyWith({
    DateTime? date,
    double? balance,
    double? balanceIn,
    double? balanceOut,
    int? paymentsCount,
    int? countIn,
    int? countOut,
    double? fee,
  }) {
    return PaymentDailyStats(
      date: date ?? this.date,
      balance: balance ?? this.balance,
      balanceIn: balanceIn ?? this.balanceIn,
      balanceOut: balanceOut ?? this.balanceOut,
      paymentsCount: paymentsCount ?? this.paymentsCount,
      countIn: countIn ?? this.countIn,
      countOut: countOut ?? this.countOut,
      fee: fee ?? this.fee,
    );
  }

  PaymentDailyStats copyWithWrapped({
    Wrapped<DateTime>? date,
    Wrapped<double?>? balance,
    Wrapped<double?>? balanceIn,
    Wrapped<double?>? balanceOut,
    Wrapped<int?>? paymentsCount,
    Wrapped<int?>? countIn,
    Wrapped<int?>? countOut,
    Wrapped<double?>? fee,
  }) {
    return PaymentDailyStats(
      date: (date != null ? date.value : this.date),
      balance: (balance != null ? balance.value : this.balance),
      balanceIn: (balanceIn != null ? balanceIn.value : this.balanceIn),
      balanceOut: (balanceOut != null ? balanceOut.value : this.balanceOut),
      paymentsCount: (paymentsCount != null
          ? paymentsCount.value
          : this.paymentsCount),
      countIn: (countIn != null ? countIn.value : this.countIn),
      countOut: (countOut != null ? countOut.value : this.countOut),
      fee: (fee != null ? fee.value : this.fee),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class PaymentHistoryPoint {
  const PaymentHistoryPoint({
    required this.date,
    required this.income,
    required this.spending,
    required this.balance,
  });

  factory PaymentHistoryPoint.fromJson(Map<String, dynamic> json) =>
      _$PaymentHistoryPointFromJson(json);

  static const toJsonFactory = _$PaymentHistoryPointToJson;
  Map<String, dynamic> toJson() => _$PaymentHistoryPointToJson(this);

  @JsonKey(name: 'date', includeIfNull: false)
  final DateTime date;
  @JsonKey(name: 'income', includeIfNull: false)
  final int income;
  @JsonKey(name: 'spending', includeIfNull: false)
  final int spending;
  @JsonKey(name: 'balance', includeIfNull: false)
  final int balance;
  static const fromJsonFactory = _$PaymentHistoryPointFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PaymentHistoryPoint &&
            (identical(other.date, date) ||
                const DeepCollectionEquality().equals(other.date, date)) &&
            (identical(other.income, income) ||
                const DeepCollectionEquality().equals(other.income, income)) &&
            (identical(other.spending, spending) ||
                const DeepCollectionEquality().equals(
                  other.spending,
                  spending,
                )) &&
            (identical(other.balance, balance) ||
                const DeepCollectionEquality().equals(other.balance, balance)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(date) ^
      const DeepCollectionEquality().hash(income) ^
      const DeepCollectionEquality().hash(spending) ^
      const DeepCollectionEquality().hash(balance) ^
      runtimeType.hashCode;
}

extension $PaymentHistoryPointExtension on PaymentHistoryPoint {
  PaymentHistoryPoint copyWith({
    DateTime? date,
    int? income,
    int? spending,
    int? balance,
  }) {
    return PaymentHistoryPoint(
      date: date ?? this.date,
      income: income ?? this.income,
      spending: spending ?? this.spending,
      balance: balance ?? this.balance,
    );
  }

  PaymentHistoryPoint copyWithWrapped({
    Wrapped<DateTime>? date,
    Wrapped<int>? income,
    Wrapped<int>? spending,
    Wrapped<int>? balance,
  }) {
    return PaymentHistoryPoint(
      date: (date != null ? date.value : this.date),
      income: (income != null ? income.value : this.income),
      spending: (spending != null ? spending.value : this.spending),
      balance: (balance != null ? balance.value : this.balance),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class PaymentWalletStats {
  const PaymentWalletStats({
    this.walletId,
    this.walletName,
    this.userId,
    required this.paymentsCount,
    this.balance,
  });

  factory PaymentWalletStats.fromJson(Map<String, dynamic> json) =>
      _$PaymentWalletStatsFromJson(json);

  static const toJsonFactory = _$PaymentWalletStatsToJson;
  Map<String, dynamic> toJson() => _$PaymentWalletStatsToJson(this);

  @JsonKey(name: 'wallet_id', includeIfNull: false)
  final String? walletId;
  @JsonKey(name: 'wallet_name', includeIfNull: false)
  final String? walletName;
  @JsonKey(name: 'user_id', includeIfNull: false)
  final String? userId;
  @JsonKey(name: 'payments_count', includeIfNull: false)
  final int paymentsCount;
  @JsonKey(name: 'balance', includeIfNull: false)
  final double? balance;
  static const fromJsonFactory = _$PaymentWalletStatsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PaymentWalletStats &&
            (identical(other.walletId, walletId) ||
                const DeepCollectionEquality().equals(
                  other.walletId,
                  walletId,
                )) &&
            (identical(other.walletName, walletName) ||
                const DeepCollectionEquality().equals(
                  other.walletName,
                  walletName,
                )) &&
            (identical(other.userId, userId) ||
                const DeepCollectionEquality().equals(other.userId, userId)) &&
            (identical(other.paymentsCount, paymentsCount) ||
                const DeepCollectionEquality().equals(
                  other.paymentsCount,
                  paymentsCount,
                )) &&
            (identical(other.balance, balance) ||
                const DeepCollectionEquality().equals(other.balance, balance)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(walletId) ^
      const DeepCollectionEquality().hash(walletName) ^
      const DeepCollectionEquality().hash(userId) ^
      const DeepCollectionEquality().hash(paymentsCount) ^
      const DeepCollectionEquality().hash(balance) ^
      runtimeType.hashCode;
}

extension $PaymentWalletStatsExtension on PaymentWalletStats {
  PaymentWalletStats copyWith({
    String? walletId,
    String? walletName,
    String? userId,
    int? paymentsCount,
    double? balance,
  }) {
    return PaymentWalletStats(
      walletId: walletId ?? this.walletId,
      walletName: walletName ?? this.walletName,
      userId: userId ?? this.userId,
      paymentsCount: paymentsCount ?? this.paymentsCount,
      balance: balance ?? this.balance,
    );
  }

  PaymentWalletStats copyWithWrapped({
    Wrapped<String?>? walletId,
    Wrapped<String?>? walletName,
    Wrapped<String?>? userId,
    Wrapped<int>? paymentsCount,
    Wrapped<double?>? balance,
  }) {
    return PaymentWalletStats(
      walletId: (walletId != null ? walletId.value : this.walletId),
      walletName: (walletName != null ? walletName.value : this.walletName),
      userId: (userId != null ? userId.value : this.userId),
      paymentsCount: (paymentsCount != null
          ? paymentsCount.value
          : this.paymentsCount),
      balance: (balance != null ? balance.value : this.balance),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class PreviewAction {
  const PreviewAction({
    this.isPreviewMode,
    this.isSettingsPreview,
    this.isOwnerDataPreview,
    this.isClientDataPreview,
    this.isPublicPagePreview,
  });

  factory PreviewAction.fromJson(Map<String, dynamic> json) =>
      _$PreviewActionFromJson(json);

  static const toJsonFactory = _$PreviewActionToJson;
  Map<String, dynamic> toJson() => _$PreviewActionToJson(this);

  @JsonKey(name: 'is_preview_mode', includeIfNull: false, defaultValue: false)
  final bool? isPreviewMode;
  @JsonKey(
    name: 'is_settings_preview',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? isSettingsPreview;
  @JsonKey(
    name: 'is_owner_data_preview',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? isOwnerDataPreview;
  @JsonKey(
    name: 'is_client_data_preview',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? isClientDataPreview;
  @JsonKey(
    name: 'is_public_page_preview',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? isPublicPagePreview;
  static const fromJsonFactory = _$PreviewActionFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PreviewAction &&
            (identical(other.isPreviewMode, isPreviewMode) ||
                const DeepCollectionEquality().equals(
                  other.isPreviewMode,
                  isPreviewMode,
                )) &&
            (identical(other.isSettingsPreview, isSettingsPreview) ||
                const DeepCollectionEquality().equals(
                  other.isSettingsPreview,
                  isSettingsPreview,
                )) &&
            (identical(other.isOwnerDataPreview, isOwnerDataPreview) ||
                const DeepCollectionEquality().equals(
                  other.isOwnerDataPreview,
                  isOwnerDataPreview,
                )) &&
            (identical(other.isClientDataPreview, isClientDataPreview) ||
                const DeepCollectionEquality().equals(
                  other.isClientDataPreview,
                  isClientDataPreview,
                )) &&
            (identical(other.isPublicPagePreview, isPublicPagePreview) ||
                const DeepCollectionEquality().equals(
                  other.isPublicPagePreview,
                  isPublicPagePreview,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(isPreviewMode) ^
      const DeepCollectionEquality().hash(isSettingsPreview) ^
      const DeepCollectionEquality().hash(isOwnerDataPreview) ^
      const DeepCollectionEquality().hash(isClientDataPreview) ^
      const DeepCollectionEquality().hash(isPublicPagePreview) ^
      runtimeType.hashCode;
}

extension $PreviewActionExtension on PreviewAction {
  PreviewAction copyWith({
    bool? isPreviewMode,
    bool? isSettingsPreview,
    bool? isOwnerDataPreview,
    bool? isClientDataPreview,
    bool? isPublicPagePreview,
  }) {
    return PreviewAction(
      isPreviewMode: isPreviewMode ?? this.isPreviewMode,
      isSettingsPreview: isSettingsPreview ?? this.isSettingsPreview,
      isOwnerDataPreview: isOwnerDataPreview ?? this.isOwnerDataPreview,
      isClientDataPreview: isClientDataPreview ?? this.isClientDataPreview,
      isPublicPagePreview: isPublicPagePreview ?? this.isPublicPagePreview,
    );
  }

  PreviewAction copyWithWrapped({
    Wrapped<bool?>? isPreviewMode,
    Wrapped<bool?>? isSettingsPreview,
    Wrapped<bool?>? isOwnerDataPreview,
    Wrapped<bool?>? isClientDataPreview,
    Wrapped<bool?>? isPublicPagePreview,
  }) {
    return PreviewAction(
      isPreviewMode: (isPreviewMode != null
          ? isPreviewMode.value
          : this.isPreviewMode),
      isSettingsPreview: (isSettingsPreview != null
          ? isSettingsPreview.value
          : this.isSettingsPreview),
      isOwnerDataPreview: (isOwnerDataPreview != null
          ? isOwnerDataPreview.value
          : this.isOwnerDataPreview),
      isClientDataPreview: (isClientDataPreview != null
          ? isClientDataPreview.value
          : this.isClientDataPreview),
      isPublicPagePreview: (isPublicPagePreview != null
          ? isPublicPagePreview.value
          : this.isPublicPagePreview),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class PublicNodeInfo {
  const PublicNodeInfo({
    required this.id,
    required this.backendName,
    required this.alias,
    required this.color,
    required this.numPeers,
    required this.blockheight,
    required this.channelStats,
    required this.addresses,
  });

  factory PublicNodeInfo.fromJson(Map<String, dynamic> json) =>
      _$PublicNodeInfoFromJson(json);

  static const toJsonFactory = _$PublicNodeInfoToJson;
  Map<String, dynamic> toJson() => _$PublicNodeInfoToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'backend_name', includeIfNull: false)
  final String backendName;
  @JsonKey(name: 'alias', includeIfNull: false)
  final String alias;
  @JsonKey(name: 'color', includeIfNull: false)
  final String color;
  @JsonKey(name: 'num_peers', includeIfNull: false)
  final int numPeers;
  @JsonKey(name: 'blockheight', includeIfNull: false)
  final int blockheight;
  @JsonKey(name: 'channel_stats', includeIfNull: false)
  final ChannelStats channelStats;
  @JsonKey(name: 'addresses', includeIfNull: false, defaultValue: <String>[])
  final List<String> addresses;
  static const fromJsonFactory = _$PublicNodeInfoFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PublicNodeInfo &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.backendName, backendName) ||
                const DeepCollectionEquality().equals(
                  other.backendName,
                  backendName,
                )) &&
            (identical(other.alias, alias) ||
                const DeepCollectionEquality().equals(other.alias, alias)) &&
            (identical(other.color, color) ||
                const DeepCollectionEquality().equals(other.color, color)) &&
            (identical(other.numPeers, numPeers) ||
                const DeepCollectionEquality().equals(
                  other.numPeers,
                  numPeers,
                )) &&
            (identical(other.blockheight, blockheight) ||
                const DeepCollectionEquality().equals(
                  other.blockheight,
                  blockheight,
                )) &&
            (identical(other.channelStats, channelStats) ||
                const DeepCollectionEquality().equals(
                  other.channelStats,
                  channelStats,
                )) &&
            (identical(other.addresses, addresses) ||
                const DeepCollectionEquality().equals(
                  other.addresses,
                  addresses,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(backendName) ^
      const DeepCollectionEquality().hash(alias) ^
      const DeepCollectionEquality().hash(color) ^
      const DeepCollectionEquality().hash(numPeers) ^
      const DeepCollectionEquality().hash(blockheight) ^
      const DeepCollectionEquality().hash(channelStats) ^
      const DeepCollectionEquality().hash(addresses) ^
      runtimeType.hashCode;
}

extension $PublicNodeInfoExtension on PublicNodeInfo {
  PublicNodeInfo copyWith({
    String? id,
    String? backendName,
    String? alias,
    String? color,
    int? numPeers,
    int? blockheight,
    ChannelStats? channelStats,
    List<String>? addresses,
  }) {
    return PublicNodeInfo(
      id: id ?? this.id,
      backendName: backendName ?? this.backendName,
      alias: alias ?? this.alias,
      color: color ?? this.color,
      numPeers: numPeers ?? this.numPeers,
      blockheight: blockheight ?? this.blockheight,
      channelStats: channelStats ?? this.channelStats,
      addresses: addresses ?? this.addresses,
    );
  }

  PublicNodeInfo copyWithWrapped({
    Wrapped<String>? id,
    Wrapped<String>? backendName,
    Wrapped<String>? alias,
    Wrapped<String>? color,
    Wrapped<int>? numPeers,
    Wrapped<int>? blockheight,
    Wrapped<ChannelStats>? channelStats,
    Wrapped<List<String>>? addresses,
  }) {
    return PublicNodeInfo(
      id: (id != null ? id.value : this.id),
      backendName: (backendName != null ? backendName.value : this.backendName),
      alias: (alias != null ? alias.value : this.alias),
      color: (color != null ? color.value : this.color),
      numPeers: (numPeers != null ? numPeers.value : this.numPeers),
      blockheight: (blockheight != null ? blockheight.value : this.blockheight),
      channelStats: (channelStats != null
          ? channelStats.value
          : this.channelStats),
      addresses: (addresses != null ? addresses.value : this.addresses),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class PublicPageFields {
  const PublicPageFields({
    this.hasPublicPage,
    required this.ownerDataFields,
    required this.clientDataFields,
    required this.actionFields,
  });

  factory PublicPageFields.fromJson(Map<String, dynamic> json) =>
      _$PublicPageFieldsFromJson(json);

  static const toJsonFactory = _$PublicPageFieldsToJson;
  Map<String, dynamic> toJson() => _$PublicPageFieldsToJson(this);

  @JsonKey(name: 'has_public_page', includeIfNull: false, defaultValue: false)
  final bool? hasPublicPage;
  @JsonKey(name: 'owner_data_fields', includeIfNull: false)
  final OwnerDataFields ownerDataFields;
  @JsonKey(name: 'client_data_fields', includeIfNull: false)
  final ClientDataFields clientDataFields;
  @JsonKey(name: 'action_fields', includeIfNull: false)
  final ActionFields actionFields;
  static const fromJsonFactory = _$PublicPageFieldsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PublicPageFields &&
            (identical(other.hasPublicPage, hasPublicPage) ||
                const DeepCollectionEquality().equals(
                  other.hasPublicPage,
                  hasPublicPage,
                )) &&
            (identical(other.ownerDataFields, ownerDataFields) ||
                const DeepCollectionEquality().equals(
                  other.ownerDataFields,
                  ownerDataFields,
                )) &&
            (identical(other.clientDataFields, clientDataFields) ||
                const DeepCollectionEquality().equals(
                  other.clientDataFields,
                  clientDataFields,
                )) &&
            (identical(other.actionFields, actionFields) ||
                const DeepCollectionEquality().equals(
                  other.actionFields,
                  actionFields,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(hasPublicPage) ^
      const DeepCollectionEquality().hash(ownerDataFields) ^
      const DeepCollectionEquality().hash(clientDataFields) ^
      const DeepCollectionEquality().hash(actionFields) ^
      runtimeType.hashCode;
}

extension $PublicPageFieldsExtension on PublicPageFields {
  PublicPageFields copyWith({
    bool? hasPublicPage,
    OwnerDataFields? ownerDataFields,
    ClientDataFields? clientDataFields,
    ActionFields? actionFields,
  }) {
    return PublicPageFields(
      hasPublicPage: hasPublicPage ?? this.hasPublicPage,
      ownerDataFields: ownerDataFields ?? this.ownerDataFields,
      clientDataFields: clientDataFields ?? this.clientDataFields,
      actionFields: actionFields ?? this.actionFields,
    );
  }

  PublicPageFields copyWithWrapped({
    Wrapped<bool?>? hasPublicPage,
    Wrapped<OwnerDataFields>? ownerDataFields,
    Wrapped<ClientDataFields>? clientDataFields,
    Wrapped<ActionFields>? actionFields,
  }) {
    return PublicPageFields(
      hasPublicPage: (hasPublicPage != null
          ? hasPublicPage.value
          : this.hasPublicPage),
      ownerDataFields: (ownerDataFields != null
          ? ownerDataFields.value
          : this.ownerDataFields),
      clientDataFields: (clientDataFields != null
          ? clientDataFields.value
          : this.clientDataFields),
      actionFields: (actionFields != null
          ? actionFields.value
          : this.actionFields),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class RegisterUser {
  const RegisterUser({
    this.email,
    required this.username,
    required this.password,
    required this.passwordRepeat,
  });

  factory RegisterUser.fromJson(Map<String, dynamic> json) =>
      _$RegisterUserFromJson(json);

  static const toJsonFactory = _$RegisterUserToJson;
  Map<String, dynamic> toJson() => _$RegisterUserToJson(this);

  @JsonKey(name: 'email', includeIfNull: false)
  final String? email;
  @JsonKey(name: 'username', includeIfNull: false)
  final String username;
  @JsonKey(name: 'password', includeIfNull: false)
  final String password;
  @JsonKey(name: 'password_repeat', includeIfNull: false)
  final String passwordRepeat;
  static const fromJsonFactory = _$RegisterUserFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RegisterUser &&
            (identical(other.email, email) ||
                const DeepCollectionEquality().equals(other.email, email)) &&
            (identical(other.username, username) ||
                const DeepCollectionEquality().equals(
                  other.username,
                  username,
                )) &&
            (identical(other.password, password) ||
                const DeepCollectionEquality().equals(
                  other.password,
                  password,
                )) &&
            (identical(other.passwordRepeat, passwordRepeat) ||
                const DeepCollectionEquality().equals(
                  other.passwordRepeat,
                  passwordRepeat,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(email) ^
      const DeepCollectionEquality().hash(username) ^
      const DeepCollectionEquality().hash(password) ^
      const DeepCollectionEquality().hash(passwordRepeat) ^
      runtimeType.hashCode;
}

extension $RegisterUserExtension on RegisterUser {
  RegisterUser copyWith({
    String? email,
    String? username,
    String? password,
    String? passwordRepeat,
  }) {
    return RegisterUser(
      email: email ?? this.email,
      username: username ?? this.username,
      password: password ?? this.password,
      passwordRepeat: passwordRepeat ?? this.passwordRepeat,
    );
  }

  RegisterUser copyWithWrapped({
    Wrapped<String?>? email,
    Wrapped<String>? username,
    Wrapped<String>? password,
    Wrapped<String>? passwordRepeat,
  }) {
    return RegisterUser(
      email: (email != null ? email.value : this.email),
      username: (username != null ? username.value : this.username),
      password: (password != null ? password.value : this.password),
      passwordRepeat: (passwordRepeat != null
          ? passwordRepeat.value
          : this.passwordRepeat),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ReleasePaymentInfo {
  const ReleasePaymentInfo({
    this.amount,
    this.payLink,
    this.paymentHash,
    this.paymentRequest,
  });

  factory ReleasePaymentInfo.fromJson(Map<String, dynamic> json) =>
      _$ReleasePaymentInfoFromJson(json);

  static const toJsonFactory = _$ReleasePaymentInfoToJson;
  Map<String, dynamic> toJson() => _$ReleasePaymentInfoToJson(this);

  @JsonKey(name: 'amount', includeIfNull: false)
  final int? amount;
  @JsonKey(name: 'pay_link', includeIfNull: false)
  final String? payLink;
  @JsonKey(name: 'payment_hash', includeIfNull: false)
  final String? paymentHash;
  @JsonKey(name: 'payment_request', includeIfNull: false)
  final String? paymentRequest;
  static const fromJsonFactory = _$ReleasePaymentInfoFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ReleasePaymentInfo &&
            (identical(other.amount, amount) ||
                const DeepCollectionEquality().equals(other.amount, amount)) &&
            (identical(other.payLink, payLink) ||
                const DeepCollectionEquality().equals(
                  other.payLink,
                  payLink,
                )) &&
            (identical(other.paymentHash, paymentHash) ||
                const DeepCollectionEquality().equals(
                  other.paymentHash,
                  paymentHash,
                )) &&
            (identical(other.paymentRequest, paymentRequest) ||
                const DeepCollectionEquality().equals(
                  other.paymentRequest,
                  paymentRequest,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(amount) ^
      const DeepCollectionEquality().hash(payLink) ^
      const DeepCollectionEquality().hash(paymentHash) ^
      const DeepCollectionEquality().hash(paymentRequest) ^
      runtimeType.hashCode;
}

extension $ReleasePaymentInfoExtension on ReleasePaymentInfo {
  ReleasePaymentInfo copyWith({
    int? amount,
    String? payLink,
    String? paymentHash,
    String? paymentRequest,
  }) {
    return ReleasePaymentInfo(
      amount: amount ?? this.amount,
      payLink: payLink ?? this.payLink,
      paymentHash: paymentHash ?? this.paymentHash,
      paymentRequest: paymentRequest ?? this.paymentRequest,
    );
  }

  ReleasePaymentInfo copyWithWrapped({
    Wrapped<int?>? amount,
    Wrapped<String?>? payLink,
    Wrapped<String?>? paymentHash,
    Wrapped<String?>? paymentRequest,
  }) {
    return ReleasePaymentInfo(
      amount: (amount != null ? amount.value : this.amount),
      payLink: (payLink != null ? payLink.value : this.payLink),
      paymentHash: (paymentHash != null ? paymentHash.value : this.paymentHash),
      paymentRequest: (paymentRequest != null
          ? paymentRequest.value
          : this.paymentRequest),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ResetUserPassword {
  const ResetUserPassword({
    required this.resetKey,
    required this.password,
    required this.passwordRepeat,
  });

  factory ResetUserPassword.fromJson(Map<String, dynamic> json) =>
      _$ResetUserPasswordFromJson(json);

  static const toJsonFactory = _$ResetUserPasswordToJson;
  Map<String, dynamic> toJson() => _$ResetUserPasswordToJson(this);

  @JsonKey(name: 'reset_key', includeIfNull: false)
  final String resetKey;
  @JsonKey(name: 'password', includeIfNull: false)
  final String password;
  @JsonKey(name: 'password_repeat', includeIfNull: false)
  final String passwordRepeat;
  static const fromJsonFactory = _$ResetUserPasswordFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ResetUserPassword &&
            (identical(other.resetKey, resetKey) ||
                const DeepCollectionEquality().equals(
                  other.resetKey,
                  resetKey,
                )) &&
            (identical(other.password, password) ||
                const DeepCollectionEquality().equals(
                  other.password,
                  password,
                )) &&
            (identical(other.passwordRepeat, passwordRepeat) ||
                const DeepCollectionEquality().equals(
                  other.passwordRepeat,
                  passwordRepeat,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(resetKey) ^
      const DeepCollectionEquality().hash(password) ^
      const DeepCollectionEquality().hash(passwordRepeat) ^
      runtimeType.hashCode;
}

extension $ResetUserPasswordExtension on ResetUserPassword {
  ResetUserPassword copyWith({
    String? resetKey,
    String? password,
    String? passwordRepeat,
  }) {
    return ResetUserPassword(
      resetKey: resetKey ?? this.resetKey,
      password: password ?? this.password,
      passwordRepeat: passwordRepeat ?? this.passwordRepeat,
    );
  }

  ResetUserPassword copyWithWrapped({
    Wrapped<String>? resetKey,
    Wrapped<String>? password,
    Wrapped<String>? passwordRepeat,
  }) {
    return ResetUserPassword(
      resetKey: (resetKey != null ? resetKey.value : this.resetKey),
      password: (password != null ? password.value : this.password),
      passwordRepeat: (passwordRepeat != null
          ? passwordRepeat.value
          : this.passwordRepeat),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class SettingsFields {
  const SettingsFields({
    required this.name,
    this.editable,
    this.fields,
    this.enabled,
    this.type,
  });

  factory SettingsFields.fromJson(Map<String, dynamic> json) =>
      _$SettingsFieldsFromJson(json);

  static const toJsonFactory = _$SettingsFieldsToJson;
  Map<String, dynamic> toJson() => _$SettingsFieldsToJson(this);

  @JsonKey(name: 'name', includeIfNull: false)
  final String name;
  @JsonKey(name: 'editable', includeIfNull: false, defaultValue: true)
  final bool? editable;
  @JsonKey(name: 'fields', includeIfNull: false, defaultValue: <DataField>[])
  final List<DataField>? fields;
  @JsonKey(name: 'enabled', includeIfNull: false, defaultValue: false)
  final bool? enabled;
  @JsonKey(name: 'type', includeIfNull: false)
  final String? type;
  static const fromJsonFactory = _$SettingsFieldsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SettingsFields &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.editable, editable) ||
                const DeepCollectionEquality().equals(
                  other.editable,
                  editable,
                )) &&
            (identical(other.fields, fields) ||
                const DeepCollectionEquality().equals(other.fields, fields)) &&
            (identical(other.enabled, enabled) ||
                const DeepCollectionEquality().equals(
                  other.enabled,
                  enabled,
                )) &&
            (identical(other.type, type) ||
                const DeepCollectionEquality().equals(other.type, type)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(editable) ^
      const DeepCollectionEquality().hash(fields) ^
      const DeepCollectionEquality().hash(enabled) ^
      const DeepCollectionEquality().hash(type) ^
      runtimeType.hashCode;
}

extension $SettingsFieldsExtension on SettingsFields {
  SettingsFields copyWith({
    String? name,
    bool? editable,
    List<DataField>? fields,
    bool? enabled,
    String? type,
  }) {
    return SettingsFields(
      name: name ?? this.name,
      editable: editable ?? this.editable,
      fields: fields ?? this.fields,
      enabled: enabled ?? this.enabled,
      type: type ?? this.type,
    );
  }

  SettingsFields copyWithWrapped({
    Wrapped<String>? name,
    Wrapped<bool?>? editable,
    Wrapped<List<DataField>?>? fields,
    Wrapped<bool?>? enabled,
    Wrapped<String?>? type,
  }) {
    return SettingsFields(
      name: (name != null ? name.value : this.name),
      editable: (editable != null ? editable.value : this.editable),
      fields: (fields != null ? fields.value : this.fields),
      enabled: (enabled != null ? enabled.value : this.enabled),
      type: (type != null ? type.value : this.type),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class SettleInvoice {
  const SettleInvoice({required this.preimage});

  factory SettleInvoice.fromJson(Map<String, dynamic> json) =>
      _$SettleInvoiceFromJson(json);

  static const toJsonFactory = _$SettleInvoiceToJson;
  Map<String, dynamic> toJson() => _$SettleInvoiceToJson(this);

  @JsonKey(name: 'preimage', includeIfNull: false)
  final String preimage;
  static const fromJsonFactory = _$SettleInvoiceFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SettleInvoice &&
            (identical(other.preimage, preimage) ||
                const DeepCollectionEquality().equals(
                  other.preimage,
                  preimage,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(preimage) ^ runtimeType.hashCode;
}

extension $SettleInvoiceExtension on SettleInvoice {
  SettleInvoice copyWith({String? preimage}) {
    return SettleInvoice(preimage: preimage ?? this.preimage);
  }

  SettleInvoice copyWithWrapped({Wrapped<String>? preimage}) {
    return SettleInvoice(
      preimage: (preimage != null ? preimage.value : this.preimage),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class SimpleItem {
  const SimpleItem({required this.id, required this.name});

  factory SimpleItem.fromJson(Map<String, dynamic> json) =>
      _$SimpleItemFromJson(json);

  static const toJsonFactory = _$SimpleItemToJson;
  Map<String, dynamic> toJson() => _$SimpleItemToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'name', includeIfNull: false)
  final String name;
  static const fromJsonFactory = _$SimpleItemFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SimpleItem &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(name) ^
      runtimeType.hashCode;
}

extension $SimpleItemExtension on SimpleItem {
  SimpleItem copyWith({String? id, String? name}) {
    return SimpleItem(id: id ?? this.id, name: name ?? this.name);
  }

  SimpleItem copyWithWrapped({Wrapped<String>? id, Wrapped<String>? name}) {
    return SimpleItem(
      id: (id != null ? id.value : this.id),
      name: (name != null ? name.value : this.name),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class SimpleStatus {
  const SimpleStatus({required this.success, required this.message});

  factory SimpleStatus.fromJson(Map<String, dynamic> json) =>
      _$SimpleStatusFromJson(json);

  static const toJsonFactory = _$SimpleStatusToJson;
  Map<String, dynamic> toJson() => _$SimpleStatusToJson(this);

  @JsonKey(name: 'success', includeIfNull: false)
  final bool success;
  @JsonKey(name: 'message', includeIfNull: false)
  final String message;
  static const fromJsonFactory = _$SimpleStatusFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SimpleStatus &&
            (identical(other.success, success) ||
                const DeepCollectionEquality().equals(
                  other.success,
                  success,
                )) &&
            (identical(other.message, message) ||
                const DeepCollectionEquality().equals(other.message, message)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(success) ^
      const DeepCollectionEquality().hash(message) ^
      runtimeType.hashCode;
}

extension $SimpleStatusExtension on SimpleStatus {
  SimpleStatus copyWith({bool? success, String? message}) {
    return SimpleStatus(
      success: success ?? this.success,
      message: message ?? this.message,
    );
  }

  SimpleStatus copyWithWrapped({
    Wrapped<bool>? success,
    Wrapped<String>? message,
  }) {
    return SimpleStatus(
      success: (success != null ? success.value : this.success),
      message: (message != null ? message.value : this.message),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class StoredPayLink {
  const StoredPayLink({
    required this.lnurl,
    required this.label,
    this.lastUsed,
  });

  factory StoredPayLink.fromJson(Map<String, dynamic> json) =>
      _$StoredPayLinkFromJson(json);

  static const toJsonFactory = _$StoredPayLinkToJson;
  Map<String, dynamic> toJson() => _$StoredPayLinkToJson(this);

  @JsonKey(name: 'lnurl', includeIfNull: false)
  final String lnurl;
  @JsonKey(name: 'label', includeIfNull: false)
  final String label;
  @JsonKey(name: 'last_used', includeIfNull: false)
  final int? lastUsed;
  static const fromJsonFactory = _$StoredPayLinkFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is StoredPayLink &&
            (identical(other.lnurl, lnurl) ||
                const DeepCollectionEquality().equals(other.lnurl, lnurl)) &&
            (identical(other.label, label) ||
                const DeepCollectionEquality().equals(other.label, label)) &&
            (identical(other.lastUsed, lastUsed) ||
                const DeepCollectionEquality().equals(
                  other.lastUsed,
                  lastUsed,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(lnurl) ^
      const DeepCollectionEquality().hash(label) ^
      const DeepCollectionEquality().hash(lastUsed) ^
      runtimeType.hashCode;
}

extension $StoredPayLinkExtension on StoredPayLink {
  StoredPayLink copyWith({String? lnurl, String? label, int? lastUsed}) {
    return StoredPayLink(
      lnurl: lnurl ?? this.lnurl,
      label: label ?? this.label,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  StoredPayLink copyWithWrapped({
    Wrapped<String>? lnurl,
    Wrapped<String>? label,
    Wrapped<int?>? lastUsed,
  }) {
    return StoredPayLink(
      lnurl: (lnurl != null ? lnurl.value : this.lnurl),
      label: (label != null ? label.value : this.label),
      lastUsed: (lastUsed != null ? lastUsed.value : this.lastUsed),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class StoredPayLinks {
  const StoredPayLinks({this.links});

  factory StoredPayLinks.fromJson(Map<String, dynamic> json) =>
      _$StoredPayLinksFromJson(json);

  static const toJsonFactory = _$StoredPayLinksToJson;
  Map<String, dynamic> toJson() => _$StoredPayLinksToJson(this);

  @JsonKey(name: 'links', includeIfNull: false, defaultValue: <StoredPayLink>[])
  final List<StoredPayLink>? links;
  static const fromJsonFactory = _$StoredPayLinksFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is StoredPayLinks &&
            (identical(other.links, links) ||
                const DeepCollectionEquality().equals(other.links, links)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(links) ^ runtimeType.hashCode;
}

extension $StoredPayLinksExtension on StoredPayLinks {
  StoredPayLinks copyWith({List<StoredPayLink>? links}) {
    return StoredPayLinks(links: links ?? this.links);
  }

  StoredPayLinks copyWithWrapped({Wrapped<List<StoredPayLink>?>? links}) {
    return StoredPayLinks(links: (links != null ? links.value : this.links));
  }
}

@JsonSerializable(explicitToJson: true)
class UpdateAccessControlList {
  const UpdateAccessControlList({
    required this.id,
    required this.name,
    this.endpoints,
    this.tokenIdList,
    required this.password,
  });

  factory UpdateAccessControlList.fromJson(Map<String, dynamic> json) =>
      _$UpdateAccessControlListFromJson(json);

  static const toJsonFactory = _$UpdateAccessControlListToJson;
  Map<String, dynamic> toJson() => _$UpdateAccessControlListToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'name', includeIfNull: false)
  final String name;
  @JsonKey(
    name: 'endpoints',
    includeIfNull: false,
    defaultValue: <EndpointAccess>[],
  )
  final List<EndpointAccess>? endpoints;
  @JsonKey(
    name: 'token_id_list',
    includeIfNull: false,
    defaultValue: <SimpleItem>[],
  )
  final List<SimpleItem>? tokenIdList;
  @JsonKey(name: 'password', includeIfNull: false)
  final String password;
  static const fromJsonFactory = _$UpdateAccessControlListFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UpdateAccessControlList &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.endpoints, endpoints) ||
                const DeepCollectionEquality().equals(
                  other.endpoints,
                  endpoints,
                )) &&
            (identical(other.tokenIdList, tokenIdList) ||
                const DeepCollectionEquality().equals(
                  other.tokenIdList,
                  tokenIdList,
                )) &&
            (identical(other.password, password) ||
                const DeepCollectionEquality().equals(
                  other.password,
                  password,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(endpoints) ^
      const DeepCollectionEquality().hash(tokenIdList) ^
      const DeepCollectionEquality().hash(password) ^
      runtimeType.hashCode;
}

extension $UpdateAccessControlListExtension on UpdateAccessControlList {
  UpdateAccessControlList copyWith({
    String? id,
    String? name,
    List<EndpointAccess>? endpoints,
    List<SimpleItem>? tokenIdList,
    String? password,
  }) {
    return UpdateAccessControlList(
      id: id ?? this.id,
      name: name ?? this.name,
      endpoints: endpoints ?? this.endpoints,
      tokenIdList: tokenIdList ?? this.tokenIdList,
      password: password ?? this.password,
    );
  }

  UpdateAccessControlList copyWithWrapped({
    Wrapped<String>? id,
    Wrapped<String>? name,
    Wrapped<List<EndpointAccess>?>? endpoints,
    Wrapped<List<SimpleItem>?>? tokenIdList,
    Wrapped<String>? password,
  }) {
    return UpdateAccessControlList(
      id: (id != null ? id.value : this.id),
      name: (name != null ? name.value : this.name),
      endpoints: (endpoints != null ? endpoints.value : this.endpoints),
      tokenIdList: (tokenIdList != null ? tokenIdList.value : this.tokenIdList),
      password: (password != null ? password.value : this.password),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class UpdateBalance {
  const UpdateBalance({required this.id, required this.amount});

  factory UpdateBalance.fromJson(Map<String, dynamic> json) =>
      _$UpdateBalanceFromJson(json);

  static const toJsonFactory = _$UpdateBalanceToJson;
  Map<String, dynamic> toJson() => _$UpdateBalanceToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'amount', includeIfNull: false)
  final int amount;
  static const fromJsonFactory = _$UpdateBalanceFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UpdateBalance &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.amount, amount) ||
                const DeepCollectionEquality().equals(other.amount, amount)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(amount) ^
      runtimeType.hashCode;
}

extension $UpdateBalanceExtension on UpdateBalance {
  UpdateBalance copyWith({String? id, int? amount}) {
    return UpdateBalance(id: id ?? this.id, amount: amount ?? this.amount);
  }

  UpdateBalance copyWithWrapped({Wrapped<String>? id, Wrapped<int>? amount}) {
    return UpdateBalance(
      id: (id != null ? id.value : this.id),
      amount: (amount != null ? amount.value : this.amount),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class UpdatePaymentLabels {
  const UpdatePaymentLabels({this.labels});

  factory UpdatePaymentLabels.fromJson(Map<String, dynamic> json) =>
      _$UpdatePaymentLabelsFromJson(json);

  static const toJsonFactory = _$UpdatePaymentLabelsToJson;
  Map<String, dynamic> toJson() => _$UpdatePaymentLabelsToJson(this);

  @JsonKey(name: 'labels', includeIfNull: false, defaultValue: <String>[])
  final List<String>? labels;
  static const fromJsonFactory = _$UpdatePaymentLabelsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UpdatePaymentLabels &&
            (identical(other.labels, labels) ||
                const DeepCollectionEquality().equals(other.labels, labels)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(labels) ^ runtimeType.hashCode;
}

extension $UpdatePaymentLabelsExtension on UpdatePaymentLabels {
  UpdatePaymentLabels copyWith({List<String>? labels}) {
    return UpdatePaymentLabels(labels: labels ?? this.labels);
  }

  UpdatePaymentLabels copyWithWrapped({Wrapped<List<String>?>? labels}) {
    return UpdatePaymentLabels(
      labels: (labels != null ? labels.value : this.labels),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class UpdateSettings {
  const UpdateSettings({
    this.keycloakDiscoveryUrl,
    this.keycloakClientId,
    this.keycloakClientSecret,
    this.keycloakClientCustomOrg,
    this.keycloakClientCustomIcon,
    this.githubClientId,
    this.githubClientSecret,
    this.googleClientId,
    this.googleClientSecret,
    this.nostrAbsoluteRequestUrls,
    this.authTokenExpireMinutes,
    this.authAllMethods,
    this.authAllowedMethods,
    this.authCredetialsUpdateThreshold,
    this.authAuthenticationCacheMinutes,
    this.lnbitsAuditEnabled,
    this.lnbitsAuditRetentionDays,
    this.lnbitsAuditLogIpAddress,
    this.lnbitsAuditLogPathParams,
    this.lnbitsAuditLogQueryParams,
    this.lnbitsAuditLogRequestBody,
    this.lnbitsAuditIncludePaths,
    this.lnbitsAuditExcludePaths,
    this.lnbitsAuditHttpMethods,
    this.lnbitsAuditHttpResponseCodes,
    this.lnbitsNodeUi,
    this.lnbitsPublicNodeUi,
    this.lnbitsNodeUiTransactions,
    this.lnbitsWebpushPubkey,
    this.lnbitsWebpushPrivkey,
    this.lightningInvoiceExpiry,
    this.paypalEnabled,
    this.paypalApiEndpoint,
    this.paypalClientId,
    this.paypalClientSecret,
    this.paypalPaymentSuccessUrl,
    this.paypalPaymentWebhookUrl,
    this.paypalWebhookId,
    this.paypalLimits,
    this.stripeEnabled,
    this.stripeApiEndpoint,
    this.stripeApiSecretKey,
    this.stripePaymentSuccessUrl,
    this.stripePaymentWebhookUrl,
    this.stripeWebhookSigningSecret,
    this.stripeLimits,
    this.breezLiquidApiKey,
    this.breezLiquidSeed,
    this.breezLiquidFeeOffsetSat,
    this.strikeApiEndpoint,
    this.strikeApiKey,
    this.breezApiKey,
    this.breezGreenlightSeed,
    this.breezGreenlightInviteCode,
    this.breezGreenlightDeviceKey,
    this.breezGreenlightDeviceCert,
    this.breezUseTrampoline,
    this.nwcPairingUrl,
    this.lntipsApiEndpoint,
    this.lntipsApiKey,
    this.lntipsAdminKey,
    this.lntipsInvoiceKey,
    this.sparkUrl,
    this.sparkToken,
    this.opennodeApiEndpoint,
    this.opennodeKey,
    this.opennodeAdminKey,
    this.opennodeInvoiceKey,
    this.phoenixdApiEndpoint,
    this.phoenixdApiPassword,
    this.zbdApiEndpoint,
    this.zbdApiKey,
    this.boltzClientEndpoint,
    this.boltzClientMacaroon,
    this.boltzClientPassword,
    this.boltzClientCert,
    this.boltzMnemonic,
    this.albyApiEndpoint,
    this.albyAccessToken,
    this.blinkApiEndpoint,
    this.blinkWsEndpoint,
    this.blinkToken,
    this.lnpayApiEndpoint,
    this.lnpayApiKey,
    this.lnpayWalletKey,
    this.lnpayAdminKey,
    this.lndGrpcEndpoint,
    this.lndGrpcCert,
    this.lndGrpcPort,
    this.lndGrpcAdminMacaroon,
    this.lndGrpcInvoiceMacaroon,
    this.lndGrpcMacaroon,
    this.lndGrpcMacaroonEncrypted,
    this.lndRestEndpoint,
    this.lndRestCert,
    this.lndRestMacaroon,
    this.lndRestMacaroonEncrypted,
    this.lndRestRouteHints,
    this.lndRestAllowSelfPayment,
    this.lndCert,
    this.lndAdminMacaroon,
    this.lndInvoiceMacaroon,
    this.lndRestAdminMacaroon,
    this.lndRestInvoiceMacaroon,
    this.eclairUrl,
    this.eclairPass,
    this.corelightningRestUrl,
    this.corelightningRestMacaroon,
    this.corelightningRestCert,
    this.corelightningRpc,
    this.corelightningPayCommand,
    this.clightningRpc,
    this.clnrestUrl,
    this.clnrestCa,
    this.clnrestCert,
    this.clnrestReadonlyRune,
    this.clnrestInvoiceRune,
    this.clnrestPayRune,
    this.clnrestRenepayRune,
    this.clnrestLastPayIndex,
    this.clnrestNodeid,
    this.clicheEndpoint,
    this.lnbitsEndpoint,
    this.lnbitsKey,
    this.lnbitsAdminKey,
    this.lnbitsInvoiceKey,
    this.fakeWalletSecret,
    this.lnbitsDenomination,
    this.lnbitsBackendWalletClass,
    this.lnbitsFundingSourcePayInvoiceWaitSeconds,
    this.fundingSourceMaxRetries,
    this.lnbitsNostrNotificationsEnabled,
    this.lnbitsNostrNotificationsPrivateKey,
    this.lnbitsNostrNotificationsIdentifiers,
    this.lnbitsTelegramNotificationsEnabled,
    this.lnbitsTelegramNotificationsAccessToken,
    this.lnbitsTelegramNotificationsChatId,
    this.lnbitsEmailNotificationsEnabled,
    this.lnbitsEmailNotificationsEmail,
    this.lnbitsEmailNotificationsUsername,
    this.lnbitsEmailNotificationsPassword,
    this.lnbitsEmailNotificationsServer,
    this.lnbitsEmailNotificationsPort,
    this.lnbitsEmailNotificationsToEmails,
    this.lnbitsNotificationSettingsUpdate,
    this.lnbitsNotificationCreditDebit,
    this.notificationBalanceDeltaThresholdSats,
    this.lnbitsNotificationServerStartStop,
    this.lnbitsNotificationWatchdog,
    this.lnbitsNotificationServerStatusHours,
    this.lnbitsNotificationIncomingPaymentAmountSats,
    this.lnbitsNotificationOutgoingPaymentAmountSats,
    this.lnbitsRateLimitNo,
    this.lnbitsRateLimitUnit,
    this.lnbitsAllowedIps,
    this.lnbitsBlockedIps,
    this.lnbitsCallbackUrlRules,
    this.lnbitsWalletLimitMaxBalance,
    this.lnbitsWalletLimitDailyMaxWithdraw,
    this.lnbitsWalletLimitSecsBetweenTrans,
    this.lnbitsOnlyAllowIncomingPayments,
    this.lnbitsWatchdogSwitchToVoidwallet,
    this.lnbitsWatchdogIntervalMinutes,
    this.lnbitsWatchdogDelta,
    this.lnbitsMaxOutgoingPaymentAmountSats,
    this.lnbitsMaxIncomingPaymentAmountSats,
    this.lnbitsExchangeRateCacheSeconds,
    this.lnbitsExchangeHistorySize,
    this.lnbitsExchangeHistoryRefreshIntervalSeconds,
    this.lnbitsExchangeRateProviders,
    this.lnbitsReserveFeeMin,
    this.lnbitsReserveFeePercent,
    this.lnbitsServiceFee,
    this.lnbitsServiceFeeIgnoreInternal,
    this.lnbitsServiceFeeMax,
    this.lnbitsServiceFeeWallet,
    this.lnbitsMaxAssetSizeMb,
    this.lnbitsAssetsAllowedMimeTypes,
    this.lnbitsAssetThumbnailWidth,
    this.lnbitsAssetThumbnailHeight,
    this.lnbitsAssetThumbnailFormat,
    this.lnbitsMaxAssetsPerUser,
    this.lnbitsAssetsNoLimitUsers,
    this.lnbitsBaseurl,
    this.lnbitsHideApi,
    this.lnbitsSiteTitle,
    this.lnbitsSiteTagline,
    this.lnbitsSiteDescription,
    this.lnbitsShowHomePageElements,
    this.lnbitsDefaultWalletName,
    this.lnbitsCustomBadge,
    this.lnbitsCustomBadgeColor,
    this.lnbitsThemeOptions,
    this.lnbitsCustomLogo,
    this.lnbitsCustomImage,
    this.lnbitsAdSpaceTitle,
    this.lnbitsAdSpace,
    this.lnbitsAdSpaceEnabled,
    this.lnbitsAllowedCurrencies,
    this.lnbitsDefaultAccountingCurrency,
    this.lnbitsQrLogo,
    this.lnbitsAppleTouchIcon,
    this.lnbitsDefaultReaction,
    this.lnbitsDefaultTheme,
    this.lnbitsDefaultBorder,
    this.lnbitsDefaultGradient,
    this.lnbitsDefaultBgimage,
    this.lnbitsAdminExtensions,
    this.lnbitsUserDefaultExtensions,
    this.lnbitsExtensionsDeactivateAll,
    this.lnbitsExtensionsBuilderActivateNonAdmins,
    this.lnbitsExtensionsReviewsUrl,
    this.lnbitsExtensionsManifests,
    this.lnbitsExtensionsBuilderManifestUrl,
    this.lnbitsAdminUsers,
    this.lnbitsAllowedUsers,
    this.lnbitsAllowNewAccounts,
  });

  factory UpdateSettings.fromJson(Map<String, dynamic> json) =>
      _$UpdateSettingsFromJson(json);

  static const toJsonFactory = _$UpdateSettingsToJson;
  Map<String, dynamic> toJson() => _$UpdateSettingsToJson(this);

  @JsonKey(name: 'keycloak_discovery_url', includeIfNull: false)
  final String? keycloakDiscoveryUrl;
  @JsonKey(name: 'keycloak_client_id', includeIfNull: false)
  final String? keycloakClientId;
  @JsonKey(name: 'keycloak_client_secret', includeIfNull: false)
  final String? keycloakClientSecret;
  @JsonKey(name: 'keycloak_client_custom_org', includeIfNull: false)
  final String? keycloakClientCustomOrg;
  @JsonKey(name: 'keycloak_client_custom_icon', includeIfNull: false)
  final String? keycloakClientCustomIcon;
  @JsonKey(name: 'github_client_id', includeIfNull: false)
  final String? githubClientId;
  @JsonKey(name: 'github_client_secret', includeIfNull: false)
  final String? githubClientSecret;
  @JsonKey(name: 'google_client_id', includeIfNull: false)
  final String? googleClientId;
  @JsonKey(name: 'google_client_secret', includeIfNull: false)
  final String? googleClientSecret;
  @JsonKey(
    name: 'nostr_absolute_request_urls',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? nostrAbsoluteRequestUrls;
  @JsonKey(name: 'auth_token_expire_minutes', includeIfNull: false)
  final int? authTokenExpireMinutes;
  @JsonKey(
    name: 'auth_all_methods',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? authAllMethods;
  @JsonKey(
    name: 'auth_allowed_methods',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? authAllowedMethods;
  @JsonKey(name: 'auth_credetials_update_threshold', includeIfNull: false)
  final int? authCredetialsUpdateThreshold;
  @JsonKey(name: 'auth_authentication_cache_minutes', includeIfNull: false)
  final int? authAuthenticationCacheMinutes;
  @JsonKey(
    name: 'lnbits_audit_enabled',
    includeIfNull: false,
    defaultValue: true,
  )
  final bool? lnbitsAuditEnabled;
  @JsonKey(name: 'lnbits_audit_retention_days', includeIfNull: false)
  final int? lnbitsAuditRetentionDays;
  @JsonKey(
    name: 'lnbits_audit_log_ip_address',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? lnbitsAuditLogIpAddress;
  @JsonKey(
    name: 'lnbits_audit_log_path_params',
    includeIfNull: false,
    defaultValue: true,
  )
  final bool? lnbitsAuditLogPathParams;
  @JsonKey(
    name: 'lnbits_audit_log_query_params',
    includeIfNull: false,
    defaultValue: true,
  )
  final bool? lnbitsAuditLogQueryParams;
  @JsonKey(
    name: 'lnbits_audit_log_request_body',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? lnbitsAuditLogRequestBody;
  @JsonKey(
    name: 'lnbits_audit_include_paths',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsAuditIncludePaths;
  @JsonKey(
    name: 'lnbits_audit_exclude_paths',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsAuditExcludePaths;
  @JsonKey(
    name: 'lnbits_audit_http_methods',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsAuditHttpMethods;
  @JsonKey(
    name: 'lnbits_audit_http_response_codes',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsAuditHttpResponseCodes;
  @JsonKey(name: 'lnbits_node_ui', includeIfNull: false, defaultValue: false)
  final bool? lnbitsNodeUi;
  @JsonKey(
    name: 'lnbits_public_node_ui',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? lnbitsPublicNodeUi;
  @JsonKey(
    name: 'lnbits_node_ui_transactions',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? lnbitsNodeUiTransactions;
  @JsonKey(name: 'lnbits_webpush_pubkey', includeIfNull: false)
  final String? lnbitsWebpushPubkey;
  @JsonKey(name: 'lnbits_webpush_privkey', includeIfNull: false)
  final String? lnbitsWebpushPrivkey;
  @JsonKey(name: 'lightning_invoice_expiry', includeIfNull: false)
  final int? lightningInvoiceExpiry;
  @JsonKey(name: 'paypal_enabled', includeIfNull: false, defaultValue: false)
  final bool? paypalEnabled;
  @JsonKey(name: 'paypal_api_endpoint', includeIfNull: false)
  final String? paypalApiEndpoint;
  @JsonKey(name: 'paypal_client_id', includeIfNull: false)
  final String? paypalClientId;
  @JsonKey(name: 'paypal_client_secret', includeIfNull: false)
  final String? paypalClientSecret;
  @JsonKey(name: 'paypal_payment_success_url', includeIfNull: false)
  final String? paypalPaymentSuccessUrl;
  @JsonKey(name: 'paypal_payment_webhook_url', includeIfNull: false)
  final String? paypalPaymentWebhookUrl;
  @JsonKey(name: 'paypal_webhook_id', includeIfNull: false)
  final String? paypalWebhookId;
  @JsonKey(name: 'paypal_limits', includeIfNull: false)
  final FiatProviderLimits? paypalLimits;
  @JsonKey(name: 'stripe_enabled', includeIfNull: false, defaultValue: false)
  final bool? stripeEnabled;
  @JsonKey(name: 'stripe_api_endpoint', includeIfNull: false)
  final String? stripeApiEndpoint;
  @JsonKey(name: 'stripe_api_secret_key', includeIfNull: false)
  final String? stripeApiSecretKey;
  @JsonKey(name: 'stripe_payment_success_url', includeIfNull: false)
  final String? stripePaymentSuccessUrl;
  @JsonKey(name: 'stripe_payment_webhook_url', includeIfNull: false)
  final String? stripePaymentWebhookUrl;
  @JsonKey(name: 'stripe_webhook_signing_secret', includeIfNull: false)
  final String? stripeWebhookSigningSecret;
  @JsonKey(name: 'stripe_limits', includeIfNull: false)
  final FiatProviderLimits? stripeLimits;
  @JsonKey(name: 'breez_liquid_api_key', includeIfNull: false)
  final String? breezLiquidApiKey;
  @JsonKey(name: 'breez_liquid_seed', includeIfNull: false)
  final String? breezLiquidSeed;
  @JsonKey(name: 'breez_liquid_fee_offset_sat', includeIfNull: false)
  final int? breezLiquidFeeOffsetSat;
  @JsonKey(name: 'strike_api_endpoint', includeIfNull: false)
  final String? strikeApiEndpoint;
  @JsonKey(name: 'strike_api_key', includeIfNull: false)
  final String? strikeApiKey;
  @JsonKey(name: 'breez_api_key', includeIfNull: false)
  final String? breezApiKey;
  @JsonKey(name: 'breez_greenlight_seed', includeIfNull: false)
  final String? breezGreenlightSeed;
  @JsonKey(name: 'breez_greenlight_invite_code', includeIfNull: false)
  final String? breezGreenlightInviteCode;
  @JsonKey(name: 'breez_greenlight_device_key', includeIfNull: false)
  final String? breezGreenlightDeviceKey;
  @JsonKey(name: 'breez_greenlight_device_cert', includeIfNull: false)
  final String? breezGreenlightDeviceCert;
  @JsonKey(
    name: 'breez_use_trampoline',
    includeIfNull: false,
    defaultValue: true,
  )
  final bool? breezUseTrampoline;
  @JsonKey(name: 'nwc_pairing_url', includeIfNull: false)
  final String? nwcPairingUrl;
  @JsonKey(name: 'lntips_api_endpoint', includeIfNull: false)
  final String? lntipsApiEndpoint;
  @JsonKey(name: 'lntips_api_key', includeIfNull: false)
  final String? lntipsApiKey;
  @JsonKey(name: 'lntips_admin_key', includeIfNull: false)
  final String? lntipsAdminKey;
  @JsonKey(name: 'lntips_invoice_key', includeIfNull: false)
  final String? lntipsInvoiceKey;
  @JsonKey(name: 'spark_url', includeIfNull: false)
  final String? sparkUrl;
  @JsonKey(name: 'spark_token', includeIfNull: false)
  final String? sparkToken;
  @JsonKey(name: 'opennode_api_endpoint', includeIfNull: false)
  final String? opennodeApiEndpoint;
  @JsonKey(name: 'opennode_key', includeIfNull: false)
  final String? opennodeKey;
  @JsonKey(name: 'opennode_admin_key', includeIfNull: false)
  final String? opennodeAdminKey;
  @JsonKey(name: 'opennode_invoice_key', includeIfNull: false)
  final String? opennodeInvoiceKey;
  @JsonKey(name: 'phoenixd_api_endpoint', includeIfNull: false)
  final String? phoenixdApiEndpoint;
  @JsonKey(name: 'phoenixd_api_password', includeIfNull: false)
  final String? phoenixdApiPassword;
  @JsonKey(name: 'zbd_api_endpoint', includeIfNull: false)
  final String? zbdApiEndpoint;
  @JsonKey(name: 'zbd_api_key', includeIfNull: false)
  final String? zbdApiKey;
  @JsonKey(name: 'boltz_client_endpoint', includeIfNull: false)
  final String? boltzClientEndpoint;
  @JsonKey(name: 'boltz_client_macaroon', includeIfNull: false)
  final String? boltzClientMacaroon;
  @JsonKey(name: 'boltz_client_password', includeIfNull: false)
  final String? boltzClientPassword;
  @JsonKey(name: 'boltz_client_cert', includeIfNull: false)
  final String? boltzClientCert;
  @JsonKey(name: 'boltz_mnemonic', includeIfNull: false)
  final String? boltzMnemonic;
  @JsonKey(name: 'alby_api_endpoint', includeIfNull: false)
  final String? albyApiEndpoint;
  @JsonKey(name: 'alby_access_token', includeIfNull: false)
  final String? albyAccessToken;
  @JsonKey(name: 'blink_api_endpoint', includeIfNull: false)
  final String? blinkApiEndpoint;
  @JsonKey(name: 'blink_ws_endpoint', includeIfNull: false)
  final String? blinkWsEndpoint;
  @JsonKey(name: 'blink_token', includeIfNull: false)
  final String? blinkToken;
  @JsonKey(name: 'lnpay_api_endpoint', includeIfNull: false)
  final String? lnpayApiEndpoint;
  @JsonKey(name: 'lnpay_api_key', includeIfNull: false)
  final String? lnpayApiKey;
  @JsonKey(name: 'lnpay_wallet_key', includeIfNull: false)
  final String? lnpayWalletKey;
  @JsonKey(name: 'lnpay_admin_key', includeIfNull: false)
  final String? lnpayAdminKey;
  @JsonKey(name: 'lnd_grpc_endpoint', includeIfNull: false)
  final String? lndGrpcEndpoint;
  @JsonKey(name: 'lnd_grpc_cert', includeIfNull: false)
  final String? lndGrpcCert;
  @JsonKey(name: 'lnd_grpc_port', includeIfNull: false)
  final int? lndGrpcPort;
  @JsonKey(name: 'lnd_grpc_admin_macaroon', includeIfNull: false)
  final String? lndGrpcAdminMacaroon;
  @JsonKey(name: 'lnd_grpc_invoice_macaroon', includeIfNull: false)
  final String? lndGrpcInvoiceMacaroon;
  @JsonKey(name: 'lnd_grpc_macaroon', includeIfNull: false)
  final String? lndGrpcMacaroon;
  @JsonKey(name: 'lnd_grpc_macaroon_encrypted', includeIfNull: false)
  final String? lndGrpcMacaroonEncrypted;
  @JsonKey(name: 'lnd_rest_endpoint', includeIfNull: false)
  final String? lndRestEndpoint;
  @JsonKey(name: 'lnd_rest_cert', includeIfNull: false)
  final String? lndRestCert;
  @JsonKey(name: 'lnd_rest_macaroon', includeIfNull: false)
  final String? lndRestMacaroon;
  @JsonKey(name: 'lnd_rest_macaroon_encrypted', includeIfNull: false)
  final String? lndRestMacaroonEncrypted;
  @JsonKey(
    name: 'lnd_rest_route_hints',
    includeIfNull: false,
    defaultValue: true,
  )
  final bool? lndRestRouteHints;
  @JsonKey(
    name: 'lnd_rest_allow_self_payment',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? lndRestAllowSelfPayment;
  @JsonKey(name: 'lnd_cert', includeIfNull: false)
  final String? lndCert;
  @JsonKey(name: 'lnd_admin_macaroon', includeIfNull: false)
  final String? lndAdminMacaroon;
  @JsonKey(name: 'lnd_invoice_macaroon', includeIfNull: false)
  final String? lndInvoiceMacaroon;
  @JsonKey(name: 'lnd_rest_admin_macaroon', includeIfNull: false)
  final String? lndRestAdminMacaroon;
  @JsonKey(name: 'lnd_rest_invoice_macaroon', includeIfNull: false)
  final String? lndRestInvoiceMacaroon;
  @JsonKey(name: 'eclair_url', includeIfNull: false)
  final String? eclairUrl;
  @JsonKey(name: 'eclair_pass', includeIfNull: false)
  final String? eclairPass;
  @JsonKey(name: 'corelightning_rest_url', includeIfNull: false)
  final String? corelightningRestUrl;
  @JsonKey(name: 'corelightning_rest_macaroon', includeIfNull: false)
  final String? corelightningRestMacaroon;
  @JsonKey(name: 'corelightning_rest_cert', includeIfNull: false)
  final String? corelightningRestCert;
  @JsonKey(name: 'corelightning_rpc', includeIfNull: false)
  final String? corelightningRpc;
  @JsonKey(name: 'corelightning_pay_command', includeIfNull: false)
  final String? corelightningPayCommand;
  @JsonKey(name: 'clightning_rpc', includeIfNull: false)
  final String? clightningRpc;
  @JsonKey(name: 'clnrest_url', includeIfNull: false)
  final String? clnrestUrl;
  @JsonKey(name: 'clnrest_ca', includeIfNull: false)
  final String? clnrestCa;
  @JsonKey(name: 'clnrest_cert', includeIfNull: false)
  final String? clnrestCert;
  @JsonKey(name: 'clnrest_readonly_rune', includeIfNull: false)
  final String? clnrestReadonlyRune;
  @JsonKey(name: 'clnrest_invoice_rune', includeIfNull: false)
  final String? clnrestInvoiceRune;
  @JsonKey(name: 'clnrest_pay_rune', includeIfNull: false)
  final String? clnrestPayRune;
  @JsonKey(name: 'clnrest_renepay_rune', includeIfNull: false)
  final String? clnrestRenepayRune;
  @JsonKey(name: 'clnrest_last_pay_index', includeIfNull: false)
  final String? clnrestLastPayIndex;
  @JsonKey(name: 'clnrest_nodeid', includeIfNull: false)
  final String? clnrestNodeid;
  @JsonKey(name: 'cliche_endpoint', includeIfNull: false)
  final String? clicheEndpoint;
  @JsonKey(name: 'lnbits_endpoint', includeIfNull: false)
  final String? lnbitsEndpoint;
  @JsonKey(name: 'lnbits_key', includeIfNull: false)
  final String? lnbitsKey;
  @JsonKey(name: 'lnbits_admin_key', includeIfNull: false)
  final String? lnbitsAdminKey;
  @JsonKey(name: 'lnbits_invoice_key', includeIfNull: false)
  final String? lnbitsInvoiceKey;
  @JsonKey(name: 'fake_wallet_secret', includeIfNull: false)
  final String? fakeWalletSecret;
  @JsonKey(name: 'lnbits_denomination', includeIfNull: false)
  final String? lnbitsDenomination;
  @JsonKey(name: 'lnbits_backend_wallet_class', includeIfNull: false)
  final String? lnbitsBackendWalletClass;
  @JsonKey(
    name: 'lnbits_funding_source_pay_invoice_wait_seconds',
    includeIfNull: false,
  )
  final int? lnbitsFundingSourcePayInvoiceWaitSeconds;
  @JsonKey(name: 'funding_source_max_retries', includeIfNull: false)
  final int? fundingSourceMaxRetries;
  @JsonKey(
    name: 'lnbits_nostr_notifications_enabled',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? lnbitsNostrNotificationsEnabled;
  @JsonKey(name: 'lnbits_nostr_notifications_private_key', includeIfNull: false)
  final String? lnbitsNostrNotificationsPrivateKey;
  @JsonKey(
    name: 'lnbits_nostr_notifications_identifiers',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsNostrNotificationsIdentifiers;
  @JsonKey(
    name: 'lnbits_telegram_notifications_enabled',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? lnbitsTelegramNotificationsEnabled;
  @JsonKey(
    name: 'lnbits_telegram_notifications_access_token',
    includeIfNull: false,
  )
  final String? lnbitsTelegramNotificationsAccessToken;
  @JsonKey(name: 'lnbits_telegram_notifications_chat_id', includeIfNull: false)
  final String? lnbitsTelegramNotificationsChatId;
  @JsonKey(
    name: 'lnbits_email_notifications_enabled',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? lnbitsEmailNotificationsEnabled;
  @JsonKey(name: 'lnbits_email_notifications_email', includeIfNull: false)
  final String? lnbitsEmailNotificationsEmail;
  @JsonKey(name: 'lnbits_email_notifications_username', includeIfNull: false)
  final String? lnbitsEmailNotificationsUsername;
  @JsonKey(name: 'lnbits_email_notifications_password', includeIfNull: false)
  final String? lnbitsEmailNotificationsPassword;
  @JsonKey(name: 'lnbits_email_notifications_server', includeIfNull: false)
  final String? lnbitsEmailNotificationsServer;
  @JsonKey(name: 'lnbits_email_notifications_port', includeIfNull: false)
  final int? lnbitsEmailNotificationsPort;
  @JsonKey(
    name: 'lnbits_email_notifications_to_emails',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsEmailNotificationsToEmails;
  @JsonKey(
    name: 'lnbits_notification_settings_update',
    includeIfNull: false,
    defaultValue: true,
  )
  final bool? lnbitsNotificationSettingsUpdate;
  @JsonKey(
    name: 'lnbits_notification_credit_debit',
    includeIfNull: false,
    defaultValue: true,
  )
  final bool? lnbitsNotificationCreditDebit;
  @JsonKey(
    name: 'notification_balance_delta_threshold_sats',
    includeIfNull: false,
  )
  final int? notificationBalanceDeltaThresholdSats;
  @JsonKey(
    name: 'lnbits_notification_server_start_stop',
    includeIfNull: false,
    defaultValue: true,
  )
  final bool? lnbitsNotificationServerStartStop;
  @JsonKey(
    name: 'lnbits_notification_watchdog',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? lnbitsNotificationWatchdog;
  @JsonKey(
    name: 'lnbits_notification_server_status_hours',
    includeIfNull: false,
  )
  final int? lnbitsNotificationServerStatusHours;
  @JsonKey(
    name: 'lnbits_notification_incoming_payment_amount_sats',
    includeIfNull: false,
  )
  final int? lnbitsNotificationIncomingPaymentAmountSats;
  @JsonKey(
    name: 'lnbits_notification_outgoing_payment_amount_sats',
    includeIfNull: false,
  )
  final int? lnbitsNotificationOutgoingPaymentAmountSats;
  @JsonKey(name: 'lnbits_rate_limit_no', includeIfNull: false)
  final int? lnbitsRateLimitNo;
  @JsonKey(name: 'lnbits_rate_limit_unit', includeIfNull: false)
  final String? lnbitsRateLimitUnit;
  @JsonKey(
    name: 'lnbits_allowed_ips',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsAllowedIps;
  @JsonKey(
    name: 'lnbits_blocked_ips',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsBlockedIps;
  @JsonKey(
    name: 'lnbits_callback_url_rules',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsCallbackUrlRules;
  @JsonKey(name: 'lnbits_wallet_limit_max_balance', includeIfNull: false)
  final int? lnbitsWalletLimitMaxBalance;
  @JsonKey(name: 'lnbits_wallet_limit_daily_max_withdraw', includeIfNull: false)
  final int? lnbitsWalletLimitDailyMaxWithdraw;
  @JsonKey(name: 'lnbits_wallet_limit_secs_between_trans', includeIfNull: false)
  final int? lnbitsWalletLimitSecsBetweenTrans;
  @JsonKey(
    name: 'lnbits_only_allow_incoming_payments',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? lnbitsOnlyAllowIncomingPayments;
  @JsonKey(
    name: 'lnbits_watchdog_switch_to_voidwallet',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? lnbitsWatchdogSwitchToVoidwallet;
  @JsonKey(name: 'lnbits_watchdog_interval_minutes', includeIfNull: false)
  final int? lnbitsWatchdogIntervalMinutes;
  @JsonKey(name: 'lnbits_watchdog_delta', includeIfNull: false)
  final int? lnbitsWatchdogDelta;
  @JsonKey(
    name: 'lnbits_max_outgoing_payment_amount_sats',
    includeIfNull: false,
  )
  final int? lnbitsMaxOutgoingPaymentAmountSats;
  @JsonKey(
    name: 'lnbits_max_incoming_payment_amount_sats',
    includeIfNull: false,
  )
  final int? lnbitsMaxIncomingPaymentAmountSats;
  @JsonKey(name: 'lnbits_exchange_rate_cache_seconds', includeIfNull: false)
  final int? lnbitsExchangeRateCacheSeconds;
  @JsonKey(name: 'lnbits_exchange_history_size', includeIfNull: false)
  final int? lnbitsExchangeHistorySize;
  @JsonKey(
    name: 'lnbits_exchange_history_refresh_interval_seconds',
    includeIfNull: false,
  )
  final int? lnbitsExchangeHistoryRefreshIntervalSeconds;
  @JsonKey(
    name: 'lnbits_exchange_rate_providers',
    includeIfNull: false,
    defaultValue: <ExchangeRateProvider>[],
  )
  final List<ExchangeRateProvider>? lnbitsExchangeRateProviders;
  @JsonKey(name: 'lnbits_reserve_fee_min', includeIfNull: false)
  final int? lnbitsReserveFeeMin;
  @JsonKey(name: 'lnbits_reserve_fee_percent', includeIfNull: false)
  final double? lnbitsReserveFeePercent;
  @JsonKey(name: 'lnbits_service_fee', includeIfNull: false)
  final double? lnbitsServiceFee;
  @JsonKey(
    name: 'lnbits_service_fee_ignore_internal',
    includeIfNull: false,
    defaultValue: true,
  )
  final bool? lnbitsServiceFeeIgnoreInternal;
  @JsonKey(name: 'lnbits_service_fee_max', includeIfNull: false)
  final int? lnbitsServiceFeeMax;
  @JsonKey(name: 'lnbits_service_fee_wallet', includeIfNull: false)
  final String? lnbitsServiceFeeWallet;
  @JsonKey(name: 'lnbits_max_asset_size_mb', includeIfNull: false)
  final double? lnbitsMaxAssetSizeMb;
  @JsonKey(
    name: 'lnbits_assets_allowed_mime_types',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsAssetsAllowedMimeTypes;
  @JsonKey(name: 'lnbits_asset_thumbnail_width', includeIfNull: false)
  final int? lnbitsAssetThumbnailWidth;
  @JsonKey(name: 'lnbits_asset_thumbnail_height', includeIfNull: false)
  final int? lnbitsAssetThumbnailHeight;
  @JsonKey(name: 'lnbits_asset_thumbnail_format', includeIfNull: false)
  final String? lnbitsAssetThumbnailFormat;
  @JsonKey(name: 'lnbits_max_assets_per_user', includeIfNull: false)
  final int? lnbitsMaxAssetsPerUser;
  @JsonKey(
    name: 'lnbits_assets_no_limit_users',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsAssetsNoLimitUsers;
  @JsonKey(name: 'lnbits_baseurl', includeIfNull: false)
  final String? lnbitsBaseurl;
  @JsonKey(name: 'lnbits_hide_api', includeIfNull: false, defaultValue: false)
  final bool? lnbitsHideApi;
  @JsonKey(name: 'lnbits_site_title', includeIfNull: false)
  final String? lnbitsSiteTitle;
  @JsonKey(name: 'lnbits_site_tagline', includeIfNull: false)
  final String? lnbitsSiteTagline;
  @JsonKey(name: 'lnbits_site_description', includeIfNull: false)
  final String? lnbitsSiteDescription;
  @JsonKey(
    name: 'lnbits_show_home_page_elements',
    includeIfNull: false,
    defaultValue: true,
  )
  final bool? lnbitsShowHomePageElements;
  @JsonKey(name: 'lnbits_default_wallet_name', includeIfNull: false)
  final String? lnbitsDefaultWalletName;
  @JsonKey(name: 'lnbits_custom_badge', includeIfNull: false)
  final String? lnbitsCustomBadge;
  @JsonKey(name: 'lnbits_custom_badge_color', includeIfNull: false)
  final String? lnbitsCustomBadgeColor;
  @JsonKey(
    name: 'lnbits_theme_options',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsThemeOptions;
  @JsonKey(name: 'lnbits_custom_logo', includeIfNull: false)
  final String? lnbitsCustomLogo;
  @JsonKey(name: 'lnbits_custom_image', includeIfNull: false)
  final String? lnbitsCustomImage;
  @JsonKey(name: 'lnbits_ad_space_title', includeIfNull: false)
  final String? lnbitsAdSpaceTitle;
  @JsonKey(name: 'lnbits_ad_space', includeIfNull: false)
  final String? lnbitsAdSpace;
  @JsonKey(
    name: 'lnbits_ad_space_enabled',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? lnbitsAdSpaceEnabled;
  @JsonKey(
    name: 'lnbits_allowed_currencies',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsAllowedCurrencies;
  @JsonKey(name: 'lnbits_default_accounting_currency', includeIfNull: false)
  final String? lnbitsDefaultAccountingCurrency;
  @JsonKey(name: 'lnbits_qr_logo', includeIfNull: false)
  final String? lnbitsQrLogo;
  @JsonKey(name: 'lnbits_apple_touch_icon', includeIfNull: false)
  final String? lnbitsAppleTouchIcon;
  @JsonKey(name: 'lnbits_default_reaction', includeIfNull: false)
  final String? lnbitsDefaultReaction;
  @JsonKey(name: 'lnbits_default_theme', includeIfNull: false)
  final String? lnbitsDefaultTheme;
  @JsonKey(name: 'lnbits_default_border', includeIfNull: false)
  final String? lnbitsDefaultBorder;
  @JsonKey(
    name: 'lnbits_default_gradient',
    includeIfNull: false,
    defaultValue: true,
  )
  final bool? lnbitsDefaultGradient;
  @JsonKey(name: 'lnbits_default_bgimage', includeIfNull: false)
  final String? lnbitsDefaultBgimage;
  @JsonKey(
    name: 'lnbits_admin_extensions',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsAdminExtensions;
  @JsonKey(
    name: 'lnbits_user_default_extensions',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsUserDefaultExtensions;
  @JsonKey(
    name: 'lnbits_extensions_deactivate_all',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? lnbitsExtensionsDeactivateAll;
  @JsonKey(
    name: 'lnbits_extensions_builder_activate_non_admins',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? lnbitsExtensionsBuilderActivateNonAdmins;
  @JsonKey(name: 'lnbits_extensions_reviews_url', includeIfNull: false)
  final String? lnbitsExtensionsReviewsUrl;
  @JsonKey(
    name: 'lnbits_extensions_manifests',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsExtensionsManifests;
  @JsonKey(name: 'lnbits_extensions_builder_manifest_url', includeIfNull: false)
  final String? lnbitsExtensionsBuilderManifestUrl;
  @JsonKey(
    name: 'lnbits_admin_users',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsAdminUsers;
  @JsonKey(
    name: 'lnbits_allowed_users',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? lnbitsAllowedUsers;
  @JsonKey(
    name: 'lnbits_allow_new_accounts',
    includeIfNull: false,
    defaultValue: true,
  )
  final bool? lnbitsAllowNewAccounts;
  static const fromJsonFactory = _$UpdateSettingsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UpdateSettings &&
            (identical(other.keycloakDiscoveryUrl, keycloakDiscoveryUrl) ||
                const DeepCollectionEquality().equals(
                  other.keycloakDiscoveryUrl,
                  keycloakDiscoveryUrl,
                )) &&
            (identical(other.keycloakClientId, keycloakClientId) ||
                const DeepCollectionEquality().equals(
                  other.keycloakClientId,
                  keycloakClientId,
                )) &&
            (identical(other.keycloakClientSecret, keycloakClientSecret) ||
                const DeepCollectionEquality().equals(
                  other.keycloakClientSecret,
                  keycloakClientSecret,
                )) &&
            (identical(
                  other.keycloakClientCustomOrg,
                  keycloakClientCustomOrg,
                ) ||
                const DeepCollectionEquality().equals(
                  other.keycloakClientCustomOrg,
                  keycloakClientCustomOrg,
                )) &&
            (identical(
                  other.keycloakClientCustomIcon,
                  keycloakClientCustomIcon,
                ) ||
                const DeepCollectionEquality().equals(
                  other.keycloakClientCustomIcon,
                  keycloakClientCustomIcon,
                )) &&
            (identical(other.githubClientId, githubClientId) ||
                const DeepCollectionEquality().equals(
                  other.githubClientId,
                  githubClientId,
                )) &&
            (identical(other.githubClientSecret, githubClientSecret) ||
                const DeepCollectionEquality().equals(
                  other.githubClientSecret,
                  githubClientSecret,
                )) &&
            (identical(other.googleClientId, googleClientId) ||
                const DeepCollectionEquality().equals(
                  other.googleClientId,
                  googleClientId,
                )) &&
            (identical(other.googleClientSecret, googleClientSecret) ||
                const DeepCollectionEquality().equals(
                  other.googleClientSecret,
                  googleClientSecret,
                )) &&
            (identical(
                  other.nostrAbsoluteRequestUrls,
                  nostrAbsoluteRequestUrls,
                ) ||
                const DeepCollectionEquality().equals(
                  other.nostrAbsoluteRequestUrls,
                  nostrAbsoluteRequestUrls,
                )) &&
            (identical(other.authTokenExpireMinutes, authTokenExpireMinutes) ||
                const DeepCollectionEquality().equals(
                  other.authTokenExpireMinutes,
                  authTokenExpireMinutes,
                )) &&
            (identical(other.authAllMethods, authAllMethods) ||
                const DeepCollectionEquality().equals(
                  other.authAllMethods,
                  authAllMethods,
                )) &&
            (identical(other.authAllowedMethods, authAllowedMethods) ||
                const DeepCollectionEquality().equals(
                  other.authAllowedMethods,
                  authAllowedMethods,
                )) &&
            (identical(
                  other.authCredetialsUpdateThreshold,
                  authCredetialsUpdateThreshold,
                ) ||
                const DeepCollectionEquality().equals(
                  other.authCredetialsUpdateThreshold,
                  authCredetialsUpdateThreshold,
                )) &&
            (identical(
                  other.authAuthenticationCacheMinutes,
                  authAuthenticationCacheMinutes,
                ) ||
                const DeepCollectionEquality().equals(
                  other.authAuthenticationCacheMinutes,
                  authAuthenticationCacheMinutes,
                )) &&
            (identical(other.lnbitsAuditEnabled, lnbitsAuditEnabled) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAuditEnabled,
                  lnbitsAuditEnabled,
                )) &&
            (identical(
                  other.lnbitsAuditRetentionDays,
                  lnbitsAuditRetentionDays,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAuditRetentionDays,
                  lnbitsAuditRetentionDays,
                )) &&
            (identical(
                  other.lnbitsAuditLogIpAddress,
                  lnbitsAuditLogIpAddress,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAuditLogIpAddress,
                  lnbitsAuditLogIpAddress,
                )) &&
            (identical(
                  other.lnbitsAuditLogPathParams,
                  lnbitsAuditLogPathParams,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAuditLogPathParams,
                  lnbitsAuditLogPathParams,
                )) &&
            (identical(
                  other.lnbitsAuditLogQueryParams,
                  lnbitsAuditLogQueryParams,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAuditLogQueryParams,
                  lnbitsAuditLogQueryParams,
                )) &&
            (identical(
                  other.lnbitsAuditLogRequestBody,
                  lnbitsAuditLogRequestBody,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAuditLogRequestBody,
                  lnbitsAuditLogRequestBody,
                )) &&
            (identical(
                  other.lnbitsAuditIncludePaths,
                  lnbitsAuditIncludePaths,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAuditIncludePaths,
                  lnbitsAuditIncludePaths,
                )) &&
            (identical(
                  other.lnbitsAuditExcludePaths,
                  lnbitsAuditExcludePaths,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAuditExcludePaths,
                  lnbitsAuditExcludePaths,
                )) &&
            (identical(other.lnbitsAuditHttpMethods, lnbitsAuditHttpMethods) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAuditHttpMethods,
                  lnbitsAuditHttpMethods,
                )) &&
            (identical(
                  other.lnbitsAuditHttpResponseCodes,
                  lnbitsAuditHttpResponseCodes,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAuditHttpResponseCodes,
                  lnbitsAuditHttpResponseCodes,
                )) &&
            (identical(other.lnbitsNodeUi, lnbitsNodeUi) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsNodeUi,
                  lnbitsNodeUi,
                )) &&
            (identical(other.lnbitsPublicNodeUi, lnbitsPublicNodeUi) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsPublicNodeUi,
                  lnbitsPublicNodeUi,
                )) &&
            (identical(
                  other.lnbitsNodeUiTransactions,
                  lnbitsNodeUiTransactions,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsNodeUiTransactions,
                  lnbitsNodeUiTransactions,
                )) &&
            (identical(other.lnbitsWebpushPubkey, lnbitsWebpushPubkey) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsWebpushPubkey,
                  lnbitsWebpushPubkey,
                )) &&
            (identical(other.lnbitsWebpushPrivkey, lnbitsWebpushPrivkey) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsWebpushPrivkey,
                  lnbitsWebpushPrivkey,
                )) &&
            (identical(other.lightningInvoiceExpiry, lightningInvoiceExpiry) ||
                const DeepCollectionEquality().equals(
                  other.lightningInvoiceExpiry,
                  lightningInvoiceExpiry,
                )) &&
            (identical(other.paypalEnabled, paypalEnabled) ||
                const DeepCollectionEquality().equals(
                  other.paypalEnabled,
                  paypalEnabled,
                )) &&
            (identical(other.paypalApiEndpoint, paypalApiEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.paypalApiEndpoint,
                  paypalApiEndpoint,
                )) &&
            (identical(other.paypalClientId, paypalClientId) ||
                const DeepCollectionEquality().equals(
                  other.paypalClientId,
                  paypalClientId,
                )) &&
            (identical(other.paypalClientSecret, paypalClientSecret) ||
                const DeepCollectionEquality().equals(
                  other.paypalClientSecret,
                  paypalClientSecret,
                )) &&
            (identical(
                  other.paypalPaymentSuccessUrl,
                  paypalPaymentSuccessUrl,
                ) ||
                const DeepCollectionEquality().equals(
                  other.paypalPaymentSuccessUrl,
                  paypalPaymentSuccessUrl,
                )) &&
            (identical(
                  other.paypalPaymentWebhookUrl,
                  paypalPaymentWebhookUrl,
                ) ||
                const DeepCollectionEquality().equals(
                  other.paypalPaymentWebhookUrl,
                  paypalPaymentWebhookUrl,
                )) &&
            (identical(other.paypalWebhookId, paypalWebhookId) ||
                const DeepCollectionEquality().equals(
                  other.paypalWebhookId,
                  paypalWebhookId,
                )) &&
            (identical(other.paypalLimits, paypalLimits) ||
                const DeepCollectionEquality().equals(
                  other.paypalLimits,
                  paypalLimits,
                )) &&
            (identical(other.stripeEnabled, stripeEnabled) ||
                const DeepCollectionEquality().equals(
                  other.stripeEnabled,
                  stripeEnabled,
                )) &&
            (identical(other.stripeApiEndpoint, stripeApiEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.stripeApiEndpoint,
                  stripeApiEndpoint,
                )) &&
            (identical(other.stripeApiSecretKey, stripeApiSecretKey) ||
                const DeepCollectionEquality().equals(
                  other.stripeApiSecretKey,
                  stripeApiSecretKey,
                )) &&
            (identical(
                  other.stripePaymentSuccessUrl,
                  stripePaymentSuccessUrl,
                ) ||
                const DeepCollectionEquality().equals(
                  other.stripePaymentSuccessUrl,
                  stripePaymentSuccessUrl,
                )) &&
            (identical(
                  other.stripePaymentWebhookUrl,
                  stripePaymentWebhookUrl,
                ) ||
                const DeepCollectionEquality().equals(
                  other.stripePaymentWebhookUrl,
                  stripePaymentWebhookUrl,
                )) &&
            (identical(
                  other.stripeWebhookSigningSecret,
                  stripeWebhookSigningSecret,
                ) ||
                const DeepCollectionEquality().equals(
                  other.stripeWebhookSigningSecret,
                  stripeWebhookSigningSecret,
                )) &&
            (identical(other.stripeLimits, stripeLimits) ||
                const DeepCollectionEquality().equals(
                  other.stripeLimits,
                  stripeLimits,
                )) &&
            (identical(other.breezLiquidApiKey, breezLiquidApiKey) ||
                const DeepCollectionEquality().equals(
                  other.breezLiquidApiKey,
                  breezLiquidApiKey,
                )) &&
            (identical(other.breezLiquidSeed, breezLiquidSeed) ||
                const DeepCollectionEquality().equals(
                  other.breezLiquidSeed,
                  breezLiquidSeed,
                )) &&
            (identical(
                  other.breezLiquidFeeOffsetSat,
                  breezLiquidFeeOffsetSat,
                ) ||
                const DeepCollectionEquality().equals(
                  other.breezLiquidFeeOffsetSat,
                  breezLiquidFeeOffsetSat,
                )) &&
            (identical(other.strikeApiEndpoint, strikeApiEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.strikeApiEndpoint,
                  strikeApiEndpoint,
                )) &&
            (identical(other.strikeApiKey, strikeApiKey) ||
                const DeepCollectionEquality().equals(
                  other.strikeApiKey,
                  strikeApiKey,
                )) &&
            (identical(other.breezApiKey, breezApiKey) ||
                const DeepCollectionEquality().equals(
                  other.breezApiKey,
                  breezApiKey,
                )) &&
            (identical(other.breezGreenlightSeed, breezGreenlightSeed) ||
                const DeepCollectionEquality().equals(
                  other.breezGreenlightSeed,
                  breezGreenlightSeed,
                )) &&
            (identical(
                  other.breezGreenlightInviteCode,
                  breezGreenlightInviteCode,
                ) ||
                const DeepCollectionEquality().equals(
                  other.breezGreenlightInviteCode,
                  breezGreenlightInviteCode,
                )) &&
            (identical(
                  other.breezGreenlightDeviceKey,
                  breezGreenlightDeviceKey,
                ) ||
                const DeepCollectionEquality().equals(
                  other.breezGreenlightDeviceKey,
                  breezGreenlightDeviceKey,
                )) &&
            (identical(
                  other.breezGreenlightDeviceCert,
                  breezGreenlightDeviceCert,
                ) ||
                const DeepCollectionEquality().equals(
                  other.breezGreenlightDeviceCert,
                  breezGreenlightDeviceCert,
                )) &&
            (identical(other.breezUseTrampoline, breezUseTrampoline) ||
                const DeepCollectionEquality().equals(
                  other.breezUseTrampoline,
                  breezUseTrampoline,
                )) &&
            (identical(other.nwcPairingUrl, nwcPairingUrl) ||
                const DeepCollectionEquality().equals(
                  other.nwcPairingUrl,
                  nwcPairingUrl,
                )) &&
            (identical(other.lntipsApiEndpoint, lntipsApiEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.lntipsApiEndpoint,
                  lntipsApiEndpoint,
                )) &&
            (identical(other.lntipsApiKey, lntipsApiKey) ||
                const DeepCollectionEquality().equals(
                  other.lntipsApiKey,
                  lntipsApiKey,
                )) &&
            (identical(other.lntipsAdminKey, lntipsAdminKey) ||
                const DeepCollectionEquality().equals(
                  other.lntipsAdminKey,
                  lntipsAdminKey,
                )) &&
            (identical(other.lntipsInvoiceKey, lntipsInvoiceKey) ||
                const DeepCollectionEquality().equals(
                  other.lntipsInvoiceKey,
                  lntipsInvoiceKey,
                )) &&
            (identical(other.sparkUrl, sparkUrl) ||
                const DeepCollectionEquality().equals(
                  other.sparkUrl,
                  sparkUrl,
                )) &&
            (identical(other.sparkToken, sparkToken) ||
                const DeepCollectionEquality().equals(
                  other.sparkToken,
                  sparkToken,
                )) &&
            (identical(other.opennodeApiEndpoint, opennodeApiEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.opennodeApiEndpoint,
                  opennodeApiEndpoint,
                )) &&
            (identical(other.opennodeKey, opennodeKey) ||
                const DeepCollectionEquality().equals(
                  other.opennodeKey,
                  opennodeKey,
                )) &&
            (identical(other.opennodeAdminKey, opennodeAdminKey) ||
                const DeepCollectionEquality().equals(
                  other.opennodeAdminKey,
                  opennodeAdminKey,
                )) &&
            (identical(other.opennodeInvoiceKey, opennodeInvoiceKey) ||
                const DeepCollectionEquality().equals(
                  other.opennodeInvoiceKey,
                  opennodeInvoiceKey,
                )) &&
            (identical(other.phoenixdApiEndpoint, phoenixdApiEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.phoenixdApiEndpoint,
                  phoenixdApiEndpoint,
                )) &&
            (identical(other.phoenixdApiPassword, phoenixdApiPassword) ||
                const DeepCollectionEquality().equals(
                  other.phoenixdApiPassword,
                  phoenixdApiPassword,
                )) &&
            (identical(other.zbdApiEndpoint, zbdApiEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.zbdApiEndpoint,
                  zbdApiEndpoint,
                )) &&
            (identical(other.zbdApiKey, zbdApiKey) ||
                const DeepCollectionEquality().equals(
                  other.zbdApiKey,
                  zbdApiKey,
                )) &&
            (identical(other.boltzClientEndpoint, boltzClientEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.boltzClientEndpoint,
                  boltzClientEndpoint,
                )) &&
            (identical(other.boltzClientMacaroon, boltzClientMacaroon) ||
                const DeepCollectionEquality().equals(
                  other.boltzClientMacaroon,
                  boltzClientMacaroon,
                )) &&
            (identical(other.boltzClientPassword, boltzClientPassword) ||
                const DeepCollectionEquality().equals(
                  other.boltzClientPassword,
                  boltzClientPassword,
                )) &&
            (identical(other.boltzClientCert, boltzClientCert) ||
                const DeepCollectionEquality().equals(
                  other.boltzClientCert,
                  boltzClientCert,
                )) &&
            (identical(other.boltzMnemonic, boltzMnemonic) ||
                const DeepCollectionEquality().equals(
                  other.boltzMnemonic,
                  boltzMnemonic,
                )) &&
            (identical(other.albyApiEndpoint, albyApiEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.albyApiEndpoint,
                  albyApiEndpoint,
                )) &&
            (identical(other.albyAccessToken, albyAccessToken) ||
                const DeepCollectionEquality().equals(
                  other.albyAccessToken,
                  albyAccessToken,
                )) &&
            (identical(other.blinkApiEndpoint, blinkApiEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.blinkApiEndpoint,
                  blinkApiEndpoint,
                )) &&
            (identical(other.blinkWsEndpoint, blinkWsEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.blinkWsEndpoint,
                  blinkWsEndpoint,
                )) &&
            (identical(other.blinkToken, blinkToken) ||
                const DeepCollectionEquality().equals(
                  other.blinkToken,
                  blinkToken,
                )) &&
            (identical(other.lnpayApiEndpoint, lnpayApiEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.lnpayApiEndpoint,
                  lnpayApiEndpoint,
                )) &&
            (identical(other.lnpayApiKey, lnpayApiKey) ||
                const DeepCollectionEquality().equals(
                  other.lnpayApiKey,
                  lnpayApiKey,
                )) &&
            (identical(other.lnpayWalletKey, lnpayWalletKey) ||
                const DeepCollectionEquality().equals(
                  other.lnpayWalletKey,
                  lnpayWalletKey,
                )) &&
            (identical(other.lnpayAdminKey, lnpayAdminKey) ||
                const DeepCollectionEquality().equals(
                  other.lnpayAdminKey,
                  lnpayAdminKey,
                )) &&
            (identical(other.lndGrpcEndpoint, lndGrpcEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.lndGrpcEndpoint,
                  lndGrpcEndpoint,
                )) &&
            (identical(other.lndGrpcCert, lndGrpcCert) ||
                const DeepCollectionEquality().equals(
                  other.lndGrpcCert,
                  lndGrpcCert,
                )) &&
            (identical(other.lndGrpcPort, lndGrpcPort) ||
                const DeepCollectionEquality().equals(
                  other.lndGrpcPort,
                  lndGrpcPort,
                )) &&
            (identical(other.lndGrpcAdminMacaroon, lndGrpcAdminMacaroon) ||
                const DeepCollectionEquality().equals(
                  other.lndGrpcAdminMacaroon,
                  lndGrpcAdminMacaroon,
                )) &&
            (identical(other.lndGrpcInvoiceMacaroon, lndGrpcInvoiceMacaroon) ||
                const DeepCollectionEquality().equals(
                  other.lndGrpcInvoiceMacaroon,
                  lndGrpcInvoiceMacaroon,
                )) &&
            (identical(other.lndGrpcMacaroon, lndGrpcMacaroon) ||
                const DeepCollectionEquality().equals(
                  other.lndGrpcMacaroon,
                  lndGrpcMacaroon,
                )) &&
            (identical(
                  other.lndGrpcMacaroonEncrypted,
                  lndGrpcMacaroonEncrypted,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lndGrpcMacaroonEncrypted,
                  lndGrpcMacaroonEncrypted,
                )) &&
            (identical(other.lndRestEndpoint, lndRestEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.lndRestEndpoint,
                  lndRestEndpoint,
                )) &&
            (identical(other.lndRestCert, lndRestCert) ||
                const DeepCollectionEquality().equals(
                  other.lndRestCert,
                  lndRestCert,
                )) &&
            (identical(other.lndRestMacaroon, lndRestMacaroon) ||
                const DeepCollectionEquality().equals(
                  other.lndRestMacaroon,
                  lndRestMacaroon,
                )) &&
            (identical(
                  other.lndRestMacaroonEncrypted,
                  lndRestMacaroonEncrypted,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lndRestMacaroonEncrypted,
                  lndRestMacaroonEncrypted,
                )) &&
            (identical(other.lndRestRouteHints, lndRestRouteHints) ||
                const DeepCollectionEquality().equals(
                  other.lndRestRouteHints,
                  lndRestRouteHints,
                )) &&
            (identical(
                  other.lndRestAllowSelfPayment,
                  lndRestAllowSelfPayment,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lndRestAllowSelfPayment,
                  lndRestAllowSelfPayment,
                )) &&
            (identical(other.lndCert, lndCert) ||
                const DeepCollectionEquality().equals(
                  other.lndCert,
                  lndCert,
                )) &&
            (identical(other.lndAdminMacaroon, lndAdminMacaroon) ||
                const DeepCollectionEquality().equals(
                  other.lndAdminMacaroon,
                  lndAdminMacaroon,
                )) &&
            (identical(other.lndInvoiceMacaroon, lndInvoiceMacaroon) ||
                const DeepCollectionEquality().equals(
                  other.lndInvoiceMacaroon,
                  lndInvoiceMacaroon,
                )) &&
            (identical(other.lndRestAdminMacaroon, lndRestAdminMacaroon) ||
                const DeepCollectionEquality().equals(
                  other.lndRestAdminMacaroon,
                  lndRestAdminMacaroon,
                )) &&
            (identical(other.lndRestInvoiceMacaroon, lndRestInvoiceMacaroon) ||
                const DeepCollectionEquality().equals(
                  other.lndRestInvoiceMacaroon,
                  lndRestInvoiceMacaroon,
                )) &&
            (identical(other.eclairUrl, eclairUrl) ||
                const DeepCollectionEquality().equals(
                  other.eclairUrl,
                  eclairUrl,
                )) &&
            (identical(other.eclairPass, eclairPass) ||
                const DeepCollectionEquality().equals(
                  other.eclairPass,
                  eclairPass,
                )) &&
            (identical(other.corelightningRestUrl, corelightningRestUrl) ||
                const DeepCollectionEquality().equals(
                  other.corelightningRestUrl,
                  corelightningRestUrl,
                )) &&
            (identical(
                  other.corelightningRestMacaroon,
                  corelightningRestMacaroon,
                ) ||
                const DeepCollectionEquality().equals(
                  other.corelightningRestMacaroon,
                  corelightningRestMacaroon,
                )) &&
            (identical(other.corelightningRestCert, corelightningRestCert) ||
                const DeepCollectionEquality().equals(
                  other.corelightningRestCert,
                  corelightningRestCert,
                )) &&
            (identical(other.corelightningRpc, corelightningRpc) ||
                const DeepCollectionEquality().equals(
                  other.corelightningRpc,
                  corelightningRpc,
                )) &&
            (identical(
                  other.corelightningPayCommand,
                  corelightningPayCommand,
                ) ||
                const DeepCollectionEquality().equals(
                  other.corelightningPayCommand,
                  corelightningPayCommand,
                )) &&
            (identical(other.clightningRpc, clightningRpc) ||
                const DeepCollectionEquality().equals(
                  other.clightningRpc,
                  clightningRpc,
                )) &&
            (identical(other.clnrestUrl, clnrestUrl) ||
                const DeepCollectionEquality().equals(
                  other.clnrestUrl,
                  clnrestUrl,
                )) &&
            (identical(other.clnrestCa, clnrestCa) ||
                const DeepCollectionEquality().equals(
                  other.clnrestCa,
                  clnrestCa,
                )) &&
            (identical(other.clnrestCert, clnrestCert) ||
                const DeepCollectionEquality().equals(
                  other.clnrestCert,
                  clnrestCert,
                )) &&
            (identical(other.clnrestReadonlyRune, clnrestReadonlyRune) ||
                const DeepCollectionEquality().equals(
                  other.clnrestReadonlyRune,
                  clnrestReadonlyRune,
                )) &&
            (identical(other.clnrestInvoiceRune, clnrestInvoiceRune) ||
                const DeepCollectionEquality().equals(
                  other.clnrestInvoiceRune,
                  clnrestInvoiceRune,
                )) &&
            (identical(other.clnrestPayRune, clnrestPayRune) ||
                const DeepCollectionEquality().equals(
                  other.clnrestPayRune,
                  clnrestPayRune,
                )) &&
            (identical(other.clnrestRenepayRune, clnrestRenepayRune) ||
                const DeepCollectionEquality().equals(
                  other.clnrestRenepayRune,
                  clnrestRenepayRune,
                )) &&
            (identical(other.clnrestLastPayIndex, clnrestLastPayIndex) ||
                const DeepCollectionEquality().equals(
                  other.clnrestLastPayIndex,
                  clnrestLastPayIndex,
                )) &&
            (identical(other.clnrestNodeid, clnrestNodeid) ||
                const DeepCollectionEquality().equals(
                  other.clnrestNodeid,
                  clnrestNodeid,
                )) &&
            (identical(other.clicheEndpoint, clicheEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.clicheEndpoint,
                  clicheEndpoint,
                )) &&
            (identical(other.lnbitsEndpoint, lnbitsEndpoint) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsEndpoint,
                  lnbitsEndpoint,
                )) &&
            (identical(other.lnbitsKey, lnbitsKey) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsKey,
                  lnbitsKey,
                )) &&
            (identical(other.lnbitsAdminKey, lnbitsAdminKey) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAdminKey,
                  lnbitsAdminKey,
                )) &&
            (identical(other.lnbitsInvoiceKey, lnbitsInvoiceKey) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsInvoiceKey,
                  lnbitsInvoiceKey,
                )) &&
            (identical(other.fakeWalletSecret, fakeWalletSecret) ||
                const DeepCollectionEquality().equals(
                  other.fakeWalletSecret,
                  fakeWalletSecret,
                )) &&
            (identical(other.lnbitsDenomination, lnbitsDenomination) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsDenomination,
                  lnbitsDenomination,
                )) &&
            (identical(
                  other.lnbitsBackendWalletClass,
                  lnbitsBackendWalletClass,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsBackendWalletClass,
                  lnbitsBackendWalletClass,
                )) &&
            (identical(
                  other.lnbitsFundingSourcePayInvoiceWaitSeconds,
                  lnbitsFundingSourcePayInvoiceWaitSeconds,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsFundingSourcePayInvoiceWaitSeconds,
                  lnbitsFundingSourcePayInvoiceWaitSeconds,
                )) &&
            (identical(
                  other.fundingSourceMaxRetries,
                  fundingSourceMaxRetries,
                ) ||
                const DeepCollectionEquality().equals(
                  other.fundingSourceMaxRetries,
                  fundingSourceMaxRetries,
                )) &&
            (identical(
                  other.lnbitsNostrNotificationsEnabled,
                  lnbitsNostrNotificationsEnabled,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsNostrNotificationsEnabled,
                  lnbitsNostrNotificationsEnabled,
                )) &&
            (identical(
                  other.lnbitsNostrNotificationsPrivateKey,
                  lnbitsNostrNotificationsPrivateKey,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsNostrNotificationsPrivateKey,
                  lnbitsNostrNotificationsPrivateKey,
                )) &&
            (identical(
                  other.lnbitsNostrNotificationsIdentifiers,
                  lnbitsNostrNotificationsIdentifiers,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsNostrNotificationsIdentifiers,
                  lnbitsNostrNotificationsIdentifiers,
                )) &&
            (identical(
                  other.lnbitsTelegramNotificationsEnabled,
                  lnbitsTelegramNotificationsEnabled,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsTelegramNotificationsEnabled,
                  lnbitsTelegramNotificationsEnabled,
                )) &&
            (identical(
                  other.lnbitsTelegramNotificationsAccessToken,
                  lnbitsTelegramNotificationsAccessToken,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsTelegramNotificationsAccessToken,
                  lnbitsTelegramNotificationsAccessToken,
                )) &&
            (identical(
                  other.lnbitsTelegramNotificationsChatId,
                  lnbitsTelegramNotificationsChatId,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsTelegramNotificationsChatId,
                  lnbitsTelegramNotificationsChatId,
                )) &&
            (identical(
                  other.lnbitsEmailNotificationsEnabled,
                  lnbitsEmailNotificationsEnabled,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsEmailNotificationsEnabled,
                  lnbitsEmailNotificationsEnabled,
                )) &&
            (identical(
                  other.lnbitsEmailNotificationsEmail,
                  lnbitsEmailNotificationsEmail,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsEmailNotificationsEmail,
                  lnbitsEmailNotificationsEmail,
                )) &&
            (identical(
                  other.lnbitsEmailNotificationsUsername,
                  lnbitsEmailNotificationsUsername,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsEmailNotificationsUsername,
                  lnbitsEmailNotificationsUsername,
                )) &&
            (identical(
                  other.lnbitsEmailNotificationsPassword,
                  lnbitsEmailNotificationsPassword,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsEmailNotificationsPassword,
                  lnbitsEmailNotificationsPassword,
                )) &&
            (identical(
                  other.lnbitsEmailNotificationsServer,
                  lnbitsEmailNotificationsServer,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsEmailNotificationsServer,
                  lnbitsEmailNotificationsServer,
                )) &&
            (identical(
                  other.lnbitsEmailNotificationsPort,
                  lnbitsEmailNotificationsPort,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsEmailNotificationsPort,
                  lnbitsEmailNotificationsPort,
                )) &&
            (identical(
                  other.lnbitsEmailNotificationsToEmails,
                  lnbitsEmailNotificationsToEmails,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsEmailNotificationsToEmails,
                  lnbitsEmailNotificationsToEmails,
                )) &&
            (identical(
                  other.lnbitsNotificationSettingsUpdate,
                  lnbitsNotificationSettingsUpdate,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsNotificationSettingsUpdate,
                  lnbitsNotificationSettingsUpdate,
                )) &&
            (identical(
                  other.lnbitsNotificationCreditDebit,
                  lnbitsNotificationCreditDebit,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsNotificationCreditDebit,
                  lnbitsNotificationCreditDebit,
                )) &&
            (identical(
                  other.notificationBalanceDeltaThresholdSats,
                  notificationBalanceDeltaThresholdSats,
                ) ||
                const DeepCollectionEquality().equals(
                  other.notificationBalanceDeltaThresholdSats,
                  notificationBalanceDeltaThresholdSats,
                )) &&
            (identical(
                  other.lnbitsNotificationServerStartStop,
                  lnbitsNotificationServerStartStop,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsNotificationServerStartStop,
                  lnbitsNotificationServerStartStop,
                )) &&
            (identical(
                  other.lnbitsNotificationWatchdog,
                  lnbitsNotificationWatchdog,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsNotificationWatchdog,
                  lnbitsNotificationWatchdog,
                )) &&
            (identical(
                  other.lnbitsNotificationServerStatusHours,
                  lnbitsNotificationServerStatusHours,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsNotificationServerStatusHours,
                  lnbitsNotificationServerStatusHours,
                )) &&
            (identical(
                  other.lnbitsNotificationIncomingPaymentAmountSats,
                  lnbitsNotificationIncomingPaymentAmountSats,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsNotificationIncomingPaymentAmountSats,
                  lnbitsNotificationIncomingPaymentAmountSats,
                )) &&
            (identical(
                  other.lnbitsNotificationOutgoingPaymentAmountSats,
                  lnbitsNotificationOutgoingPaymentAmountSats,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsNotificationOutgoingPaymentAmountSats,
                  lnbitsNotificationOutgoingPaymentAmountSats,
                )) &&
            (identical(other.lnbitsRateLimitNo, lnbitsRateLimitNo) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsRateLimitNo,
                  lnbitsRateLimitNo,
                )) &&
            (identical(other.lnbitsRateLimitUnit, lnbitsRateLimitUnit) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsRateLimitUnit,
                  lnbitsRateLimitUnit,
                )) &&
            (identical(other.lnbitsAllowedIps, lnbitsAllowedIps) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAllowedIps,
                  lnbitsAllowedIps,
                )) &&
            (identical(other.lnbitsBlockedIps, lnbitsBlockedIps) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsBlockedIps,
                  lnbitsBlockedIps,
                )) &&
            (identical(other.lnbitsCallbackUrlRules, lnbitsCallbackUrlRules) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsCallbackUrlRules,
                  lnbitsCallbackUrlRules,
                )) &&
            (identical(
                  other.lnbitsWalletLimitMaxBalance,
                  lnbitsWalletLimitMaxBalance,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsWalletLimitMaxBalance,
                  lnbitsWalletLimitMaxBalance,
                )) &&
            (identical(
                  other.lnbitsWalletLimitDailyMaxWithdraw,
                  lnbitsWalletLimitDailyMaxWithdraw,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsWalletLimitDailyMaxWithdraw,
                  lnbitsWalletLimitDailyMaxWithdraw,
                )) &&
            (identical(
                  other.lnbitsWalletLimitSecsBetweenTrans,
                  lnbitsWalletLimitSecsBetweenTrans,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsWalletLimitSecsBetweenTrans,
                  lnbitsWalletLimitSecsBetweenTrans,
                )) &&
            (identical(
                  other.lnbitsOnlyAllowIncomingPayments,
                  lnbitsOnlyAllowIncomingPayments,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsOnlyAllowIncomingPayments,
                  lnbitsOnlyAllowIncomingPayments,
                )) &&
            (identical(
                  other.lnbitsWatchdogSwitchToVoidwallet,
                  lnbitsWatchdogSwitchToVoidwallet,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsWatchdogSwitchToVoidwallet,
                  lnbitsWatchdogSwitchToVoidwallet,
                )) &&
            (identical(
                  other.lnbitsWatchdogIntervalMinutes,
                  lnbitsWatchdogIntervalMinutes,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsWatchdogIntervalMinutes,
                  lnbitsWatchdogIntervalMinutes,
                )) &&
            (identical(other.lnbitsWatchdogDelta, lnbitsWatchdogDelta) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsWatchdogDelta,
                  lnbitsWatchdogDelta,
                )) &&
            (identical(
                  other.lnbitsMaxOutgoingPaymentAmountSats,
                  lnbitsMaxOutgoingPaymentAmountSats,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsMaxOutgoingPaymentAmountSats,
                  lnbitsMaxOutgoingPaymentAmountSats,
                )) &&
            (identical(
                  other.lnbitsMaxIncomingPaymentAmountSats,
                  lnbitsMaxIncomingPaymentAmountSats,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsMaxIncomingPaymentAmountSats,
                  lnbitsMaxIncomingPaymentAmountSats,
                )) &&
            (identical(
                  other.lnbitsExchangeRateCacheSeconds,
                  lnbitsExchangeRateCacheSeconds,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsExchangeRateCacheSeconds,
                  lnbitsExchangeRateCacheSeconds,
                )) &&
            (identical(
                  other.lnbitsExchangeHistorySize,
                  lnbitsExchangeHistorySize,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsExchangeHistorySize,
                  lnbitsExchangeHistorySize,
                )) &&
            (identical(
                  other.lnbitsExchangeHistoryRefreshIntervalSeconds,
                  lnbitsExchangeHistoryRefreshIntervalSeconds,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsExchangeHistoryRefreshIntervalSeconds,
                  lnbitsExchangeHistoryRefreshIntervalSeconds,
                )) &&
            (identical(
                  other.lnbitsExchangeRateProviders,
                  lnbitsExchangeRateProviders,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsExchangeRateProviders,
                  lnbitsExchangeRateProviders,
                )) &&
            (identical(other.lnbitsReserveFeeMin, lnbitsReserveFeeMin) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsReserveFeeMin,
                  lnbitsReserveFeeMin,
                )) &&
            (identical(
                  other.lnbitsReserveFeePercent,
                  lnbitsReserveFeePercent,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsReserveFeePercent,
                  lnbitsReserveFeePercent,
                )) &&
            (identical(other.lnbitsServiceFee, lnbitsServiceFee) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsServiceFee,
                  lnbitsServiceFee,
                )) &&
            (identical(
                  other.lnbitsServiceFeeIgnoreInternal,
                  lnbitsServiceFeeIgnoreInternal,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsServiceFeeIgnoreInternal,
                  lnbitsServiceFeeIgnoreInternal,
                )) &&
            (identical(other.lnbitsServiceFeeMax, lnbitsServiceFeeMax) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsServiceFeeMax,
                  lnbitsServiceFeeMax,
                )) &&
            (identical(other.lnbitsServiceFeeWallet, lnbitsServiceFeeWallet) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsServiceFeeWallet,
                  lnbitsServiceFeeWallet,
                )) &&
            (identical(other.lnbitsMaxAssetSizeMb, lnbitsMaxAssetSizeMb) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsMaxAssetSizeMb,
                  lnbitsMaxAssetSizeMb,
                )) &&
            (identical(
                  other.lnbitsAssetsAllowedMimeTypes,
                  lnbitsAssetsAllowedMimeTypes,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAssetsAllowedMimeTypes,
                  lnbitsAssetsAllowedMimeTypes,
                )) &&
            (identical(
                  other.lnbitsAssetThumbnailWidth,
                  lnbitsAssetThumbnailWidth,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAssetThumbnailWidth,
                  lnbitsAssetThumbnailWidth,
                )) &&
            (identical(
                  other.lnbitsAssetThumbnailHeight,
                  lnbitsAssetThumbnailHeight,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAssetThumbnailHeight,
                  lnbitsAssetThumbnailHeight,
                )) &&
            (identical(
                  other.lnbitsAssetThumbnailFormat,
                  lnbitsAssetThumbnailFormat,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAssetThumbnailFormat,
                  lnbitsAssetThumbnailFormat,
                )) &&
            (identical(other.lnbitsMaxAssetsPerUser, lnbitsMaxAssetsPerUser) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsMaxAssetsPerUser,
                  lnbitsMaxAssetsPerUser,
                )) &&
            (identical(
                  other.lnbitsAssetsNoLimitUsers,
                  lnbitsAssetsNoLimitUsers,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAssetsNoLimitUsers,
                  lnbitsAssetsNoLimitUsers,
                )) &&
            (identical(other.lnbitsBaseurl, lnbitsBaseurl) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsBaseurl,
                  lnbitsBaseurl,
                )) &&
            (identical(other.lnbitsHideApi, lnbitsHideApi) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsHideApi,
                  lnbitsHideApi,
                )) &&
            (identical(other.lnbitsSiteTitle, lnbitsSiteTitle) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsSiteTitle,
                  lnbitsSiteTitle,
                )) &&
            (identical(other.lnbitsSiteTagline, lnbitsSiteTagline) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsSiteTagline,
                  lnbitsSiteTagline,
                )) &&
            (identical(other.lnbitsSiteDescription, lnbitsSiteDescription) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsSiteDescription,
                  lnbitsSiteDescription,
                )) &&
            (identical(
                  other.lnbitsShowHomePageElements,
                  lnbitsShowHomePageElements,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsShowHomePageElements,
                  lnbitsShowHomePageElements,
                )) &&
            (identical(
                  other.lnbitsDefaultWalletName,
                  lnbitsDefaultWalletName,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsDefaultWalletName,
                  lnbitsDefaultWalletName,
                )) &&
            (identical(other.lnbitsCustomBadge, lnbitsCustomBadge) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsCustomBadge,
                  lnbitsCustomBadge,
                )) &&
            (identical(other.lnbitsCustomBadgeColor, lnbitsCustomBadgeColor) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsCustomBadgeColor,
                  lnbitsCustomBadgeColor,
                )) &&
            (identical(other.lnbitsThemeOptions, lnbitsThemeOptions) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsThemeOptions,
                  lnbitsThemeOptions,
                )) &&
            (identical(other.lnbitsCustomLogo, lnbitsCustomLogo) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsCustomLogo,
                  lnbitsCustomLogo,
                )) &&
            (identical(other.lnbitsCustomImage, lnbitsCustomImage) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsCustomImage,
                  lnbitsCustomImage,
                )) &&
            (identical(other.lnbitsAdSpaceTitle, lnbitsAdSpaceTitle) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAdSpaceTitle,
                  lnbitsAdSpaceTitle,
                )) &&
            (identical(other.lnbitsAdSpace, lnbitsAdSpace) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAdSpace,
                  lnbitsAdSpace,
                )) &&
            (identical(other.lnbitsAdSpaceEnabled, lnbitsAdSpaceEnabled) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAdSpaceEnabled,
                  lnbitsAdSpaceEnabled,
                )) &&
            (identical(
                  other.lnbitsAllowedCurrencies,
                  lnbitsAllowedCurrencies,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAllowedCurrencies,
                  lnbitsAllowedCurrencies,
                )) &&
            (identical(
                  other.lnbitsDefaultAccountingCurrency,
                  lnbitsDefaultAccountingCurrency,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsDefaultAccountingCurrency,
                  lnbitsDefaultAccountingCurrency,
                )) &&
            (identical(other.lnbitsQrLogo, lnbitsQrLogo) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsQrLogo,
                  lnbitsQrLogo,
                )) &&
            (identical(other.lnbitsAppleTouchIcon, lnbitsAppleTouchIcon) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAppleTouchIcon,
                  lnbitsAppleTouchIcon,
                )) &&
            (identical(other.lnbitsDefaultReaction, lnbitsDefaultReaction) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsDefaultReaction,
                  lnbitsDefaultReaction,
                )) &&
            (identical(other.lnbitsDefaultTheme, lnbitsDefaultTheme) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsDefaultTheme,
                  lnbitsDefaultTheme,
                )) &&
            (identical(other.lnbitsDefaultBorder, lnbitsDefaultBorder) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsDefaultBorder,
                  lnbitsDefaultBorder,
                )) &&
            (identical(other.lnbitsDefaultGradient, lnbitsDefaultGradient) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsDefaultGradient,
                  lnbitsDefaultGradient,
                )) &&
            (identical(other.lnbitsDefaultBgimage, lnbitsDefaultBgimage) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsDefaultBgimage,
                  lnbitsDefaultBgimage,
                )) &&
            (identical(other.lnbitsAdminExtensions, lnbitsAdminExtensions) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAdminExtensions,
                  lnbitsAdminExtensions,
                )) &&
            (identical(
                  other.lnbitsUserDefaultExtensions,
                  lnbitsUserDefaultExtensions,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsUserDefaultExtensions,
                  lnbitsUserDefaultExtensions,
                )) &&
            (identical(
                  other.lnbitsExtensionsDeactivateAll,
                  lnbitsExtensionsDeactivateAll,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsExtensionsDeactivateAll,
                  lnbitsExtensionsDeactivateAll,
                )) &&
            (identical(
                  other.lnbitsExtensionsBuilderActivateNonAdmins,
                  lnbitsExtensionsBuilderActivateNonAdmins,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsExtensionsBuilderActivateNonAdmins,
                  lnbitsExtensionsBuilderActivateNonAdmins,
                )) &&
            (identical(
                  other.lnbitsExtensionsReviewsUrl,
                  lnbitsExtensionsReviewsUrl,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsExtensionsReviewsUrl,
                  lnbitsExtensionsReviewsUrl,
                )) &&
            (identical(
                  other.lnbitsExtensionsManifests,
                  lnbitsExtensionsManifests,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsExtensionsManifests,
                  lnbitsExtensionsManifests,
                )) &&
            (identical(
                  other.lnbitsExtensionsBuilderManifestUrl,
                  lnbitsExtensionsBuilderManifestUrl,
                ) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsExtensionsBuilderManifestUrl,
                  lnbitsExtensionsBuilderManifestUrl,
                )) &&
            (identical(other.lnbitsAdminUsers, lnbitsAdminUsers) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAdminUsers,
                  lnbitsAdminUsers,
                )) &&
            (identical(other.lnbitsAllowedUsers, lnbitsAllowedUsers) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAllowedUsers,
                  lnbitsAllowedUsers,
                )) &&
            (identical(other.lnbitsAllowNewAccounts, lnbitsAllowNewAccounts) ||
                const DeepCollectionEquality().equals(
                  other.lnbitsAllowNewAccounts,
                  lnbitsAllowNewAccounts,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(keycloakDiscoveryUrl) ^
      const DeepCollectionEquality().hash(keycloakClientId) ^
      const DeepCollectionEquality().hash(keycloakClientSecret) ^
      const DeepCollectionEquality().hash(keycloakClientCustomOrg) ^
      const DeepCollectionEquality().hash(keycloakClientCustomIcon) ^
      const DeepCollectionEquality().hash(githubClientId) ^
      const DeepCollectionEquality().hash(githubClientSecret) ^
      const DeepCollectionEquality().hash(googleClientId) ^
      const DeepCollectionEquality().hash(googleClientSecret) ^
      const DeepCollectionEquality().hash(nostrAbsoluteRequestUrls) ^
      const DeepCollectionEquality().hash(authTokenExpireMinutes) ^
      const DeepCollectionEquality().hash(authAllMethods) ^
      const DeepCollectionEquality().hash(authAllowedMethods) ^
      const DeepCollectionEquality().hash(authCredetialsUpdateThreshold) ^
      const DeepCollectionEquality().hash(authAuthenticationCacheMinutes) ^
      const DeepCollectionEquality().hash(lnbitsAuditEnabled) ^
      const DeepCollectionEquality().hash(lnbitsAuditRetentionDays) ^
      const DeepCollectionEquality().hash(lnbitsAuditLogIpAddress) ^
      const DeepCollectionEquality().hash(lnbitsAuditLogPathParams) ^
      const DeepCollectionEquality().hash(lnbitsAuditLogQueryParams) ^
      const DeepCollectionEquality().hash(lnbitsAuditLogRequestBody) ^
      const DeepCollectionEquality().hash(lnbitsAuditIncludePaths) ^
      const DeepCollectionEquality().hash(lnbitsAuditExcludePaths) ^
      const DeepCollectionEquality().hash(lnbitsAuditHttpMethods) ^
      const DeepCollectionEquality().hash(lnbitsAuditHttpResponseCodes) ^
      const DeepCollectionEquality().hash(lnbitsNodeUi) ^
      const DeepCollectionEquality().hash(lnbitsPublicNodeUi) ^
      const DeepCollectionEquality().hash(lnbitsNodeUiTransactions) ^
      const DeepCollectionEquality().hash(lnbitsWebpushPubkey) ^
      const DeepCollectionEquality().hash(lnbitsWebpushPrivkey) ^
      const DeepCollectionEquality().hash(lightningInvoiceExpiry) ^
      const DeepCollectionEquality().hash(paypalEnabled) ^
      const DeepCollectionEquality().hash(paypalApiEndpoint) ^
      const DeepCollectionEquality().hash(paypalClientId) ^
      const DeepCollectionEquality().hash(paypalClientSecret) ^
      const DeepCollectionEquality().hash(paypalPaymentSuccessUrl) ^
      const DeepCollectionEquality().hash(paypalPaymentWebhookUrl) ^
      const DeepCollectionEquality().hash(paypalWebhookId) ^
      const DeepCollectionEquality().hash(paypalLimits) ^
      const DeepCollectionEquality().hash(stripeEnabled) ^
      const DeepCollectionEquality().hash(stripeApiEndpoint) ^
      const DeepCollectionEquality().hash(stripeApiSecretKey) ^
      const DeepCollectionEquality().hash(stripePaymentSuccessUrl) ^
      const DeepCollectionEquality().hash(stripePaymentWebhookUrl) ^
      const DeepCollectionEquality().hash(stripeWebhookSigningSecret) ^
      const DeepCollectionEquality().hash(stripeLimits) ^
      const DeepCollectionEquality().hash(breezLiquidApiKey) ^
      const DeepCollectionEquality().hash(breezLiquidSeed) ^
      const DeepCollectionEquality().hash(breezLiquidFeeOffsetSat) ^
      const DeepCollectionEquality().hash(strikeApiEndpoint) ^
      const DeepCollectionEquality().hash(strikeApiKey) ^
      const DeepCollectionEquality().hash(breezApiKey) ^
      const DeepCollectionEquality().hash(breezGreenlightSeed) ^
      const DeepCollectionEquality().hash(breezGreenlightInviteCode) ^
      const DeepCollectionEquality().hash(breezGreenlightDeviceKey) ^
      const DeepCollectionEquality().hash(breezGreenlightDeviceCert) ^
      const DeepCollectionEquality().hash(breezUseTrampoline) ^
      const DeepCollectionEquality().hash(nwcPairingUrl) ^
      const DeepCollectionEquality().hash(lntipsApiEndpoint) ^
      const DeepCollectionEquality().hash(lntipsApiKey) ^
      const DeepCollectionEquality().hash(lntipsAdminKey) ^
      const DeepCollectionEquality().hash(lntipsInvoiceKey) ^
      const DeepCollectionEquality().hash(sparkUrl) ^
      const DeepCollectionEquality().hash(sparkToken) ^
      const DeepCollectionEquality().hash(opennodeApiEndpoint) ^
      const DeepCollectionEquality().hash(opennodeKey) ^
      const DeepCollectionEquality().hash(opennodeAdminKey) ^
      const DeepCollectionEquality().hash(opennodeInvoiceKey) ^
      const DeepCollectionEquality().hash(phoenixdApiEndpoint) ^
      const DeepCollectionEquality().hash(phoenixdApiPassword) ^
      const DeepCollectionEquality().hash(zbdApiEndpoint) ^
      const DeepCollectionEquality().hash(zbdApiKey) ^
      const DeepCollectionEquality().hash(boltzClientEndpoint) ^
      const DeepCollectionEquality().hash(boltzClientMacaroon) ^
      const DeepCollectionEquality().hash(boltzClientPassword) ^
      const DeepCollectionEquality().hash(boltzClientCert) ^
      const DeepCollectionEquality().hash(boltzMnemonic) ^
      const DeepCollectionEquality().hash(albyApiEndpoint) ^
      const DeepCollectionEquality().hash(albyAccessToken) ^
      const DeepCollectionEquality().hash(blinkApiEndpoint) ^
      const DeepCollectionEquality().hash(blinkWsEndpoint) ^
      const DeepCollectionEquality().hash(blinkToken) ^
      const DeepCollectionEquality().hash(lnpayApiEndpoint) ^
      const DeepCollectionEquality().hash(lnpayApiKey) ^
      const DeepCollectionEquality().hash(lnpayWalletKey) ^
      const DeepCollectionEquality().hash(lnpayAdminKey) ^
      const DeepCollectionEquality().hash(lndGrpcEndpoint) ^
      const DeepCollectionEquality().hash(lndGrpcCert) ^
      const DeepCollectionEquality().hash(lndGrpcPort) ^
      const DeepCollectionEquality().hash(lndGrpcAdminMacaroon) ^
      const DeepCollectionEquality().hash(lndGrpcInvoiceMacaroon) ^
      const DeepCollectionEquality().hash(lndGrpcMacaroon) ^
      const DeepCollectionEquality().hash(lndGrpcMacaroonEncrypted) ^
      const DeepCollectionEquality().hash(lndRestEndpoint) ^
      const DeepCollectionEquality().hash(lndRestCert) ^
      const DeepCollectionEquality().hash(lndRestMacaroon) ^
      const DeepCollectionEquality().hash(lndRestMacaroonEncrypted) ^
      const DeepCollectionEquality().hash(lndRestRouteHints) ^
      const DeepCollectionEquality().hash(lndRestAllowSelfPayment) ^
      const DeepCollectionEquality().hash(lndCert) ^
      const DeepCollectionEquality().hash(lndAdminMacaroon) ^
      const DeepCollectionEquality().hash(lndInvoiceMacaroon) ^
      const DeepCollectionEquality().hash(lndRestAdminMacaroon) ^
      const DeepCollectionEquality().hash(lndRestInvoiceMacaroon) ^
      const DeepCollectionEquality().hash(eclairUrl) ^
      const DeepCollectionEquality().hash(eclairPass) ^
      const DeepCollectionEquality().hash(corelightningRestUrl) ^
      const DeepCollectionEquality().hash(corelightningRestMacaroon) ^
      const DeepCollectionEquality().hash(corelightningRestCert) ^
      const DeepCollectionEquality().hash(corelightningRpc) ^
      const DeepCollectionEquality().hash(corelightningPayCommand) ^
      const DeepCollectionEquality().hash(clightningRpc) ^
      const DeepCollectionEquality().hash(clnrestUrl) ^
      const DeepCollectionEquality().hash(clnrestCa) ^
      const DeepCollectionEquality().hash(clnrestCert) ^
      const DeepCollectionEquality().hash(clnrestReadonlyRune) ^
      const DeepCollectionEquality().hash(clnrestInvoiceRune) ^
      const DeepCollectionEquality().hash(clnrestPayRune) ^
      const DeepCollectionEquality().hash(clnrestRenepayRune) ^
      const DeepCollectionEquality().hash(clnrestLastPayIndex) ^
      const DeepCollectionEquality().hash(clnrestNodeid) ^
      const DeepCollectionEquality().hash(clicheEndpoint) ^
      const DeepCollectionEquality().hash(lnbitsEndpoint) ^
      const DeepCollectionEquality().hash(lnbitsKey) ^
      const DeepCollectionEquality().hash(lnbitsAdminKey) ^
      const DeepCollectionEquality().hash(lnbitsInvoiceKey) ^
      const DeepCollectionEquality().hash(fakeWalletSecret) ^
      const DeepCollectionEquality().hash(lnbitsDenomination) ^
      const DeepCollectionEquality().hash(lnbitsBackendWalletClass) ^
      const DeepCollectionEquality().hash(
        lnbitsFundingSourcePayInvoiceWaitSeconds,
      ) ^
      const DeepCollectionEquality().hash(fundingSourceMaxRetries) ^
      const DeepCollectionEquality().hash(lnbitsNostrNotificationsEnabled) ^
      const DeepCollectionEquality().hash(lnbitsNostrNotificationsPrivateKey) ^
      const DeepCollectionEquality().hash(lnbitsNostrNotificationsIdentifiers) ^
      const DeepCollectionEquality().hash(lnbitsTelegramNotificationsEnabled) ^
      const DeepCollectionEquality().hash(
        lnbitsTelegramNotificationsAccessToken,
      ) ^
      const DeepCollectionEquality().hash(lnbitsTelegramNotificationsChatId) ^
      const DeepCollectionEquality().hash(lnbitsEmailNotificationsEnabled) ^
      const DeepCollectionEquality().hash(lnbitsEmailNotificationsEmail) ^
      const DeepCollectionEquality().hash(lnbitsEmailNotificationsUsername) ^
      const DeepCollectionEquality().hash(lnbitsEmailNotificationsPassword) ^
      const DeepCollectionEquality().hash(lnbitsEmailNotificationsServer) ^
      const DeepCollectionEquality().hash(lnbitsEmailNotificationsPort) ^
      const DeepCollectionEquality().hash(lnbitsEmailNotificationsToEmails) ^
      const DeepCollectionEquality().hash(lnbitsNotificationSettingsUpdate) ^
      const DeepCollectionEquality().hash(lnbitsNotificationCreditDebit) ^
      const DeepCollectionEquality().hash(
        notificationBalanceDeltaThresholdSats,
      ) ^
      const DeepCollectionEquality().hash(lnbitsNotificationServerStartStop) ^
      const DeepCollectionEquality().hash(lnbitsNotificationWatchdog) ^
      const DeepCollectionEquality().hash(lnbitsNotificationServerStatusHours) ^
      const DeepCollectionEquality().hash(
        lnbitsNotificationIncomingPaymentAmountSats,
      ) ^
      const DeepCollectionEquality().hash(
        lnbitsNotificationOutgoingPaymentAmountSats,
      ) ^
      const DeepCollectionEquality().hash(lnbitsRateLimitNo) ^
      const DeepCollectionEquality().hash(lnbitsRateLimitUnit) ^
      const DeepCollectionEquality().hash(lnbitsAllowedIps) ^
      const DeepCollectionEquality().hash(lnbitsBlockedIps) ^
      const DeepCollectionEquality().hash(lnbitsCallbackUrlRules) ^
      const DeepCollectionEquality().hash(lnbitsWalletLimitMaxBalance) ^
      const DeepCollectionEquality().hash(lnbitsWalletLimitDailyMaxWithdraw) ^
      const DeepCollectionEquality().hash(lnbitsWalletLimitSecsBetweenTrans) ^
      const DeepCollectionEquality().hash(lnbitsOnlyAllowIncomingPayments) ^
      const DeepCollectionEquality().hash(lnbitsWatchdogSwitchToVoidwallet) ^
      const DeepCollectionEquality().hash(lnbitsWatchdogIntervalMinutes) ^
      const DeepCollectionEquality().hash(lnbitsWatchdogDelta) ^
      const DeepCollectionEquality().hash(lnbitsMaxOutgoingPaymentAmountSats) ^
      const DeepCollectionEquality().hash(lnbitsMaxIncomingPaymentAmountSats) ^
      const DeepCollectionEquality().hash(lnbitsExchangeRateCacheSeconds) ^
      const DeepCollectionEquality().hash(lnbitsExchangeHistorySize) ^
      const DeepCollectionEquality().hash(
        lnbitsExchangeHistoryRefreshIntervalSeconds,
      ) ^
      const DeepCollectionEquality().hash(lnbitsExchangeRateProviders) ^
      const DeepCollectionEquality().hash(lnbitsReserveFeeMin) ^
      const DeepCollectionEquality().hash(lnbitsReserveFeePercent) ^
      const DeepCollectionEquality().hash(lnbitsServiceFee) ^
      const DeepCollectionEquality().hash(lnbitsServiceFeeIgnoreInternal) ^
      const DeepCollectionEquality().hash(lnbitsServiceFeeMax) ^
      const DeepCollectionEquality().hash(lnbitsServiceFeeWallet) ^
      const DeepCollectionEquality().hash(lnbitsMaxAssetSizeMb) ^
      const DeepCollectionEquality().hash(lnbitsAssetsAllowedMimeTypes) ^
      const DeepCollectionEquality().hash(lnbitsAssetThumbnailWidth) ^
      const DeepCollectionEquality().hash(lnbitsAssetThumbnailHeight) ^
      const DeepCollectionEquality().hash(lnbitsAssetThumbnailFormat) ^
      const DeepCollectionEquality().hash(lnbitsMaxAssetsPerUser) ^
      const DeepCollectionEquality().hash(lnbitsAssetsNoLimitUsers) ^
      const DeepCollectionEquality().hash(lnbitsBaseurl) ^
      const DeepCollectionEquality().hash(lnbitsHideApi) ^
      const DeepCollectionEquality().hash(lnbitsSiteTitle) ^
      const DeepCollectionEquality().hash(lnbitsSiteTagline) ^
      const DeepCollectionEquality().hash(lnbitsSiteDescription) ^
      const DeepCollectionEquality().hash(lnbitsShowHomePageElements) ^
      const DeepCollectionEquality().hash(lnbitsDefaultWalletName) ^
      const DeepCollectionEquality().hash(lnbitsCustomBadge) ^
      const DeepCollectionEquality().hash(lnbitsCustomBadgeColor) ^
      const DeepCollectionEquality().hash(lnbitsThemeOptions) ^
      const DeepCollectionEquality().hash(lnbitsCustomLogo) ^
      const DeepCollectionEquality().hash(lnbitsCustomImage) ^
      const DeepCollectionEquality().hash(lnbitsAdSpaceTitle) ^
      const DeepCollectionEquality().hash(lnbitsAdSpace) ^
      const DeepCollectionEquality().hash(lnbitsAdSpaceEnabled) ^
      const DeepCollectionEquality().hash(lnbitsAllowedCurrencies) ^
      const DeepCollectionEquality().hash(lnbitsDefaultAccountingCurrency) ^
      const DeepCollectionEquality().hash(lnbitsQrLogo) ^
      const DeepCollectionEquality().hash(lnbitsAppleTouchIcon) ^
      const DeepCollectionEquality().hash(lnbitsDefaultReaction) ^
      const DeepCollectionEquality().hash(lnbitsDefaultTheme) ^
      const DeepCollectionEquality().hash(lnbitsDefaultBorder) ^
      const DeepCollectionEquality().hash(lnbitsDefaultGradient) ^
      const DeepCollectionEquality().hash(lnbitsDefaultBgimage) ^
      const DeepCollectionEquality().hash(lnbitsAdminExtensions) ^
      const DeepCollectionEquality().hash(lnbitsUserDefaultExtensions) ^
      const DeepCollectionEquality().hash(lnbitsExtensionsDeactivateAll) ^
      const DeepCollectionEquality().hash(
        lnbitsExtensionsBuilderActivateNonAdmins,
      ) ^
      const DeepCollectionEquality().hash(lnbitsExtensionsReviewsUrl) ^
      const DeepCollectionEquality().hash(lnbitsExtensionsManifests) ^
      const DeepCollectionEquality().hash(lnbitsExtensionsBuilderManifestUrl) ^
      const DeepCollectionEquality().hash(lnbitsAdminUsers) ^
      const DeepCollectionEquality().hash(lnbitsAllowedUsers) ^
      const DeepCollectionEquality().hash(lnbitsAllowNewAccounts) ^
      runtimeType.hashCode;
}

extension $UpdateSettingsExtension on UpdateSettings {
  UpdateSettings copyWith({
    String? keycloakDiscoveryUrl,
    String? keycloakClientId,
    String? keycloakClientSecret,
    String? keycloakClientCustomOrg,
    String? keycloakClientCustomIcon,
    String? githubClientId,
    String? githubClientSecret,
    String? googleClientId,
    String? googleClientSecret,
    List<String>? nostrAbsoluteRequestUrls,
    int? authTokenExpireMinutes,
    List<String>? authAllMethods,
    List<String>? authAllowedMethods,
    int? authCredetialsUpdateThreshold,
    int? authAuthenticationCacheMinutes,
    bool? lnbitsAuditEnabled,
    int? lnbitsAuditRetentionDays,
    bool? lnbitsAuditLogIpAddress,
    bool? lnbitsAuditLogPathParams,
    bool? lnbitsAuditLogQueryParams,
    bool? lnbitsAuditLogRequestBody,
    List<String>? lnbitsAuditIncludePaths,
    List<String>? lnbitsAuditExcludePaths,
    List<String>? lnbitsAuditHttpMethods,
    List<String>? lnbitsAuditHttpResponseCodes,
    bool? lnbitsNodeUi,
    bool? lnbitsPublicNodeUi,
    bool? lnbitsNodeUiTransactions,
    String? lnbitsWebpushPubkey,
    String? lnbitsWebpushPrivkey,
    int? lightningInvoiceExpiry,
    bool? paypalEnabled,
    String? paypalApiEndpoint,
    String? paypalClientId,
    String? paypalClientSecret,
    String? paypalPaymentSuccessUrl,
    String? paypalPaymentWebhookUrl,
    String? paypalWebhookId,
    FiatProviderLimits? paypalLimits,
    bool? stripeEnabled,
    String? stripeApiEndpoint,
    String? stripeApiSecretKey,
    String? stripePaymentSuccessUrl,
    String? stripePaymentWebhookUrl,
    String? stripeWebhookSigningSecret,
    FiatProviderLimits? stripeLimits,
    String? breezLiquidApiKey,
    String? breezLiquidSeed,
    int? breezLiquidFeeOffsetSat,
    String? strikeApiEndpoint,
    String? strikeApiKey,
    String? breezApiKey,
    String? breezGreenlightSeed,
    String? breezGreenlightInviteCode,
    String? breezGreenlightDeviceKey,
    String? breezGreenlightDeviceCert,
    bool? breezUseTrampoline,
    String? nwcPairingUrl,
    String? lntipsApiEndpoint,
    String? lntipsApiKey,
    String? lntipsAdminKey,
    String? lntipsInvoiceKey,
    String? sparkUrl,
    String? sparkToken,
    String? opennodeApiEndpoint,
    String? opennodeKey,
    String? opennodeAdminKey,
    String? opennodeInvoiceKey,
    String? phoenixdApiEndpoint,
    String? phoenixdApiPassword,
    String? zbdApiEndpoint,
    String? zbdApiKey,
    String? boltzClientEndpoint,
    String? boltzClientMacaroon,
    String? boltzClientPassword,
    String? boltzClientCert,
    String? boltzMnemonic,
    String? albyApiEndpoint,
    String? albyAccessToken,
    String? blinkApiEndpoint,
    String? blinkWsEndpoint,
    String? blinkToken,
    String? lnpayApiEndpoint,
    String? lnpayApiKey,
    String? lnpayWalletKey,
    String? lnpayAdminKey,
    String? lndGrpcEndpoint,
    String? lndGrpcCert,
    int? lndGrpcPort,
    String? lndGrpcAdminMacaroon,
    String? lndGrpcInvoiceMacaroon,
    String? lndGrpcMacaroon,
    String? lndGrpcMacaroonEncrypted,
    String? lndRestEndpoint,
    String? lndRestCert,
    String? lndRestMacaroon,
    String? lndRestMacaroonEncrypted,
    bool? lndRestRouteHints,
    bool? lndRestAllowSelfPayment,
    String? lndCert,
    String? lndAdminMacaroon,
    String? lndInvoiceMacaroon,
    String? lndRestAdminMacaroon,
    String? lndRestInvoiceMacaroon,
    String? eclairUrl,
    String? eclairPass,
    String? corelightningRestUrl,
    String? corelightningRestMacaroon,
    String? corelightningRestCert,
    String? corelightningRpc,
    String? corelightningPayCommand,
    String? clightningRpc,
    String? clnrestUrl,
    String? clnrestCa,
    String? clnrestCert,
    String? clnrestReadonlyRune,
    String? clnrestInvoiceRune,
    String? clnrestPayRune,
    String? clnrestRenepayRune,
    String? clnrestLastPayIndex,
    String? clnrestNodeid,
    String? clicheEndpoint,
    String? lnbitsEndpoint,
    String? lnbitsKey,
    String? lnbitsAdminKey,
    String? lnbitsInvoiceKey,
    String? fakeWalletSecret,
    String? lnbitsDenomination,
    String? lnbitsBackendWalletClass,
    int? lnbitsFundingSourcePayInvoiceWaitSeconds,
    int? fundingSourceMaxRetries,
    bool? lnbitsNostrNotificationsEnabled,
    String? lnbitsNostrNotificationsPrivateKey,
    List<String>? lnbitsNostrNotificationsIdentifiers,
    bool? lnbitsTelegramNotificationsEnabled,
    String? lnbitsTelegramNotificationsAccessToken,
    String? lnbitsTelegramNotificationsChatId,
    bool? lnbitsEmailNotificationsEnabled,
    String? lnbitsEmailNotificationsEmail,
    String? lnbitsEmailNotificationsUsername,
    String? lnbitsEmailNotificationsPassword,
    String? lnbitsEmailNotificationsServer,
    int? lnbitsEmailNotificationsPort,
    List<String>? lnbitsEmailNotificationsToEmails,
    bool? lnbitsNotificationSettingsUpdate,
    bool? lnbitsNotificationCreditDebit,
    int? notificationBalanceDeltaThresholdSats,
    bool? lnbitsNotificationServerStartStop,
    bool? lnbitsNotificationWatchdog,
    int? lnbitsNotificationServerStatusHours,
    int? lnbitsNotificationIncomingPaymentAmountSats,
    int? lnbitsNotificationOutgoingPaymentAmountSats,
    int? lnbitsRateLimitNo,
    String? lnbitsRateLimitUnit,
    List<String>? lnbitsAllowedIps,
    List<String>? lnbitsBlockedIps,
    List<String>? lnbitsCallbackUrlRules,
    int? lnbitsWalletLimitMaxBalance,
    int? lnbitsWalletLimitDailyMaxWithdraw,
    int? lnbitsWalletLimitSecsBetweenTrans,
    bool? lnbitsOnlyAllowIncomingPayments,
    bool? lnbitsWatchdogSwitchToVoidwallet,
    int? lnbitsWatchdogIntervalMinutes,
    int? lnbitsWatchdogDelta,
    int? lnbitsMaxOutgoingPaymentAmountSats,
    int? lnbitsMaxIncomingPaymentAmountSats,
    int? lnbitsExchangeRateCacheSeconds,
    int? lnbitsExchangeHistorySize,
    int? lnbitsExchangeHistoryRefreshIntervalSeconds,
    List<ExchangeRateProvider>? lnbitsExchangeRateProviders,
    int? lnbitsReserveFeeMin,
    double? lnbitsReserveFeePercent,
    double? lnbitsServiceFee,
    bool? lnbitsServiceFeeIgnoreInternal,
    int? lnbitsServiceFeeMax,
    String? lnbitsServiceFeeWallet,
    double? lnbitsMaxAssetSizeMb,
    List<String>? lnbitsAssetsAllowedMimeTypes,
    int? lnbitsAssetThumbnailWidth,
    int? lnbitsAssetThumbnailHeight,
    String? lnbitsAssetThumbnailFormat,
    int? lnbitsMaxAssetsPerUser,
    List<String>? lnbitsAssetsNoLimitUsers,
    String? lnbitsBaseurl,
    bool? lnbitsHideApi,
    String? lnbitsSiteTitle,
    String? lnbitsSiteTagline,
    String? lnbitsSiteDescription,
    bool? lnbitsShowHomePageElements,
    String? lnbitsDefaultWalletName,
    String? lnbitsCustomBadge,
    String? lnbitsCustomBadgeColor,
    List<String>? lnbitsThemeOptions,
    String? lnbitsCustomLogo,
    String? lnbitsCustomImage,
    String? lnbitsAdSpaceTitle,
    String? lnbitsAdSpace,
    bool? lnbitsAdSpaceEnabled,
    List<String>? lnbitsAllowedCurrencies,
    String? lnbitsDefaultAccountingCurrency,
    String? lnbitsQrLogo,
    String? lnbitsAppleTouchIcon,
    String? lnbitsDefaultReaction,
    String? lnbitsDefaultTheme,
    String? lnbitsDefaultBorder,
    bool? lnbitsDefaultGradient,
    String? lnbitsDefaultBgimage,
    List<String>? lnbitsAdminExtensions,
    List<String>? lnbitsUserDefaultExtensions,
    bool? lnbitsExtensionsDeactivateAll,
    bool? lnbitsExtensionsBuilderActivateNonAdmins,
    String? lnbitsExtensionsReviewsUrl,
    List<String>? lnbitsExtensionsManifests,
    String? lnbitsExtensionsBuilderManifestUrl,
    List<String>? lnbitsAdminUsers,
    List<String>? lnbitsAllowedUsers,
    bool? lnbitsAllowNewAccounts,
  }) {
    return UpdateSettings(
      keycloakDiscoveryUrl: keycloakDiscoveryUrl ?? this.keycloakDiscoveryUrl,
      keycloakClientId: keycloakClientId ?? this.keycloakClientId,
      keycloakClientSecret: keycloakClientSecret ?? this.keycloakClientSecret,
      keycloakClientCustomOrg:
          keycloakClientCustomOrg ?? this.keycloakClientCustomOrg,
      keycloakClientCustomIcon:
          keycloakClientCustomIcon ?? this.keycloakClientCustomIcon,
      githubClientId: githubClientId ?? this.githubClientId,
      githubClientSecret: githubClientSecret ?? this.githubClientSecret,
      googleClientId: googleClientId ?? this.googleClientId,
      googleClientSecret: googleClientSecret ?? this.googleClientSecret,
      nostrAbsoluteRequestUrls:
          nostrAbsoluteRequestUrls ?? this.nostrAbsoluteRequestUrls,
      authTokenExpireMinutes:
          authTokenExpireMinutes ?? this.authTokenExpireMinutes,
      authAllMethods: authAllMethods ?? this.authAllMethods,
      authAllowedMethods: authAllowedMethods ?? this.authAllowedMethods,
      authCredetialsUpdateThreshold:
          authCredetialsUpdateThreshold ?? this.authCredetialsUpdateThreshold,
      authAuthenticationCacheMinutes:
          authAuthenticationCacheMinutes ?? this.authAuthenticationCacheMinutes,
      lnbitsAuditEnabled: lnbitsAuditEnabled ?? this.lnbitsAuditEnabled,
      lnbitsAuditRetentionDays:
          lnbitsAuditRetentionDays ?? this.lnbitsAuditRetentionDays,
      lnbitsAuditLogIpAddress:
          lnbitsAuditLogIpAddress ?? this.lnbitsAuditLogIpAddress,
      lnbitsAuditLogPathParams:
          lnbitsAuditLogPathParams ?? this.lnbitsAuditLogPathParams,
      lnbitsAuditLogQueryParams:
          lnbitsAuditLogQueryParams ?? this.lnbitsAuditLogQueryParams,
      lnbitsAuditLogRequestBody:
          lnbitsAuditLogRequestBody ?? this.lnbitsAuditLogRequestBody,
      lnbitsAuditIncludePaths:
          lnbitsAuditIncludePaths ?? this.lnbitsAuditIncludePaths,
      lnbitsAuditExcludePaths:
          lnbitsAuditExcludePaths ?? this.lnbitsAuditExcludePaths,
      lnbitsAuditHttpMethods:
          lnbitsAuditHttpMethods ?? this.lnbitsAuditHttpMethods,
      lnbitsAuditHttpResponseCodes:
          lnbitsAuditHttpResponseCodes ?? this.lnbitsAuditHttpResponseCodes,
      lnbitsNodeUi: lnbitsNodeUi ?? this.lnbitsNodeUi,
      lnbitsPublicNodeUi: lnbitsPublicNodeUi ?? this.lnbitsPublicNodeUi,
      lnbitsNodeUiTransactions:
          lnbitsNodeUiTransactions ?? this.lnbitsNodeUiTransactions,
      lnbitsWebpushPubkey: lnbitsWebpushPubkey ?? this.lnbitsWebpushPubkey,
      lnbitsWebpushPrivkey: lnbitsWebpushPrivkey ?? this.lnbitsWebpushPrivkey,
      lightningInvoiceExpiry:
          lightningInvoiceExpiry ?? this.lightningInvoiceExpiry,
      paypalEnabled: paypalEnabled ?? this.paypalEnabled,
      paypalApiEndpoint: paypalApiEndpoint ?? this.paypalApiEndpoint,
      paypalClientId: paypalClientId ?? this.paypalClientId,
      paypalClientSecret: paypalClientSecret ?? this.paypalClientSecret,
      paypalPaymentSuccessUrl:
          paypalPaymentSuccessUrl ?? this.paypalPaymentSuccessUrl,
      paypalPaymentWebhookUrl:
          paypalPaymentWebhookUrl ?? this.paypalPaymentWebhookUrl,
      paypalWebhookId: paypalWebhookId ?? this.paypalWebhookId,
      paypalLimits: paypalLimits ?? this.paypalLimits,
      stripeEnabled: stripeEnabled ?? this.stripeEnabled,
      stripeApiEndpoint: stripeApiEndpoint ?? this.stripeApiEndpoint,
      stripeApiSecretKey: stripeApiSecretKey ?? this.stripeApiSecretKey,
      stripePaymentSuccessUrl:
          stripePaymentSuccessUrl ?? this.stripePaymentSuccessUrl,
      stripePaymentWebhookUrl:
          stripePaymentWebhookUrl ?? this.stripePaymentWebhookUrl,
      stripeWebhookSigningSecret:
          stripeWebhookSigningSecret ?? this.stripeWebhookSigningSecret,
      stripeLimits: stripeLimits ?? this.stripeLimits,
      breezLiquidApiKey: breezLiquidApiKey ?? this.breezLiquidApiKey,
      breezLiquidSeed: breezLiquidSeed ?? this.breezLiquidSeed,
      breezLiquidFeeOffsetSat:
          breezLiquidFeeOffsetSat ?? this.breezLiquidFeeOffsetSat,
      strikeApiEndpoint: strikeApiEndpoint ?? this.strikeApiEndpoint,
      strikeApiKey: strikeApiKey ?? this.strikeApiKey,
      breezApiKey: breezApiKey ?? this.breezApiKey,
      breezGreenlightSeed: breezGreenlightSeed ?? this.breezGreenlightSeed,
      breezGreenlightInviteCode:
          breezGreenlightInviteCode ?? this.breezGreenlightInviteCode,
      breezGreenlightDeviceKey:
          breezGreenlightDeviceKey ?? this.breezGreenlightDeviceKey,
      breezGreenlightDeviceCert:
          breezGreenlightDeviceCert ?? this.breezGreenlightDeviceCert,
      breezUseTrampoline: breezUseTrampoline ?? this.breezUseTrampoline,
      nwcPairingUrl: nwcPairingUrl ?? this.nwcPairingUrl,
      lntipsApiEndpoint: lntipsApiEndpoint ?? this.lntipsApiEndpoint,
      lntipsApiKey: lntipsApiKey ?? this.lntipsApiKey,
      lntipsAdminKey: lntipsAdminKey ?? this.lntipsAdminKey,
      lntipsInvoiceKey: lntipsInvoiceKey ?? this.lntipsInvoiceKey,
      sparkUrl: sparkUrl ?? this.sparkUrl,
      sparkToken: sparkToken ?? this.sparkToken,
      opennodeApiEndpoint: opennodeApiEndpoint ?? this.opennodeApiEndpoint,
      opennodeKey: opennodeKey ?? this.opennodeKey,
      opennodeAdminKey: opennodeAdminKey ?? this.opennodeAdminKey,
      opennodeInvoiceKey: opennodeInvoiceKey ?? this.opennodeInvoiceKey,
      phoenixdApiEndpoint: phoenixdApiEndpoint ?? this.phoenixdApiEndpoint,
      phoenixdApiPassword: phoenixdApiPassword ?? this.phoenixdApiPassword,
      zbdApiEndpoint: zbdApiEndpoint ?? this.zbdApiEndpoint,
      zbdApiKey: zbdApiKey ?? this.zbdApiKey,
      boltzClientEndpoint: boltzClientEndpoint ?? this.boltzClientEndpoint,
      boltzClientMacaroon: boltzClientMacaroon ?? this.boltzClientMacaroon,
      boltzClientPassword: boltzClientPassword ?? this.boltzClientPassword,
      boltzClientCert: boltzClientCert ?? this.boltzClientCert,
      boltzMnemonic: boltzMnemonic ?? this.boltzMnemonic,
      albyApiEndpoint: albyApiEndpoint ?? this.albyApiEndpoint,
      albyAccessToken: albyAccessToken ?? this.albyAccessToken,
      blinkApiEndpoint: blinkApiEndpoint ?? this.blinkApiEndpoint,
      blinkWsEndpoint: blinkWsEndpoint ?? this.blinkWsEndpoint,
      blinkToken: blinkToken ?? this.blinkToken,
      lnpayApiEndpoint: lnpayApiEndpoint ?? this.lnpayApiEndpoint,
      lnpayApiKey: lnpayApiKey ?? this.lnpayApiKey,
      lnpayWalletKey: lnpayWalletKey ?? this.lnpayWalletKey,
      lnpayAdminKey: lnpayAdminKey ?? this.lnpayAdminKey,
      lndGrpcEndpoint: lndGrpcEndpoint ?? this.lndGrpcEndpoint,
      lndGrpcCert: lndGrpcCert ?? this.lndGrpcCert,
      lndGrpcPort: lndGrpcPort ?? this.lndGrpcPort,
      lndGrpcAdminMacaroon: lndGrpcAdminMacaroon ?? this.lndGrpcAdminMacaroon,
      lndGrpcInvoiceMacaroon:
          lndGrpcInvoiceMacaroon ?? this.lndGrpcInvoiceMacaroon,
      lndGrpcMacaroon: lndGrpcMacaroon ?? this.lndGrpcMacaroon,
      lndGrpcMacaroonEncrypted:
          lndGrpcMacaroonEncrypted ?? this.lndGrpcMacaroonEncrypted,
      lndRestEndpoint: lndRestEndpoint ?? this.lndRestEndpoint,
      lndRestCert: lndRestCert ?? this.lndRestCert,
      lndRestMacaroon: lndRestMacaroon ?? this.lndRestMacaroon,
      lndRestMacaroonEncrypted:
          lndRestMacaroonEncrypted ?? this.lndRestMacaroonEncrypted,
      lndRestRouteHints: lndRestRouteHints ?? this.lndRestRouteHints,
      lndRestAllowSelfPayment:
          lndRestAllowSelfPayment ?? this.lndRestAllowSelfPayment,
      lndCert: lndCert ?? this.lndCert,
      lndAdminMacaroon: lndAdminMacaroon ?? this.lndAdminMacaroon,
      lndInvoiceMacaroon: lndInvoiceMacaroon ?? this.lndInvoiceMacaroon,
      lndRestAdminMacaroon: lndRestAdminMacaroon ?? this.lndRestAdminMacaroon,
      lndRestInvoiceMacaroon:
          lndRestInvoiceMacaroon ?? this.lndRestInvoiceMacaroon,
      eclairUrl: eclairUrl ?? this.eclairUrl,
      eclairPass: eclairPass ?? this.eclairPass,
      corelightningRestUrl: corelightningRestUrl ?? this.corelightningRestUrl,
      corelightningRestMacaroon:
          corelightningRestMacaroon ?? this.corelightningRestMacaroon,
      corelightningRestCert:
          corelightningRestCert ?? this.corelightningRestCert,
      corelightningRpc: corelightningRpc ?? this.corelightningRpc,
      corelightningPayCommand:
          corelightningPayCommand ?? this.corelightningPayCommand,
      clightningRpc: clightningRpc ?? this.clightningRpc,
      clnrestUrl: clnrestUrl ?? this.clnrestUrl,
      clnrestCa: clnrestCa ?? this.clnrestCa,
      clnrestCert: clnrestCert ?? this.clnrestCert,
      clnrestReadonlyRune: clnrestReadonlyRune ?? this.clnrestReadonlyRune,
      clnrestInvoiceRune: clnrestInvoiceRune ?? this.clnrestInvoiceRune,
      clnrestPayRune: clnrestPayRune ?? this.clnrestPayRune,
      clnrestRenepayRune: clnrestRenepayRune ?? this.clnrestRenepayRune,
      clnrestLastPayIndex: clnrestLastPayIndex ?? this.clnrestLastPayIndex,
      clnrestNodeid: clnrestNodeid ?? this.clnrestNodeid,
      clicheEndpoint: clicheEndpoint ?? this.clicheEndpoint,
      lnbitsEndpoint: lnbitsEndpoint ?? this.lnbitsEndpoint,
      lnbitsKey: lnbitsKey ?? this.lnbitsKey,
      lnbitsAdminKey: lnbitsAdminKey ?? this.lnbitsAdminKey,
      lnbitsInvoiceKey: lnbitsInvoiceKey ?? this.lnbitsInvoiceKey,
      fakeWalletSecret: fakeWalletSecret ?? this.fakeWalletSecret,
      lnbitsDenomination: lnbitsDenomination ?? this.lnbitsDenomination,
      lnbitsBackendWalletClass:
          lnbitsBackendWalletClass ?? this.lnbitsBackendWalletClass,
      lnbitsFundingSourcePayInvoiceWaitSeconds:
          lnbitsFundingSourcePayInvoiceWaitSeconds ??
          this.lnbitsFundingSourcePayInvoiceWaitSeconds,
      fundingSourceMaxRetries:
          fundingSourceMaxRetries ?? this.fundingSourceMaxRetries,
      lnbitsNostrNotificationsEnabled:
          lnbitsNostrNotificationsEnabled ??
          this.lnbitsNostrNotificationsEnabled,
      lnbitsNostrNotificationsPrivateKey:
          lnbitsNostrNotificationsPrivateKey ??
          this.lnbitsNostrNotificationsPrivateKey,
      lnbitsNostrNotificationsIdentifiers:
          lnbitsNostrNotificationsIdentifiers ??
          this.lnbitsNostrNotificationsIdentifiers,
      lnbitsTelegramNotificationsEnabled:
          lnbitsTelegramNotificationsEnabled ??
          this.lnbitsTelegramNotificationsEnabled,
      lnbitsTelegramNotificationsAccessToken:
          lnbitsTelegramNotificationsAccessToken ??
          this.lnbitsTelegramNotificationsAccessToken,
      lnbitsTelegramNotificationsChatId:
          lnbitsTelegramNotificationsChatId ??
          this.lnbitsTelegramNotificationsChatId,
      lnbitsEmailNotificationsEnabled:
          lnbitsEmailNotificationsEnabled ??
          this.lnbitsEmailNotificationsEnabled,
      lnbitsEmailNotificationsEmail:
          lnbitsEmailNotificationsEmail ?? this.lnbitsEmailNotificationsEmail,
      lnbitsEmailNotificationsUsername:
          lnbitsEmailNotificationsUsername ??
          this.lnbitsEmailNotificationsUsername,
      lnbitsEmailNotificationsPassword:
          lnbitsEmailNotificationsPassword ??
          this.lnbitsEmailNotificationsPassword,
      lnbitsEmailNotificationsServer:
          lnbitsEmailNotificationsServer ?? this.lnbitsEmailNotificationsServer,
      lnbitsEmailNotificationsPort:
          lnbitsEmailNotificationsPort ?? this.lnbitsEmailNotificationsPort,
      lnbitsEmailNotificationsToEmails:
          lnbitsEmailNotificationsToEmails ??
          this.lnbitsEmailNotificationsToEmails,
      lnbitsNotificationSettingsUpdate:
          lnbitsNotificationSettingsUpdate ??
          this.lnbitsNotificationSettingsUpdate,
      lnbitsNotificationCreditDebit:
          lnbitsNotificationCreditDebit ?? this.lnbitsNotificationCreditDebit,
      notificationBalanceDeltaThresholdSats:
          notificationBalanceDeltaThresholdSats ??
          this.notificationBalanceDeltaThresholdSats,
      lnbitsNotificationServerStartStop:
          lnbitsNotificationServerStartStop ??
          this.lnbitsNotificationServerStartStop,
      lnbitsNotificationWatchdog:
          lnbitsNotificationWatchdog ?? this.lnbitsNotificationWatchdog,
      lnbitsNotificationServerStatusHours:
          lnbitsNotificationServerStatusHours ??
          this.lnbitsNotificationServerStatusHours,
      lnbitsNotificationIncomingPaymentAmountSats:
          lnbitsNotificationIncomingPaymentAmountSats ??
          this.lnbitsNotificationIncomingPaymentAmountSats,
      lnbitsNotificationOutgoingPaymentAmountSats:
          lnbitsNotificationOutgoingPaymentAmountSats ??
          this.lnbitsNotificationOutgoingPaymentAmountSats,
      lnbitsRateLimitNo: lnbitsRateLimitNo ?? this.lnbitsRateLimitNo,
      lnbitsRateLimitUnit: lnbitsRateLimitUnit ?? this.lnbitsRateLimitUnit,
      lnbitsAllowedIps: lnbitsAllowedIps ?? this.lnbitsAllowedIps,
      lnbitsBlockedIps: lnbitsBlockedIps ?? this.lnbitsBlockedIps,
      lnbitsCallbackUrlRules:
          lnbitsCallbackUrlRules ?? this.lnbitsCallbackUrlRules,
      lnbitsWalletLimitMaxBalance:
          lnbitsWalletLimitMaxBalance ?? this.lnbitsWalletLimitMaxBalance,
      lnbitsWalletLimitDailyMaxWithdraw:
          lnbitsWalletLimitDailyMaxWithdraw ??
          this.lnbitsWalletLimitDailyMaxWithdraw,
      lnbitsWalletLimitSecsBetweenTrans:
          lnbitsWalletLimitSecsBetweenTrans ??
          this.lnbitsWalletLimitSecsBetweenTrans,
      lnbitsOnlyAllowIncomingPayments:
          lnbitsOnlyAllowIncomingPayments ??
          this.lnbitsOnlyAllowIncomingPayments,
      lnbitsWatchdogSwitchToVoidwallet:
          lnbitsWatchdogSwitchToVoidwallet ??
          this.lnbitsWatchdogSwitchToVoidwallet,
      lnbitsWatchdogIntervalMinutes:
          lnbitsWatchdogIntervalMinutes ?? this.lnbitsWatchdogIntervalMinutes,
      lnbitsWatchdogDelta: lnbitsWatchdogDelta ?? this.lnbitsWatchdogDelta,
      lnbitsMaxOutgoingPaymentAmountSats:
          lnbitsMaxOutgoingPaymentAmountSats ??
          this.lnbitsMaxOutgoingPaymentAmountSats,
      lnbitsMaxIncomingPaymentAmountSats:
          lnbitsMaxIncomingPaymentAmountSats ??
          this.lnbitsMaxIncomingPaymentAmountSats,
      lnbitsExchangeRateCacheSeconds:
          lnbitsExchangeRateCacheSeconds ?? this.lnbitsExchangeRateCacheSeconds,
      lnbitsExchangeHistorySize:
          lnbitsExchangeHistorySize ?? this.lnbitsExchangeHistorySize,
      lnbitsExchangeHistoryRefreshIntervalSeconds:
          lnbitsExchangeHistoryRefreshIntervalSeconds ??
          this.lnbitsExchangeHistoryRefreshIntervalSeconds,
      lnbitsExchangeRateProviders:
          lnbitsExchangeRateProviders ?? this.lnbitsExchangeRateProviders,
      lnbitsReserveFeeMin: lnbitsReserveFeeMin ?? this.lnbitsReserveFeeMin,
      lnbitsReserveFeePercent:
          lnbitsReserveFeePercent ?? this.lnbitsReserveFeePercent,
      lnbitsServiceFee: lnbitsServiceFee ?? this.lnbitsServiceFee,
      lnbitsServiceFeeIgnoreInternal:
          lnbitsServiceFeeIgnoreInternal ?? this.lnbitsServiceFeeIgnoreInternal,
      lnbitsServiceFeeMax: lnbitsServiceFeeMax ?? this.lnbitsServiceFeeMax,
      lnbitsServiceFeeWallet:
          lnbitsServiceFeeWallet ?? this.lnbitsServiceFeeWallet,
      lnbitsMaxAssetSizeMb: lnbitsMaxAssetSizeMb ?? this.lnbitsMaxAssetSizeMb,
      lnbitsAssetsAllowedMimeTypes:
          lnbitsAssetsAllowedMimeTypes ?? this.lnbitsAssetsAllowedMimeTypes,
      lnbitsAssetThumbnailWidth:
          lnbitsAssetThumbnailWidth ?? this.lnbitsAssetThumbnailWidth,
      lnbitsAssetThumbnailHeight:
          lnbitsAssetThumbnailHeight ?? this.lnbitsAssetThumbnailHeight,
      lnbitsAssetThumbnailFormat:
          lnbitsAssetThumbnailFormat ?? this.lnbitsAssetThumbnailFormat,
      lnbitsMaxAssetsPerUser:
          lnbitsMaxAssetsPerUser ?? this.lnbitsMaxAssetsPerUser,
      lnbitsAssetsNoLimitUsers:
          lnbitsAssetsNoLimitUsers ?? this.lnbitsAssetsNoLimitUsers,
      lnbitsBaseurl: lnbitsBaseurl ?? this.lnbitsBaseurl,
      lnbitsHideApi: lnbitsHideApi ?? this.lnbitsHideApi,
      lnbitsSiteTitle: lnbitsSiteTitle ?? this.lnbitsSiteTitle,
      lnbitsSiteTagline: lnbitsSiteTagline ?? this.lnbitsSiteTagline,
      lnbitsSiteDescription:
          lnbitsSiteDescription ?? this.lnbitsSiteDescription,
      lnbitsShowHomePageElements:
          lnbitsShowHomePageElements ?? this.lnbitsShowHomePageElements,
      lnbitsDefaultWalletName:
          lnbitsDefaultWalletName ?? this.lnbitsDefaultWalletName,
      lnbitsCustomBadge: lnbitsCustomBadge ?? this.lnbitsCustomBadge,
      lnbitsCustomBadgeColor:
          lnbitsCustomBadgeColor ?? this.lnbitsCustomBadgeColor,
      lnbitsThemeOptions: lnbitsThemeOptions ?? this.lnbitsThemeOptions,
      lnbitsCustomLogo: lnbitsCustomLogo ?? this.lnbitsCustomLogo,
      lnbitsCustomImage: lnbitsCustomImage ?? this.lnbitsCustomImage,
      lnbitsAdSpaceTitle: lnbitsAdSpaceTitle ?? this.lnbitsAdSpaceTitle,
      lnbitsAdSpace: lnbitsAdSpace ?? this.lnbitsAdSpace,
      lnbitsAdSpaceEnabled: lnbitsAdSpaceEnabled ?? this.lnbitsAdSpaceEnabled,
      lnbitsAllowedCurrencies:
          lnbitsAllowedCurrencies ?? this.lnbitsAllowedCurrencies,
      lnbitsDefaultAccountingCurrency:
          lnbitsDefaultAccountingCurrency ??
          this.lnbitsDefaultAccountingCurrency,
      lnbitsQrLogo: lnbitsQrLogo ?? this.lnbitsQrLogo,
      lnbitsAppleTouchIcon: lnbitsAppleTouchIcon ?? this.lnbitsAppleTouchIcon,
      lnbitsDefaultReaction:
          lnbitsDefaultReaction ?? this.lnbitsDefaultReaction,
      lnbitsDefaultTheme: lnbitsDefaultTheme ?? this.lnbitsDefaultTheme,
      lnbitsDefaultBorder: lnbitsDefaultBorder ?? this.lnbitsDefaultBorder,
      lnbitsDefaultGradient:
          lnbitsDefaultGradient ?? this.lnbitsDefaultGradient,
      lnbitsDefaultBgimage: lnbitsDefaultBgimage ?? this.lnbitsDefaultBgimage,
      lnbitsAdminExtensions:
          lnbitsAdminExtensions ?? this.lnbitsAdminExtensions,
      lnbitsUserDefaultExtensions:
          lnbitsUserDefaultExtensions ?? this.lnbitsUserDefaultExtensions,
      lnbitsExtensionsDeactivateAll:
          lnbitsExtensionsDeactivateAll ?? this.lnbitsExtensionsDeactivateAll,
      lnbitsExtensionsBuilderActivateNonAdmins:
          lnbitsExtensionsBuilderActivateNonAdmins ??
          this.lnbitsExtensionsBuilderActivateNonAdmins,
      lnbitsExtensionsReviewsUrl:
          lnbitsExtensionsReviewsUrl ?? this.lnbitsExtensionsReviewsUrl,
      lnbitsExtensionsManifests:
          lnbitsExtensionsManifests ?? this.lnbitsExtensionsManifests,
      lnbitsExtensionsBuilderManifestUrl:
          lnbitsExtensionsBuilderManifestUrl ??
          this.lnbitsExtensionsBuilderManifestUrl,
      lnbitsAdminUsers: lnbitsAdminUsers ?? this.lnbitsAdminUsers,
      lnbitsAllowedUsers: lnbitsAllowedUsers ?? this.lnbitsAllowedUsers,
      lnbitsAllowNewAccounts:
          lnbitsAllowNewAccounts ?? this.lnbitsAllowNewAccounts,
    );
  }

  UpdateSettings copyWithWrapped({
    Wrapped<String?>? keycloakDiscoveryUrl,
    Wrapped<String?>? keycloakClientId,
    Wrapped<String?>? keycloakClientSecret,
    Wrapped<String?>? keycloakClientCustomOrg,
    Wrapped<String?>? keycloakClientCustomIcon,
    Wrapped<String?>? githubClientId,
    Wrapped<String?>? githubClientSecret,
    Wrapped<String?>? googleClientId,
    Wrapped<String?>? googleClientSecret,
    Wrapped<List<String>?>? nostrAbsoluteRequestUrls,
    Wrapped<int?>? authTokenExpireMinutes,
    Wrapped<List<String>?>? authAllMethods,
    Wrapped<List<String>?>? authAllowedMethods,
    Wrapped<int?>? authCredetialsUpdateThreshold,
    Wrapped<int?>? authAuthenticationCacheMinutes,
    Wrapped<bool?>? lnbitsAuditEnabled,
    Wrapped<int?>? lnbitsAuditRetentionDays,
    Wrapped<bool?>? lnbitsAuditLogIpAddress,
    Wrapped<bool?>? lnbitsAuditLogPathParams,
    Wrapped<bool?>? lnbitsAuditLogQueryParams,
    Wrapped<bool?>? lnbitsAuditLogRequestBody,
    Wrapped<List<String>?>? lnbitsAuditIncludePaths,
    Wrapped<List<String>?>? lnbitsAuditExcludePaths,
    Wrapped<List<String>?>? lnbitsAuditHttpMethods,
    Wrapped<List<String>?>? lnbitsAuditHttpResponseCodes,
    Wrapped<bool?>? lnbitsNodeUi,
    Wrapped<bool?>? lnbitsPublicNodeUi,
    Wrapped<bool?>? lnbitsNodeUiTransactions,
    Wrapped<String?>? lnbitsWebpushPubkey,
    Wrapped<String?>? lnbitsWebpushPrivkey,
    Wrapped<int?>? lightningInvoiceExpiry,
    Wrapped<bool?>? paypalEnabled,
    Wrapped<String?>? paypalApiEndpoint,
    Wrapped<String?>? paypalClientId,
    Wrapped<String?>? paypalClientSecret,
    Wrapped<String?>? paypalPaymentSuccessUrl,
    Wrapped<String?>? paypalPaymentWebhookUrl,
    Wrapped<String?>? paypalWebhookId,
    Wrapped<FiatProviderLimits?>? paypalLimits,
    Wrapped<bool?>? stripeEnabled,
    Wrapped<String?>? stripeApiEndpoint,
    Wrapped<String?>? stripeApiSecretKey,
    Wrapped<String?>? stripePaymentSuccessUrl,
    Wrapped<String?>? stripePaymentWebhookUrl,
    Wrapped<String?>? stripeWebhookSigningSecret,
    Wrapped<FiatProviderLimits?>? stripeLimits,
    Wrapped<String?>? breezLiquidApiKey,
    Wrapped<String?>? breezLiquidSeed,
    Wrapped<int?>? breezLiquidFeeOffsetSat,
    Wrapped<String?>? strikeApiEndpoint,
    Wrapped<String?>? strikeApiKey,
    Wrapped<String?>? breezApiKey,
    Wrapped<String?>? breezGreenlightSeed,
    Wrapped<String?>? breezGreenlightInviteCode,
    Wrapped<String?>? breezGreenlightDeviceKey,
    Wrapped<String?>? breezGreenlightDeviceCert,
    Wrapped<bool?>? breezUseTrampoline,
    Wrapped<String?>? nwcPairingUrl,
    Wrapped<String?>? lntipsApiEndpoint,
    Wrapped<String?>? lntipsApiKey,
    Wrapped<String?>? lntipsAdminKey,
    Wrapped<String?>? lntipsInvoiceKey,
    Wrapped<String?>? sparkUrl,
    Wrapped<String?>? sparkToken,
    Wrapped<String?>? opennodeApiEndpoint,
    Wrapped<String?>? opennodeKey,
    Wrapped<String?>? opennodeAdminKey,
    Wrapped<String?>? opennodeInvoiceKey,
    Wrapped<String?>? phoenixdApiEndpoint,
    Wrapped<String?>? phoenixdApiPassword,
    Wrapped<String?>? zbdApiEndpoint,
    Wrapped<String?>? zbdApiKey,
    Wrapped<String?>? boltzClientEndpoint,
    Wrapped<String?>? boltzClientMacaroon,
    Wrapped<String?>? boltzClientPassword,
    Wrapped<String?>? boltzClientCert,
    Wrapped<String?>? boltzMnemonic,
    Wrapped<String?>? albyApiEndpoint,
    Wrapped<String?>? albyAccessToken,
    Wrapped<String?>? blinkApiEndpoint,
    Wrapped<String?>? blinkWsEndpoint,
    Wrapped<String?>? blinkToken,
    Wrapped<String?>? lnpayApiEndpoint,
    Wrapped<String?>? lnpayApiKey,
    Wrapped<String?>? lnpayWalletKey,
    Wrapped<String?>? lnpayAdminKey,
    Wrapped<String?>? lndGrpcEndpoint,
    Wrapped<String?>? lndGrpcCert,
    Wrapped<int?>? lndGrpcPort,
    Wrapped<String?>? lndGrpcAdminMacaroon,
    Wrapped<String?>? lndGrpcInvoiceMacaroon,
    Wrapped<String?>? lndGrpcMacaroon,
    Wrapped<String?>? lndGrpcMacaroonEncrypted,
    Wrapped<String?>? lndRestEndpoint,
    Wrapped<String?>? lndRestCert,
    Wrapped<String?>? lndRestMacaroon,
    Wrapped<String?>? lndRestMacaroonEncrypted,
    Wrapped<bool?>? lndRestRouteHints,
    Wrapped<bool?>? lndRestAllowSelfPayment,
    Wrapped<String?>? lndCert,
    Wrapped<String?>? lndAdminMacaroon,
    Wrapped<String?>? lndInvoiceMacaroon,
    Wrapped<String?>? lndRestAdminMacaroon,
    Wrapped<String?>? lndRestInvoiceMacaroon,
    Wrapped<String?>? eclairUrl,
    Wrapped<String?>? eclairPass,
    Wrapped<String?>? corelightningRestUrl,
    Wrapped<String?>? corelightningRestMacaroon,
    Wrapped<String?>? corelightningRestCert,
    Wrapped<String?>? corelightningRpc,
    Wrapped<String?>? corelightningPayCommand,
    Wrapped<String?>? clightningRpc,
    Wrapped<String?>? clnrestUrl,
    Wrapped<String?>? clnrestCa,
    Wrapped<String?>? clnrestCert,
    Wrapped<String?>? clnrestReadonlyRune,
    Wrapped<String?>? clnrestInvoiceRune,
    Wrapped<String?>? clnrestPayRune,
    Wrapped<String?>? clnrestRenepayRune,
    Wrapped<String?>? clnrestLastPayIndex,
    Wrapped<String?>? clnrestNodeid,
    Wrapped<String?>? clicheEndpoint,
    Wrapped<String?>? lnbitsEndpoint,
    Wrapped<String?>? lnbitsKey,
    Wrapped<String?>? lnbitsAdminKey,
    Wrapped<String?>? lnbitsInvoiceKey,
    Wrapped<String?>? fakeWalletSecret,
    Wrapped<String?>? lnbitsDenomination,
    Wrapped<String?>? lnbitsBackendWalletClass,
    Wrapped<int?>? lnbitsFundingSourcePayInvoiceWaitSeconds,
    Wrapped<int?>? fundingSourceMaxRetries,
    Wrapped<bool?>? lnbitsNostrNotificationsEnabled,
    Wrapped<String?>? lnbitsNostrNotificationsPrivateKey,
    Wrapped<List<String>?>? lnbitsNostrNotificationsIdentifiers,
    Wrapped<bool?>? lnbitsTelegramNotificationsEnabled,
    Wrapped<String?>? lnbitsTelegramNotificationsAccessToken,
    Wrapped<String?>? lnbitsTelegramNotificationsChatId,
    Wrapped<bool?>? lnbitsEmailNotificationsEnabled,
    Wrapped<String?>? lnbitsEmailNotificationsEmail,
    Wrapped<String?>? lnbitsEmailNotificationsUsername,
    Wrapped<String?>? lnbitsEmailNotificationsPassword,
    Wrapped<String?>? lnbitsEmailNotificationsServer,
    Wrapped<int?>? lnbitsEmailNotificationsPort,
    Wrapped<List<String>?>? lnbitsEmailNotificationsToEmails,
    Wrapped<bool?>? lnbitsNotificationSettingsUpdate,
    Wrapped<bool?>? lnbitsNotificationCreditDebit,
    Wrapped<int?>? notificationBalanceDeltaThresholdSats,
    Wrapped<bool?>? lnbitsNotificationServerStartStop,
    Wrapped<bool?>? lnbitsNotificationWatchdog,
    Wrapped<int?>? lnbitsNotificationServerStatusHours,
    Wrapped<int?>? lnbitsNotificationIncomingPaymentAmountSats,
    Wrapped<int?>? lnbitsNotificationOutgoingPaymentAmountSats,
    Wrapped<int?>? lnbitsRateLimitNo,
    Wrapped<String?>? lnbitsRateLimitUnit,
    Wrapped<List<String>?>? lnbitsAllowedIps,
    Wrapped<List<String>?>? lnbitsBlockedIps,
    Wrapped<List<String>?>? lnbitsCallbackUrlRules,
    Wrapped<int?>? lnbitsWalletLimitMaxBalance,
    Wrapped<int?>? lnbitsWalletLimitDailyMaxWithdraw,
    Wrapped<int?>? lnbitsWalletLimitSecsBetweenTrans,
    Wrapped<bool?>? lnbitsOnlyAllowIncomingPayments,
    Wrapped<bool?>? lnbitsWatchdogSwitchToVoidwallet,
    Wrapped<int?>? lnbitsWatchdogIntervalMinutes,
    Wrapped<int?>? lnbitsWatchdogDelta,
    Wrapped<int?>? lnbitsMaxOutgoingPaymentAmountSats,
    Wrapped<int?>? lnbitsMaxIncomingPaymentAmountSats,
    Wrapped<int?>? lnbitsExchangeRateCacheSeconds,
    Wrapped<int?>? lnbitsExchangeHistorySize,
    Wrapped<int?>? lnbitsExchangeHistoryRefreshIntervalSeconds,
    Wrapped<List<ExchangeRateProvider>?>? lnbitsExchangeRateProviders,
    Wrapped<int?>? lnbitsReserveFeeMin,
    Wrapped<double?>? lnbitsReserveFeePercent,
    Wrapped<double?>? lnbitsServiceFee,
    Wrapped<bool?>? lnbitsServiceFeeIgnoreInternal,
    Wrapped<int?>? lnbitsServiceFeeMax,
    Wrapped<String?>? lnbitsServiceFeeWallet,
    Wrapped<double?>? lnbitsMaxAssetSizeMb,
    Wrapped<List<String>?>? lnbitsAssetsAllowedMimeTypes,
    Wrapped<int?>? lnbitsAssetThumbnailWidth,
    Wrapped<int?>? lnbitsAssetThumbnailHeight,
    Wrapped<String?>? lnbitsAssetThumbnailFormat,
    Wrapped<int?>? lnbitsMaxAssetsPerUser,
    Wrapped<List<String>?>? lnbitsAssetsNoLimitUsers,
    Wrapped<String?>? lnbitsBaseurl,
    Wrapped<bool?>? lnbitsHideApi,
    Wrapped<String?>? lnbitsSiteTitle,
    Wrapped<String?>? lnbitsSiteTagline,
    Wrapped<String?>? lnbitsSiteDescription,
    Wrapped<bool?>? lnbitsShowHomePageElements,
    Wrapped<String?>? lnbitsDefaultWalletName,
    Wrapped<String?>? lnbitsCustomBadge,
    Wrapped<String?>? lnbitsCustomBadgeColor,
    Wrapped<List<String>?>? lnbitsThemeOptions,
    Wrapped<String?>? lnbitsCustomLogo,
    Wrapped<String?>? lnbitsCustomImage,
    Wrapped<String?>? lnbitsAdSpaceTitle,
    Wrapped<String?>? lnbitsAdSpace,
    Wrapped<bool?>? lnbitsAdSpaceEnabled,
    Wrapped<List<String>?>? lnbitsAllowedCurrencies,
    Wrapped<String?>? lnbitsDefaultAccountingCurrency,
    Wrapped<String?>? lnbitsQrLogo,
    Wrapped<String?>? lnbitsAppleTouchIcon,
    Wrapped<String?>? lnbitsDefaultReaction,
    Wrapped<String?>? lnbitsDefaultTheme,
    Wrapped<String?>? lnbitsDefaultBorder,
    Wrapped<bool?>? lnbitsDefaultGradient,
    Wrapped<String?>? lnbitsDefaultBgimage,
    Wrapped<List<String>?>? lnbitsAdminExtensions,
    Wrapped<List<String>?>? lnbitsUserDefaultExtensions,
    Wrapped<bool?>? lnbitsExtensionsDeactivateAll,
    Wrapped<bool?>? lnbitsExtensionsBuilderActivateNonAdmins,
    Wrapped<String?>? lnbitsExtensionsReviewsUrl,
    Wrapped<List<String>?>? lnbitsExtensionsManifests,
    Wrapped<String?>? lnbitsExtensionsBuilderManifestUrl,
    Wrapped<List<String>?>? lnbitsAdminUsers,
    Wrapped<List<String>?>? lnbitsAllowedUsers,
    Wrapped<bool?>? lnbitsAllowNewAccounts,
  }) {
    return UpdateSettings(
      keycloakDiscoveryUrl: (keycloakDiscoveryUrl != null
          ? keycloakDiscoveryUrl.value
          : this.keycloakDiscoveryUrl),
      keycloakClientId: (keycloakClientId != null
          ? keycloakClientId.value
          : this.keycloakClientId),
      keycloakClientSecret: (keycloakClientSecret != null
          ? keycloakClientSecret.value
          : this.keycloakClientSecret),
      keycloakClientCustomOrg: (keycloakClientCustomOrg != null
          ? keycloakClientCustomOrg.value
          : this.keycloakClientCustomOrg),
      keycloakClientCustomIcon: (keycloakClientCustomIcon != null
          ? keycloakClientCustomIcon.value
          : this.keycloakClientCustomIcon),
      githubClientId: (githubClientId != null
          ? githubClientId.value
          : this.githubClientId),
      githubClientSecret: (githubClientSecret != null
          ? githubClientSecret.value
          : this.githubClientSecret),
      googleClientId: (googleClientId != null
          ? googleClientId.value
          : this.googleClientId),
      googleClientSecret: (googleClientSecret != null
          ? googleClientSecret.value
          : this.googleClientSecret),
      nostrAbsoluteRequestUrls: (nostrAbsoluteRequestUrls != null
          ? nostrAbsoluteRequestUrls.value
          : this.nostrAbsoluteRequestUrls),
      authTokenExpireMinutes: (authTokenExpireMinutes != null
          ? authTokenExpireMinutes.value
          : this.authTokenExpireMinutes),
      authAllMethods: (authAllMethods != null
          ? authAllMethods.value
          : this.authAllMethods),
      authAllowedMethods: (authAllowedMethods != null
          ? authAllowedMethods.value
          : this.authAllowedMethods),
      authCredetialsUpdateThreshold: (authCredetialsUpdateThreshold != null
          ? authCredetialsUpdateThreshold.value
          : this.authCredetialsUpdateThreshold),
      authAuthenticationCacheMinutes: (authAuthenticationCacheMinutes != null
          ? authAuthenticationCacheMinutes.value
          : this.authAuthenticationCacheMinutes),
      lnbitsAuditEnabled: (lnbitsAuditEnabled != null
          ? lnbitsAuditEnabled.value
          : this.lnbitsAuditEnabled),
      lnbitsAuditRetentionDays: (lnbitsAuditRetentionDays != null
          ? lnbitsAuditRetentionDays.value
          : this.lnbitsAuditRetentionDays),
      lnbitsAuditLogIpAddress: (lnbitsAuditLogIpAddress != null
          ? lnbitsAuditLogIpAddress.value
          : this.lnbitsAuditLogIpAddress),
      lnbitsAuditLogPathParams: (lnbitsAuditLogPathParams != null
          ? lnbitsAuditLogPathParams.value
          : this.lnbitsAuditLogPathParams),
      lnbitsAuditLogQueryParams: (lnbitsAuditLogQueryParams != null
          ? lnbitsAuditLogQueryParams.value
          : this.lnbitsAuditLogQueryParams),
      lnbitsAuditLogRequestBody: (lnbitsAuditLogRequestBody != null
          ? lnbitsAuditLogRequestBody.value
          : this.lnbitsAuditLogRequestBody),
      lnbitsAuditIncludePaths: (lnbitsAuditIncludePaths != null
          ? lnbitsAuditIncludePaths.value
          : this.lnbitsAuditIncludePaths),
      lnbitsAuditExcludePaths: (lnbitsAuditExcludePaths != null
          ? lnbitsAuditExcludePaths.value
          : this.lnbitsAuditExcludePaths),
      lnbitsAuditHttpMethods: (lnbitsAuditHttpMethods != null
          ? lnbitsAuditHttpMethods.value
          : this.lnbitsAuditHttpMethods),
      lnbitsAuditHttpResponseCodes: (lnbitsAuditHttpResponseCodes != null
          ? lnbitsAuditHttpResponseCodes.value
          : this.lnbitsAuditHttpResponseCodes),
      lnbitsNodeUi: (lnbitsNodeUi != null
          ? lnbitsNodeUi.value
          : this.lnbitsNodeUi),
      lnbitsPublicNodeUi: (lnbitsPublicNodeUi != null
          ? lnbitsPublicNodeUi.value
          : this.lnbitsPublicNodeUi),
      lnbitsNodeUiTransactions: (lnbitsNodeUiTransactions != null
          ? lnbitsNodeUiTransactions.value
          : this.lnbitsNodeUiTransactions),
      lnbitsWebpushPubkey: (lnbitsWebpushPubkey != null
          ? lnbitsWebpushPubkey.value
          : this.lnbitsWebpushPubkey),
      lnbitsWebpushPrivkey: (lnbitsWebpushPrivkey != null
          ? lnbitsWebpushPrivkey.value
          : this.lnbitsWebpushPrivkey),
      lightningInvoiceExpiry: (lightningInvoiceExpiry != null
          ? lightningInvoiceExpiry.value
          : this.lightningInvoiceExpiry),
      paypalEnabled: (paypalEnabled != null
          ? paypalEnabled.value
          : this.paypalEnabled),
      paypalApiEndpoint: (paypalApiEndpoint != null
          ? paypalApiEndpoint.value
          : this.paypalApiEndpoint),
      paypalClientId: (paypalClientId != null
          ? paypalClientId.value
          : this.paypalClientId),
      paypalClientSecret: (paypalClientSecret != null
          ? paypalClientSecret.value
          : this.paypalClientSecret),
      paypalPaymentSuccessUrl: (paypalPaymentSuccessUrl != null
          ? paypalPaymentSuccessUrl.value
          : this.paypalPaymentSuccessUrl),
      paypalPaymentWebhookUrl: (paypalPaymentWebhookUrl != null
          ? paypalPaymentWebhookUrl.value
          : this.paypalPaymentWebhookUrl),
      paypalWebhookId: (paypalWebhookId != null
          ? paypalWebhookId.value
          : this.paypalWebhookId),
      paypalLimits: (paypalLimits != null
          ? paypalLimits.value
          : this.paypalLimits),
      stripeEnabled: (stripeEnabled != null
          ? stripeEnabled.value
          : this.stripeEnabled),
      stripeApiEndpoint: (stripeApiEndpoint != null
          ? stripeApiEndpoint.value
          : this.stripeApiEndpoint),
      stripeApiSecretKey: (stripeApiSecretKey != null
          ? stripeApiSecretKey.value
          : this.stripeApiSecretKey),
      stripePaymentSuccessUrl: (stripePaymentSuccessUrl != null
          ? stripePaymentSuccessUrl.value
          : this.stripePaymentSuccessUrl),
      stripePaymentWebhookUrl: (stripePaymentWebhookUrl != null
          ? stripePaymentWebhookUrl.value
          : this.stripePaymentWebhookUrl),
      stripeWebhookSigningSecret: (stripeWebhookSigningSecret != null
          ? stripeWebhookSigningSecret.value
          : this.stripeWebhookSigningSecret),
      stripeLimits: (stripeLimits != null
          ? stripeLimits.value
          : this.stripeLimits),
      breezLiquidApiKey: (breezLiquidApiKey != null
          ? breezLiquidApiKey.value
          : this.breezLiquidApiKey),
      breezLiquidSeed: (breezLiquidSeed != null
          ? breezLiquidSeed.value
          : this.breezLiquidSeed),
      breezLiquidFeeOffsetSat: (breezLiquidFeeOffsetSat != null
          ? breezLiquidFeeOffsetSat.value
          : this.breezLiquidFeeOffsetSat),
      strikeApiEndpoint: (strikeApiEndpoint != null
          ? strikeApiEndpoint.value
          : this.strikeApiEndpoint),
      strikeApiKey: (strikeApiKey != null
          ? strikeApiKey.value
          : this.strikeApiKey),
      breezApiKey: (breezApiKey != null ? breezApiKey.value : this.breezApiKey),
      breezGreenlightSeed: (breezGreenlightSeed != null
          ? breezGreenlightSeed.value
          : this.breezGreenlightSeed),
      breezGreenlightInviteCode: (breezGreenlightInviteCode != null
          ? breezGreenlightInviteCode.value
          : this.breezGreenlightInviteCode),
      breezGreenlightDeviceKey: (breezGreenlightDeviceKey != null
          ? breezGreenlightDeviceKey.value
          : this.breezGreenlightDeviceKey),
      breezGreenlightDeviceCert: (breezGreenlightDeviceCert != null
          ? breezGreenlightDeviceCert.value
          : this.breezGreenlightDeviceCert),
      breezUseTrampoline: (breezUseTrampoline != null
          ? breezUseTrampoline.value
          : this.breezUseTrampoline),
      nwcPairingUrl: (nwcPairingUrl != null
          ? nwcPairingUrl.value
          : this.nwcPairingUrl),
      lntipsApiEndpoint: (lntipsApiEndpoint != null
          ? lntipsApiEndpoint.value
          : this.lntipsApiEndpoint),
      lntipsApiKey: (lntipsApiKey != null
          ? lntipsApiKey.value
          : this.lntipsApiKey),
      lntipsAdminKey: (lntipsAdminKey != null
          ? lntipsAdminKey.value
          : this.lntipsAdminKey),
      lntipsInvoiceKey: (lntipsInvoiceKey != null
          ? lntipsInvoiceKey.value
          : this.lntipsInvoiceKey),
      sparkUrl: (sparkUrl != null ? sparkUrl.value : this.sparkUrl),
      sparkToken: (sparkToken != null ? sparkToken.value : this.sparkToken),
      opennodeApiEndpoint: (opennodeApiEndpoint != null
          ? opennodeApiEndpoint.value
          : this.opennodeApiEndpoint),
      opennodeKey: (opennodeKey != null ? opennodeKey.value : this.opennodeKey),
      opennodeAdminKey: (opennodeAdminKey != null
          ? opennodeAdminKey.value
          : this.opennodeAdminKey),
      opennodeInvoiceKey: (opennodeInvoiceKey != null
          ? opennodeInvoiceKey.value
          : this.opennodeInvoiceKey),
      phoenixdApiEndpoint: (phoenixdApiEndpoint != null
          ? phoenixdApiEndpoint.value
          : this.phoenixdApiEndpoint),
      phoenixdApiPassword: (phoenixdApiPassword != null
          ? phoenixdApiPassword.value
          : this.phoenixdApiPassword),
      zbdApiEndpoint: (zbdApiEndpoint != null
          ? zbdApiEndpoint.value
          : this.zbdApiEndpoint),
      zbdApiKey: (zbdApiKey != null ? zbdApiKey.value : this.zbdApiKey),
      boltzClientEndpoint: (boltzClientEndpoint != null
          ? boltzClientEndpoint.value
          : this.boltzClientEndpoint),
      boltzClientMacaroon: (boltzClientMacaroon != null
          ? boltzClientMacaroon.value
          : this.boltzClientMacaroon),
      boltzClientPassword: (boltzClientPassword != null
          ? boltzClientPassword.value
          : this.boltzClientPassword),
      boltzClientCert: (boltzClientCert != null
          ? boltzClientCert.value
          : this.boltzClientCert),
      boltzMnemonic: (boltzMnemonic != null
          ? boltzMnemonic.value
          : this.boltzMnemonic),
      albyApiEndpoint: (albyApiEndpoint != null
          ? albyApiEndpoint.value
          : this.albyApiEndpoint),
      albyAccessToken: (albyAccessToken != null
          ? albyAccessToken.value
          : this.albyAccessToken),
      blinkApiEndpoint: (blinkApiEndpoint != null
          ? blinkApiEndpoint.value
          : this.blinkApiEndpoint),
      blinkWsEndpoint: (blinkWsEndpoint != null
          ? blinkWsEndpoint.value
          : this.blinkWsEndpoint),
      blinkToken: (blinkToken != null ? blinkToken.value : this.blinkToken),
      lnpayApiEndpoint: (lnpayApiEndpoint != null
          ? lnpayApiEndpoint.value
          : this.lnpayApiEndpoint),
      lnpayApiKey: (lnpayApiKey != null ? lnpayApiKey.value : this.lnpayApiKey),
      lnpayWalletKey: (lnpayWalletKey != null
          ? lnpayWalletKey.value
          : this.lnpayWalletKey),
      lnpayAdminKey: (lnpayAdminKey != null
          ? lnpayAdminKey.value
          : this.lnpayAdminKey),
      lndGrpcEndpoint: (lndGrpcEndpoint != null
          ? lndGrpcEndpoint.value
          : this.lndGrpcEndpoint),
      lndGrpcCert: (lndGrpcCert != null ? lndGrpcCert.value : this.lndGrpcCert),
      lndGrpcPort: (lndGrpcPort != null ? lndGrpcPort.value : this.lndGrpcPort),
      lndGrpcAdminMacaroon: (lndGrpcAdminMacaroon != null
          ? lndGrpcAdminMacaroon.value
          : this.lndGrpcAdminMacaroon),
      lndGrpcInvoiceMacaroon: (lndGrpcInvoiceMacaroon != null
          ? lndGrpcInvoiceMacaroon.value
          : this.lndGrpcInvoiceMacaroon),
      lndGrpcMacaroon: (lndGrpcMacaroon != null
          ? lndGrpcMacaroon.value
          : this.lndGrpcMacaroon),
      lndGrpcMacaroonEncrypted: (lndGrpcMacaroonEncrypted != null
          ? lndGrpcMacaroonEncrypted.value
          : this.lndGrpcMacaroonEncrypted),
      lndRestEndpoint: (lndRestEndpoint != null
          ? lndRestEndpoint.value
          : this.lndRestEndpoint),
      lndRestCert: (lndRestCert != null ? lndRestCert.value : this.lndRestCert),
      lndRestMacaroon: (lndRestMacaroon != null
          ? lndRestMacaroon.value
          : this.lndRestMacaroon),
      lndRestMacaroonEncrypted: (lndRestMacaroonEncrypted != null
          ? lndRestMacaroonEncrypted.value
          : this.lndRestMacaroonEncrypted),
      lndRestRouteHints: (lndRestRouteHints != null
          ? lndRestRouteHints.value
          : this.lndRestRouteHints),
      lndRestAllowSelfPayment: (lndRestAllowSelfPayment != null
          ? lndRestAllowSelfPayment.value
          : this.lndRestAllowSelfPayment),
      lndCert: (lndCert != null ? lndCert.value : this.lndCert),
      lndAdminMacaroon: (lndAdminMacaroon != null
          ? lndAdminMacaroon.value
          : this.lndAdminMacaroon),
      lndInvoiceMacaroon: (lndInvoiceMacaroon != null
          ? lndInvoiceMacaroon.value
          : this.lndInvoiceMacaroon),
      lndRestAdminMacaroon: (lndRestAdminMacaroon != null
          ? lndRestAdminMacaroon.value
          : this.lndRestAdminMacaroon),
      lndRestInvoiceMacaroon: (lndRestInvoiceMacaroon != null
          ? lndRestInvoiceMacaroon.value
          : this.lndRestInvoiceMacaroon),
      eclairUrl: (eclairUrl != null ? eclairUrl.value : this.eclairUrl),
      eclairPass: (eclairPass != null ? eclairPass.value : this.eclairPass),
      corelightningRestUrl: (corelightningRestUrl != null
          ? corelightningRestUrl.value
          : this.corelightningRestUrl),
      corelightningRestMacaroon: (corelightningRestMacaroon != null
          ? corelightningRestMacaroon.value
          : this.corelightningRestMacaroon),
      corelightningRestCert: (corelightningRestCert != null
          ? corelightningRestCert.value
          : this.corelightningRestCert),
      corelightningRpc: (corelightningRpc != null
          ? corelightningRpc.value
          : this.corelightningRpc),
      corelightningPayCommand: (corelightningPayCommand != null
          ? corelightningPayCommand.value
          : this.corelightningPayCommand),
      clightningRpc: (clightningRpc != null
          ? clightningRpc.value
          : this.clightningRpc),
      clnrestUrl: (clnrestUrl != null ? clnrestUrl.value : this.clnrestUrl),
      clnrestCa: (clnrestCa != null ? clnrestCa.value : this.clnrestCa),
      clnrestCert: (clnrestCert != null ? clnrestCert.value : this.clnrestCert),
      clnrestReadonlyRune: (clnrestReadonlyRune != null
          ? clnrestReadonlyRune.value
          : this.clnrestReadonlyRune),
      clnrestInvoiceRune: (clnrestInvoiceRune != null
          ? clnrestInvoiceRune.value
          : this.clnrestInvoiceRune),
      clnrestPayRune: (clnrestPayRune != null
          ? clnrestPayRune.value
          : this.clnrestPayRune),
      clnrestRenepayRune: (clnrestRenepayRune != null
          ? clnrestRenepayRune.value
          : this.clnrestRenepayRune),
      clnrestLastPayIndex: (clnrestLastPayIndex != null
          ? clnrestLastPayIndex.value
          : this.clnrestLastPayIndex),
      clnrestNodeid: (clnrestNodeid != null
          ? clnrestNodeid.value
          : this.clnrestNodeid),
      clicheEndpoint: (clicheEndpoint != null
          ? clicheEndpoint.value
          : this.clicheEndpoint),
      lnbitsEndpoint: (lnbitsEndpoint != null
          ? lnbitsEndpoint.value
          : this.lnbitsEndpoint),
      lnbitsKey: (lnbitsKey != null ? lnbitsKey.value : this.lnbitsKey),
      lnbitsAdminKey: (lnbitsAdminKey != null
          ? lnbitsAdminKey.value
          : this.lnbitsAdminKey),
      lnbitsInvoiceKey: (lnbitsInvoiceKey != null
          ? lnbitsInvoiceKey.value
          : this.lnbitsInvoiceKey),
      fakeWalletSecret: (fakeWalletSecret != null
          ? fakeWalletSecret.value
          : this.fakeWalletSecret),
      lnbitsDenomination: (lnbitsDenomination != null
          ? lnbitsDenomination.value
          : this.lnbitsDenomination),
      lnbitsBackendWalletClass: (lnbitsBackendWalletClass != null
          ? lnbitsBackendWalletClass.value
          : this.lnbitsBackendWalletClass),
      lnbitsFundingSourcePayInvoiceWaitSeconds:
          (lnbitsFundingSourcePayInvoiceWaitSeconds != null
          ? lnbitsFundingSourcePayInvoiceWaitSeconds.value
          : this.lnbitsFundingSourcePayInvoiceWaitSeconds),
      fundingSourceMaxRetries: (fundingSourceMaxRetries != null
          ? fundingSourceMaxRetries.value
          : this.fundingSourceMaxRetries),
      lnbitsNostrNotificationsEnabled: (lnbitsNostrNotificationsEnabled != null
          ? lnbitsNostrNotificationsEnabled.value
          : this.lnbitsNostrNotificationsEnabled),
      lnbitsNostrNotificationsPrivateKey:
          (lnbitsNostrNotificationsPrivateKey != null
          ? lnbitsNostrNotificationsPrivateKey.value
          : this.lnbitsNostrNotificationsPrivateKey),
      lnbitsNostrNotificationsIdentifiers:
          (lnbitsNostrNotificationsIdentifiers != null
          ? lnbitsNostrNotificationsIdentifiers.value
          : this.lnbitsNostrNotificationsIdentifiers),
      lnbitsTelegramNotificationsEnabled:
          (lnbitsTelegramNotificationsEnabled != null
          ? lnbitsTelegramNotificationsEnabled.value
          : this.lnbitsTelegramNotificationsEnabled),
      lnbitsTelegramNotificationsAccessToken:
          (lnbitsTelegramNotificationsAccessToken != null
          ? lnbitsTelegramNotificationsAccessToken.value
          : this.lnbitsTelegramNotificationsAccessToken),
      lnbitsTelegramNotificationsChatId:
          (lnbitsTelegramNotificationsChatId != null
          ? lnbitsTelegramNotificationsChatId.value
          : this.lnbitsTelegramNotificationsChatId),
      lnbitsEmailNotificationsEnabled: (lnbitsEmailNotificationsEnabled != null
          ? lnbitsEmailNotificationsEnabled.value
          : this.lnbitsEmailNotificationsEnabled),
      lnbitsEmailNotificationsEmail: (lnbitsEmailNotificationsEmail != null
          ? lnbitsEmailNotificationsEmail.value
          : this.lnbitsEmailNotificationsEmail),
      lnbitsEmailNotificationsUsername:
          (lnbitsEmailNotificationsUsername != null
          ? lnbitsEmailNotificationsUsername.value
          : this.lnbitsEmailNotificationsUsername),
      lnbitsEmailNotificationsPassword:
          (lnbitsEmailNotificationsPassword != null
          ? lnbitsEmailNotificationsPassword.value
          : this.lnbitsEmailNotificationsPassword),
      lnbitsEmailNotificationsServer: (lnbitsEmailNotificationsServer != null
          ? lnbitsEmailNotificationsServer.value
          : this.lnbitsEmailNotificationsServer),
      lnbitsEmailNotificationsPort: (lnbitsEmailNotificationsPort != null
          ? lnbitsEmailNotificationsPort.value
          : this.lnbitsEmailNotificationsPort),
      lnbitsEmailNotificationsToEmails:
          (lnbitsEmailNotificationsToEmails != null
          ? lnbitsEmailNotificationsToEmails.value
          : this.lnbitsEmailNotificationsToEmails),
      lnbitsNotificationSettingsUpdate:
          (lnbitsNotificationSettingsUpdate != null
          ? lnbitsNotificationSettingsUpdate.value
          : this.lnbitsNotificationSettingsUpdate),
      lnbitsNotificationCreditDebit: (lnbitsNotificationCreditDebit != null
          ? lnbitsNotificationCreditDebit.value
          : this.lnbitsNotificationCreditDebit),
      notificationBalanceDeltaThresholdSats:
          (notificationBalanceDeltaThresholdSats != null
          ? notificationBalanceDeltaThresholdSats.value
          : this.notificationBalanceDeltaThresholdSats),
      lnbitsNotificationServerStartStop:
          (lnbitsNotificationServerStartStop != null
          ? lnbitsNotificationServerStartStop.value
          : this.lnbitsNotificationServerStartStop),
      lnbitsNotificationWatchdog: (lnbitsNotificationWatchdog != null
          ? lnbitsNotificationWatchdog.value
          : this.lnbitsNotificationWatchdog),
      lnbitsNotificationServerStatusHours:
          (lnbitsNotificationServerStatusHours != null
          ? lnbitsNotificationServerStatusHours.value
          : this.lnbitsNotificationServerStatusHours),
      lnbitsNotificationIncomingPaymentAmountSats:
          (lnbitsNotificationIncomingPaymentAmountSats != null
          ? lnbitsNotificationIncomingPaymentAmountSats.value
          : this.lnbitsNotificationIncomingPaymentAmountSats),
      lnbitsNotificationOutgoingPaymentAmountSats:
          (lnbitsNotificationOutgoingPaymentAmountSats != null
          ? lnbitsNotificationOutgoingPaymentAmountSats.value
          : this.lnbitsNotificationOutgoingPaymentAmountSats),
      lnbitsRateLimitNo: (lnbitsRateLimitNo != null
          ? lnbitsRateLimitNo.value
          : this.lnbitsRateLimitNo),
      lnbitsRateLimitUnit: (lnbitsRateLimitUnit != null
          ? lnbitsRateLimitUnit.value
          : this.lnbitsRateLimitUnit),
      lnbitsAllowedIps: (lnbitsAllowedIps != null
          ? lnbitsAllowedIps.value
          : this.lnbitsAllowedIps),
      lnbitsBlockedIps: (lnbitsBlockedIps != null
          ? lnbitsBlockedIps.value
          : this.lnbitsBlockedIps),
      lnbitsCallbackUrlRules: (lnbitsCallbackUrlRules != null
          ? lnbitsCallbackUrlRules.value
          : this.lnbitsCallbackUrlRules),
      lnbitsWalletLimitMaxBalance: (lnbitsWalletLimitMaxBalance != null
          ? lnbitsWalletLimitMaxBalance.value
          : this.lnbitsWalletLimitMaxBalance),
      lnbitsWalletLimitDailyMaxWithdraw:
          (lnbitsWalletLimitDailyMaxWithdraw != null
          ? lnbitsWalletLimitDailyMaxWithdraw.value
          : this.lnbitsWalletLimitDailyMaxWithdraw),
      lnbitsWalletLimitSecsBetweenTrans:
          (lnbitsWalletLimitSecsBetweenTrans != null
          ? lnbitsWalletLimitSecsBetweenTrans.value
          : this.lnbitsWalletLimitSecsBetweenTrans),
      lnbitsOnlyAllowIncomingPayments: (lnbitsOnlyAllowIncomingPayments != null
          ? lnbitsOnlyAllowIncomingPayments.value
          : this.lnbitsOnlyAllowIncomingPayments),
      lnbitsWatchdogSwitchToVoidwallet:
          (lnbitsWatchdogSwitchToVoidwallet != null
          ? lnbitsWatchdogSwitchToVoidwallet.value
          : this.lnbitsWatchdogSwitchToVoidwallet),
      lnbitsWatchdogIntervalMinutes: (lnbitsWatchdogIntervalMinutes != null
          ? lnbitsWatchdogIntervalMinutes.value
          : this.lnbitsWatchdogIntervalMinutes),
      lnbitsWatchdogDelta: (lnbitsWatchdogDelta != null
          ? lnbitsWatchdogDelta.value
          : this.lnbitsWatchdogDelta),
      lnbitsMaxOutgoingPaymentAmountSats:
          (lnbitsMaxOutgoingPaymentAmountSats != null
          ? lnbitsMaxOutgoingPaymentAmountSats.value
          : this.lnbitsMaxOutgoingPaymentAmountSats),
      lnbitsMaxIncomingPaymentAmountSats:
          (lnbitsMaxIncomingPaymentAmountSats != null
          ? lnbitsMaxIncomingPaymentAmountSats.value
          : this.lnbitsMaxIncomingPaymentAmountSats),
      lnbitsExchangeRateCacheSeconds: (lnbitsExchangeRateCacheSeconds != null
          ? lnbitsExchangeRateCacheSeconds.value
          : this.lnbitsExchangeRateCacheSeconds),
      lnbitsExchangeHistorySize: (lnbitsExchangeHistorySize != null
          ? lnbitsExchangeHistorySize.value
          : this.lnbitsExchangeHistorySize),
      lnbitsExchangeHistoryRefreshIntervalSeconds:
          (lnbitsExchangeHistoryRefreshIntervalSeconds != null
          ? lnbitsExchangeHistoryRefreshIntervalSeconds.value
          : this.lnbitsExchangeHistoryRefreshIntervalSeconds),
      lnbitsExchangeRateProviders: (lnbitsExchangeRateProviders != null
          ? lnbitsExchangeRateProviders.value
          : this.lnbitsExchangeRateProviders),
      lnbitsReserveFeeMin: (lnbitsReserveFeeMin != null
          ? lnbitsReserveFeeMin.value
          : this.lnbitsReserveFeeMin),
      lnbitsReserveFeePercent: (lnbitsReserveFeePercent != null
          ? lnbitsReserveFeePercent.value
          : this.lnbitsReserveFeePercent),
      lnbitsServiceFee: (lnbitsServiceFee != null
          ? lnbitsServiceFee.value
          : this.lnbitsServiceFee),
      lnbitsServiceFeeIgnoreInternal: (lnbitsServiceFeeIgnoreInternal != null
          ? lnbitsServiceFeeIgnoreInternal.value
          : this.lnbitsServiceFeeIgnoreInternal),
      lnbitsServiceFeeMax: (lnbitsServiceFeeMax != null
          ? lnbitsServiceFeeMax.value
          : this.lnbitsServiceFeeMax),
      lnbitsServiceFeeWallet: (lnbitsServiceFeeWallet != null
          ? lnbitsServiceFeeWallet.value
          : this.lnbitsServiceFeeWallet),
      lnbitsMaxAssetSizeMb: (lnbitsMaxAssetSizeMb != null
          ? lnbitsMaxAssetSizeMb.value
          : this.lnbitsMaxAssetSizeMb),
      lnbitsAssetsAllowedMimeTypes: (lnbitsAssetsAllowedMimeTypes != null
          ? lnbitsAssetsAllowedMimeTypes.value
          : this.lnbitsAssetsAllowedMimeTypes),
      lnbitsAssetThumbnailWidth: (lnbitsAssetThumbnailWidth != null
          ? lnbitsAssetThumbnailWidth.value
          : this.lnbitsAssetThumbnailWidth),
      lnbitsAssetThumbnailHeight: (lnbitsAssetThumbnailHeight != null
          ? lnbitsAssetThumbnailHeight.value
          : this.lnbitsAssetThumbnailHeight),
      lnbitsAssetThumbnailFormat: (lnbitsAssetThumbnailFormat != null
          ? lnbitsAssetThumbnailFormat.value
          : this.lnbitsAssetThumbnailFormat),
      lnbitsMaxAssetsPerUser: (lnbitsMaxAssetsPerUser != null
          ? lnbitsMaxAssetsPerUser.value
          : this.lnbitsMaxAssetsPerUser),
      lnbitsAssetsNoLimitUsers: (lnbitsAssetsNoLimitUsers != null
          ? lnbitsAssetsNoLimitUsers.value
          : this.lnbitsAssetsNoLimitUsers),
      lnbitsBaseurl: (lnbitsBaseurl != null
          ? lnbitsBaseurl.value
          : this.lnbitsBaseurl),
      lnbitsHideApi: (lnbitsHideApi != null
          ? lnbitsHideApi.value
          : this.lnbitsHideApi),
      lnbitsSiteTitle: (lnbitsSiteTitle != null
          ? lnbitsSiteTitle.value
          : this.lnbitsSiteTitle),
      lnbitsSiteTagline: (lnbitsSiteTagline != null
          ? lnbitsSiteTagline.value
          : this.lnbitsSiteTagline),
      lnbitsSiteDescription: (lnbitsSiteDescription != null
          ? lnbitsSiteDescription.value
          : this.lnbitsSiteDescription),
      lnbitsShowHomePageElements: (lnbitsShowHomePageElements != null
          ? lnbitsShowHomePageElements.value
          : this.lnbitsShowHomePageElements),
      lnbitsDefaultWalletName: (lnbitsDefaultWalletName != null
          ? lnbitsDefaultWalletName.value
          : this.lnbitsDefaultWalletName),
      lnbitsCustomBadge: (lnbitsCustomBadge != null
          ? lnbitsCustomBadge.value
          : this.lnbitsCustomBadge),
      lnbitsCustomBadgeColor: (lnbitsCustomBadgeColor != null
          ? lnbitsCustomBadgeColor.value
          : this.lnbitsCustomBadgeColor),
      lnbitsThemeOptions: (lnbitsThemeOptions != null
          ? lnbitsThemeOptions.value
          : this.lnbitsThemeOptions),
      lnbitsCustomLogo: (lnbitsCustomLogo != null
          ? lnbitsCustomLogo.value
          : this.lnbitsCustomLogo),
      lnbitsCustomImage: (lnbitsCustomImage != null
          ? lnbitsCustomImage.value
          : this.lnbitsCustomImage),
      lnbitsAdSpaceTitle: (lnbitsAdSpaceTitle != null
          ? lnbitsAdSpaceTitle.value
          : this.lnbitsAdSpaceTitle),
      lnbitsAdSpace: (lnbitsAdSpace != null
          ? lnbitsAdSpace.value
          : this.lnbitsAdSpace),
      lnbitsAdSpaceEnabled: (lnbitsAdSpaceEnabled != null
          ? lnbitsAdSpaceEnabled.value
          : this.lnbitsAdSpaceEnabled),
      lnbitsAllowedCurrencies: (lnbitsAllowedCurrencies != null
          ? lnbitsAllowedCurrencies.value
          : this.lnbitsAllowedCurrencies),
      lnbitsDefaultAccountingCurrency: (lnbitsDefaultAccountingCurrency != null
          ? lnbitsDefaultAccountingCurrency.value
          : this.lnbitsDefaultAccountingCurrency),
      lnbitsQrLogo: (lnbitsQrLogo != null
          ? lnbitsQrLogo.value
          : this.lnbitsQrLogo),
      lnbitsAppleTouchIcon: (lnbitsAppleTouchIcon != null
          ? lnbitsAppleTouchIcon.value
          : this.lnbitsAppleTouchIcon),
      lnbitsDefaultReaction: (lnbitsDefaultReaction != null
          ? lnbitsDefaultReaction.value
          : this.lnbitsDefaultReaction),
      lnbitsDefaultTheme: (lnbitsDefaultTheme != null
          ? lnbitsDefaultTheme.value
          : this.lnbitsDefaultTheme),
      lnbitsDefaultBorder: (lnbitsDefaultBorder != null
          ? lnbitsDefaultBorder.value
          : this.lnbitsDefaultBorder),
      lnbitsDefaultGradient: (lnbitsDefaultGradient != null
          ? lnbitsDefaultGradient.value
          : this.lnbitsDefaultGradient),
      lnbitsDefaultBgimage: (lnbitsDefaultBgimage != null
          ? lnbitsDefaultBgimage.value
          : this.lnbitsDefaultBgimage),
      lnbitsAdminExtensions: (lnbitsAdminExtensions != null
          ? lnbitsAdminExtensions.value
          : this.lnbitsAdminExtensions),
      lnbitsUserDefaultExtensions: (lnbitsUserDefaultExtensions != null
          ? lnbitsUserDefaultExtensions.value
          : this.lnbitsUserDefaultExtensions),
      lnbitsExtensionsDeactivateAll: (lnbitsExtensionsDeactivateAll != null
          ? lnbitsExtensionsDeactivateAll.value
          : this.lnbitsExtensionsDeactivateAll),
      lnbitsExtensionsBuilderActivateNonAdmins:
          (lnbitsExtensionsBuilderActivateNonAdmins != null
          ? lnbitsExtensionsBuilderActivateNonAdmins.value
          : this.lnbitsExtensionsBuilderActivateNonAdmins),
      lnbitsExtensionsReviewsUrl: (lnbitsExtensionsReviewsUrl != null
          ? lnbitsExtensionsReviewsUrl.value
          : this.lnbitsExtensionsReviewsUrl),
      lnbitsExtensionsManifests: (lnbitsExtensionsManifests != null
          ? lnbitsExtensionsManifests.value
          : this.lnbitsExtensionsManifests),
      lnbitsExtensionsBuilderManifestUrl:
          (lnbitsExtensionsBuilderManifestUrl != null
          ? lnbitsExtensionsBuilderManifestUrl.value
          : this.lnbitsExtensionsBuilderManifestUrl),
      lnbitsAdminUsers: (lnbitsAdminUsers != null
          ? lnbitsAdminUsers.value
          : this.lnbitsAdminUsers),
      lnbitsAllowedUsers: (lnbitsAllowedUsers != null
          ? lnbitsAllowedUsers.value
          : this.lnbitsAllowedUsers),
      lnbitsAllowNewAccounts: (lnbitsAllowNewAccounts != null
          ? lnbitsAllowNewAccounts.value
          : this.lnbitsAllowNewAccounts),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class UpdateSuperuserPassword {
  const UpdateSuperuserPassword({
    required this.username,
    required this.password,
    required this.passwordRepeat,
  });

  factory UpdateSuperuserPassword.fromJson(Map<String, dynamic> json) =>
      _$UpdateSuperuserPasswordFromJson(json);

  static const toJsonFactory = _$UpdateSuperuserPasswordToJson;
  Map<String, dynamic> toJson() => _$UpdateSuperuserPasswordToJson(this);

  @JsonKey(name: 'username', includeIfNull: false)
  final String username;
  @JsonKey(name: 'password', includeIfNull: false)
  final String password;
  @JsonKey(name: 'password_repeat', includeIfNull: false)
  final String passwordRepeat;
  static const fromJsonFactory = _$UpdateSuperuserPasswordFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UpdateSuperuserPassword &&
            (identical(other.username, username) ||
                const DeepCollectionEquality().equals(
                  other.username,
                  username,
                )) &&
            (identical(other.password, password) ||
                const DeepCollectionEquality().equals(
                  other.password,
                  password,
                )) &&
            (identical(other.passwordRepeat, passwordRepeat) ||
                const DeepCollectionEquality().equals(
                  other.passwordRepeat,
                  passwordRepeat,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(username) ^
      const DeepCollectionEquality().hash(password) ^
      const DeepCollectionEquality().hash(passwordRepeat) ^
      runtimeType.hashCode;
}

extension $UpdateSuperuserPasswordExtension on UpdateSuperuserPassword {
  UpdateSuperuserPassword copyWith({
    String? username,
    String? password,
    String? passwordRepeat,
  }) {
    return UpdateSuperuserPassword(
      username: username ?? this.username,
      password: password ?? this.password,
      passwordRepeat: passwordRepeat ?? this.passwordRepeat,
    );
  }

  UpdateSuperuserPassword copyWithWrapped({
    Wrapped<String>? username,
    Wrapped<String>? password,
    Wrapped<String>? passwordRepeat,
  }) {
    return UpdateSuperuserPassword(
      username: (username != null ? username.value : this.username),
      password: (password != null ? password.value : this.password),
      passwordRepeat: (passwordRepeat != null
          ? passwordRepeat.value
          : this.passwordRepeat),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class UpdateUser {
  const UpdateUser({required this.userId, required this.username, this.extra});

  factory UpdateUser.fromJson(Map<String, dynamic> json) =>
      _$UpdateUserFromJson(json);

  static const toJsonFactory = _$UpdateUserToJson;
  Map<String, dynamic> toJson() => _$UpdateUserToJson(this);

  @JsonKey(name: 'user_id', includeIfNull: false)
  final String userId;
  @JsonKey(name: 'username', includeIfNull: false)
  final String username;
  @JsonKey(name: 'extra', includeIfNull: false)
  final UserExtra? extra;
  static const fromJsonFactory = _$UpdateUserFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UpdateUser &&
            (identical(other.userId, userId) ||
                const DeepCollectionEquality().equals(other.userId, userId)) &&
            (identical(other.username, username) ||
                const DeepCollectionEquality().equals(
                  other.username,
                  username,
                )) &&
            (identical(other.extra, extra) ||
                const DeepCollectionEquality().equals(other.extra, extra)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(userId) ^
      const DeepCollectionEquality().hash(username) ^
      const DeepCollectionEquality().hash(extra) ^
      runtimeType.hashCode;
}

extension $UpdateUserExtension on UpdateUser {
  UpdateUser copyWith({String? userId, String? username, UserExtra? extra}) {
    return UpdateUser(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      extra: extra ?? this.extra,
    );
  }

  UpdateUser copyWithWrapped({
    Wrapped<String>? userId,
    Wrapped<String>? username,
    Wrapped<UserExtra?>? extra,
  }) {
    return UpdateUser(
      userId: (userId != null ? userId.value : this.userId),
      username: (username != null ? username.value : this.username),
      extra: (extra != null ? extra.value : this.extra),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class UpdateUserPassword {
  const UpdateUserPassword({
    required this.userId,
    this.passwordOld,
    required this.password,
    required this.passwordRepeat,
    required this.username,
  });

  factory UpdateUserPassword.fromJson(Map<String, dynamic> json) =>
      _$UpdateUserPasswordFromJson(json);

  static const toJsonFactory = _$UpdateUserPasswordToJson;
  Map<String, dynamic> toJson() => _$UpdateUserPasswordToJson(this);

  @JsonKey(name: 'user_id', includeIfNull: false)
  final String userId;
  @JsonKey(name: 'password_old', includeIfNull: false)
  final String? passwordOld;
  @JsonKey(name: 'password', includeIfNull: false)
  final String password;
  @JsonKey(name: 'password_repeat', includeIfNull: false)
  final String passwordRepeat;
  @JsonKey(name: 'username', includeIfNull: false)
  final String username;
  static const fromJsonFactory = _$UpdateUserPasswordFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UpdateUserPassword &&
            (identical(other.userId, userId) ||
                const DeepCollectionEquality().equals(other.userId, userId)) &&
            (identical(other.passwordOld, passwordOld) ||
                const DeepCollectionEquality().equals(
                  other.passwordOld,
                  passwordOld,
                )) &&
            (identical(other.password, password) ||
                const DeepCollectionEquality().equals(
                  other.password,
                  password,
                )) &&
            (identical(other.passwordRepeat, passwordRepeat) ||
                const DeepCollectionEquality().equals(
                  other.passwordRepeat,
                  passwordRepeat,
                )) &&
            (identical(other.username, username) ||
                const DeepCollectionEquality().equals(
                  other.username,
                  username,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(userId) ^
      const DeepCollectionEquality().hash(passwordOld) ^
      const DeepCollectionEquality().hash(password) ^
      const DeepCollectionEquality().hash(passwordRepeat) ^
      const DeepCollectionEquality().hash(username) ^
      runtimeType.hashCode;
}

extension $UpdateUserPasswordExtension on UpdateUserPassword {
  UpdateUserPassword copyWith({
    String? userId,
    String? passwordOld,
    String? password,
    String? passwordRepeat,
    String? username,
  }) {
    return UpdateUserPassword(
      userId: userId ?? this.userId,
      passwordOld: passwordOld ?? this.passwordOld,
      password: password ?? this.password,
      passwordRepeat: passwordRepeat ?? this.passwordRepeat,
      username: username ?? this.username,
    );
  }

  UpdateUserPassword copyWithWrapped({
    Wrapped<String>? userId,
    Wrapped<String?>? passwordOld,
    Wrapped<String>? password,
    Wrapped<String>? passwordRepeat,
    Wrapped<String>? username,
  }) {
    return UpdateUserPassword(
      userId: (userId != null ? userId.value : this.userId),
      passwordOld: (passwordOld != null ? passwordOld.value : this.passwordOld),
      password: (password != null ? password.value : this.password),
      passwordRepeat: (passwordRepeat != null
          ? passwordRepeat.value
          : this.passwordRepeat),
      username: (username != null ? username.value : this.username),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class UpdateUserPubkey {
  const UpdateUserPubkey({required this.userId, required this.pubkey});

  factory UpdateUserPubkey.fromJson(Map<String, dynamic> json) =>
      _$UpdateUserPubkeyFromJson(json);

  static const toJsonFactory = _$UpdateUserPubkeyToJson;
  Map<String, dynamic> toJson() => _$UpdateUserPubkeyToJson(this);

  @JsonKey(name: 'user_id', includeIfNull: false)
  final String userId;
  @JsonKey(name: 'pubkey', includeIfNull: false)
  final String pubkey;
  static const fromJsonFactory = _$UpdateUserPubkeyFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UpdateUserPubkey &&
            (identical(other.userId, userId) ||
                const DeepCollectionEquality().equals(other.userId, userId)) &&
            (identical(other.pubkey, pubkey) ||
                const DeepCollectionEquality().equals(other.pubkey, pubkey)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(userId) ^
      const DeepCollectionEquality().hash(pubkey) ^
      runtimeType.hashCode;
}

extension $UpdateUserPubkeyExtension on UpdateUserPubkey {
  UpdateUserPubkey copyWith({String? userId, String? pubkey}) {
    return UpdateUserPubkey(
      userId: userId ?? this.userId,
      pubkey: pubkey ?? this.pubkey,
    );
  }

  UpdateUserPubkey copyWithWrapped({
    Wrapped<String>? userId,
    Wrapped<String>? pubkey,
  }) {
    return UpdateUserPubkey(
      userId: (userId != null ? userId.value : this.userId),
      pubkey: (pubkey != null ? pubkey.value : this.pubkey),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class User {
  const User({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.email,
    this.username,
    this.pubkey,
    this.externalId,
    this.extensions,
    this.wallets,
    this.admin,
    this.superUser,
    this.fiatProviders,
    this.hasPassword,
    this.extra,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  static const toJsonFactory = _$UserToJson;
  Map<String, dynamic> toJson() => _$UserToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'created_at', includeIfNull: false)
  final DateTime createdAt;
  @JsonKey(name: 'updated_at', includeIfNull: false)
  final DateTime updatedAt;
  @JsonKey(name: 'email', includeIfNull: false)
  final String? email;
  @JsonKey(name: 'username', includeIfNull: false)
  final String? username;
  @JsonKey(name: 'pubkey', includeIfNull: false)
  final String? pubkey;
  @JsonKey(name: 'external_id', includeIfNull: false)
  final String? externalId;
  @JsonKey(name: 'extensions', includeIfNull: false, defaultValue: <String>[])
  final List<String>? extensions;
  @JsonKey(name: 'wallets', includeIfNull: false, defaultValue: <Wallet>[])
  final List<Wallet>? wallets;
  @JsonKey(name: 'admin', includeIfNull: false, defaultValue: false)
  final bool? admin;
  @JsonKey(name: 'super_user', includeIfNull: false, defaultValue: false)
  final bool? superUser;
  @JsonKey(
    name: 'fiat_providers',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? fiatProviders;
  @JsonKey(name: 'has_password', includeIfNull: false, defaultValue: false)
  final bool? hasPassword;
  @JsonKey(name: 'extra', includeIfNull: false)
  final UserExtra? extra;
  static const fromJsonFactory = _$UserFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is User &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.createdAt, createdAt) ||
                const DeepCollectionEquality().equals(
                  other.createdAt,
                  createdAt,
                )) &&
            (identical(other.updatedAt, updatedAt) ||
                const DeepCollectionEquality().equals(
                  other.updatedAt,
                  updatedAt,
                )) &&
            (identical(other.email, email) ||
                const DeepCollectionEquality().equals(other.email, email)) &&
            (identical(other.username, username) ||
                const DeepCollectionEquality().equals(
                  other.username,
                  username,
                )) &&
            (identical(other.pubkey, pubkey) ||
                const DeepCollectionEquality().equals(other.pubkey, pubkey)) &&
            (identical(other.externalId, externalId) ||
                const DeepCollectionEquality().equals(
                  other.externalId,
                  externalId,
                )) &&
            (identical(other.extensions, extensions) ||
                const DeepCollectionEquality().equals(
                  other.extensions,
                  extensions,
                )) &&
            (identical(other.wallets, wallets) ||
                const DeepCollectionEquality().equals(
                  other.wallets,
                  wallets,
                )) &&
            (identical(other.admin, admin) ||
                const DeepCollectionEquality().equals(other.admin, admin)) &&
            (identical(other.superUser, superUser) ||
                const DeepCollectionEquality().equals(
                  other.superUser,
                  superUser,
                )) &&
            (identical(other.fiatProviders, fiatProviders) ||
                const DeepCollectionEquality().equals(
                  other.fiatProviders,
                  fiatProviders,
                )) &&
            (identical(other.hasPassword, hasPassword) ||
                const DeepCollectionEquality().equals(
                  other.hasPassword,
                  hasPassword,
                )) &&
            (identical(other.extra, extra) ||
                const DeepCollectionEquality().equals(other.extra, extra)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(createdAt) ^
      const DeepCollectionEquality().hash(updatedAt) ^
      const DeepCollectionEquality().hash(email) ^
      const DeepCollectionEquality().hash(username) ^
      const DeepCollectionEquality().hash(pubkey) ^
      const DeepCollectionEquality().hash(externalId) ^
      const DeepCollectionEquality().hash(extensions) ^
      const DeepCollectionEquality().hash(wallets) ^
      const DeepCollectionEquality().hash(admin) ^
      const DeepCollectionEquality().hash(superUser) ^
      const DeepCollectionEquality().hash(fiatProviders) ^
      const DeepCollectionEquality().hash(hasPassword) ^
      const DeepCollectionEquality().hash(extra) ^
      runtimeType.hashCode;
}

extension $UserExtension on User {
  User copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? email,
    String? username,
    String? pubkey,
    String? externalId,
    List<String>? extensions,
    List<Wallet>? wallets,
    bool? admin,
    bool? superUser,
    List<String>? fiatProviders,
    bool? hasPassword,
    UserExtra? extra,
  }) {
    return User(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      email: email ?? this.email,
      username: username ?? this.username,
      pubkey: pubkey ?? this.pubkey,
      externalId: externalId ?? this.externalId,
      extensions: extensions ?? this.extensions,
      wallets: wallets ?? this.wallets,
      admin: admin ?? this.admin,
      superUser: superUser ?? this.superUser,
      fiatProviders: fiatProviders ?? this.fiatProviders,
      hasPassword: hasPassword ?? this.hasPassword,
      extra: extra ?? this.extra,
    );
  }

  User copyWithWrapped({
    Wrapped<String>? id,
    Wrapped<DateTime>? createdAt,
    Wrapped<DateTime>? updatedAt,
    Wrapped<String?>? email,
    Wrapped<String?>? username,
    Wrapped<String?>? pubkey,
    Wrapped<String?>? externalId,
    Wrapped<List<String>?>? extensions,
    Wrapped<List<Wallet>?>? wallets,
    Wrapped<bool?>? admin,
    Wrapped<bool?>? superUser,
    Wrapped<List<String>?>? fiatProviders,
    Wrapped<bool?>? hasPassword,
    Wrapped<UserExtra?>? extra,
  }) {
    return User(
      id: (id != null ? id.value : this.id),
      createdAt: (createdAt != null ? createdAt.value : this.createdAt),
      updatedAt: (updatedAt != null ? updatedAt.value : this.updatedAt),
      email: (email != null ? email.value : this.email),
      username: (username != null ? username.value : this.username),
      pubkey: (pubkey != null ? pubkey.value : this.pubkey),
      externalId: (externalId != null ? externalId.value : this.externalId),
      extensions: (extensions != null ? extensions.value : this.extensions),
      wallets: (wallets != null ? wallets.value : this.wallets),
      admin: (admin != null ? admin.value : this.admin),
      superUser: (superUser != null ? superUser.value : this.superUser),
      fiatProviders: (fiatProviders != null
          ? fiatProviders.value
          : this.fiatProviders),
      hasPassword: (hasPassword != null ? hasPassword.value : this.hasPassword),
      extra: (extra != null ? extra.value : this.extra),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class UserAcls {
  const UserAcls({required this.id, this.accessControlList, this.updatedAt});

  factory UserAcls.fromJson(Map<String, dynamic> json) =>
      _$UserAclsFromJson(json);

  static const toJsonFactory = _$UserAclsToJson;
  Map<String, dynamic> toJson() => _$UserAclsToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(
    name: 'access_control_list',
    includeIfNull: false,
    defaultValue: <AccessControlList>[],
  )
  final List<AccessControlList>? accessControlList;
  @JsonKey(name: 'updated_at', includeIfNull: false)
  final DateTime? updatedAt;
  static const fromJsonFactory = _$UserAclsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserAcls &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.accessControlList, accessControlList) ||
                const DeepCollectionEquality().equals(
                  other.accessControlList,
                  accessControlList,
                )) &&
            (identical(other.updatedAt, updatedAt) ||
                const DeepCollectionEquality().equals(
                  other.updatedAt,
                  updatedAt,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(accessControlList) ^
      const DeepCollectionEquality().hash(updatedAt) ^
      runtimeType.hashCode;
}

extension $UserAclsExtension on UserAcls {
  UserAcls copyWith({
    String? id,
    List<AccessControlList>? accessControlList,
    DateTime? updatedAt,
  }) {
    return UserAcls(
      id: id ?? this.id,
      accessControlList: accessControlList ?? this.accessControlList,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  UserAcls copyWithWrapped({
    Wrapped<String>? id,
    Wrapped<List<AccessControlList>?>? accessControlList,
    Wrapped<DateTime?>? updatedAt,
  }) {
    return UserAcls(
      id: (id != null ? id.value : this.id),
      accessControlList: (accessControlList != null
          ? accessControlList.value
          : this.accessControlList),
      updatedAt: (updatedAt != null ? updatedAt.value : this.updatedAt),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class UserExtra {
  const UserExtra({
    this.emailVerified,
    this.firstName,
    this.lastName,
    this.displayName,
    this.picture,
    this.provider,
    this.visibleWalletCount,
    this.notifications,
    this.walletInviteRequests,
    this.labels,
  });

  factory UserExtra.fromJson(Map<String, dynamic> json) =>
      _$UserExtraFromJson(json);

  static const toJsonFactory = _$UserExtraToJson;
  Map<String, dynamic> toJson() => _$UserExtraToJson(this);

  @JsonKey(name: 'email_verified', includeIfNull: false, defaultValue: false)
  final bool? emailVerified;
  @JsonKey(name: 'first_name', includeIfNull: false)
  final String? firstName;
  @JsonKey(name: 'last_name', includeIfNull: false)
  final String? lastName;
  @JsonKey(name: 'display_name', includeIfNull: false)
  final String? displayName;
  @JsonKey(name: 'picture', includeIfNull: false)
  final String? picture;
  @JsonKey(name: 'provider', includeIfNull: false)
  final String? provider;
  @JsonKey(name: 'visible_wallet_count', includeIfNull: false)
  final int? visibleWalletCount;
  @JsonKey(name: 'notifications', includeIfNull: false)
  final UserNotifications? notifications;
  @JsonKey(
    name: 'wallet_invite_requests',
    includeIfNull: false,
    defaultValue: <WalletInviteRequest>[],
  )
  final List<WalletInviteRequest>? walletInviteRequests;
  @JsonKey(name: 'labels', includeIfNull: false, defaultValue: <UserLabel>[])
  final List<UserLabel>? labels;
  static const fromJsonFactory = _$UserExtraFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserExtra &&
            (identical(other.emailVerified, emailVerified) ||
                const DeepCollectionEquality().equals(
                  other.emailVerified,
                  emailVerified,
                )) &&
            (identical(other.firstName, firstName) ||
                const DeepCollectionEquality().equals(
                  other.firstName,
                  firstName,
                )) &&
            (identical(other.lastName, lastName) ||
                const DeepCollectionEquality().equals(
                  other.lastName,
                  lastName,
                )) &&
            (identical(other.displayName, displayName) ||
                const DeepCollectionEquality().equals(
                  other.displayName,
                  displayName,
                )) &&
            (identical(other.picture, picture) ||
                const DeepCollectionEquality().equals(
                  other.picture,
                  picture,
                )) &&
            (identical(other.provider, provider) ||
                const DeepCollectionEquality().equals(
                  other.provider,
                  provider,
                )) &&
            (identical(other.visibleWalletCount, visibleWalletCount) ||
                const DeepCollectionEquality().equals(
                  other.visibleWalletCount,
                  visibleWalletCount,
                )) &&
            (identical(other.notifications, notifications) ||
                const DeepCollectionEquality().equals(
                  other.notifications,
                  notifications,
                )) &&
            (identical(other.walletInviteRequests, walletInviteRequests) ||
                const DeepCollectionEquality().equals(
                  other.walletInviteRequests,
                  walletInviteRequests,
                )) &&
            (identical(other.labels, labels) ||
                const DeepCollectionEquality().equals(other.labels, labels)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(emailVerified) ^
      const DeepCollectionEquality().hash(firstName) ^
      const DeepCollectionEquality().hash(lastName) ^
      const DeepCollectionEquality().hash(displayName) ^
      const DeepCollectionEquality().hash(picture) ^
      const DeepCollectionEquality().hash(provider) ^
      const DeepCollectionEquality().hash(visibleWalletCount) ^
      const DeepCollectionEquality().hash(notifications) ^
      const DeepCollectionEquality().hash(walletInviteRequests) ^
      const DeepCollectionEquality().hash(labels) ^
      runtimeType.hashCode;
}

extension $UserExtraExtension on UserExtra {
  UserExtra copyWith({
    bool? emailVerified,
    String? firstName,
    String? lastName,
    String? displayName,
    String? picture,
    String? provider,
    int? visibleWalletCount,
    UserNotifications? notifications,
    List<WalletInviteRequest>? walletInviteRequests,
    List<UserLabel>? labels,
  }) {
    return UserExtra(
      emailVerified: emailVerified ?? this.emailVerified,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      displayName: displayName ?? this.displayName,
      picture: picture ?? this.picture,
      provider: provider ?? this.provider,
      visibleWalletCount: visibleWalletCount ?? this.visibleWalletCount,
      notifications: notifications ?? this.notifications,
      walletInviteRequests: walletInviteRequests ?? this.walletInviteRequests,
      labels: labels ?? this.labels,
    );
  }

  UserExtra copyWithWrapped({
    Wrapped<bool?>? emailVerified,
    Wrapped<String?>? firstName,
    Wrapped<String?>? lastName,
    Wrapped<String?>? displayName,
    Wrapped<String?>? picture,
    Wrapped<String?>? provider,
    Wrapped<int?>? visibleWalletCount,
    Wrapped<UserNotifications?>? notifications,
    Wrapped<List<WalletInviteRequest>?>? walletInviteRequests,
    Wrapped<List<UserLabel>?>? labels,
  }) {
    return UserExtra(
      emailVerified: (emailVerified != null
          ? emailVerified.value
          : this.emailVerified),
      firstName: (firstName != null ? firstName.value : this.firstName),
      lastName: (lastName != null ? lastName.value : this.lastName),
      displayName: (displayName != null ? displayName.value : this.displayName),
      picture: (picture != null ? picture.value : this.picture),
      provider: (provider != null ? provider.value : this.provider),
      visibleWalletCount: (visibleWalletCount != null
          ? visibleWalletCount.value
          : this.visibleWalletCount),
      notifications: (notifications != null
          ? notifications.value
          : this.notifications),
      walletInviteRequests: (walletInviteRequests != null
          ? walletInviteRequests.value
          : this.walletInviteRequests),
      labels: (labels != null ? labels.value : this.labels),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class UserLabel {
  const UserLabel({required this.name, this.description, this.color});

  factory UserLabel.fromJson(Map<String, dynamic> json) =>
      _$UserLabelFromJson(json);

  static const toJsonFactory = _$UserLabelToJson;
  Map<String, dynamic> toJson() => _$UserLabelToJson(this);

  @JsonKey(name: 'name', includeIfNull: false)
  final String name;
  @JsonKey(name: 'description', includeIfNull: false)
  final String? description;
  @JsonKey(name: 'color', includeIfNull: false)
  final String? color;
  static const fromJsonFactory = _$UserLabelFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserLabel &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.description, description) ||
                const DeepCollectionEquality().equals(
                  other.description,
                  description,
                )) &&
            (identical(other.color, color) ||
                const DeepCollectionEquality().equals(other.color, color)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(description) ^
      const DeepCollectionEquality().hash(color) ^
      runtimeType.hashCode;
}

extension $UserLabelExtension on UserLabel {
  UserLabel copyWith({String? name, String? description, String? color}) {
    return UserLabel(
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
    );
  }

  UserLabel copyWithWrapped({
    Wrapped<String>? name,
    Wrapped<String?>? description,
    Wrapped<String?>? color,
  }) {
    return UserLabel(
      name: (name != null ? name.value : this.name),
      description: (description != null ? description.value : this.description),
      color: (color != null ? color.value : this.color),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class UserNotifications {
  const UserNotifications({
    this.nostrIdentifier,
    this.telegramChatId,
    this.emailAddress,
    this.excludedWallets,
    this.outgoingPaymentsSats,
    this.incomingPaymentsSats,
  });

  factory UserNotifications.fromJson(Map<String, dynamic> json) =>
      _$UserNotificationsFromJson(json);

  static const toJsonFactory = _$UserNotificationsToJson;
  Map<String, dynamic> toJson() => _$UserNotificationsToJson(this);

  @JsonKey(name: 'nostr_identifier', includeIfNull: false)
  final String? nostrIdentifier;
  @JsonKey(name: 'telegram_chat_id', includeIfNull: false)
  final String? telegramChatId;
  @JsonKey(name: 'email_address', includeIfNull: false)
  final String? emailAddress;
  @JsonKey(
    name: 'excluded_wallets',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? excludedWallets;
  @JsonKey(name: 'outgoing_payments_sats', includeIfNull: false)
  final int? outgoingPaymentsSats;
  @JsonKey(name: 'incoming_payments_sats', includeIfNull: false)
  final int? incomingPaymentsSats;
  static const fromJsonFactory = _$UserNotificationsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserNotifications &&
            (identical(other.nostrIdentifier, nostrIdentifier) ||
                const DeepCollectionEquality().equals(
                  other.nostrIdentifier,
                  nostrIdentifier,
                )) &&
            (identical(other.telegramChatId, telegramChatId) ||
                const DeepCollectionEquality().equals(
                  other.telegramChatId,
                  telegramChatId,
                )) &&
            (identical(other.emailAddress, emailAddress) ||
                const DeepCollectionEquality().equals(
                  other.emailAddress,
                  emailAddress,
                )) &&
            (identical(other.excludedWallets, excludedWallets) ||
                const DeepCollectionEquality().equals(
                  other.excludedWallets,
                  excludedWallets,
                )) &&
            (identical(other.outgoingPaymentsSats, outgoingPaymentsSats) ||
                const DeepCollectionEquality().equals(
                  other.outgoingPaymentsSats,
                  outgoingPaymentsSats,
                )) &&
            (identical(other.incomingPaymentsSats, incomingPaymentsSats) ||
                const DeepCollectionEquality().equals(
                  other.incomingPaymentsSats,
                  incomingPaymentsSats,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(nostrIdentifier) ^
      const DeepCollectionEquality().hash(telegramChatId) ^
      const DeepCollectionEquality().hash(emailAddress) ^
      const DeepCollectionEquality().hash(excludedWallets) ^
      const DeepCollectionEquality().hash(outgoingPaymentsSats) ^
      const DeepCollectionEquality().hash(incomingPaymentsSats) ^
      runtimeType.hashCode;
}

extension $UserNotificationsExtension on UserNotifications {
  UserNotifications copyWith({
    String? nostrIdentifier,
    String? telegramChatId,
    String? emailAddress,
    List<String>? excludedWallets,
    int? outgoingPaymentsSats,
    int? incomingPaymentsSats,
  }) {
    return UserNotifications(
      nostrIdentifier: nostrIdentifier ?? this.nostrIdentifier,
      telegramChatId: telegramChatId ?? this.telegramChatId,
      emailAddress: emailAddress ?? this.emailAddress,
      excludedWallets: excludedWallets ?? this.excludedWallets,
      outgoingPaymentsSats: outgoingPaymentsSats ?? this.outgoingPaymentsSats,
      incomingPaymentsSats: incomingPaymentsSats ?? this.incomingPaymentsSats,
    );
  }

  UserNotifications copyWithWrapped({
    Wrapped<String?>? nostrIdentifier,
    Wrapped<String?>? telegramChatId,
    Wrapped<String?>? emailAddress,
    Wrapped<List<String>?>? excludedWallets,
    Wrapped<int?>? outgoingPaymentsSats,
    Wrapped<int?>? incomingPaymentsSats,
  }) {
    return UserNotifications(
      nostrIdentifier: (nostrIdentifier != null
          ? nostrIdentifier.value
          : this.nostrIdentifier),
      telegramChatId: (telegramChatId != null
          ? telegramChatId.value
          : this.telegramChatId),
      emailAddress: (emailAddress != null
          ? emailAddress.value
          : this.emailAddress),
      excludedWallets: (excludedWallets != null
          ? excludedWallets.value
          : this.excludedWallets),
      outgoingPaymentsSats: (outgoingPaymentsSats != null
          ? outgoingPaymentsSats.value
          : this.outgoingPaymentsSats),
      incomingPaymentsSats: (incomingPaymentsSats != null
          ? incomingPaymentsSats.value
          : this.incomingPaymentsSats),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ValidationError {
  const ValidationError({
    required this.loc,
    required this.msg,
    required this.type,
  });

  factory ValidationError.fromJson(Map<String, dynamic> json) =>
      _$ValidationErrorFromJson(json);

  static const toJsonFactory = _$ValidationErrorToJson;
  Map<String, dynamic> toJson() => _$ValidationErrorToJson(this);

  @JsonKey(name: 'loc', includeIfNull: false, defaultValue: <Object>[])
  final List<Object> loc;
  @JsonKey(name: 'msg', includeIfNull: false)
  final String msg;
  @JsonKey(name: 'type', includeIfNull: false)
  final String type;
  static const fromJsonFactory = _$ValidationErrorFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ValidationError &&
            (identical(other.loc, loc) ||
                const DeepCollectionEquality().equals(other.loc, loc)) &&
            (identical(other.msg, msg) ||
                const DeepCollectionEquality().equals(other.msg, msg)) &&
            (identical(other.type, type) ||
                const DeepCollectionEquality().equals(other.type, type)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(loc) ^
      const DeepCollectionEquality().hash(msg) ^
      const DeepCollectionEquality().hash(type) ^
      runtimeType.hashCode;
}

extension $ValidationErrorExtension on ValidationError {
  ValidationError copyWith({List<Object>? loc, String? msg, String? type}) {
    return ValidationError(
      loc: loc ?? this.loc,
      msg: msg ?? this.msg,
      type: type ?? this.type,
    );
  }

  ValidationError copyWithWrapped({
    Wrapped<List<Object>>? loc,
    Wrapped<String>? msg,
    Wrapped<String>? type,
  }) {
    return ValidationError(
      loc: (loc != null ? loc.value : this.loc),
      msg: (msg != null ? msg.value : this.msg),
      type: (type != null ? type.value : this.type),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class Wallet {
  const Wallet({
    required this.id,
    required this.user,
    this.walletType,
    required this.adminkey,
    required this.inkey,
    required this.name,
    this.sharedWalletId,
    this.deleted,
    this.createdAt,
    this.updatedAt,
    this.currency,
    this.balanceMsat,
    this.extra,
    this.storedPaylinks,
    this.sharePermissions,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) => _$WalletFromJson(json);

  static const toJsonFactory = _$WalletToJson;
  Map<String, dynamic> toJson() => _$WalletToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'user', includeIfNull: false)
  final String user;
  @JsonKey(name: 'wallet_type', includeIfNull: false)
  final String? walletType;
  @JsonKey(name: 'adminkey', includeIfNull: false)
  final String adminkey;
  @JsonKey(name: 'inkey', includeIfNull: false)
  final String inkey;
  @JsonKey(name: 'name', includeIfNull: false)
  final String name;
  @JsonKey(name: 'shared_wallet_id', includeIfNull: false)
  final String? sharedWalletId;
  @JsonKey(name: 'deleted', includeIfNull: false, defaultValue: false)
  final bool? deleted;
  @JsonKey(name: 'created_at', includeIfNull: false)
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at', includeIfNull: false)
  final DateTime? updatedAt;
  @JsonKey(name: 'currency', includeIfNull: false)
  final String? currency;
  @JsonKey(name: 'balance_msat', includeIfNull: false)
  final int? balanceMsat;
  @JsonKey(name: 'extra', includeIfNull: false)
  final WalletExtra? extra;
  @JsonKey(name: 'stored_paylinks', includeIfNull: false)
  final StoredPayLinks? storedPaylinks;
  @JsonKey(
    name: 'share_permissions',
    includeIfNull: false,
    toJson: walletPermissionListToJson,
    fromJson: walletPermissionSharePermissionsListFromJson,
  )
  final List<enums.WalletPermission>? sharePermissions;
  static List<enums.WalletPermission>
  walletPermissionSharePermissionsListFromJson(List? value) =>
      walletPermissionListFromJson(value, []);

  static const fromJsonFactory = _$WalletFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Wallet &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.user, user) ||
                const DeepCollectionEquality().equals(other.user, user)) &&
            (identical(other.walletType, walletType) ||
                const DeepCollectionEquality().equals(
                  other.walletType,
                  walletType,
                )) &&
            (identical(other.adminkey, adminkey) ||
                const DeepCollectionEquality().equals(
                  other.adminkey,
                  adminkey,
                )) &&
            (identical(other.inkey, inkey) ||
                const DeepCollectionEquality().equals(other.inkey, inkey)) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.sharedWalletId, sharedWalletId) ||
                const DeepCollectionEquality().equals(
                  other.sharedWalletId,
                  sharedWalletId,
                )) &&
            (identical(other.deleted, deleted) ||
                const DeepCollectionEquality().equals(
                  other.deleted,
                  deleted,
                )) &&
            (identical(other.createdAt, createdAt) ||
                const DeepCollectionEquality().equals(
                  other.createdAt,
                  createdAt,
                )) &&
            (identical(other.updatedAt, updatedAt) ||
                const DeepCollectionEquality().equals(
                  other.updatedAt,
                  updatedAt,
                )) &&
            (identical(other.currency, currency) ||
                const DeepCollectionEquality().equals(
                  other.currency,
                  currency,
                )) &&
            (identical(other.balanceMsat, balanceMsat) ||
                const DeepCollectionEquality().equals(
                  other.balanceMsat,
                  balanceMsat,
                )) &&
            (identical(other.extra, extra) ||
                const DeepCollectionEquality().equals(other.extra, extra)) &&
            (identical(other.storedPaylinks, storedPaylinks) ||
                const DeepCollectionEquality().equals(
                  other.storedPaylinks,
                  storedPaylinks,
                )) &&
            (identical(other.sharePermissions, sharePermissions) ||
                const DeepCollectionEquality().equals(
                  other.sharePermissions,
                  sharePermissions,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(user) ^
      const DeepCollectionEquality().hash(walletType) ^
      const DeepCollectionEquality().hash(adminkey) ^
      const DeepCollectionEquality().hash(inkey) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(sharedWalletId) ^
      const DeepCollectionEquality().hash(deleted) ^
      const DeepCollectionEquality().hash(createdAt) ^
      const DeepCollectionEquality().hash(updatedAt) ^
      const DeepCollectionEquality().hash(currency) ^
      const DeepCollectionEquality().hash(balanceMsat) ^
      const DeepCollectionEquality().hash(extra) ^
      const DeepCollectionEquality().hash(storedPaylinks) ^
      const DeepCollectionEquality().hash(sharePermissions) ^
      runtimeType.hashCode;
}

extension $WalletExtension on Wallet {
  Wallet copyWith({
    String? id,
    String? user,
    String? walletType,
    String? adminkey,
    String? inkey,
    String? name,
    String? sharedWalletId,
    bool? deleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? currency,
    int? balanceMsat,
    WalletExtra? extra,
    StoredPayLinks? storedPaylinks,
    List<enums.WalletPermission>? sharePermissions,
  }) {
    return Wallet(
      id: id ?? this.id,
      user: user ?? this.user,
      walletType: walletType ?? this.walletType,
      adminkey: adminkey ?? this.adminkey,
      inkey: inkey ?? this.inkey,
      name: name ?? this.name,
      sharedWalletId: sharedWalletId ?? this.sharedWalletId,
      deleted: deleted ?? this.deleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currency: currency ?? this.currency,
      balanceMsat: balanceMsat ?? this.balanceMsat,
      extra: extra ?? this.extra,
      storedPaylinks: storedPaylinks ?? this.storedPaylinks,
      sharePermissions: sharePermissions ?? this.sharePermissions,
    );
  }

  Wallet copyWithWrapped({
    Wrapped<String>? id,
    Wrapped<String>? user,
    Wrapped<String?>? walletType,
    Wrapped<String>? adminkey,
    Wrapped<String>? inkey,
    Wrapped<String>? name,
    Wrapped<String?>? sharedWalletId,
    Wrapped<bool?>? deleted,
    Wrapped<DateTime?>? createdAt,
    Wrapped<DateTime?>? updatedAt,
    Wrapped<String?>? currency,
    Wrapped<int?>? balanceMsat,
    Wrapped<WalletExtra?>? extra,
    Wrapped<StoredPayLinks?>? storedPaylinks,
    Wrapped<List<enums.WalletPermission>?>? sharePermissions,
  }) {
    return Wallet(
      id: (id != null ? id.value : this.id),
      user: (user != null ? user.value : this.user),
      walletType: (walletType != null ? walletType.value : this.walletType),
      adminkey: (adminkey != null ? adminkey.value : this.adminkey),
      inkey: (inkey != null ? inkey.value : this.inkey),
      name: (name != null ? name.value : this.name),
      sharedWalletId: (sharedWalletId != null
          ? sharedWalletId.value
          : this.sharedWalletId),
      deleted: (deleted != null ? deleted.value : this.deleted),
      createdAt: (createdAt != null ? createdAt.value : this.createdAt),
      updatedAt: (updatedAt != null ? updatedAt.value : this.updatedAt),
      currency: (currency != null ? currency.value : this.currency),
      balanceMsat: (balanceMsat != null ? balanceMsat.value : this.balanceMsat),
      extra: (extra != null ? extra.value : this.extra),
      storedPaylinks: (storedPaylinks != null
          ? storedPaylinks.value
          : this.storedPaylinks),
      sharePermissions: (sharePermissions != null
          ? sharePermissions.value
          : this.sharePermissions),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class WalletExtra {
  const WalletExtra({this.icon, this.color, this.pinned, this.sharedWith});

  factory WalletExtra.fromJson(Map<String, dynamic> json) =>
      _$WalletExtraFromJson(json);

  static const toJsonFactory = _$WalletExtraToJson;
  Map<String, dynamic> toJson() => _$WalletExtraToJson(this);

  @JsonKey(name: 'icon', includeIfNull: false)
  final String? icon;
  @JsonKey(name: 'color', includeIfNull: false)
  final String? color;
  @JsonKey(name: 'pinned', includeIfNull: false, defaultValue: false)
  final bool? pinned;
  @JsonKey(
    name: 'shared_with',
    includeIfNull: false,
    defaultValue: <WalletSharePermission>[],
  )
  final List<WalletSharePermission>? sharedWith;
  static const fromJsonFactory = _$WalletExtraFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is WalletExtra &&
            (identical(other.icon, icon) ||
                const DeepCollectionEquality().equals(other.icon, icon)) &&
            (identical(other.color, color) ||
                const DeepCollectionEquality().equals(other.color, color)) &&
            (identical(other.pinned, pinned) ||
                const DeepCollectionEquality().equals(other.pinned, pinned)) &&
            (identical(other.sharedWith, sharedWith) ||
                const DeepCollectionEquality().equals(
                  other.sharedWith,
                  sharedWith,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(icon) ^
      const DeepCollectionEquality().hash(color) ^
      const DeepCollectionEquality().hash(pinned) ^
      const DeepCollectionEquality().hash(sharedWith) ^
      runtimeType.hashCode;
}

extension $WalletExtraExtension on WalletExtra {
  WalletExtra copyWith({
    String? icon,
    String? color,
    bool? pinned,
    List<WalletSharePermission>? sharedWith,
  }) {
    return WalletExtra(
      icon: icon ?? this.icon,
      color: color ?? this.color,
      pinned: pinned ?? this.pinned,
      sharedWith: sharedWith ?? this.sharedWith,
    );
  }

  WalletExtra copyWithWrapped({
    Wrapped<String?>? icon,
    Wrapped<String?>? color,
    Wrapped<bool?>? pinned,
    Wrapped<List<WalletSharePermission>?>? sharedWith,
  }) {
    return WalletExtra(
      icon: (icon != null ? icon.value : this.icon),
      color: (color != null ? color.value : this.color),
      pinned: (pinned != null ? pinned.value : this.pinned),
      sharedWith: (sharedWith != null ? sharedWith.value : this.sharedWith),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class WalletInviteRequest {
  const WalletInviteRequest({
    required this.requestId,
    this.fromUserName,
    required this.toWalletId,
    required this.toWalletName,
  });

  factory WalletInviteRequest.fromJson(Map<String, dynamic> json) =>
      _$WalletInviteRequestFromJson(json);

  static const toJsonFactory = _$WalletInviteRequestToJson;
  Map<String, dynamic> toJson() => _$WalletInviteRequestToJson(this);

  @JsonKey(name: 'request_id', includeIfNull: false)
  final String requestId;
  @JsonKey(name: 'from_user_name', includeIfNull: false)
  final String? fromUserName;
  @JsonKey(name: 'to_wallet_id', includeIfNull: false)
  final String toWalletId;
  @JsonKey(name: 'to_wallet_name', includeIfNull: false)
  final String toWalletName;
  static const fromJsonFactory = _$WalletInviteRequestFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is WalletInviteRequest &&
            (identical(other.requestId, requestId) ||
                const DeepCollectionEquality().equals(
                  other.requestId,
                  requestId,
                )) &&
            (identical(other.fromUserName, fromUserName) ||
                const DeepCollectionEquality().equals(
                  other.fromUserName,
                  fromUserName,
                )) &&
            (identical(other.toWalletId, toWalletId) ||
                const DeepCollectionEquality().equals(
                  other.toWalletId,
                  toWalletId,
                )) &&
            (identical(other.toWalletName, toWalletName) ||
                const DeepCollectionEquality().equals(
                  other.toWalletName,
                  toWalletName,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(requestId) ^
      const DeepCollectionEquality().hash(fromUserName) ^
      const DeepCollectionEquality().hash(toWalletId) ^
      const DeepCollectionEquality().hash(toWalletName) ^
      runtimeType.hashCode;
}

extension $WalletInviteRequestExtension on WalletInviteRequest {
  WalletInviteRequest copyWith({
    String? requestId,
    String? fromUserName,
    String? toWalletId,
    String? toWalletName,
  }) {
    return WalletInviteRequest(
      requestId: requestId ?? this.requestId,
      fromUserName: fromUserName ?? this.fromUserName,
      toWalletId: toWalletId ?? this.toWalletId,
      toWalletName: toWalletName ?? this.toWalletName,
    );
  }

  WalletInviteRequest copyWithWrapped({
    Wrapped<String>? requestId,
    Wrapped<String?>? fromUserName,
    Wrapped<String>? toWalletId,
    Wrapped<String>? toWalletName,
  }) {
    return WalletInviteRequest(
      requestId: (requestId != null ? requestId.value : this.requestId),
      fromUserName: (fromUserName != null
          ? fromUserName.value
          : this.fromUserName),
      toWalletId: (toWalletId != null ? toWalletId.value : this.toWalletId),
      toWalletName: (toWalletName != null
          ? toWalletName.value
          : this.toWalletName),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class WalletSharePermission {
  const WalletSharePermission({
    this.requestId,
    required this.username,
    this.sharedWithWalletId,
    this.permissions,
    required this.status,
    this.comment,
  });

  factory WalletSharePermission.fromJson(Map<String, dynamic> json) =>
      _$WalletSharePermissionFromJson(json);

  static const toJsonFactory = _$WalletSharePermissionToJson;
  Map<String, dynamic> toJson() => _$WalletSharePermissionToJson(this);

  @JsonKey(name: 'request_id', includeIfNull: false)
  final String? requestId;
  @JsonKey(name: 'username', includeIfNull: false)
  final String username;
  @JsonKey(name: 'shared_with_wallet_id', includeIfNull: false)
  final String? sharedWithWalletId;
  @JsonKey(
    name: 'permissions',
    includeIfNull: false,
    toJson: walletPermissionListToJson,
    fromJson: walletPermissionPermissionsListFromJson,
  )
  final List<enums.WalletPermission>? permissions;
  static List<enums.WalletPermission> walletPermissionPermissionsListFromJson(
    List? value,
  ) => walletPermissionListFromJson(value, []);

  @JsonKey(
    name: 'status',
    includeIfNull: false,
    toJson: walletShareStatusToJson,
    fromJson: walletShareStatusFromJson,
  )
  final enums.WalletShareStatus status;
  @JsonKey(name: 'comment', includeIfNull: false)
  final String? comment;
  static const fromJsonFactory = _$WalletSharePermissionFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is WalletSharePermission &&
            (identical(other.requestId, requestId) ||
                const DeepCollectionEquality().equals(
                  other.requestId,
                  requestId,
                )) &&
            (identical(other.username, username) ||
                const DeepCollectionEquality().equals(
                  other.username,
                  username,
                )) &&
            (identical(other.sharedWithWalletId, sharedWithWalletId) ||
                const DeepCollectionEquality().equals(
                  other.sharedWithWalletId,
                  sharedWithWalletId,
                )) &&
            (identical(other.permissions, permissions) ||
                const DeepCollectionEquality().equals(
                  other.permissions,
                  permissions,
                )) &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)) &&
            (identical(other.comment, comment) ||
                const DeepCollectionEquality().equals(other.comment, comment)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(requestId) ^
      const DeepCollectionEquality().hash(username) ^
      const DeepCollectionEquality().hash(sharedWithWalletId) ^
      const DeepCollectionEquality().hash(permissions) ^
      const DeepCollectionEquality().hash(status) ^
      const DeepCollectionEquality().hash(comment) ^
      runtimeType.hashCode;
}

extension $WalletSharePermissionExtension on WalletSharePermission {
  WalletSharePermission copyWith({
    String? requestId,
    String? username,
    String? sharedWithWalletId,
    List<enums.WalletPermission>? permissions,
    enums.WalletShareStatus? status,
    String? comment,
  }) {
    return WalletSharePermission(
      requestId: requestId ?? this.requestId,
      username: username ?? this.username,
      sharedWithWalletId: sharedWithWalletId ?? this.sharedWithWalletId,
      permissions: permissions ?? this.permissions,
      status: status ?? this.status,
      comment: comment ?? this.comment,
    );
  }

  WalletSharePermission copyWithWrapped({
    Wrapped<String?>? requestId,
    Wrapped<String>? username,
    Wrapped<String?>? sharedWithWalletId,
    Wrapped<List<enums.WalletPermission>?>? permissions,
    Wrapped<enums.WalletShareStatus>? status,
    Wrapped<String?>? comment,
  }) {
    return WalletSharePermission(
      requestId: (requestId != null ? requestId.value : this.requestId),
      username: (username != null ? username.value : this.username),
      sharedWithWalletId: (sharedWithWalletId != null
          ? sharedWithWalletId.value
          : this.sharedWithWalletId),
      permissions: (permissions != null ? permissions.value : this.permissions),
      status: (status != null ? status.value : this.status),
      comment: (comment != null ? comment.value : this.comment),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class WebPushSubscription {
  const WebPushSubscription({
    required this.endpoint,
    required this.user,
    required this.data,
    required this.host,
    required this.timestamp,
  });

  factory WebPushSubscription.fromJson(Map<String, dynamic> json) =>
      _$WebPushSubscriptionFromJson(json);

  static const toJsonFactory = _$WebPushSubscriptionToJson;
  Map<String, dynamic> toJson() => _$WebPushSubscriptionToJson(this);

  @JsonKey(name: 'endpoint', includeIfNull: false)
  final String endpoint;
  @JsonKey(name: 'user', includeIfNull: false)
  final String user;
  @JsonKey(name: 'data', includeIfNull: false)
  final String data;
  @JsonKey(name: 'host', includeIfNull: false)
  final String host;
  @JsonKey(name: 'timestamp', includeIfNull: false)
  final DateTime timestamp;
  static const fromJsonFactory = _$WebPushSubscriptionFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is WebPushSubscription &&
            (identical(other.endpoint, endpoint) ||
                const DeepCollectionEquality().equals(
                  other.endpoint,
                  endpoint,
                )) &&
            (identical(other.user, user) ||
                const DeepCollectionEquality().equals(other.user, user)) &&
            (identical(other.data, data) ||
                const DeepCollectionEquality().equals(other.data, data)) &&
            (identical(other.host, host) ||
                const DeepCollectionEquality().equals(other.host, host)) &&
            (identical(other.timestamp, timestamp) ||
                const DeepCollectionEquality().equals(
                  other.timestamp,
                  timestamp,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(endpoint) ^
      const DeepCollectionEquality().hash(user) ^
      const DeepCollectionEquality().hash(data) ^
      const DeepCollectionEquality().hash(host) ^
      const DeepCollectionEquality().hash(timestamp) ^
      runtimeType.hashCode;
}

extension $WebPushSubscriptionExtension on WebPushSubscription {
  WebPushSubscription copyWith({
    String? endpoint,
    String? user,
    String? data,
    String? host,
    DateTime? timestamp,
  }) {
    return WebPushSubscription(
      endpoint: endpoint ?? this.endpoint,
      user: user ?? this.user,
      data: data ?? this.data,
      host: host ?? this.host,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  WebPushSubscription copyWithWrapped({
    Wrapped<String>? endpoint,
    Wrapped<String>? user,
    Wrapped<String>? data,
    Wrapped<String>? host,
    Wrapped<DateTime>? timestamp,
  }) {
    return WebPushSubscription(
      endpoint: (endpoint != null ? endpoint.value : this.endpoint),
      user: (user != null ? user.value : this.user),
      data: (data != null ? data.value : this.data),
      host: (host != null ? host.value : this.host),
      timestamp: (timestamp != null ? timestamp.value : this.timestamp),
    );
  }
}

String? actionFieldsAmountSourceNullableToJson(
  enums.ActionFieldsAmountSource? actionFieldsAmountSource,
) {
  return actionFieldsAmountSource?.value;
}

String? actionFieldsAmountSourceToJson(
  enums.ActionFieldsAmountSource actionFieldsAmountSource,
) {
  return actionFieldsAmountSource.value;
}

enums.ActionFieldsAmountSource actionFieldsAmountSourceFromJson(
  Object? actionFieldsAmountSource, [
  enums.ActionFieldsAmountSource? defaultValue,
]) {
  return enums.ActionFieldsAmountSource.values.firstWhereOrNull(
        (e) => e.value == actionFieldsAmountSource,
      ) ??
      defaultValue ??
      enums.ActionFieldsAmountSource.swaggerGeneratedUnknown;
}

enums.ActionFieldsAmountSource? actionFieldsAmountSourceNullableFromJson(
  Object? actionFieldsAmountSource, [
  enums.ActionFieldsAmountSource? defaultValue,
]) {
  if (actionFieldsAmountSource == null) {
    return null;
  }
  return enums.ActionFieldsAmountSource.values.firstWhereOrNull(
        (e) => e.value == actionFieldsAmountSource,
      ) ??
      defaultValue;
}

String actionFieldsAmountSourceExplodedListToJson(
  List<enums.ActionFieldsAmountSource>? actionFieldsAmountSource,
) {
  return actionFieldsAmountSource?.map((e) => e.value!).join(',') ?? '';
}

List<String> actionFieldsAmountSourceListToJson(
  List<enums.ActionFieldsAmountSource>? actionFieldsAmountSource,
) {
  if (actionFieldsAmountSource == null) {
    return [];
  }

  return actionFieldsAmountSource.map((e) => e.value!).toList();
}

List<enums.ActionFieldsAmountSource> actionFieldsAmountSourceListFromJson(
  List? actionFieldsAmountSource, [
  List<enums.ActionFieldsAmountSource>? defaultValue,
]) {
  if (actionFieldsAmountSource == null) {
    return defaultValue ?? [];
  }

  return actionFieldsAmountSource
      .map((e) => actionFieldsAmountSourceFromJson(e.toString()))
      .toList();
}

List<enums.ActionFieldsAmountSource>?
actionFieldsAmountSourceNullableListFromJson(
  List? actionFieldsAmountSource, [
  List<enums.ActionFieldsAmountSource>? defaultValue,
]) {
  if (actionFieldsAmountSource == null) {
    return defaultValue;
  }

  return actionFieldsAmountSource
      .map((e) => actionFieldsAmountSourceFromJson(e.toString()))
      .toList();
}

String? channelStateNullableToJson(enums.ChannelState? channelState) {
  return channelState?.value;
}

String? channelStateToJson(enums.ChannelState channelState) {
  return channelState.value;
}

enums.ChannelState channelStateFromJson(
  Object? channelState, [
  enums.ChannelState? defaultValue,
]) {
  return enums.ChannelState.values.firstWhereOrNull(
        (e) => e.value == channelState,
      ) ??
      defaultValue ??
      enums.ChannelState.swaggerGeneratedUnknown;
}

enums.ChannelState? channelStateNullableFromJson(
  Object? channelState, [
  enums.ChannelState? defaultValue,
]) {
  if (channelState == null) {
    return null;
  }
  return enums.ChannelState.values.firstWhereOrNull(
        (e) => e.value == channelState,
      ) ??
      defaultValue;
}

String channelStateExplodedListToJson(List<enums.ChannelState>? channelState) {
  return channelState?.map((e) => e.value!).join(',') ?? '';
}

List<String> channelStateListToJson(List<enums.ChannelState>? channelState) {
  if (channelState == null) {
    return [];
  }

  return channelState.map((e) => e.value!).toList();
}

List<enums.ChannelState> channelStateListFromJson(
  List? channelState, [
  List<enums.ChannelState>? defaultValue,
]) {
  if (channelState == null) {
    return defaultValue ?? [];
  }

  return channelState.map((e) => channelStateFromJson(e.toString())).toList();
}

List<enums.ChannelState>? channelStateNullableListFromJson(
  List? channelState, [
  List<enums.ChannelState>? defaultValue,
]) {
  if (channelState == null) {
    return defaultValue;
  }

  return channelState.map((e) => channelStateFromJson(e.toString())).toList();
}

String? lnurlResponseTagNullableToJson(
  enums.LnurlResponseTag? lnurlResponseTag,
) {
  return lnurlResponseTag?.value;
}

String? lnurlResponseTagToJson(enums.LnurlResponseTag lnurlResponseTag) {
  return lnurlResponseTag.value;
}

enums.LnurlResponseTag lnurlResponseTagFromJson(
  Object? lnurlResponseTag, [
  enums.LnurlResponseTag? defaultValue,
]) {
  return enums.LnurlResponseTag.values.firstWhereOrNull(
        (e) => e.value == lnurlResponseTag,
      ) ??
      defaultValue ??
      enums.LnurlResponseTag.swaggerGeneratedUnknown;
}

enums.LnurlResponseTag? lnurlResponseTagNullableFromJson(
  Object? lnurlResponseTag, [
  enums.LnurlResponseTag? defaultValue,
]) {
  if (lnurlResponseTag == null) {
    return null;
  }
  return enums.LnurlResponseTag.values.firstWhereOrNull(
        (e) => e.value == lnurlResponseTag,
      ) ??
      defaultValue;
}

String lnurlResponseTagExplodedListToJson(
  List<enums.LnurlResponseTag>? lnurlResponseTag,
) {
  return lnurlResponseTag?.map((e) => e.value!).join(',') ?? '';
}

List<String> lnurlResponseTagListToJson(
  List<enums.LnurlResponseTag>? lnurlResponseTag,
) {
  if (lnurlResponseTag == null) {
    return [];
  }

  return lnurlResponseTag.map((e) => e.value!).toList();
}

List<enums.LnurlResponseTag> lnurlResponseTagListFromJson(
  List? lnurlResponseTag, [
  List<enums.LnurlResponseTag>? defaultValue,
]) {
  if (lnurlResponseTag == null) {
    return defaultValue ?? [];
  }

  return lnurlResponseTag
      .map((e) => lnurlResponseTagFromJson(e.toString()))
      .toList();
}

List<enums.LnurlResponseTag>? lnurlResponseTagNullableListFromJson(
  List? lnurlResponseTag, [
  List<enums.LnurlResponseTag>? defaultValue,
]) {
  if (lnurlResponseTag == null) {
    return defaultValue;
  }

  return lnurlResponseTag
      .map((e) => lnurlResponseTagFromJson(e.toString()))
      .toList();
}

String? lnurlStatusNullableToJson(enums.LnurlStatus? lnurlStatus) {
  return lnurlStatus?.value;
}

String? lnurlStatusToJson(enums.LnurlStatus lnurlStatus) {
  return lnurlStatus.value;
}

enums.LnurlStatus lnurlStatusFromJson(
  Object? lnurlStatus, [
  enums.LnurlStatus? defaultValue,
]) {
  return enums.LnurlStatus.values.firstWhereOrNull(
        (e) => e.value == lnurlStatus,
      ) ??
      defaultValue ??
      enums.LnurlStatus.swaggerGeneratedUnknown;
}

enums.LnurlStatus? lnurlStatusNullableFromJson(
  Object? lnurlStatus, [
  enums.LnurlStatus? defaultValue,
]) {
  if (lnurlStatus == null) {
    return null;
  }
  return enums.LnurlStatus.values.firstWhereOrNull(
        (e) => e.value == lnurlStatus,
      ) ??
      defaultValue;
}

String lnurlStatusExplodedListToJson(List<enums.LnurlStatus>? lnurlStatus) {
  return lnurlStatus?.map((e) => e.value!).join(',') ?? '';
}

List<String> lnurlStatusListToJson(List<enums.LnurlStatus>? lnurlStatus) {
  if (lnurlStatus == null) {
    return [];
  }

  return lnurlStatus.map((e) => e.value!).toList();
}

List<enums.LnurlStatus> lnurlStatusListFromJson(
  List? lnurlStatus, [
  List<enums.LnurlStatus>? defaultValue,
]) {
  if (lnurlStatus == null) {
    return defaultValue ?? [];
  }

  return lnurlStatus.map((e) => lnurlStatusFromJson(e.toString())).toList();
}

List<enums.LnurlStatus>? lnurlStatusNullableListFromJson(
  List? lnurlStatus, [
  List<enums.LnurlStatus>? defaultValue,
]) {
  if (lnurlStatus == null) {
    return defaultValue;
  }

  return lnurlStatus.map((e) => lnurlStatusFromJson(e.toString())).toList();
}

String? walletPermissionNullableToJson(
  enums.WalletPermission? walletPermission,
) {
  return walletPermission?.value;
}

String? walletPermissionToJson(enums.WalletPermission walletPermission) {
  return walletPermission.value;
}

enums.WalletPermission walletPermissionFromJson(
  Object? walletPermission, [
  enums.WalletPermission? defaultValue,
]) {
  return enums.WalletPermission.values.firstWhereOrNull(
        (e) => e.value == walletPermission,
      ) ??
      defaultValue ??
      enums.WalletPermission.swaggerGeneratedUnknown;
}

enums.WalletPermission? walletPermissionNullableFromJson(
  Object? walletPermission, [
  enums.WalletPermission? defaultValue,
]) {
  if (walletPermission == null) {
    return null;
  }
  return enums.WalletPermission.values.firstWhereOrNull(
        (e) => e.value == walletPermission,
      ) ??
      defaultValue;
}

String walletPermissionExplodedListToJson(
  List<enums.WalletPermission>? walletPermission,
) {
  return walletPermission?.map((e) => e.value!).join(',') ?? '';
}

List<String> walletPermissionListToJson(
  List<enums.WalletPermission>? walletPermission,
) {
  if (walletPermission == null) {
    return [];
  }

  return walletPermission.map((e) => e.value!).toList();
}

List<enums.WalletPermission> walletPermissionListFromJson(
  List? walletPermission, [
  List<enums.WalletPermission>? defaultValue,
]) {
  if (walletPermission == null) {
    return defaultValue ?? [];
  }

  return walletPermission
      .map((e) => walletPermissionFromJson(e.toString()))
      .toList();
}

List<enums.WalletPermission>? walletPermissionNullableListFromJson(
  List? walletPermission, [
  List<enums.WalletPermission>? defaultValue,
]) {
  if (walletPermission == null) {
    return defaultValue;
  }

  return walletPermission
      .map((e) => walletPermissionFromJson(e.toString()))
      .toList();
}

String? walletShareStatusNullableToJson(
  enums.WalletShareStatus? walletShareStatus,
) {
  return walletShareStatus?.value;
}

String? walletShareStatusToJson(enums.WalletShareStatus walletShareStatus) {
  return walletShareStatus.value;
}

enums.WalletShareStatus walletShareStatusFromJson(
  Object? walletShareStatus, [
  enums.WalletShareStatus? defaultValue,
]) {
  return enums.WalletShareStatus.values.firstWhereOrNull(
        (e) => e.value == walletShareStatus,
      ) ??
      defaultValue ??
      enums.WalletShareStatus.swaggerGeneratedUnknown;
}

enums.WalletShareStatus? walletShareStatusNullableFromJson(
  Object? walletShareStatus, [
  enums.WalletShareStatus? defaultValue,
]) {
  if (walletShareStatus == null) {
    return null;
  }
  return enums.WalletShareStatus.values.firstWhereOrNull(
        (e) => e.value == walletShareStatus,
      ) ??
      defaultValue;
}

String walletShareStatusExplodedListToJson(
  List<enums.WalletShareStatus>? walletShareStatus,
) {
  return walletShareStatus?.map((e) => e.value!).join(',') ?? '';
}

List<String> walletShareStatusListToJson(
  List<enums.WalletShareStatus>? walletShareStatus,
) {
  if (walletShareStatus == null) {
    return [];
  }

  return walletShareStatus.map((e) => e.value!).toList();
}

List<enums.WalletShareStatus> walletShareStatusListFromJson(
  List? walletShareStatus, [
  List<enums.WalletShareStatus>? defaultValue,
]) {
  if (walletShareStatus == null) {
    return defaultValue ?? [];
  }

  return walletShareStatus
      .map((e) => walletShareStatusFromJson(e.toString()))
      .toList();
}

List<enums.WalletShareStatus>? walletShareStatusNullableListFromJson(
  List? walletShareStatus, [
  List<enums.WalletShareStatus>? defaultValue,
]) {
  if (walletShareStatus == null) {
    return defaultValue;
  }

  return walletShareStatus
      .map((e) => walletShareStatusFromJson(e.toString()))
      .toList();
}

String? walletTypeNullableToJson(enums.WalletType? walletType) {
  return walletType?.value;
}

String? walletTypeToJson(enums.WalletType walletType) {
  return walletType.value;
}

enums.WalletType walletTypeFromJson(
  Object? walletType, [
  enums.WalletType? defaultValue,
]) {
  return enums.WalletType.values.firstWhereOrNull(
        (e) => e.value == walletType,
      ) ??
      defaultValue ??
      enums.WalletType.swaggerGeneratedUnknown;
}

enums.WalletType? walletTypeNullableFromJson(
  Object? walletType, [
  enums.WalletType? defaultValue,
]) {
  if (walletType == null) {
    return null;
  }
  return enums.WalletType.values.firstWhereOrNull(
        (e) => e.value == walletType,
      ) ??
      defaultValue;
}

String walletTypeExplodedListToJson(List<enums.WalletType>? walletType) {
  return walletType?.map((e) => e.value!).join(',') ?? '';
}

List<String> walletTypeListToJson(List<enums.WalletType>? walletType) {
  if (walletType == null) {
    return [];
  }

  return walletType.map((e) => e.value!).toList();
}

List<enums.WalletType> walletTypeListFromJson(
  List? walletType, [
  List<enums.WalletType>? defaultValue,
]) {
  if (walletType == null) {
    return defaultValue ?? [];
  }

  return walletType.map((e) => walletTypeFromJson(e.toString())).toList();
}

List<enums.WalletType>? walletTypeNullableListFromJson(
  List? walletType, [
  List<enums.WalletType>? defaultValue,
]) {
  if (walletType == null) {
    return defaultValue;
  }

  return walletType.map((e) => walletTypeFromJson(e.toString())).toList();
}

String? nodeApiV1PaymentsGetDirectionNullableToJson(
  enums.NodeApiV1PaymentsGetDirection? nodeApiV1PaymentsGetDirection,
) {
  return nodeApiV1PaymentsGetDirection?.value;
}

String? nodeApiV1PaymentsGetDirectionToJson(
  enums.NodeApiV1PaymentsGetDirection nodeApiV1PaymentsGetDirection,
) {
  return nodeApiV1PaymentsGetDirection.value;
}

enums.NodeApiV1PaymentsGetDirection nodeApiV1PaymentsGetDirectionFromJson(
  Object? nodeApiV1PaymentsGetDirection, [
  enums.NodeApiV1PaymentsGetDirection? defaultValue,
]) {
  return enums.NodeApiV1PaymentsGetDirection.values.firstWhereOrNull(
        (e) => e.value == nodeApiV1PaymentsGetDirection,
      ) ??
      defaultValue ??
      enums.NodeApiV1PaymentsGetDirection.swaggerGeneratedUnknown;
}

enums.NodeApiV1PaymentsGetDirection?
nodeApiV1PaymentsGetDirectionNullableFromJson(
  Object? nodeApiV1PaymentsGetDirection, [
  enums.NodeApiV1PaymentsGetDirection? defaultValue,
]) {
  if (nodeApiV1PaymentsGetDirection == null) {
    return null;
  }
  return enums.NodeApiV1PaymentsGetDirection.values.firstWhereOrNull(
        (e) => e.value == nodeApiV1PaymentsGetDirection,
      ) ??
      defaultValue;
}

String nodeApiV1PaymentsGetDirectionExplodedListToJson(
  List<enums.NodeApiV1PaymentsGetDirection>? nodeApiV1PaymentsGetDirection,
) {
  return nodeApiV1PaymentsGetDirection?.map((e) => e.value!).join(',') ?? '';
}

List<String> nodeApiV1PaymentsGetDirectionListToJson(
  List<enums.NodeApiV1PaymentsGetDirection>? nodeApiV1PaymentsGetDirection,
) {
  if (nodeApiV1PaymentsGetDirection == null) {
    return [];
  }

  return nodeApiV1PaymentsGetDirection.map((e) => e.value!).toList();
}

List<enums.NodeApiV1PaymentsGetDirection>
nodeApiV1PaymentsGetDirectionListFromJson(
  List? nodeApiV1PaymentsGetDirection, [
  List<enums.NodeApiV1PaymentsGetDirection>? defaultValue,
]) {
  if (nodeApiV1PaymentsGetDirection == null) {
    return defaultValue ?? [];
  }

  return nodeApiV1PaymentsGetDirection
      .map((e) => nodeApiV1PaymentsGetDirectionFromJson(e.toString()))
      .toList();
}

List<enums.NodeApiV1PaymentsGetDirection>?
nodeApiV1PaymentsGetDirectionNullableListFromJson(
  List? nodeApiV1PaymentsGetDirection, [
  List<enums.NodeApiV1PaymentsGetDirection>? defaultValue,
]) {
  if (nodeApiV1PaymentsGetDirection == null) {
    return defaultValue;
  }

  return nodeApiV1PaymentsGetDirection
      .map((e) => nodeApiV1PaymentsGetDirectionFromJson(e.toString()))
      .toList();
}

String? nodeApiV1InvoicesGetDirectionNullableToJson(
  enums.NodeApiV1InvoicesGetDirection? nodeApiV1InvoicesGetDirection,
) {
  return nodeApiV1InvoicesGetDirection?.value;
}

String? nodeApiV1InvoicesGetDirectionToJson(
  enums.NodeApiV1InvoicesGetDirection nodeApiV1InvoicesGetDirection,
) {
  return nodeApiV1InvoicesGetDirection.value;
}

enums.NodeApiV1InvoicesGetDirection nodeApiV1InvoicesGetDirectionFromJson(
  Object? nodeApiV1InvoicesGetDirection, [
  enums.NodeApiV1InvoicesGetDirection? defaultValue,
]) {
  return enums.NodeApiV1InvoicesGetDirection.values.firstWhereOrNull(
        (e) => e.value == nodeApiV1InvoicesGetDirection,
      ) ??
      defaultValue ??
      enums.NodeApiV1InvoicesGetDirection.swaggerGeneratedUnknown;
}

enums.NodeApiV1InvoicesGetDirection?
nodeApiV1InvoicesGetDirectionNullableFromJson(
  Object? nodeApiV1InvoicesGetDirection, [
  enums.NodeApiV1InvoicesGetDirection? defaultValue,
]) {
  if (nodeApiV1InvoicesGetDirection == null) {
    return null;
  }
  return enums.NodeApiV1InvoicesGetDirection.values.firstWhereOrNull(
        (e) => e.value == nodeApiV1InvoicesGetDirection,
      ) ??
      defaultValue;
}

String nodeApiV1InvoicesGetDirectionExplodedListToJson(
  List<enums.NodeApiV1InvoicesGetDirection>? nodeApiV1InvoicesGetDirection,
) {
  return nodeApiV1InvoicesGetDirection?.map((e) => e.value!).join(',') ?? '';
}

List<String> nodeApiV1InvoicesGetDirectionListToJson(
  List<enums.NodeApiV1InvoicesGetDirection>? nodeApiV1InvoicesGetDirection,
) {
  if (nodeApiV1InvoicesGetDirection == null) {
    return [];
  }

  return nodeApiV1InvoicesGetDirection.map((e) => e.value!).toList();
}

List<enums.NodeApiV1InvoicesGetDirection>
nodeApiV1InvoicesGetDirectionListFromJson(
  List? nodeApiV1InvoicesGetDirection, [
  List<enums.NodeApiV1InvoicesGetDirection>? defaultValue,
]) {
  if (nodeApiV1InvoicesGetDirection == null) {
    return defaultValue ?? [];
  }

  return nodeApiV1InvoicesGetDirection
      .map((e) => nodeApiV1InvoicesGetDirectionFromJson(e.toString()))
      .toList();
}

List<enums.NodeApiV1InvoicesGetDirection>?
nodeApiV1InvoicesGetDirectionNullableListFromJson(
  List? nodeApiV1InvoicesGetDirection, [
  List<enums.NodeApiV1InvoicesGetDirection>? defaultValue,
]) {
  if (nodeApiV1InvoicesGetDirection == null) {
    return defaultValue;
  }

  return nodeApiV1InvoicesGetDirection
      .map((e) => nodeApiV1InvoicesGetDirectionFromJson(e.toString()))
      .toList();
}

String? apiV1PaymentsGetDirectionNullableToJson(
  enums.ApiV1PaymentsGetDirection? apiV1PaymentsGetDirection,
) {
  return apiV1PaymentsGetDirection?.value;
}

String? apiV1PaymentsGetDirectionToJson(
  enums.ApiV1PaymentsGetDirection apiV1PaymentsGetDirection,
) {
  return apiV1PaymentsGetDirection.value;
}

enums.ApiV1PaymentsGetDirection apiV1PaymentsGetDirectionFromJson(
  Object? apiV1PaymentsGetDirection, [
  enums.ApiV1PaymentsGetDirection? defaultValue,
]) {
  return enums.ApiV1PaymentsGetDirection.values.firstWhereOrNull(
        (e) => e.value == apiV1PaymentsGetDirection,
      ) ??
      defaultValue ??
      enums.ApiV1PaymentsGetDirection.swaggerGeneratedUnknown;
}

enums.ApiV1PaymentsGetDirection? apiV1PaymentsGetDirectionNullableFromJson(
  Object? apiV1PaymentsGetDirection, [
  enums.ApiV1PaymentsGetDirection? defaultValue,
]) {
  if (apiV1PaymentsGetDirection == null) {
    return null;
  }
  return enums.ApiV1PaymentsGetDirection.values.firstWhereOrNull(
        (e) => e.value == apiV1PaymentsGetDirection,
      ) ??
      defaultValue;
}

String apiV1PaymentsGetDirectionExplodedListToJson(
  List<enums.ApiV1PaymentsGetDirection>? apiV1PaymentsGetDirection,
) {
  return apiV1PaymentsGetDirection?.map((e) => e.value!).join(',') ?? '';
}

List<String> apiV1PaymentsGetDirectionListToJson(
  List<enums.ApiV1PaymentsGetDirection>? apiV1PaymentsGetDirection,
) {
  if (apiV1PaymentsGetDirection == null) {
    return [];
  }

  return apiV1PaymentsGetDirection.map((e) => e.value!).toList();
}

List<enums.ApiV1PaymentsGetDirection> apiV1PaymentsGetDirectionListFromJson(
  List? apiV1PaymentsGetDirection, [
  List<enums.ApiV1PaymentsGetDirection>? defaultValue,
]) {
  if (apiV1PaymentsGetDirection == null) {
    return defaultValue ?? [];
  }

  return apiV1PaymentsGetDirection
      .map((e) => apiV1PaymentsGetDirectionFromJson(e.toString()))
      .toList();
}

List<enums.ApiV1PaymentsGetDirection>?
apiV1PaymentsGetDirectionNullableListFromJson(
  List? apiV1PaymentsGetDirection, [
  List<enums.ApiV1PaymentsGetDirection>? defaultValue,
]) {
  if (apiV1PaymentsGetDirection == null) {
    return defaultValue;
  }

  return apiV1PaymentsGetDirection
      .map((e) => apiV1PaymentsGetDirectionFromJson(e.toString()))
      .toList();
}

String? apiV1PaymentsHistoryGetGroupNullableToJson(
  enums.ApiV1PaymentsHistoryGetGroup? apiV1PaymentsHistoryGetGroup,
) {
  return apiV1PaymentsHistoryGetGroup?.value;
}

String? apiV1PaymentsHistoryGetGroupToJson(
  enums.ApiV1PaymentsHistoryGetGroup apiV1PaymentsHistoryGetGroup,
) {
  return apiV1PaymentsHistoryGetGroup.value;
}

enums.ApiV1PaymentsHistoryGetGroup apiV1PaymentsHistoryGetGroupFromJson(
  Object? apiV1PaymentsHistoryGetGroup, [
  enums.ApiV1PaymentsHistoryGetGroup? defaultValue,
]) {
  return enums.ApiV1PaymentsHistoryGetGroup.values.firstWhereOrNull(
        (e) => e.value == apiV1PaymentsHistoryGetGroup,
      ) ??
      defaultValue ??
      enums.ApiV1PaymentsHistoryGetGroup.swaggerGeneratedUnknown;
}

enums.ApiV1PaymentsHistoryGetGroup?
apiV1PaymentsHistoryGetGroupNullableFromJson(
  Object? apiV1PaymentsHistoryGetGroup, [
  enums.ApiV1PaymentsHistoryGetGroup? defaultValue,
]) {
  if (apiV1PaymentsHistoryGetGroup == null) {
    return null;
  }
  return enums.ApiV1PaymentsHistoryGetGroup.values.firstWhereOrNull(
        (e) => e.value == apiV1PaymentsHistoryGetGroup,
      ) ??
      defaultValue;
}

String apiV1PaymentsHistoryGetGroupExplodedListToJson(
  List<enums.ApiV1PaymentsHistoryGetGroup>? apiV1PaymentsHistoryGetGroup,
) {
  return apiV1PaymentsHistoryGetGroup?.map((e) => e.value!).join(',') ?? '';
}

List<String> apiV1PaymentsHistoryGetGroupListToJson(
  List<enums.ApiV1PaymentsHistoryGetGroup>? apiV1PaymentsHistoryGetGroup,
) {
  if (apiV1PaymentsHistoryGetGroup == null) {
    return [];
  }

  return apiV1PaymentsHistoryGetGroup.map((e) => e.value!).toList();
}

List<enums.ApiV1PaymentsHistoryGetGroup>
apiV1PaymentsHistoryGetGroupListFromJson(
  List? apiV1PaymentsHistoryGetGroup, [
  List<enums.ApiV1PaymentsHistoryGetGroup>? defaultValue,
]) {
  if (apiV1PaymentsHistoryGetGroup == null) {
    return defaultValue ?? [];
  }

  return apiV1PaymentsHistoryGetGroup
      .map((e) => apiV1PaymentsHistoryGetGroupFromJson(e.toString()))
      .toList();
}

List<enums.ApiV1PaymentsHistoryGetGroup>?
apiV1PaymentsHistoryGetGroupNullableListFromJson(
  List? apiV1PaymentsHistoryGetGroup, [
  List<enums.ApiV1PaymentsHistoryGetGroup>? defaultValue,
]) {
  if (apiV1PaymentsHistoryGetGroup == null) {
    return defaultValue;
  }

  return apiV1PaymentsHistoryGetGroup
      .map((e) => apiV1PaymentsHistoryGetGroupFromJson(e.toString()))
      .toList();
}

String? apiV1PaymentsHistoryGetDirectionNullableToJson(
  enums.ApiV1PaymentsHistoryGetDirection? apiV1PaymentsHistoryGetDirection,
) {
  return apiV1PaymentsHistoryGetDirection?.value;
}

String? apiV1PaymentsHistoryGetDirectionToJson(
  enums.ApiV1PaymentsHistoryGetDirection apiV1PaymentsHistoryGetDirection,
) {
  return apiV1PaymentsHistoryGetDirection.value;
}

enums.ApiV1PaymentsHistoryGetDirection apiV1PaymentsHistoryGetDirectionFromJson(
  Object? apiV1PaymentsHistoryGetDirection, [
  enums.ApiV1PaymentsHistoryGetDirection? defaultValue,
]) {
  return enums.ApiV1PaymentsHistoryGetDirection.values.firstWhereOrNull(
        (e) => e.value == apiV1PaymentsHistoryGetDirection,
      ) ??
      defaultValue ??
      enums.ApiV1PaymentsHistoryGetDirection.swaggerGeneratedUnknown;
}

enums.ApiV1PaymentsHistoryGetDirection?
apiV1PaymentsHistoryGetDirectionNullableFromJson(
  Object? apiV1PaymentsHistoryGetDirection, [
  enums.ApiV1PaymentsHistoryGetDirection? defaultValue,
]) {
  if (apiV1PaymentsHistoryGetDirection == null) {
    return null;
  }
  return enums.ApiV1PaymentsHistoryGetDirection.values.firstWhereOrNull(
        (e) => e.value == apiV1PaymentsHistoryGetDirection,
      ) ??
      defaultValue;
}

String apiV1PaymentsHistoryGetDirectionExplodedListToJson(
  List<enums.ApiV1PaymentsHistoryGetDirection>?
  apiV1PaymentsHistoryGetDirection,
) {
  return apiV1PaymentsHistoryGetDirection?.map((e) => e.value!).join(',') ?? '';
}

List<String> apiV1PaymentsHistoryGetDirectionListToJson(
  List<enums.ApiV1PaymentsHistoryGetDirection>?
  apiV1PaymentsHistoryGetDirection,
) {
  if (apiV1PaymentsHistoryGetDirection == null) {
    return [];
  }

  return apiV1PaymentsHistoryGetDirection.map((e) => e.value!).toList();
}

List<enums.ApiV1PaymentsHistoryGetDirection>
apiV1PaymentsHistoryGetDirectionListFromJson(
  List? apiV1PaymentsHistoryGetDirection, [
  List<enums.ApiV1PaymentsHistoryGetDirection>? defaultValue,
]) {
  if (apiV1PaymentsHistoryGetDirection == null) {
    return defaultValue ?? [];
  }

  return apiV1PaymentsHistoryGetDirection
      .map((e) => apiV1PaymentsHistoryGetDirectionFromJson(e.toString()))
      .toList();
}

List<enums.ApiV1PaymentsHistoryGetDirection>?
apiV1PaymentsHistoryGetDirectionNullableListFromJson(
  List? apiV1PaymentsHistoryGetDirection, [
  List<enums.ApiV1PaymentsHistoryGetDirection>? defaultValue,
]) {
  if (apiV1PaymentsHistoryGetDirection == null) {
    return defaultValue;
  }

  return apiV1PaymentsHistoryGetDirection
      .map((e) => apiV1PaymentsHistoryGetDirectionFromJson(e.toString()))
      .toList();
}

String? apiV1PaymentsStatsCountGetCountByNullableToJson(
  enums.ApiV1PaymentsStatsCountGetCountBy? apiV1PaymentsStatsCountGetCountBy,
) {
  return apiV1PaymentsStatsCountGetCountBy?.value;
}

String? apiV1PaymentsStatsCountGetCountByToJson(
  enums.ApiV1PaymentsStatsCountGetCountBy apiV1PaymentsStatsCountGetCountBy,
) {
  return apiV1PaymentsStatsCountGetCountBy.value;
}

enums.ApiV1PaymentsStatsCountGetCountBy
apiV1PaymentsStatsCountGetCountByFromJson(
  Object? apiV1PaymentsStatsCountGetCountBy, [
  enums.ApiV1PaymentsStatsCountGetCountBy? defaultValue,
]) {
  return enums.ApiV1PaymentsStatsCountGetCountBy.values.firstWhereOrNull(
        (e) => e.value == apiV1PaymentsStatsCountGetCountBy,
      ) ??
      defaultValue ??
      enums.ApiV1PaymentsStatsCountGetCountBy.swaggerGeneratedUnknown;
}

enums.ApiV1PaymentsStatsCountGetCountBy?
apiV1PaymentsStatsCountGetCountByNullableFromJson(
  Object? apiV1PaymentsStatsCountGetCountBy, [
  enums.ApiV1PaymentsStatsCountGetCountBy? defaultValue,
]) {
  if (apiV1PaymentsStatsCountGetCountBy == null) {
    return null;
  }
  return enums.ApiV1PaymentsStatsCountGetCountBy.values.firstWhereOrNull(
        (e) => e.value == apiV1PaymentsStatsCountGetCountBy,
      ) ??
      defaultValue;
}

String apiV1PaymentsStatsCountGetCountByExplodedListToJson(
  List<enums.ApiV1PaymentsStatsCountGetCountBy>?
  apiV1PaymentsStatsCountGetCountBy,
) {
  return apiV1PaymentsStatsCountGetCountBy?.map((e) => e.value!).join(',') ??
      '';
}

List<String> apiV1PaymentsStatsCountGetCountByListToJson(
  List<enums.ApiV1PaymentsStatsCountGetCountBy>?
  apiV1PaymentsStatsCountGetCountBy,
) {
  if (apiV1PaymentsStatsCountGetCountBy == null) {
    return [];
  }

  return apiV1PaymentsStatsCountGetCountBy.map((e) => e.value!).toList();
}

List<enums.ApiV1PaymentsStatsCountGetCountBy>
apiV1PaymentsStatsCountGetCountByListFromJson(
  List? apiV1PaymentsStatsCountGetCountBy, [
  List<enums.ApiV1PaymentsStatsCountGetCountBy>? defaultValue,
]) {
  if (apiV1PaymentsStatsCountGetCountBy == null) {
    return defaultValue ?? [];
  }

  return apiV1PaymentsStatsCountGetCountBy
      .map((e) => apiV1PaymentsStatsCountGetCountByFromJson(e.toString()))
      .toList();
}

List<enums.ApiV1PaymentsStatsCountGetCountBy>?
apiV1PaymentsStatsCountGetCountByNullableListFromJson(
  List? apiV1PaymentsStatsCountGetCountBy, [
  List<enums.ApiV1PaymentsStatsCountGetCountBy>? defaultValue,
]) {
  if (apiV1PaymentsStatsCountGetCountBy == null) {
    return defaultValue;
  }

  return apiV1PaymentsStatsCountGetCountBy
      .map((e) => apiV1PaymentsStatsCountGetCountByFromJson(e.toString()))
      .toList();
}

String? apiV1PaymentsStatsCountGetDirectionNullableToJson(
  enums.ApiV1PaymentsStatsCountGetDirection?
  apiV1PaymentsStatsCountGetDirection,
) {
  return apiV1PaymentsStatsCountGetDirection?.value;
}

String? apiV1PaymentsStatsCountGetDirectionToJson(
  enums.ApiV1PaymentsStatsCountGetDirection apiV1PaymentsStatsCountGetDirection,
) {
  return apiV1PaymentsStatsCountGetDirection.value;
}

enums.ApiV1PaymentsStatsCountGetDirection
apiV1PaymentsStatsCountGetDirectionFromJson(
  Object? apiV1PaymentsStatsCountGetDirection, [
  enums.ApiV1PaymentsStatsCountGetDirection? defaultValue,
]) {
  return enums.ApiV1PaymentsStatsCountGetDirection.values.firstWhereOrNull(
        (e) => e.value == apiV1PaymentsStatsCountGetDirection,
      ) ??
      defaultValue ??
      enums.ApiV1PaymentsStatsCountGetDirection.swaggerGeneratedUnknown;
}

enums.ApiV1PaymentsStatsCountGetDirection?
apiV1PaymentsStatsCountGetDirectionNullableFromJson(
  Object? apiV1PaymentsStatsCountGetDirection, [
  enums.ApiV1PaymentsStatsCountGetDirection? defaultValue,
]) {
  if (apiV1PaymentsStatsCountGetDirection == null) {
    return null;
  }
  return enums.ApiV1PaymentsStatsCountGetDirection.values.firstWhereOrNull(
        (e) => e.value == apiV1PaymentsStatsCountGetDirection,
      ) ??
      defaultValue;
}

String apiV1PaymentsStatsCountGetDirectionExplodedListToJson(
  List<enums.ApiV1PaymentsStatsCountGetDirection>?
  apiV1PaymentsStatsCountGetDirection,
) {
  return apiV1PaymentsStatsCountGetDirection?.map((e) => e.value!).join(',') ??
      '';
}

List<String> apiV1PaymentsStatsCountGetDirectionListToJson(
  List<enums.ApiV1PaymentsStatsCountGetDirection>?
  apiV1PaymentsStatsCountGetDirection,
) {
  if (apiV1PaymentsStatsCountGetDirection == null) {
    return [];
  }

  return apiV1PaymentsStatsCountGetDirection.map((e) => e.value!).toList();
}

List<enums.ApiV1PaymentsStatsCountGetDirection>
apiV1PaymentsStatsCountGetDirectionListFromJson(
  List? apiV1PaymentsStatsCountGetDirection, [
  List<enums.ApiV1PaymentsStatsCountGetDirection>? defaultValue,
]) {
  if (apiV1PaymentsStatsCountGetDirection == null) {
    return defaultValue ?? [];
  }

  return apiV1PaymentsStatsCountGetDirection
      .map((e) => apiV1PaymentsStatsCountGetDirectionFromJson(e.toString()))
      .toList();
}

List<enums.ApiV1PaymentsStatsCountGetDirection>?
apiV1PaymentsStatsCountGetDirectionNullableListFromJson(
  List? apiV1PaymentsStatsCountGetDirection, [
  List<enums.ApiV1PaymentsStatsCountGetDirection>? defaultValue,
]) {
  if (apiV1PaymentsStatsCountGetDirection == null) {
    return defaultValue;
  }

  return apiV1PaymentsStatsCountGetDirection
      .map((e) => apiV1PaymentsStatsCountGetDirectionFromJson(e.toString()))
      .toList();
}

String? apiV1PaymentsStatsWalletsGetDirectionNullableToJson(
  enums.ApiV1PaymentsStatsWalletsGetDirection?
  apiV1PaymentsStatsWalletsGetDirection,
) {
  return apiV1PaymentsStatsWalletsGetDirection?.value;
}

String? apiV1PaymentsStatsWalletsGetDirectionToJson(
  enums.ApiV1PaymentsStatsWalletsGetDirection
  apiV1PaymentsStatsWalletsGetDirection,
) {
  return apiV1PaymentsStatsWalletsGetDirection.value;
}

enums.ApiV1PaymentsStatsWalletsGetDirection
apiV1PaymentsStatsWalletsGetDirectionFromJson(
  Object? apiV1PaymentsStatsWalletsGetDirection, [
  enums.ApiV1PaymentsStatsWalletsGetDirection? defaultValue,
]) {
  return enums.ApiV1PaymentsStatsWalletsGetDirection.values.firstWhereOrNull(
        (e) => e.value == apiV1PaymentsStatsWalletsGetDirection,
      ) ??
      defaultValue ??
      enums.ApiV1PaymentsStatsWalletsGetDirection.swaggerGeneratedUnknown;
}

enums.ApiV1PaymentsStatsWalletsGetDirection?
apiV1PaymentsStatsWalletsGetDirectionNullableFromJson(
  Object? apiV1PaymentsStatsWalletsGetDirection, [
  enums.ApiV1PaymentsStatsWalletsGetDirection? defaultValue,
]) {
  if (apiV1PaymentsStatsWalletsGetDirection == null) {
    return null;
  }
  return enums.ApiV1PaymentsStatsWalletsGetDirection.values.firstWhereOrNull(
        (e) => e.value == apiV1PaymentsStatsWalletsGetDirection,
      ) ??
      defaultValue;
}

String apiV1PaymentsStatsWalletsGetDirectionExplodedListToJson(
  List<enums.ApiV1PaymentsStatsWalletsGetDirection>?
  apiV1PaymentsStatsWalletsGetDirection,
) {
  return apiV1PaymentsStatsWalletsGetDirection
          ?.map((e) => e.value!)
          .join(',') ??
      '';
}

List<String> apiV1PaymentsStatsWalletsGetDirectionListToJson(
  List<enums.ApiV1PaymentsStatsWalletsGetDirection>?
  apiV1PaymentsStatsWalletsGetDirection,
) {
  if (apiV1PaymentsStatsWalletsGetDirection == null) {
    return [];
  }

  return apiV1PaymentsStatsWalletsGetDirection.map((e) => e.value!).toList();
}

List<enums.ApiV1PaymentsStatsWalletsGetDirection>
apiV1PaymentsStatsWalletsGetDirectionListFromJson(
  List? apiV1PaymentsStatsWalletsGetDirection, [
  List<enums.ApiV1PaymentsStatsWalletsGetDirection>? defaultValue,
]) {
  if (apiV1PaymentsStatsWalletsGetDirection == null) {
    return defaultValue ?? [];
  }

  return apiV1PaymentsStatsWalletsGetDirection
      .map((e) => apiV1PaymentsStatsWalletsGetDirectionFromJson(e.toString()))
      .toList();
}

List<enums.ApiV1PaymentsStatsWalletsGetDirection>?
apiV1PaymentsStatsWalletsGetDirectionNullableListFromJson(
  List? apiV1PaymentsStatsWalletsGetDirection, [
  List<enums.ApiV1PaymentsStatsWalletsGetDirection>? defaultValue,
]) {
  if (apiV1PaymentsStatsWalletsGetDirection == null) {
    return defaultValue;
  }

  return apiV1PaymentsStatsWalletsGetDirection
      .map((e) => apiV1PaymentsStatsWalletsGetDirectionFromJson(e.toString()))
      .toList();
}

String? apiV1PaymentsStatsDailyGetDirectionNullableToJson(
  enums.ApiV1PaymentsStatsDailyGetDirection?
  apiV1PaymentsStatsDailyGetDirection,
) {
  return apiV1PaymentsStatsDailyGetDirection?.value;
}

String? apiV1PaymentsStatsDailyGetDirectionToJson(
  enums.ApiV1PaymentsStatsDailyGetDirection apiV1PaymentsStatsDailyGetDirection,
) {
  return apiV1PaymentsStatsDailyGetDirection.value;
}

enums.ApiV1PaymentsStatsDailyGetDirection
apiV1PaymentsStatsDailyGetDirectionFromJson(
  Object? apiV1PaymentsStatsDailyGetDirection, [
  enums.ApiV1PaymentsStatsDailyGetDirection? defaultValue,
]) {
  return enums.ApiV1PaymentsStatsDailyGetDirection.values.firstWhereOrNull(
        (e) => e.value == apiV1PaymentsStatsDailyGetDirection,
      ) ??
      defaultValue ??
      enums.ApiV1PaymentsStatsDailyGetDirection.swaggerGeneratedUnknown;
}

enums.ApiV1PaymentsStatsDailyGetDirection?
apiV1PaymentsStatsDailyGetDirectionNullableFromJson(
  Object? apiV1PaymentsStatsDailyGetDirection, [
  enums.ApiV1PaymentsStatsDailyGetDirection? defaultValue,
]) {
  if (apiV1PaymentsStatsDailyGetDirection == null) {
    return null;
  }
  return enums.ApiV1PaymentsStatsDailyGetDirection.values.firstWhereOrNull(
        (e) => e.value == apiV1PaymentsStatsDailyGetDirection,
      ) ??
      defaultValue;
}

String apiV1PaymentsStatsDailyGetDirectionExplodedListToJson(
  List<enums.ApiV1PaymentsStatsDailyGetDirection>?
  apiV1PaymentsStatsDailyGetDirection,
) {
  return apiV1PaymentsStatsDailyGetDirection?.map((e) => e.value!).join(',') ??
      '';
}

List<String> apiV1PaymentsStatsDailyGetDirectionListToJson(
  List<enums.ApiV1PaymentsStatsDailyGetDirection>?
  apiV1PaymentsStatsDailyGetDirection,
) {
  if (apiV1PaymentsStatsDailyGetDirection == null) {
    return [];
  }

  return apiV1PaymentsStatsDailyGetDirection.map((e) => e.value!).toList();
}

List<enums.ApiV1PaymentsStatsDailyGetDirection>
apiV1PaymentsStatsDailyGetDirectionListFromJson(
  List? apiV1PaymentsStatsDailyGetDirection, [
  List<enums.ApiV1PaymentsStatsDailyGetDirection>? defaultValue,
]) {
  if (apiV1PaymentsStatsDailyGetDirection == null) {
    return defaultValue ?? [];
  }

  return apiV1PaymentsStatsDailyGetDirection
      .map((e) => apiV1PaymentsStatsDailyGetDirectionFromJson(e.toString()))
      .toList();
}

List<enums.ApiV1PaymentsStatsDailyGetDirection>?
apiV1PaymentsStatsDailyGetDirectionNullableListFromJson(
  List? apiV1PaymentsStatsDailyGetDirection, [
  List<enums.ApiV1PaymentsStatsDailyGetDirection>? defaultValue,
]) {
  if (apiV1PaymentsStatsDailyGetDirection == null) {
    return defaultValue;
  }

  return apiV1PaymentsStatsDailyGetDirection
      .map((e) => apiV1PaymentsStatsDailyGetDirectionFromJson(e.toString()))
      .toList();
}

String? apiV1PaymentsPaginatedGetDirectionNullableToJson(
  enums.ApiV1PaymentsPaginatedGetDirection? apiV1PaymentsPaginatedGetDirection,
) {
  return apiV1PaymentsPaginatedGetDirection?.value;
}

String? apiV1PaymentsPaginatedGetDirectionToJson(
  enums.ApiV1PaymentsPaginatedGetDirection apiV1PaymentsPaginatedGetDirection,
) {
  return apiV1PaymentsPaginatedGetDirection.value;
}

enums.ApiV1PaymentsPaginatedGetDirection
apiV1PaymentsPaginatedGetDirectionFromJson(
  Object? apiV1PaymentsPaginatedGetDirection, [
  enums.ApiV1PaymentsPaginatedGetDirection? defaultValue,
]) {
  return enums.ApiV1PaymentsPaginatedGetDirection.values.firstWhereOrNull(
        (e) => e.value == apiV1PaymentsPaginatedGetDirection,
      ) ??
      defaultValue ??
      enums.ApiV1PaymentsPaginatedGetDirection.swaggerGeneratedUnknown;
}

enums.ApiV1PaymentsPaginatedGetDirection?
apiV1PaymentsPaginatedGetDirectionNullableFromJson(
  Object? apiV1PaymentsPaginatedGetDirection, [
  enums.ApiV1PaymentsPaginatedGetDirection? defaultValue,
]) {
  if (apiV1PaymentsPaginatedGetDirection == null) {
    return null;
  }
  return enums.ApiV1PaymentsPaginatedGetDirection.values.firstWhereOrNull(
        (e) => e.value == apiV1PaymentsPaginatedGetDirection,
      ) ??
      defaultValue;
}

String apiV1PaymentsPaginatedGetDirectionExplodedListToJson(
  List<enums.ApiV1PaymentsPaginatedGetDirection>?
  apiV1PaymentsPaginatedGetDirection,
) {
  return apiV1PaymentsPaginatedGetDirection?.map((e) => e.value!).join(',') ??
      '';
}

List<String> apiV1PaymentsPaginatedGetDirectionListToJson(
  List<enums.ApiV1PaymentsPaginatedGetDirection>?
  apiV1PaymentsPaginatedGetDirection,
) {
  if (apiV1PaymentsPaginatedGetDirection == null) {
    return [];
  }

  return apiV1PaymentsPaginatedGetDirection.map((e) => e.value!).toList();
}

List<enums.ApiV1PaymentsPaginatedGetDirection>
apiV1PaymentsPaginatedGetDirectionListFromJson(
  List? apiV1PaymentsPaginatedGetDirection, [
  List<enums.ApiV1PaymentsPaginatedGetDirection>? defaultValue,
]) {
  if (apiV1PaymentsPaginatedGetDirection == null) {
    return defaultValue ?? [];
  }

  return apiV1PaymentsPaginatedGetDirection
      .map((e) => apiV1PaymentsPaginatedGetDirectionFromJson(e.toString()))
      .toList();
}

List<enums.ApiV1PaymentsPaginatedGetDirection>?
apiV1PaymentsPaginatedGetDirectionNullableListFromJson(
  List? apiV1PaymentsPaginatedGetDirection, [
  List<enums.ApiV1PaymentsPaginatedGetDirection>? defaultValue,
]) {
  if (apiV1PaymentsPaginatedGetDirection == null) {
    return defaultValue;
  }

  return apiV1PaymentsPaginatedGetDirection
      .map((e) => apiV1PaymentsPaginatedGetDirectionFromJson(e.toString()))
      .toList();
}

String? apiV1PaymentsAllPaginatedGetDirectionNullableToJson(
  enums.ApiV1PaymentsAllPaginatedGetDirection?
  apiV1PaymentsAllPaginatedGetDirection,
) {
  return apiV1PaymentsAllPaginatedGetDirection?.value;
}

String? apiV1PaymentsAllPaginatedGetDirectionToJson(
  enums.ApiV1PaymentsAllPaginatedGetDirection
  apiV1PaymentsAllPaginatedGetDirection,
) {
  return apiV1PaymentsAllPaginatedGetDirection.value;
}

enums.ApiV1PaymentsAllPaginatedGetDirection
apiV1PaymentsAllPaginatedGetDirectionFromJson(
  Object? apiV1PaymentsAllPaginatedGetDirection, [
  enums.ApiV1PaymentsAllPaginatedGetDirection? defaultValue,
]) {
  return enums.ApiV1PaymentsAllPaginatedGetDirection.values.firstWhereOrNull(
        (e) => e.value == apiV1PaymentsAllPaginatedGetDirection,
      ) ??
      defaultValue ??
      enums.ApiV1PaymentsAllPaginatedGetDirection.swaggerGeneratedUnknown;
}

enums.ApiV1PaymentsAllPaginatedGetDirection?
apiV1PaymentsAllPaginatedGetDirectionNullableFromJson(
  Object? apiV1PaymentsAllPaginatedGetDirection, [
  enums.ApiV1PaymentsAllPaginatedGetDirection? defaultValue,
]) {
  if (apiV1PaymentsAllPaginatedGetDirection == null) {
    return null;
  }
  return enums.ApiV1PaymentsAllPaginatedGetDirection.values.firstWhereOrNull(
        (e) => e.value == apiV1PaymentsAllPaginatedGetDirection,
      ) ??
      defaultValue;
}

String apiV1PaymentsAllPaginatedGetDirectionExplodedListToJson(
  List<enums.ApiV1PaymentsAllPaginatedGetDirection>?
  apiV1PaymentsAllPaginatedGetDirection,
) {
  return apiV1PaymentsAllPaginatedGetDirection
          ?.map((e) => e.value!)
          .join(',') ??
      '';
}

List<String> apiV1PaymentsAllPaginatedGetDirectionListToJson(
  List<enums.ApiV1PaymentsAllPaginatedGetDirection>?
  apiV1PaymentsAllPaginatedGetDirection,
) {
  if (apiV1PaymentsAllPaginatedGetDirection == null) {
    return [];
  }

  return apiV1PaymentsAllPaginatedGetDirection.map((e) => e.value!).toList();
}

List<enums.ApiV1PaymentsAllPaginatedGetDirection>
apiV1PaymentsAllPaginatedGetDirectionListFromJson(
  List? apiV1PaymentsAllPaginatedGetDirection, [
  List<enums.ApiV1PaymentsAllPaginatedGetDirection>? defaultValue,
]) {
  if (apiV1PaymentsAllPaginatedGetDirection == null) {
    return defaultValue ?? [];
  }

  return apiV1PaymentsAllPaginatedGetDirection
      .map((e) => apiV1PaymentsAllPaginatedGetDirectionFromJson(e.toString()))
      .toList();
}

List<enums.ApiV1PaymentsAllPaginatedGetDirection>?
apiV1PaymentsAllPaginatedGetDirectionNullableListFromJson(
  List? apiV1PaymentsAllPaginatedGetDirection, [
  List<enums.ApiV1PaymentsAllPaginatedGetDirection>? defaultValue,
]) {
  if (apiV1PaymentsAllPaginatedGetDirection == null) {
    return defaultValue;
  }

  return apiV1PaymentsAllPaginatedGetDirection
      .map((e) => apiV1PaymentsAllPaginatedGetDirectionFromJson(e.toString()))
      .toList();
}

String? apiV1WalletPaginatedGetDirectionNullableToJson(
  enums.ApiV1WalletPaginatedGetDirection? apiV1WalletPaginatedGetDirection,
) {
  return apiV1WalletPaginatedGetDirection?.value;
}

String? apiV1WalletPaginatedGetDirectionToJson(
  enums.ApiV1WalletPaginatedGetDirection apiV1WalletPaginatedGetDirection,
) {
  return apiV1WalletPaginatedGetDirection.value;
}

enums.ApiV1WalletPaginatedGetDirection apiV1WalletPaginatedGetDirectionFromJson(
  Object? apiV1WalletPaginatedGetDirection, [
  enums.ApiV1WalletPaginatedGetDirection? defaultValue,
]) {
  return enums.ApiV1WalletPaginatedGetDirection.values.firstWhereOrNull(
        (e) => e.value == apiV1WalletPaginatedGetDirection,
      ) ??
      defaultValue ??
      enums.ApiV1WalletPaginatedGetDirection.swaggerGeneratedUnknown;
}

enums.ApiV1WalletPaginatedGetDirection?
apiV1WalletPaginatedGetDirectionNullableFromJson(
  Object? apiV1WalletPaginatedGetDirection, [
  enums.ApiV1WalletPaginatedGetDirection? defaultValue,
]) {
  if (apiV1WalletPaginatedGetDirection == null) {
    return null;
  }
  return enums.ApiV1WalletPaginatedGetDirection.values.firstWhereOrNull(
        (e) => e.value == apiV1WalletPaginatedGetDirection,
      ) ??
      defaultValue;
}

String apiV1WalletPaginatedGetDirectionExplodedListToJson(
  List<enums.ApiV1WalletPaginatedGetDirection>?
  apiV1WalletPaginatedGetDirection,
) {
  return apiV1WalletPaginatedGetDirection?.map((e) => e.value!).join(',') ?? '';
}

List<String> apiV1WalletPaginatedGetDirectionListToJson(
  List<enums.ApiV1WalletPaginatedGetDirection>?
  apiV1WalletPaginatedGetDirection,
) {
  if (apiV1WalletPaginatedGetDirection == null) {
    return [];
  }

  return apiV1WalletPaginatedGetDirection.map((e) => e.value!).toList();
}

List<enums.ApiV1WalletPaginatedGetDirection>
apiV1WalletPaginatedGetDirectionListFromJson(
  List? apiV1WalletPaginatedGetDirection, [
  List<enums.ApiV1WalletPaginatedGetDirection>? defaultValue,
]) {
  if (apiV1WalletPaginatedGetDirection == null) {
    return defaultValue ?? [];
  }

  return apiV1WalletPaginatedGetDirection
      .map((e) => apiV1WalletPaginatedGetDirectionFromJson(e.toString()))
      .toList();
}

List<enums.ApiV1WalletPaginatedGetDirection>?
apiV1WalletPaginatedGetDirectionNullableListFromJson(
  List? apiV1WalletPaginatedGetDirection, [
  List<enums.ApiV1WalletPaginatedGetDirection>? defaultValue,
]) {
  if (apiV1WalletPaginatedGetDirection == null) {
    return defaultValue;
  }

  return apiV1WalletPaginatedGetDirection
      .map((e) => apiV1WalletPaginatedGetDirectionFromJson(e.toString()))
      .toList();
}

String? usersApiV1UserGetDirectionNullableToJson(
  enums.UsersApiV1UserGetDirection? usersApiV1UserGetDirection,
) {
  return usersApiV1UserGetDirection?.value;
}

String? usersApiV1UserGetDirectionToJson(
  enums.UsersApiV1UserGetDirection usersApiV1UserGetDirection,
) {
  return usersApiV1UserGetDirection.value;
}

enums.UsersApiV1UserGetDirection usersApiV1UserGetDirectionFromJson(
  Object? usersApiV1UserGetDirection, [
  enums.UsersApiV1UserGetDirection? defaultValue,
]) {
  return enums.UsersApiV1UserGetDirection.values.firstWhereOrNull(
        (e) => e.value == usersApiV1UserGetDirection,
      ) ??
      defaultValue ??
      enums.UsersApiV1UserGetDirection.swaggerGeneratedUnknown;
}

enums.UsersApiV1UserGetDirection? usersApiV1UserGetDirectionNullableFromJson(
  Object? usersApiV1UserGetDirection, [
  enums.UsersApiV1UserGetDirection? defaultValue,
]) {
  if (usersApiV1UserGetDirection == null) {
    return null;
  }
  return enums.UsersApiV1UserGetDirection.values.firstWhereOrNull(
        (e) => e.value == usersApiV1UserGetDirection,
      ) ??
      defaultValue;
}

String usersApiV1UserGetDirectionExplodedListToJson(
  List<enums.UsersApiV1UserGetDirection>? usersApiV1UserGetDirection,
) {
  return usersApiV1UserGetDirection?.map((e) => e.value!).join(',') ?? '';
}

List<String> usersApiV1UserGetDirectionListToJson(
  List<enums.UsersApiV1UserGetDirection>? usersApiV1UserGetDirection,
) {
  if (usersApiV1UserGetDirection == null) {
    return [];
  }

  return usersApiV1UserGetDirection.map((e) => e.value!).toList();
}

List<enums.UsersApiV1UserGetDirection> usersApiV1UserGetDirectionListFromJson(
  List? usersApiV1UserGetDirection, [
  List<enums.UsersApiV1UserGetDirection>? defaultValue,
]) {
  if (usersApiV1UserGetDirection == null) {
    return defaultValue ?? [];
  }

  return usersApiV1UserGetDirection
      .map((e) => usersApiV1UserGetDirectionFromJson(e.toString()))
      .toList();
}

List<enums.UsersApiV1UserGetDirection>?
usersApiV1UserGetDirectionNullableListFromJson(
  List? usersApiV1UserGetDirection, [
  List<enums.UsersApiV1UserGetDirection>? defaultValue,
]) {
  if (usersApiV1UserGetDirection == null) {
    return defaultValue;
  }

  return usersApiV1UserGetDirection
      .map((e) => usersApiV1UserGetDirectionFromJson(e.toString()))
      .toList();
}

String? auditApiV1GetDirectionNullableToJson(
  enums.AuditApiV1GetDirection? auditApiV1GetDirection,
) {
  return auditApiV1GetDirection?.value;
}

String? auditApiV1GetDirectionToJson(
  enums.AuditApiV1GetDirection auditApiV1GetDirection,
) {
  return auditApiV1GetDirection.value;
}

enums.AuditApiV1GetDirection auditApiV1GetDirectionFromJson(
  Object? auditApiV1GetDirection, [
  enums.AuditApiV1GetDirection? defaultValue,
]) {
  return enums.AuditApiV1GetDirection.values.firstWhereOrNull(
        (e) => e.value == auditApiV1GetDirection,
      ) ??
      defaultValue ??
      enums.AuditApiV1GetDirection.swaggerGeneratedUnknown;
}

enums.AuditApiV1GetDirection? auditApiV1GetDirectionNullableFromJson(
  Object? auditApiV1GetDirection, [
  enums.AuditApiV1GetDirection? defaultValue,
]) {
  if (auditApiV1GetDirection == null) {
    return null;
  }
  return enums.AuditApiV1GetDirection.values.firstWhereOrNull(
        (e) => e.value == auditApiV1GetDirection,
      ) ??
      defaultValue;
}

String auditApiV1GetDirectionExplodedListToJson(
  List<enums.AuditApiV1GetDirection>? auditApiV1GetDirection,
) {
  return auditApiV1GetDirection?.map((e) => e.value!).join(',') ?? '';
}

List<String> auditApiV1GetDirectionListToJson(
  List<enums.AuditApiV1GetDirection>? auditApiV1GetDirection,
) {
  if (auditApiV1GetDirection == null) {
    return [];
  }

  return auditApiV1GetDirection.map((e) => e.value!).toList();
}

List<enums.AuditApiV1GetDirection> auditApiV1GetDirectionListFromJson(
  List? auditApiV1GetDirection, [
  List<enums.AuditApiV1GetDirection>? defaultValue,
]) {
  if (auditApiV1GetDirection == null) {
    return defaultValue ?? [];
  }

  return auditApiV1GetDirection
      .map((e) => auditApiV1GetDirectionFromJson(e.toString()))
      .toList();
}

List<enums.AuditApiV1GetDirection>? auditApiV1GetDirectionNullableListFromJson(
  List? auditApiV1GetDirection, [
  List<enums.AuditApiV1GetDirection>? defaultValue,
]) {
  if (auditApiV1GetDirection == null) {
    return defaultValue;
  }

  return auditApiV1GetDirection
      .map((e) => auditApiV1GetDirectionFromJson(e.toString()))
      .toList();
}

String? auditApiV1StatsGetDirectionNullableToJson(
  enums.AuditApiV1StatsGetDirection? auditApiV1StatsGetDirection,
) {
  return auditApiV1StatsGetDirection?.value;
}

String? auditApiV1StatsGetDirectionToJson(
  enums.AuditApiV1StatsGetDirection auditApiV1StatsGetDirection,
) {
  return auditApiV1StatsGetDirection.value;
}

enums.AuditApiV1StatsGetDirection auditApiV1StatsGetDirectionFromJson(
  Object? auditApiV1StatsGetDirection, [
  enums.AuditApiV1StatsGetDirection? defaultValue,
]) {
  return enums.AuditApiV1StatsGetDirection.values.firstWhereOrNull(
        (e) => e.value == auditApiV1StatsGetDirection,
      ) ??
      defaultValue ??
      enums.AuditApiV1StatsGetDirection.swaggerGeneratedUnknown;
}

enums.AuditApiV1StatsGetDirection? auditApiV1StatsGetDirectionNullableFromJson(
  Object? auditApiV1StatsGetDirection, [
  enums.AuditApiV1StatsGetDirection? defaultValue,
]) {
  if (auditApiV1StatsGetDirection == null) {
    return null;
  }
  return enums.AuditApiV1StatsGetDirection.values.firstWhereOrNull(
        (e) => e.value == auditApiV1StatsGetDirection,
      ) ??
      defaultValue;
}

String auditApiV1StatsGetDirectionExplodedListToJson(
  List<enums.AuditApiV1StatsGetDirection>? auditApiV1StatsGetDirection,
) {
  return auditApiV1StatsGetDirection?.map((e) => e.value!).join(',') ?? '';
}

List<String> auditApiV1StatsGetDirectionListToJson(
  List<enums.AuditApiV1StatsGetDirection>? auditApiV1StatsGetDirection,
) {
  if (auditApiV1StatsGetDirection == null) {
    return [];
  }

  return auditApiV1StatsGetDirection.map((e) => e.value!).toList();
}

List<enums.AuditApiV1StatsGetDirection> auditApiV1StatsGetDirectionListFromJson(
  List? auditApiV1StatsGetDirection, [
  List<enums.AuditApiV1StatsGetDirection>? defaultValue,
]) {
  if (auditApiV1StatsGetDirection == null) {
    return defaultValue ?? [];
  }

  return auditApiV1StatsGetDirection
      .map((e) => auditApiV1StatsGetDirectionFromJson(e.toString()))
      .toList();
}

List<enums.AuditApiV1StatsGetDirection>?
auditApiV1StatsGetDirectionNullableListFromJson(
  List? auditApiV1StatsGetDirection, [
  List<enums.AuditApiV1StatsGetDirection>? defaultValue,
]) {
  if (auditApiV1StatsGetDirection == null) {
    return defaultValue;
  }

  return auditApiV1StatsGetDirection
      .map((e) => auditApiV1StatsGetDirectionFromJson(e.toString()))
      .toList();
}

String? apiV1AssetsPaginatedGetDirectionNullableToJson(
  enums.ApiV1AssetsPaginatedGetDirection? apiV1AssetsPaginatedGetDirection,
) {
  return apiV1AssetsPaginatedGetDirection?.value;
}

String? apiV1AssetsPaginatedGetDirectionToJson(
  enums.ApiV1AssetsPaginatedGetDirection apiV1AssetsPaginatedGetDirection,
) {
  return apiV1AssetsPaginatedGetDirection.value;
}

enums.ApiV1AssetsPaginatedGetDirection apiV1AssetsPaginatedGetDirectionFromJson(
  Object? apiV1AssetsPaginatedGetDirection, [
  enums.ApiV1AssetsPaginatedGetDirection? defaultValue,
]) {
  return enums.ApiV1AssetsPaginatedGetDirection.values.firstWhereOrNull(
        (e) => e.value == apiV1AssetsPaginatedGetDirection,
      ) ??
      defaultValue ??
      enums.ApiV1AssetsPaginatedGetDirection.swaggerGeneratedUnknown;
}

enums.ApiV1AssetsPaginatedGetDirection?
apiV1AssetsPaginatedGetDirectionNullableFromJson(
  Object? apiV1AssetsPaginatedGetDirection, [
  enums.ApiV1AssetsPaginatedGetDirection? defaultValue,
]) {
  if (apiV1AssetsPaginatedGetDirection == null) {
    return null;
  }
  return enums.ApiV1AssetsPaginatedGetDirection.values.firstWhereOrNull(
        (e) => e.value == apiV1AssetsPaginatedGetDirection,
      ) ??
      defaultValue;
}

String apiV1AssetsPaginatedGetDirectionExplodedListToJson(
  List<enums.ApiV1AssetsPaginatedGetDirection>?
  apiV1AssetsPaginatedGetDirection,
) {
  return apiV1AssetsPaginatedGetDirection?.map((e) => e.value!).join(',') ?? '';
}

List<String> apiV1AssetsPaginatedGetDirectionListToJson(
  List<enums.ApiV1AssetsPaginatedGetDirection>?
  apiV1AssetsPaginatedGetDirection,
) {
  if (apiV1AssetsPaginatedGetDirection == null) {
    return [];
  }

  return apiV1AssetsPaginatedGetDirection.map((e) => e.value!).toList();
}

List<enums.ApiV1AssetsPaginatedGetDirection>
apiV1AssetsPaginatedGetDirectionListFromJson(
  List? apiV1AssetsPaginatedGetDirection, [
  List<enums.ApiV1AssetsPaginatedGetDirection>? defaultValue,
]) {
  if (apiV1AssetsPaginatedGetDirection == null) {
    return defaultValue ?? [];
  }

  return apiV1AssetsPaginatedGetDirection
      .map((e) => apiV1AssetsPaginatedGetDirectionFromJson(e.toString()))
      .toList();
}

List<enums.ApiV1AssetsPaginatedGetDirection>?
apiV1AssetsPaginatedGetDirectionNullableListFromJson(
  List? apiV1AssetsPaginatedGetDirection, [
  List<enums.ApiV1AssetsPaginatedGetDirection>? defaultValue,
]) {
  if (apiV1AssetsPaginatedGetDirection == null) {
    return defaultValue;
  }

  return apiV1AssetsPaginatedGetDirection
      .map((e) => apiV1AssetsPaginatedGetDirectionFromJson(e.toString()))
      .toList();
}

typedef $JsonFactory<T> = T Function(Map<String, dynamic> json);

class $CustomJsonDecoder {
  $CustomJsonDecoder(this.factories);

  final Map<Type, $JsonFactory> factories;

  dynamic decode<T>(dynamic entity) {
    if (entity is Iterable) {
      return _decodeList<T>(entity);
    }

    if (entity is T) {
      return entity;
    }

    if (isTypeOf<T, Map>()) {
      return entity;
    }

    if (isTypeOf<T, Iterable>()) {
      return entity;
    }

    if (entity is Map<String, dynamic>) {
      return _decodeMap<T>(entity);
    }

    return entity;
  }

  T _decodeMap<T>(Map<String, dynamic> values) {
    final jsonFactory = factories[T];
    if (jsonFactory == null || jsonFactory is! $JsonFactory<T>) {
      return throw "Could not find factory for type $T. Is '$T: $T.fromJsonFactory' included in the CustomJsonDecoder instance creation in bootstrapper.dart?";
    }

    return jsonFactory(values);
  }

  List<T> _decodeList<T>(Iterable values) =>
      values.where((v) => v != null).map<T>((v) => decode<T>(v) as T).toList();
}

class $JsonSerializableConverter extends chopper.JsonConverter {
  @override
  FutureOr<chopper.Response<ResultType>> convertResponse<ResultType, Item>(
    chopper.Response response,
  ) async {
    if (response.bodyString.isEmpty) {
      // In rare cases, when let's say 204 (no content) is returned -
      // we cannot decode the missing json with the result type specified
      return chopper.Response(response.base, null, error: response.error);
    }

    if (ResultType == String) {
      return response.copyWith();
    }

    if (ResultType == DateTime) {
      return response.copyWith(
        body:
            DateTime.parse((response.body as String).replaceAll('"', ''))
                as ResultType,
      );
    }

    final jsonRes = await super.convertResponse(response);
    return jsonRes.copyWith<ResultType>(
      body: $jsonDecoder.decode<Item>(jsonRes.body) as ResultType,
    );
  }
}

final $jsonDecoder = $CustomJsonDecoder(generatedMapping);

// ignore: unused_element
String? _dateToJson(DateTime? date) {
  if (date == null) {
    return null;
  }

  final year = date.year.toString();
  final month = date.month < 10 ? '0${date.month}' : date.month.toString();
  final day = date.day < 10 ? '0${date.day}' : date.day.toString();

  return '$year-$month-$day';
}

class Wrapped<T> {
  final T value;
  const Wrapped.value(this.value);
}
