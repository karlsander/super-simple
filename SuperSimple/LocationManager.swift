import CoreLocation

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()

    var userLocation: CLLocation?
    var cityName: String = "Berlin"

    /// When set, overrides user location for API calls
    var selectedLocation: CLLocation? {
        didSet {
            if let loc = selectedLocation {
                UserDefaults.standard.set(loc.coordinate.latitude, forKey: "selectedLat")
                UserDefaults.standard.set(loc.coordinate.longitude, forKey: "selectedLon")
            } else {
                UserDefaults.standard.removeObject(forKey: "selectedLat")
                UserDefaults.standard.removeObject(forKey: "selectedLon")
                UserDefaults.standard.removeObject(forKey: "selectedCityName")
                // Re-geocode from user location
                if let loc = userLocation {
                    reverseGeocode(loc)
                }
            }
        }
    }

    private let manager = CLLocationManager()

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        // Restore persisted location selection
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "selectedLat") != nil {
            let lat = defaults.double(forKey: "selectedLat")
            let lon = defaults.double(forKey: "selectedLon")
            selectedLocation = CLLocation(latitude: lat, longitude: lon)
            if let name = defaults.string(forKey: "selectedCityName") {
                cityName = name
            }
        }
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
        manager.stopUpdatingLocation()
        if selectedLocation == nil, let loc = locations.last {
            reverseGeocode(loc)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}

    func distance(to latitude: Double, longitude: Double) -> Double? {
        guard let user = userLocation else { return nil }
        let cinema = CLLocation(latitude: latitude, longitude: longitude)
        return user.distance(from: cinema)
    }

    func formattedDistance(to latitude: Double, longitude: Double) -> String? {
        guard let meters = distance(to: latitude, longitude: longitude) else { return nil }
        if meters < 1000 {
            return "\(Int(meters)) m"
        }
        return String(format: "%.1f km", meters / 1000)
    }

    var apiLocation: KinoAPIClient.Location? {
        if let loc = selectedLocation {
            return KinoAPIClient.Location(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude, radius: 10)
        }
        guard let loc = userLocation else { return nil }
        return KinoAPIClient.Location(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude, radius: 10)
    }

    func selectLocation(coordinate: CLLocationCoordinate2D, name: String) {
        selectedLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        cityName = name
        UserDefaults.standard.set(name, forKey: "selectedCityName")
    }

    func clearSelectedLocation() {
        selectedLocation = nil
    }

    private func reverseGeocode(_ location: CLLocation) {
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            if let city = placemarks?.first?.locality {
                self?.cityName = city
            }
        }
    }
}
