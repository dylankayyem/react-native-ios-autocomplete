#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(AddressAutocomplete, NSObject)

RCT_EXTERN_METHOD(getAddressSuggestions:(NSString *)address
    withResolver:(RCTPromiseResolveBlock)resolve
    withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getAddressDetails:(NSString *)address
    withResolver:(RCTPromiseResolveBlock)resolve
    withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(searchNearby:(NSString *)query
    withLatitude:(NSNumber *)latitude
    withLongitude:(NSNumber *)longitude
    withRadiusMeters:(NSNumber *)radiusMeters
    withMaxResults:(NSNumber *)maxResults
    withResolver:(RCTPromiseResolveBlock)resolve
    withRejecter:(RCTPromiseRejectBlock)reject)

@end
