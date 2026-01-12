#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(ReverseGeocode, NSObject)

RCT_EXTERN_METHOD(
  reverseGeocodeLocation:(NSNumber *)longitude
  withLatitude:(NSNumber *)latitude
  withResolver:(RCTPromiseResolveBlock)resolve
  withRejecter:(RCTPromiseRejectBlock)reject
)

@end
