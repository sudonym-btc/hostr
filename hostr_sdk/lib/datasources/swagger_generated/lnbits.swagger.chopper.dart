// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'lnbits.swagger.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$Lnbits extends Lnbits {
  _$Lnbits([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = Lnbits;

  @override
  Future<Response<User>> _apiV1AuthGet({
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/auth');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<User, User>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1AuthPost({
    required LoginUsernamePassword? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/auth');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1AuthNostrPost({
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
  }) {
    final Uri $url = Uri.parse('/api/v1/auth/nostr');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1AuthUsrPost({
    required LoginUsr? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/auth/usr');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<UserAcls>> _apiV1AuthAclGet({
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/auth/acl');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<UserAcls, UserAcls>($request);
  }

  @override
  Future<Response<UserAcls>> _apiV1AuthAclPut({
    String? usr,
    required UpdateAccessControlList? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/auth/acl');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<UserAcls, UserAcls>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1AuthAclDelete({
    String? usr,
    required DeleteAccessControlList? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/auth/acl');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final $body = body;
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<UserAcls>> _apiV1AuthAclPatch({
    String? usr,
    required UpdateAccessControlList? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/auth/acl');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<UserAcls, UserAcls>($request);
  }

  @override
  Future<Response<ApiTokenResponse>> _apiV1AuthAclTokenPost({
    String? usr,
    required ApiTokenRequest? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/auth/acl/token');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<ApiTokenResponse, ApiTokenResponse>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1AuthAclTokenDelete({
    String? usr,
    required DeleteTokenRequest? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/auth/acl/token');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final $body = body;
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1AuthProviderGet({
    required String? provider,
    String? userId,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/auth/${provider}');
    final Map<String, dynamic> $params = <String, dynamic>{'user_id': userId};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1AuthProviderTokenGet({
    required String? provider,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/auth/${provider}/token');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1AuthLogoutPost({
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
  }) {
    final Uri $url = Uri.parse('/api/v1/auth/logout');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1AuthRegisterPost({
    required RegisterUser? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/auth/register');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<User>> _apiV1AuthPubkeyPut({
    String? usr,
    required UpdateUserPubkey? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/auth/pubkey');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<User, User>($request);
  }

  @override
  Future<Response<User>> _apiV1AuthPasswordPut({
    String? usr,
    required UpdateUserPassword? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/auth/password');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<User, User>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1AuthResetPut({
    required ResetUserPassword? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/auth/reset');
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<User>> _apiV1AuthUpdatePut({
    String? usr,
    required UpdateUser? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/auth/update');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<User, User>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1AuthFirstInstallPut({
    required UpdateSuperuserPassword? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/auth/first_install');
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _adminApiV1AuditGet({
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/admin/api/v1/audit');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _adminApiV1MonitorGet({
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/admin/api/v1/monitor');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _adminApiV1TestemailGet({
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/admin/api/v1/testemail');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<AdminSettings>> _adminApiV1SettingsGet({
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/admin/api/v1/settings');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<AdminSettings, AdminSettings>($request);
  }

  @override
  Future<Response<dynamic>> _adminApiV1SettingsPut({
    String? usr,
    required UpdateSettings? body,
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
  }) {
    final Uri $url = Uri.parse('/admin/api/v1/settings');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _adminApiV1SettingsDelete({
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/admin/api/v1/settings');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _adminApiV1SettingsPatch({
    String? usr,
    required Object? body,
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
  }) {
    final Uri $url = Uri.parse('/admin/api/v1/settings');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _adminApiV1SettingsDefaultGet({
    required String? fieldName,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/admin/api/v1/settings/default');
    final Map<String, dynamic> $params = <String, dynamic>{
      'field_name': fieldName,
      'usr': usr,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<Object>> _adminApiV1RestartGet({
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/admin/api/v1/restart');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<dynamic>> _adminApiV1BackupGet({
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/admin/api/v1/backup');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _nodeApiV1OkGet({
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/node/api/v1/ok');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<NodeInfoResponse>> _nodeApiV1InfoGet({
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/node/api/v1/info');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<NodeInfoResponse, NodeInfoResponse>($request);
  }

  @override
  Future<Response<List<NodeChannel>>> _nodeApiV1ChannelsGet({
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/node/api/v1/channels');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<List<NodeChannel>, NodeChannel>($request);
  }

  @override
  Future<Response<ChannelPoint>> _nodeApiV1ChannelsPost({
    String? usr,
    required BodyApiCreateChannelNodeApiV1ChannelsPost? body,
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
  }) {
    final Uri $url = Uri.parse('/node/api/v1/channels');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<ChannelPoint, ChannelPoint>($request);
  }

  @override
  Future<Response<List<NodeChannel>>> _nodeApiV1ChannelsDelete({
    required String? shortId,
    required String? fundingTxid,
    required int? outputIndex,
    bool? force,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/node/api/v1/channels');
    final Map<String, dynamic> $params = <String, dynamic>{
      'short_id': shortId,
      'funding_txid': fundingTxid,
      'output_index': outputIndex,
      'force': force,
      'usr': usr,
    };
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<List<NodeChannel>, NodeChannel>($request);
  }

  @override
  Future<Response<NodeChannel>> _nodeApiV1ChannelsChannelIdGet({
    required String? channelId,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/node/api/v1/channels/${channelId}');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<NodeChannel, NodeChannel>($request);
  }

  @override
  Future<Response<dynamic>> _nodeApiV1ChannelsChannelIdPut({
    required String? channelId,
    String? usr,
    required BodyApiSetChannelFeesNodeApiV1ChannelsChannelIdPut? body,
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
  }) {
    final Uri $url = Uri.parse('/node/api/v1/channels/${channelId}');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<Page>> _nodeApiV1PaymentsGet({
    String? usr,
    int? limit,
    int? offset,
    String? sortby,
    String? direction,
    String? search,
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
  }) {
    final Uri $url = Uri.parse('/node/api/v1/payments');
    final Map<String, dynamic> $params = <String, dynamic>{
      'usr': usr,
      'limit': limit,
      'offset': offset,
      'sortby': sortby,
      'direction': direction,
      'search': search,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<Page, Page>($request);
  }

  @override
  Future<Response<Page>> _nodeApiV1InvoicesGet({
    String? usr,
    int? limit,
    int? offset,
    String? sortby,
    String? direction,
    String? search,
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
  }) {
    final Uri $url = Uri.parse('/node/api/v1/invoices');
    final Map<String, dynamic> $params = <String, dynamic>{
      'usr': usr,
      'limit': limit,
      'offset': offset,
      'sortby': sortby,
      'direction': direction,
      'search': search,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<Page, Page>($request);
  }

  @override
  Future<Response<List<NodePeerInfo>>> _nodeApiV1PeersGet({
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/node/api/v1/peers');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<List<NodePeerInfo>, NodePeerInfo>($request);
  }

  @override
  Future<Response<dynamic>> _nodeApiV1PeersPost({
    String? usr,
    required BodyApiConnectPeerNodeApiV1PeersPost? body,
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
  }) {
    final Uri $url = Uri.parse('/node/api/v1/peers');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<NodeRank>> _nodeApiV1RankGet({
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/node/api/v1/rank');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<NodeRank, NodeRank>($request);
  }

  @override
  Future<Response<List<Extension>>> _apiV1ExtensionGet({
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/extension');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<List<Extension>, Extension>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1ExtensionPost({
    String? usr,
    required CreateExtension? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/extension');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1ExtensionExtIdDetailsGet({
    required String? extId,
    required String? detailsLink,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/extension/${extId}/details');
    final Map<String, dynamic> $params = <String, dynamic>{
      'details_link': detailsLink,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<SimpleStatus>> _apiV1ExtensionExtIdSellPut({
    required String? extId,
    String? usr,
    required PayToEnableInfo? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/extension/${extId}/sell');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<SimpleStatus, SimpleStatus>($request);
  }

  @override
  Future<Response<SimpleStatus>> _apiV1ExtensionExtIdEnablePut({
    required String? extId,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/extension/${extId}/enable');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<SimpleStatus, SimpleStatus>($request);
  }

  @override
  Future<Response<SimpleStatus>> _apiV1ExtensionExtIdDisablePut({
    required String? extId,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/extension/${extId}/disable');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<SimpleStatus, SimpleStatus>($request);
  }

  @override
  Future<Response<SimpleStatus>> _apiV1ExtensionExtIdActivatePut({
    required String? extId,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/extension/${extId}/activate');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<SimpleStatus, SimpleStatus>($request);
  }

  @override
  Future<Response<SimpleStatus>> _apiV1ExtensionExtIdDeactivatePut({
    required String? extId,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/extension/${extId}/deactivate');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<SimpleStatus, SimpleStatus>($request);
  }

  @override
  Future<Response<SimpleStatus>> _apiV1ExtensionExtIdDelete({
    required String? extId,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/extension/${extId}');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<SimpleStatus, SimpleStatus>($request);
  }

  @override
  Future<Response<List<ExtensionRelease>>> _apiV1ExtensionExtIdReleasesGet({
    required String? extId,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/extension/${extId}/releases');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<List<ExtensionRelease>, ExtensionRelease>($request);
  }

  @override
  Future<Response<ReleasePaymentInfo>> _apiV1ExtensionExtIdInvoiceInstallPut({
    required String? extId,
    String? usr,
    required CreateExtension? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/extension/${extId}/invoice/install');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<ReleasePaymentInfo, ReleasePaymentInfo>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1ExtensionExtIdInvoiceEnablePut({
    required String? extId,
    String? usr,
    required PayToEnableInfo? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/extension/${extId}/invoice/enable');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1ExtensionReleaseOrgRepoTagNameGet({
    required String? org,
    required String? repo,
    required String? tagName,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse(
      '/api/v1/extension/release/${org}/${repo}/${tagName}',
    );
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1ExtensionExtIdDbDelete({
    required String? extId,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/extension/${extId}/db');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1ExtensionAllGet({
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/extension/all');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<List<ExtensionReviewsStatus>>> _apiV1ExtensionReviewsTagsGet({
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/extension/reviews/tags');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<List<ExtensionReviewsStatus>, ExtensionReviewsStatus>(
      $request,
    );
  }

  @override
  Future<Response<Page>> _apiV1ExtensionReviewsExtIdGet({
    required String? extId,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/extension/reviews/${extId}');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<Page, Page>($request);
  }

  @override
  Future<Response<ExtensionReviewPaymentRequest>> _apiV1ExtensionReviewsPut({
    String? usr,
    required CreateExtensionReview? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/extension/reviews');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client
        .send<ExtensionReviewPaymentRequest, ExtensionReviewPaymentRequest>(
          $request,
        );
  }

  @override
  Future<Response<dynamic>> _apiV1ExtensionBuilderZipPost({
    String? usr,
    required ExtensionData? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/extension/builder/zip');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<SimpleStatus>> _apiV1ExtensionBuilderDeployPost({
    String? usr,
    required ExtensionData? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/extension/builder/deploy');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<SimpleStatus, SimpleStatus>($request);
  }

  @override
  Future<Response<SimpleStatus>> _apiV1ExtensionBuilderPreviewPost({
    String? usr,
    required ExtensionData? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/extension/builder/preview');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<SimpleStatus, SimpleStatus>($request);
  }

  @override
  Future<Response<SimpleStatus>> _apiV1ExtensionBuilderDelete({
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/extension/builder');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<SimpleStatus, SimpleStatus>($request);
  }

  @override
  Future<Response<dynamic>> _nodeApiV1PeersPeerIdDelete({
    required String? peerId,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/node/api/v1/peers/${peerId}');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<PublicNodeInfo>> _nodePublicApiV1InfoGet({
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
  }) {
    final Uri $url = Uri.parse('/node/public/api/v1/info');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<PublicNodeInfo, PublicNodeInfo>($request);
  }

  @override
  Future<Response<NodeRank>> _nodePublicApiV1RankGet({
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
  }) {
    final Uri $url = Uri.parse('/node/public/api/v1/rank');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<NodeRank, NodeRank>($request);
  }

  @override
  Future<Response<List<Payment>>> _apiV1PaymentsGet({
    int? limit,
    int? offset,
    String? sortby,
    String? direction,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/payments');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      'sortby': sortby,
      'direction': direction,
      'search': search,
      'status': status,
      'tag': tag,
      'checking_id': checkingId,
      'amount': amount,
      'fee': fee,
      'memo': memo,
      'time': time,
      'preimage': preimage,
      'payment_hash': paymentHash,
      'wallet_id': walletId,
      'labels': labels,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<List<Payment>, Payment>($request);
  }

  @override
  Future<Response<Payment>> _apiV1PaymentsPost({
    required CreateInvoice? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/payments');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<Payment, Payment>($request);
  }

  @override
  Future<Response<List<PaymentHistoryPoint>>> _apiV1PaymentsHistoryGet({
    String? group,
    int? limit,
    int? offset,
    String? sortby,
    String? direction,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/payments/history');
    final Map<String, dynamic> $params = <String, dynamic>{
      'group': group,
      'limit': limit,
      'offset': offset,
      'sortby': sortby,
      'direction': direction,
      'search': search,
      'status': status,
      'tag': tag,
      'checking_id': checkingId,
      'amount': amount,
      'fee': fee,
      'memo': memo,
      'time': time,
      'preimage': preimage,
      'payment_hash': paymentHash,
      'wallet_id': walletId,
      'labels': labels,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<List<PaymentHistoryPoint>, PaymentHistoryPoint>(
      $request,
    );
  }

  @override
  Future<Response<List<PaymentCountStat>>> _apiV1PaymentsStatsCountGet({
    String? countBy,
    int? limit,
    int? offset,
    String? sortby,
    String? direction,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/payments/stats/count');
    final Map<String, dynamic> $params = <String, dynamic>{
      'count_by': countBy,
      'limit': limit,
      'offset': offset,
      'sortby': sortby,
      'direction': direction,
      'search': search,
      'usr': usr,
      'status': status,
      'tag': tag,
      'checking_id': checkingId,
      'amount': amount,
      'fee': fee,
      'memo': memo,
      'time': time,
      'preimage': preimage,
      'payment_hash': paymentHash,
      'wallet_id': walletId,
      'labels': labels,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<List<PaymentCountStat>, PaymentCountStat>($request);
  }

  @override
  Future<Response<List<PaymentWalletStats>>> _apiV1PaymentsStatsWalletsGet({
    int? limit,
    int? offset,
    String? sortby,
    String? direction,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/payments/stats/wallets');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      'sortby': sortby,
      'direction': direction,
      'search': search,
      'usr': usr,
      'status': status,
      'tag': tag,
      'checking_id': checkingId,
      'amount': amount,
      'fee': fee,
      'memo': memo,
      'time': time,
      'preimage': preimage,
      'payment_hash': paymentHash,
      'wallet_id': walletId,
      'labels': labels,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<List<PaymentWalletStats>, PaymentWalletStats>($request);
  }

  @override
  Future<Response<List<PaymentDailyStats>>> _apiV1PaymentsStatsDailyGet({
    String? usr,
    int? limit,
    int? offset,
    String? sortby,
    String? direction,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/payments/stats/daily');
    final Map<String, dynamic> $params = <String, dynamic>{
      'usr': usr,
      'limit': limit,
      'offset': offset,
      'sortby': sortby,
      'direction': direction,
      'search': search,
      'status': status,
      'tag': tag,
      'checking_id': checkingId,
      'amount': amount,
      'fee': fee,
      'memo': memo,
      'time': time,
      'preimage': preimage,
      'payment_hash': paymentHash,
      'wallet_id': walletId,
      'labels': labels,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<List<PaymentDailyStats>, PaymentDailyStats>($request);
  }

  @override
  Future<Response<Page>> _apiV1PaymentsPaginatedGet({
    bool? recheckPending,
    int? limit,
    int? offset,
    String? sortby,
    String? direction,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/payments/paginated');
    final Map<String, dynamic> $params = <String, dynamic>{
      'recheck_pending': recheckPending,
      'limit': limit,
      'offset': offset,
      'sortby': sortby,
      'direction': direction,
      'search': search,
      'status': status,
      'tag': tag,
      'checking_id': checkingId,
      'amount': amount,
      'fee': fee,
      'memo': memo,
      'time': time,
      'preimage': preimage,
      'payment_hash': paymentHash,
      'wallet_id': walletId,
      'labels': labels,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<Page, Page>($request);
  }

  @override
  Future<Response<Page>> _apiV1PaymentsAllPaginatedGet({
    int? limit,
    int? offset,
    String? sortby,
    String? direction,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/payments/all/paginated');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      'sortby': sortby,
      'direction': direction,
      'search': search,
      'usr': usr,
      'status': status,
      'tag': tag,
      'checking_id': checkingId,
      'amount': amount,
      'fee': fee,
      'memo': memo,
      'time': time,
      'preimage': preimage,
      'payment_hash': paymentHash,
      'wallet_id': walletId,
      'labels': labels,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<Page, Page>($request);
  }

  @override
  Future<Response<SimpleStatus>> _apiV1PaymentsPaymentHashLabelsPut({
    required String? paymentHash,
    required UpdatePaymentLabels? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/payments/${paymentHash}/labels');
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<SimpleStatus, SimpleStatus>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1PaymentsFeeReserveGet({
    String? invoice,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/payments/fee-reserve');
    final Map<String, dynamic> $params = <String, dynamic>{'invoice': invoice};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1PaymentsPaymentHashGet({
    required Object? paymentHash,
    String? xApiKey,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/payments/${paymentHash}');
    final Map<String, String> $headers = {
      if (xApiKey != null) 'x-api-key': xApiKey,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      headers: $headers,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1PaymentsDecodePost({
    required DecodePayment? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/payments/decode');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1PaymentsSettlePost({
    required SettleInvoice? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/payments/settle');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1PaymentsCancelPost({
    required CancelInvoice? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/payments/cancel');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<SimpleStatus>> _apiV1PaymentsPaymentRequestPayWithNfcPost({
    required String? paymentRequest,
    required CreateLnurlWithdraw? body,
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
  }) {
    final Uri $url = Uri.parse(
      '/api/v1/payments/${paymentRequest}/pay-with-nfc',
    );
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<SimpleStatus, SimpleStatus>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1WalletGet({
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
  }) {
    final Uri $url = Uri.parse('/api/v1/wallet');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<Wallet>> _apiV1WalletPost({
    String? usr,
    required CreateWallet? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/wallet');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<Wallet, Wallet>($request);
  }

  @override
  Future<Response<Wallet>> _apiV1WalletPatch({
    required BodyApiUpdateWalletApiV1WalletPatch? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/wallet');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<Wallet, Wallet>($request);
  }

  @override
  Future<Response<Page>> _apiV1WalletPaginatedGet({
    String? usr,
    int? limit,
    int? offset,
    String? sortby,
    String? direction,
    String? search,
    String? id,
    String? name,
    String? currency,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/wallet/paginated');
    final Map<String, dynamic> $params = <String, dynamic>{
      'usr': usr,
      'limit': limit,
      'offset': offset,
      'sortby': sortby,
      'direction': direction,
      'search': search,
      'id': id,
      'name': name,
      'currency': currency,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<Page, Page>($request);
  }

  @override
  Future<Response<WalletSharePermission>> _apiV1WalletShareInvitePut({
    required WalletSharePermission? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/wallet/share/invite');
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<WalletSharePermission, WalletSharePermission>($request);
  }

  @override
  Future<Response<SimpleStatus>> _apiV1WalletShareInviteShareRequestIdDelete({
    required String? shareRequestId,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/wallet/share/invite/${shareRequestId}');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<SimpleStatus, SimpleStatus>($request);
  }

  @override
  Future<Response<WalletSharePermission>> _apiV1WalletSharePut({
    required WalletSharePermission? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/wallet/share');
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<WalletSharePermission, WalletSharePermission>($request);
  }

  @override
  Future<Response<SimpleStatus>> _apiV1WalletShareShareRequestIdDelete({
    required String? shareRequestId,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/wallet/share/${shareRequestId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<SimpleStatus, SimpleStatus>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1WalletNewNamePut({
    required String? newName,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/wallet/${newName}');
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<Wallet>> _apiV1WalletResetWalletIdPut({
    required String? walletId,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/wallet/reset/${walletId}');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<Wallet, Wallet>($request);
  }

  @override
  Future<Response<List<StoredPayLink>>> _apiV1WalletStoredPaylinksWalletIdPut({
    required String? walletId,
    required StoredPayLinks? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/wallet/stored_paylinks/${walletId}');
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<List<StoredPayLink>, StoredPayLink>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1WalletWalletIdDelete({
    required String? walletId,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/wallet/${walletId}');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<Object>> _apiV1HealthGet({
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
  }) {
    final Uri $url = Uri.parse('/api/v1/health');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<Object>> _apiV1StatusGet({
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/status');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<List<Wallet>>> _apiV1WalletsGet({
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/wallets');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<List<Wallet>, Wallet>($request);
  }

  @override
  Future<Response<Wallet>> _apiV1AccountPost({
    required CreateWallet? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/account');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<Wallet, Wallet>($request);
  }

  @override
  Future<Response<List<Object>>> _apiV1RateHistoryGet({
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/rate/history');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<List<Object>, Object>($request);
  }

  @override
  Future<Response<Object>> _apiV1RateCurrencyGet({
    required String? currency,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/rate/${currency}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<List<String>>> _apiV1CurrenciesGet({
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
  }) {
    final Uri $url = Uri.parse('/api/v1/currencies');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<String>, String>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1ConversionPost({
    required ConversionData? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/conversion');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1QrcodeDataGet({
    required String? data,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/qrcode/${data}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1QrcodeGet({
    required String? data,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/qrcode');
    final Map<String, dynamic> $params = <String, dynamic>{'data': data};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1WsItemIdPost({
    required String? itemId,
    required String? data,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/ws/${itemId}');
    final Map<String, dynamic> $params = <String, dynamic>{'data': data};
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1WsItemIdDataGet({
    required String? itemId,
    required String? data,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/ws/${itemId}/${data}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<SimpleStatus>> _apiV1CallbackProviderNamePost({
    required String? providerName,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/callback/${providerName}');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<SimpleStatus, SimpleStatus>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1TinyurlPost({
    required String? url,
    bool? endless,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/tinyurl');
    final Map<String, dynamic> $params = <String, dynamic>{
      'url': url,
      'endless': endless,
    };
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1TinyurlTinyurlIdGet({
    required String? tinyurlId,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/tinyurl/${tinyurlId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1TinyurlTinyurlIdDelete({
    required String? tinyurlId,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/tinyurl/${tinyurlId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _tTinyurlIdGet({
    required String? tinyurlId,
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
  }) {
    final Uri $url = Uri.parse('/t/${tinyurlId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<WebPushSubscription>> _apiV1WebpushPost({
    String? usr,
    required CreateWebPushSubscription? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/webpush');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<WebPushSubscription, WebPushSubscription>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1WebpushDelete({
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/webpush');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<Page>> _usersApiV1UserGet({
    String? usr,
    int? limit,
    int? offset,
    String? sortby,
    String? direction,
    String? search,
    String? id,
    String? username,
    String? email,
    String? pubkey,
    String? externalId,
    String? walletId,
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
  }) {
    final Uri $url = Uri.parse('/users/api/v1/user');
    final Map<String, dynamic> $params = <String, dynamic>{
      'usr': usr,
      'limit': limit,
      'offset': offset,
      'sortby': sortby,
      'direction': direction,
      'search': search,
      'id': id,
      'username': username,
      'email': email,
      'pubkey': pubkey,
      'external_id': externalId,
      'wallet_id': walletId,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<Page, Page>($request);
  }

  @override
  Future<Response<CreateUser>> _usersApiV1UserPost({
    String? usr,
    required CreateUser? body,
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
  }) {
    final Uri $url = Uri.parse('/users/api/v1/user');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<CreateUser, CreateUser>($request);
  }

  @override
  Future<Response<User>> _usersApiV1UserUserIdGet({
    required String? userId,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/users/api/v1/user/${userId}');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<User, User>($request);
  }

  @override
  Future<Response<CreateUser>> _usersApiV1UserUserIdPut({
    required String? userId,
    String? usr,
    required CreateUser? body,
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
  }) {
    final Uri $url = Uri.parse('/users/api/v1/user/${userId}');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<CreateUser, CreateUser>($request);
  }

  @override
  Future<Response<SimpleStatus>> _usersApiV1UserUserIdDelete({
    required String? userId,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/users/api/v1/user/${userId}');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<SimpleStatus, SimpleStatus>($request);
  }

  @override
  Future<Response<String>> _usersApiV1UserUserIdResetPasswordPut({
    required String? userId,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/users/api/v1/user/${userId}/reset_password');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<String, String>($request);
  }

  @override
  Future<Response<SimpleStatus>> _usersApiV1UserUserIdAdminGet({
    required String? userId,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/users/api/v1/user/${userId}/admin');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<SimpleStatus, SimpleStatus>($request);
  }

  @override
  Future<Response<List<Wallet>>> _usersApiV1UserUserIdWalletGet({
    required String? userId,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/users/api/v1/user/${userId}/wallet');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<List<Wallet>, Wallet>($request);
  }

  @override
  Future<Response<dynamic>> _usersApiV1UserUserIdWalletPost({
    required String? userId,
    String? usr,
    required BodyCreateANewWalletForUserUsersApiV1UserUserIdWalletPost? body,
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
  }) {
    final Uri $url = Uri.parse('/users/api/v1/user/${userId}/wallet');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<SimpleStatus>> _usersApiV1UserUserIdWalletWalletUndeletePut({
    required String? userId,
    required String? wallet,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse(
      '/users/api/v1/user/${userId}/wallet/${wallet}/undelete',
    );
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<SimpleStatus, SimpleStatus>($request);
  }

  @override
  Future<Response<SimpleStatus>> _usersApiV1UserUserIdWalletsDelete({
    required String? userId,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/users/api/v1/user/${userId}/wallets');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<SimpleStatus, SimpleStatus>($request);
  }

  @override
  Future<Response<SimpleStatus>> _usersApiV1UserUserIdWalletWalletDelete({
    required String? userId,
    required String? wallet,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/users/api/v1/user/${userId}/wallet/${wallet}');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<SimpleStatus, SimpleStatus>($request);
  }

  @override
  Future<Response<SimpleStatus>> _usersApiV1BalancePut({
    String? usr,
    required UpdateBalance? body,
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
  }) {
    final Uri $url = Uri.parse('/users/api/v1/balance');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<SimpleStatus, SimpleStatus>($request);
  }

  @override
  Future<Response<Page>> _auditApiV1Get({
    String? usr,
    int? limit,
    int? offset,
    String? sortby,
    String? direction,
    String? search,
    String? ipAddress,
    String? userId,
    String? path,
    String? requestMethod,
    String? responseCode,
    String? component,
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
  }) {
    final Uri $url = Uri.parse('/audit/api/v1');
    final Map<String, dynamic> $params = <String, dynamic>{
      'usr': usr,
      'limit': limit,
      'offset': offset,
      'sortby': sortby,
      'direction': direction,
      'search': search,
      'ip_address': ipAddress,
      'user_id': userId,
      'path': path,
      'request_method': requestMethod,
      'response_code': responseCode,
      'component': component,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<Page, Page>($request);
  }

  @override
  Future<Response<AuditStats>> _auditApiV1StatsGet({
    String? usr,
    int? limit,
    int? offset,
    String? sortby,
    String? direction,
    String? search,
    String? ipAddress,
    String? userId,
    String? path,
    String? requestMethod,
    String? responseCode,
    String? component,
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
  }) {
    final Uri $url = Uri.parse('/audit/api/v1/stats');
    final Map<String, dynamic> $params = <String, dynamic>{
      'usr': usr,
      'limit': limit,
      'offset': offset,
      'sortby': sortby,
      'direction': direction,
      'search': search,
      'ip_address': ipAddress,
      'user_id': userId,
      'path': path,
      'request_method': requestMethod,
      'response_code': responseCode,
      'component': component,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<AuditStats, AuditStats>($request);
  }

  @override
  Future<Response<Page>> _apiV1AssetsPaginatedGet({
    String? usr,
    int? limit,
    int? offset,
    String? sortby,
    String? direction,
    String? search,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/assets/paginated');
    final Map<String, dynamic> $params = <String, dynamic>{
      'usr': usr,
      'limit': limit,
      'offset': offset,
      'sortby': sortby,
      'direction': direction,
      'search': search,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<Page, Page>($request);
  }

  @override
  Future<Response<AssetInfo>> _apiV1AssetsAssetIdGet({
    required String? assetId,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/assets/${assetId}');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<AssetInfo, AssetInfo>($request);
  }

  @override
  Future<Response<AssetInfo>> _apiV1AssetsAssetIdPut({
    required String? assetId,
    String? usr,
    required AssetUpdate? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/assets/${assetId}');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<AssetInfo, AssetInfo>($request);
  }

  @override
  Future<Response<SimpleStatus>> _apiV1AssetsAssetIdDelete({
    required String? assetId,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/assets/${assetId}');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<SimpleStatus, SimpleStatus>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1AssetsAssetIdBinaryGet({
    required String? assetId,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/assets/${assetId}/binary');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1AssetsAssetIdThumbnailGet({
    required String? assetId,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/assets/${assetId}/thumbnail');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<AssetInfo>> _apiV1AssetsPost({
    bool? publicAsset,
    String? usr,
    required BodyUploadApiV1AssetsPost body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/assets');
    final Map<String, dynamic> $params = <String, dynamic>{
      'public_asset': publicAsset,
      'usr': usr,
    };
    final List<PartValue> $parts = <PartValue>[
      PartValue<BodyUploadApiV1AssetsPost>('body', body),
    ];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<AssetInfo, AssetInfo>($request);
  }

  @override
  Future<Response<SimpleStatus>> _apiV1FiatCheckProviderPut({
    required String? provider,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/fiat/check/${provider}');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<SimpleStatus, SimpleStatus>($request);
  }

  @override
  Future<Response<FiatSubscriptionResponse>>
  _apiV1FiatProviderSubscriptionPost({
    required String? provider,
    required CreateFiatSubscription? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/fiat/${provider}/subscription');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<FiatSubscriptionResponse, FiatSubscriptionResponse>(
      $request,
    );
  }

  @override
  Future<Response<FiatSubscriptionResponse>>
  _apiV1FiatProviderSubscriptionSubscriptionIdDelete({
    required String? provider,
    required String? subscriptionId,
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
  }) {
    final Uri $url = Uri.parse(
      '/api/v1/fiat/${provider}/subscription/${subscriptionId}',
    );
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<FiatSubscriptionResponse, FiatSubscriptionResponse>(
      $request,
    );
  }

  @override
  Future<Response<dynamic>> _apiV1FiatProviderConnectionTokenPost({
    required String? provider,
    String? usr,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/fiat/${provider}/connection_token');
    final Map<String, dynamic> $params = <String, dynamic>{'usr': usr};
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1LnurlscanCodeGet({
    required String? code,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/lnurlscan/${code}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> _apiV1LnurlscanPost({
    required LnurlScan? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/lnurlscan');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<LnurlResponseModel>> _apiV1LnurlauthPost({
    required LnurlAuthResponse? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/lnurlauth');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<LnurlResponseModel, LnurlResponseModel>($request);
  }

  @override
  Future<Response<Payment>> _apiV1PaymentsLnurlPost({
    required CreateLnurlPayment? body,
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
  }) {
    final Uri $url = Uri.parse('/api/v1/payments/lnurl');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<Payment, Payment>($request);
  }
}
