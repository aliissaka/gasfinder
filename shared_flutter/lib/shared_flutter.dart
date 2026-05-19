/// Shared widgets, API client, and design system for Gas Finder Flutter apps.
library;

export 'src/design/colors.dart';
export 'src/design/widgets/big_button.dart';
export 'src/design/widgets/brand_logo.dart';
export 'src/design/widgets/upgrade_required_screen.dart';

export 'src/api/api_client.dart';
export 'src/api/api_exception.dart';
export 'src/api/auth_api.dart';
export 'src/api/version_api.dart';
export 'src/api/brands_api.dart';
export 'src/api/stock_api.dart';
export 'src/api/retailers_api.dart';
export 'src/api/sync_api.dart';
export 'src/api/models/auth_response.dart';
export 'src/api/models/login_request.dart';
export 'src/api/models/register_retailer_request.dart';
export 'src/api/models/app_version_response.dart';
export 'src/api/models/brand_dto.dart';
export 'src/api/models/stock_item_dto.dart';
export 'src/api/models/stock_update_request.dart';
export 'src/api/models/stock_update_batch_request.dart';
export 'src/api/models/stock_update_result.dart';
export 'src/api/models/stock_update_batch_response.dart';
export 'src/api/models/retailer_list_item.dart';
export 'src/api/models/retailer_detail.dart';
export 'src/api/models/brand_sync_response.dart';
export 'src/api/models/retailer_sync_response.dart';

export 'src/auth/number_pad.dart';
export 'src/auth/phone_input_screen.dart';
export 'src/auth/pin_input_screen.dart';
export 'src/auth/auth_storage.dart';
export 'src/auth/auth_session.dart';
export 'src/auth/login_flow.dart';
