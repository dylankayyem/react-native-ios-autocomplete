import CoreLocation
import Foundation
import MapKit
import React

@objc(ReverseGeocode)
class ReverseGeocode: NSObject {
    lazy var geocoder = CLGeocoder()

    @objc(reverseGeocodeLocation:withLatitude:withResolver:withRejecter:)
    func reverseGeocodeLocation(
        longitude: NSNumber,
        latitude: NSNumber,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        let location = CLLocation(
            latitude: latitude.doubleValue,
            longitude: longitude.doubleValue
        )

        geocoder.reverseGeocodeLocation(
            location,
            preferredLocale: Locale(identifier: "en_US")
        ) { placemarks, error in
            if let error = error {
                reject("reverse_geocode", error.localizedDescription, error)
                return
            }

            guard let pm = placemarks?.first else {
                resolve([:])
                return
            }

            let addressDetails: [String: Any] = [
                "street": pm.thoroughfare as Any,
                "house": pm.subThoroughfare as Any,
                "city": pm.locality as Any,
                "country": pm.country as Any,
                "zip": pm.postalCode as Any
            ]

            resolve(addressDetails)
        }
    }

    @objc static func requiresMainQueueSetup() -> Bool {
        return false
    }
}
