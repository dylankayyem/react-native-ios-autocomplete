import MapKit
import Foundation
import React

@objc(AddressAutocomplete)
class AddressAutocomplete: NSObject, MKLocalSearchCompleterDelegate {

    var resolver: RCTPromiseResolveBlock?
    var rejecter: RCTPromiseRejectBlock?
    let completer: MKLocalSearchCompleter = MKLocalSearchCompleter();
    var searchRequest: MKLocalSearch.Request?
    var localSearch: MKLocalSearch?

    override init() {
        super.init()
        completer.delegate = self
    }
    
    @objc(getAddressSuggestions:withResolver:withRejecter:)
    func getAddressSuggestions(address: String!, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            if self.completer.isSearching {
                self.completer.cancel()
            }
            self.completer.queryFragment = address
            self.resolver = resolve
            self.rejecter = reject

            if self.completer.isSearching {
                print("Searching" + address)
            }
        }
    }

    @objc(getAddressDetails:withResolver:withRejecter:)
    func getAddressDetails(address: String!, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            if self.localSearch?.isSearching == true {
            self.localSearch?.cancel()
            }

            guard let address = address, !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            reject("address_autocomplete", "Address length should be greater than 0", nil)
            return
            }

            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = address

            let search = MKLocalSearch(request: request)
            self.localSearch = search

            search.start { response, error in
            if let error = error {
                reject("address_autocomplete", "Search failed", error)
                return
            }

            guard let response = response else {
                reject("address_autocomplete", "Unknown error", nil)
                return
            }

            guard let item = response.mapItems.first else {
                reject("address_autocomplete", "No results", nil)
                return
            }

            let placemark = item.placemark

            // Keep legacy fields for compatibility (your JS currently expects these)
            let legacyTitle = placemark.title ?? item.name ?? address
            let legacyCoordinate: [String: Any] = [
                "latitude": placemark.coordinate.latitude,
                "longitude": placemark.coordinate.longitude
            ]

            let legacyRegion: [String: Any] = [
                "latitude": response.boundingRegion.center.latitude,
                "longitude": response.boundingRegion.center.longitude,
                "latitudeDelta": response.boundingRegion.span.latitudeDelta,
                "longitudeDelta": response.boundingRegion.span.longitudeDelta
            ]

            // Preferred location source (if available)
            let locCoord = item.location?.coordinate ?? placemark.coordinate
            let location: [String: Any] = [
                "latitude": locCoord.latitude,
                "longitude": locCoord.longitude
            ]

            // POI typing (Option B)
            let poiCategoryRaw = item.pointOfInterestCategory?.rawValue
            let kind = (poiCategoryRaw != nil) ? "poi" : "address"

            // Modern addressRepresentations (safe KVC access to avoid SDK compile issues)
            // If your SDK doesn't have it, this will simply return [] instead of failing to compile.
            let addressRepresentations = item.value(forKey: "addressRepresentations") as? [String] ?? []

            // Structured address (normalized; not named "placemark" in JS)
            let structuredAddress: [String: Any] = [
                "street": placemark.thoroughfare as Any,
                "house": placemark.subThoroughfare as Any,
                "city": placemark.locality as Any,
                "region": placemark.administrativeArea as Any,
                "postalCode": placemark.postalCode as Any,
                "country": placemark.country as Any,
                "isoCountryCode": placemark.isoCountryCode as Any
            ]

            let details: [String: Any] = [
                // ✅ legacy (kept)
                "title": legacyTitle,
                "coordinate": legacyCoordinate,
                "region": legacyRegion,

                // ✅ new (added)
                "location": location,
                "addressRepresentations": addressRepresentations,
                "address": structuredAddress,

                "kind": kind,
                "poiCategory": poiCategoryRaw as Any,

                "phoneNumber": item.phoneNumber as Any,
                "url": item.url?.absoluteString as Any,
                "timeZone": placemark.timeZone?.identifier as Any
            ]

            resolve(details)
            }
        }
    }


    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results.flatMap { (result) -> String? in
            return result.title + " " + result.subtitle
        }
        print(completer.results)
        self.resolver?(results)
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        self.rejecter?("address_autocomplete", "An error occured", error)
        print(error)
    }

    @objc(multiply:withB:withResolver:withRejecter:)
    func multiply(a: Float, b: Float, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
        resolve(a*b)
    }

    @objc static func requiresMainQueueSetup() -> Bool {
        return false
    }
}
