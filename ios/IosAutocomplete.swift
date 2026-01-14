import MapKit
import Foundation
import React

@objc(AddressAutocomplete)
class AddressAutocomplete: NSObject, MKLocalSearchCompleterDelegate {

    var resolver: RCTPromiseResolveBlock?
    var rejecter: RCTPromiseRejectBlock?
    let completer: MKLocalSearchCompleter = MKLocalSearchCompleter()

    var localSearch: MKLocalSearch?

    override init() {
        super.init()
        completer.delegate = self
    }

    private func buildDetails(
        item: MKMapItem,
        boundingRegion: MKCoordinateRegion,
        fallbackTitle: String
    ) -> [String: Any] {
        let placemark = item.placemark

        let legacyTitle = placemark.title ?? item.name ?? fallbackTitle

        let legacyCoordinate: [String: Any] = [
            "latitude": placemark.coordinate.latitude,
            "longitude": placemark.coordinate.longitude
        ]

        let legacyRegion: [String: Any] = [
            "latitude": boundingRegion.center.latitude,
            "longitude": boundingRegion.center.longitude,
            "latitudeDelta": boundingRegion.span.latitudeDelta,
            "longitudeDelta": boundingRegion.span.longitudeDelta
        ]

        let locCoord: CLLocationCoordinate2D
        if #available(iOS 26.0, *) {
            locCoord = item.location.coordinate
        } else {
            locCoord = placemark.coordinate
        }

        let location: [String: Any] = [
            "latitude": locCoord.latitude,
            "longitude": locCoord.longitude
        ]

        let poiCategoryRaw = item.pointOfInterestCategory?.rawValue
        let kind = (poiCategoryRaw != nil) ? "poi" : "address"

        let addressRepresentations = item.value(forKey: "addressRepresentations") as? [String] ?? []

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
            "title": legacyTitle,
            "coordinate": legacyCoordinate,
            "region": legacyRegion,
            "location": location,
            "addressRepresentations": addressRepresentations,
            "address": structuredAddress,
            "kind": kind,
            "poiCategory": poiCategoryRaw as Any,
            "phoneNumber": item.phoneNumber as Any,
            "url": item.url?.absoluteString as Any,
            "timeZone": placemark.timeZone?.identifier as Any
        ]

        return details
    }

    private func cancelActiveSearchIfNeeded() {
        if self.localSearch?.isSearching == true {
            self.localSearch?.cancel()
        }
    }

    @objc(getAddressSuggestions:withResolver:withRejecter:)
    func getAddressSuggestions(address: String!, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            if self.completer.isSearching {
                self.completer.cancel()
            }

            self.resolver = resolve
            self.rejecter = reject
            self.completer.queryFragment = address
        }
    }

    @objc(getAddressDetails:withResolver:withRejecter:)
    func getAddressDetails(address: String!, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            self.cancelActiveSearchIfNeeded()

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

                let details = self.buildDetails(
                    item: item,
                    boundingRegion: response.boundingRegion,
                    fallbackTitle: address
                )

                resolve(details)
            }
        }
    }

    @objc(searchNearby:withLatitude:withLongitude:withRadiusMeters:withMaxResults:withResolver:withRejecter:)
    func searchNearby(
        query: String!,
        latitude: NSNumber?,
        longitude: NSNumber?,
        radiusMeters: NSNumber?,
        maxResults: NSNumber?,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        DispatchQueue.main.async {
            self.cancelActiveSearchIfNeeded()

            let q = (query ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if q.isEmpty {
                reject("address_autocomplete", "Query length should be greater than 0", nil)
                return
            }

            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = q
            request.resultTypes = [.address, .pointOfInterest]

            if let lat = latitude?.doubleValue, let lon = longitude?.doubleValue {
                let meters = radiusMeters?.doubleValue ?? 15000.0
                let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                request.region = MKCoordinateRegion(center: center, latitudinalMeters: meters, longitudinalMeters: meters)
            }

            let search = MKLocalSearch(request: request)
            self.localSearch = search

            search.start { response, error in
                if let error = error {
                    reject("address_autocomplete", "Search nearby failed", error)
                    return
                }

                guard let response = response else {
                    reject("address_autocomplete", "Unknown error", nil)
                    return
                }

                let limit = maxResults?.intValue ?? 25
                let items = Array(response.mapItems.prefix(max(1, limit)))

                let results: [[String: Any]] = items.map { item in
                    return self.buildDetails(
                        item: item,
                        boundingRegion: response.boundingRegion,
                        fallbackTitle: q
                    )
                }

                resolve(results)
            }
        }
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results.map { result in
            return (result.title + " " + result.subtitle).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        self.resolver?(results)
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        self.rejecter?("address_autocomplete", "An error occured", error)
    }

    @objc static func requiresMainQueueSetup() -> Bool {
        return false
    }
}
