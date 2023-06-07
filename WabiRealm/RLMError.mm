////////////////////////////////////////////////////////////////////////////
//
// Copyright 2022 WabiRealm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMError_Private.hpp"

#import "RLMSyncSession_Private.hpp"
#import "RLMUtil.hpp"

#import <wabi-realm/object-store/sync/app.hpp>
#import <wabi-realm/sync/client.hpp>
#import <wabi-realm/util/basic_system_errors.hpp>

NSString *const RLMErrorDomain = @"io.realm";
NSString *const RLMUnknownSystemErrorDomain = @"io.realm.unknown";
NSString *const RLMSyncErrorDomain = @"io.realm.sync";
NSString *const RLMSyncAuthErrorDomain = @"io.realm.sync.auth";
NSString *const RLMAppErrorDomain = @"io.realm.app";

NSString *const kRLMSyncPathOfRealmBackupCopyKey =
    @"recovered_realm_location_path";
NSString *const kRLMSyncErrorActionTokenKey = @"error_action_token";
NSString *const RLMErrorCodeKey = @"Error Code";
NSString *const RLMErrorCodeNameKey = @"Error Name";
NSString *const RLMServerLogURLKey = @"Server Log URL";
NSString *const RLMCompensatingWriteInfoKey = @"Compensating Write Info";
NSString *const RLMHTTPStatusCodeKey = @"HTTP Status Code";
static NSString *const RLMDeprecatedErrorCodeKey = @"Error Code";

namespace {
NSInteger translateFileError(wabi_realm::ErrorCodes::Error code) {
  using ec = wabi_realm::ErrorCodes::Error;
  switch (code) {
  case ec::AddressSpaceExhausted:
    return RLMErrorAddressSpaceExhausted;
  case ec::DeleteOnOpenRealm:
    return RLMErrorAlreadyOpen;
  case ec::FileAlreadyExists:
    return RLMErrorFileExists;
  case ec::FileFormatUpgradeRequired:
    return RLMErrorFileFormatUpgradeRequired;
  case ec::FileNotFound:
    return RLMErrorFileNotFound;
  case ec::FileOperationFailed:
    return RLMErrorFileOperationFailed;
  case ec::IncompatibleHistories:
    return RLMErrorIncompatibleHistories;
  case ec::IncompatibleLockFile:
    return RLMErrorIncompatibleLockFile;
  case ec::IncompatibleSession:
    return RLMErrorIncompatibleSession;
  case ec::InvalidDatabase:
    return RLMErrorInvalidDatabase;
  case ec::MultipleSyncAgents:
    return RLMErrorMultipleSyncAgents;
  case ec::NoSubscriptionForWrite:
    return RLMErrorNoSubscriptionForWrite;
  case ec::OutOfDiskSpace:
    return RLMErrorOutOfDiskSpace;
  case ec::PermissionDenied:
    return RLMErrorFilePermissionDenied;
  case ec::SchemaMismatch:
    return RLMErrorSchemaMismatch;
  case ec::SubscriptionFailed:
    return RLMErrorSubscriptionFailed;
  case ec::UnsupportedFileFormatVersion:
    return RLMErrorUnsupportedFileFormatVersion;

  case ec::APIKeyAlreadyExists:
    return RLMAppErrorAPIKeyAlreadyExists;
  case ec::AccountNameInUse:
    return RLMAppErrorAccountNameInUse;
  case ec::AppUnknownError:
    return RLMAppErrorUnknown;
  case ec::AuthError:
    return RLMAppErrorAuthError;
  case ec::AuthProviderNotFound:
    return RLMAppErrorAuthProviderNotFound;
  case ec::DomainNotAllowed:
    return RLMAppErrorDomainNotAllowed;
  case ec::ExecutionTimeLimitExceeded:
    return RLMAppErrorExecutionTimeLimitExceeded;
  case ec::FunctionExecutionError:
    return RLMAppErrorFunctionExecutionError;
  case ec::FunctionInvalid:
    return RLMAppErrorFunctionInvalid;
  case ec::FunctionNotFound:
    return RLMAppErrorFunctionNotFound;
  case ec::FunctionSyntaxError:
    return RLMAppErrorFunctionSyntaxError;
  case ec::InvalidPassword:
    return RLMAppErrorInvalidPassword;
  case ec::InvalidSession:
    return RLMAppErrorInvalidSession;
  case ec::MaintenanceInProgress:
    return RLMAppErrorMaintenanceInProgress;
  case ec::MissingParameter:
    return RLMAppErrorMissingParameter;
  case ec::MongoDBError:
    return RLMAppErrorMongoDBError;
  case ec::NotCallable:
    return RLMAppErrorNotCallable;
  case ec::ReadSizeLimitExceeded:
    return RLMAppErrorReadSizeLimitExceeded;
  case ec::UserAlreadyConfirmed:
    return RLMAppErrorUserAlreadyConfirmed;
  case ec::UserAppDomainMismatch:
    return RLMAppErrorUserAppDomainMismatch;
  case ec::UserDisabled:
    return RLMAppErrorUserDisabled;
  case ec::UserNotFound:
    return RLMAppErrorUserNotFound;
  case ec::ValueAlreadyExists:
    return RLMAppErrorValueAlreadyExists;
  case ec::ValueDuplicateName:
    return RLMAppErrorValueDuplicateName;
  case ec::ValueNotFound:
    return RLMAppErrorValueNotFound;

  case ec::AWSError:
  case ec::GCMError:
  case ec::HTTPError:
  case ec::InternalServerError:
  case ec::TwilioError:
    return RLMAppErrorInternalServerError;

  case ec::ArgumentsNotAllowed:
  case ec::BadRequest:
  case ec::InvalidParameter:
    return RLMAppErrorBadRequest;

  default: {
    auto category = wabi_realm::ErrorCodes::error_categories(code);
    if (category.test(wabi_realm::ErrorCategory::file_access)) {
      return RLMErrorFileAccess;
    }
    if (category.test(wabi_realm::ErrorCategory::app_error)) {
      return RLMAppErrorUnknown;
    }
    return RLMErrorFail;
  }
  }
}

NSString *errorDomain(wabi_realm::ErrorCodes::Error error) {
  auto category = wabi_realm::ErrorCodes::error_categories(error);
  if (category.test(wabi_realm::ErrorCategory::app_error)) {
    return RLMAppErrorDomain;
  }
  return RLMErrorDomain;
}

NSString *errorString(wabi_realm::ErrorCodes::Error error) {
  return RLMStringViewToNSString(wabi_realm::ErrorCodes::error_string(error));
}

NSError *translateSystemError(std::error_code ec, const char *msg) {
  int code = ec.value();
  BOOL isGenericCategoryError =
      ec.category() == std::generic_category() ||
      ec.category() == wabi_realm::util::error::basic_system_error_category();
  NSString *errorDomain =
      isGenericCategoryError ? NSPOSIXErrorDomain : RLMUnknownSystemErrorDomain;

  NSMutableDictionary *userInfo = [NSMutableDictionary new];
  userInfo[NSLocalizedDescriptionKey] = @(msg);
  // FIXME: remove these in v11
  userInfo[@"Error Code"] = @(code);
  userInfo[@"Category"] = @(ec.category().name());

#if REALM_ENABLE_SYNC
  if (ec.category() == wabi_realm::sync::client_error_category()) {
    if (code ==
        static_cast<int>(wabi_realm::sync::Client::Error::connect_timeout)) {
      errorDomain = NSPOSIXErrorDomain;
      code = ETIMEDOUT;
    } else {
      errorDomain = RLMSyncErrorDomain;
    }
  }
#endif

  return [NSError errorWithDomain:errorDomain code:code userInfo:userInfo.copy];
}
} // anonymous namespace

NSError *makeError(wabi_realm::Status const &status) {
  if (status.is_ok()) {
    return nil;
  }
  auto code = translateFileError(status.code());
  return
      [NSError errorWithDomain:errorDomain(status.code())
                          code:code
                      userInfo:@{
                        NSLocalizedDescriptionKey : @(status.reason().c_str()),
                        RLMDeprecatedErrorCodeKey : @(code),
                        RLMErrorCodeNameKey : errorString(status.code())
                      }];
}

NSError *makeError(wabi_realm::Exception const &exception) {
  auto status = exception.to_status();
  if (status.code() == wabi_realm::ErrorCodes::SystemError &&
      status.get_std_error_code() != std::error_code{}) {
    return translateSystemError(status.get_std_error_code(), exception.what());
  }

  NSInteger code = translateFileError(exception.code());
  return [NSError errorWithDomain:errorDomain(status.code())
                             code:code
                         userInfo:@{
                           NSLocalizedDescriptionKey : @(exception.what()),
                           RLMDeprecatedErrorCodeKey : @(code),
                           RLMErrorCodeNameKey : errorString(exception.code())
                         }];
}

NSError *makeError(wabi_realm::FileAccessError const &exception) {
  NSInteger code = translateFileError(exception.code());
  return [NSError errorWithDomain:errorDomain(exception.code())
                             code:code
                         userInfo:@{
                           NSLocalizedDescriptionKey : @(exception.what()),
                           NSFilePathErrorKey : @(exception.get_path().data()),
                           RLMDeprecatedErrorCodeKey : @(code),
                           RLMErrorCodeNameKey : errorString(exception.code())
                         }];
}

NSError *makeError(std::exception const &exception) {
  return [NSError errorWithDomain:RLMErrorDomain
                             code:RLMErrorFail
                         userInfo:@{
                           NSLocalizedDescriptionKey : @(exception.what())
                         }];
}

NSError *makeError(std::system_error const &exception) {
  return translateSystemError(exception.code(), exception.what());
}

__attribute__((objc_direct_members))
@implementation RLMCompensatingWriteInfo {
  wabi_realm::sync::CompensatingWriteErrorInfo _info;
}

- (instancetype)initWithInfo:
    (wabi_realm::sync::CompensatingWriteErrorInfo &&)info {
  if ((self = [super init])) {
    _info = std::move(info);
  }
  return self;
}

- (NSString *)objectType {
  return @(_info.object_name.c_str());
}

- (NSString *)reason {
  return @(_info.reason.c_str());
}

- (id<RLMValue>)primaryKey {
  return RLMMixedToObjc(_info.primary_key);
}
@end

NSError *makeError(wabi_realm::SyncError &&error) {
  auto &status = error.to_status();
  if (status.is_ok()) {
    return nil;
  }

  NSMutableDictionary *userInfo = [NSMutableDictionary new];
  userInfo[NSLocalizedDescriptionKey] =
      RLMStringViewToNSString(error.simple_message);
  if (!error.logURL.empty()) {
    userInfo[RLMServerLogURLKey] = RLMStringViewToNSString(error.logURL);
  }
  if (!error.compensating_writes_info.empty()) {
    NSMutableArray *array = [[NSMutableArray alloc]
        initWithCapacity:error.compensating_writes_info.size()];
    for (auto &info : error.compensating_writes_info) {
      [array addObject:[[RLMCompensatingWriteInfo alloc]
                           initWithInfo:std::move(info)]];
    }
    userInfo[RLMCompensatingWriteInfoKey] = [array copy];
  }
  for (auto &pair : error.user_info) {
    if (pair.first == wabi_realm::SyncError::c_original_file_path_key) {
      userInfo[kRLMSyncErrorActionTokenKey] =
          [[RLMSyncErrorActionToken alloc] initWithOriginalPath:pair.second];
    } else if (pair.first == wabi_realm::SyncError::c_recovery_file_path_key) {
      userInfo[kRLMSyncPathOfRealmBackupCopyKey] = @(pair.second.c_str());
    }
  }

  RLMSyncError errorCode = RLMSyncErrorClientInternalError;
  if (error.is_client_reset_requested())
    errorCode = RLMSyncErrorClientResetError;
  else if (error.is_session_level_protocol_error()) {
    using enum wabi_realm::sync::ProtocolError;
    switch (static_cast<wabi_realm::sync::ProtocolError>(
        error.to_status().get_std_error_code().value())) {
    case permission_denied:
      errorCode = RLMSyncErrorPermissionDeniedError;
      break;
    case bad_authentication:
      errorCode = RLMSyncErrorClientUserError;
      break;
    case compensating_write:
      errorCode = RLMSyncErrorWriteRejected;
      break;
    default:
      errorCode = RLMSyncErrorClientSessionError;
    }
  } else if (!error.is_fatal) {
    return nil;
  }

  return [NSError errorWithDomain:RLMSyncErrorDomain
                             code:errorCode
                         userInfo:userInfo.copy];
}

NSError *makeError(wabi_realm::app::AppError const &appError) {
  auto &status = appError.to_status();
  if (status.is_ok()) {
    return nil;
  }

  auto code = translateFileError(status.code());
  return [NSError
      errorWithDomain:errorDomain(status.code())
                 code:code
             userInfo:@{
               NSLocalizedDescriptionKey : @(status.reason().c_str()),
               RLMDeprecatedErrorCodeKey : @(code),
               RLMErrorCodeNameKey : errorString(status.code()),
               RLMServerLogURLKey : @(appError.link_to_server_logs.c_str())
             }];
}