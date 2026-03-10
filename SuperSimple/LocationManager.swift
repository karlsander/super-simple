import CoreLocation

struct City: Identifiable, Hashable {
    let name: String
    let latitude: Double
    let longitude: Double
    var id: String { name }

    static let all: [City] = [
        City(name: "Berlin", latitude: 52.52, longitude: 13.405),
        City(name: "München", latitude: 48.1351, longitude: 11.582),
        City(name: "Hamburg", latitude: 53.5511, longitude: 9.9937),
        City(name: "Köln", latitude: 50.9375, longitude: 6.9603),
        City(name: "Frankfurt", latitude: 50.1109, longitude: 8.6821),
        City(name: "Stuttgart", latitude: 48.7758, longitude: 9.1829),
        City(name: "Düsseldorf", latitude: 51.2277, longitude: 6.7735),
        City(name: "Leipzig", latitude: 51.3397, longitude: 12.3731),
        City(name: "Dortmund", latitude: 51.5136, longitude: 7.4653),
        City(name: "Dresden", latitude: 51.0504, longitude: 13.7373),
        City(name: "Nürnberg", latitude: 49.4521, longitude: 11.0767),
        City(name: "Hannover", latitude: 52.3759, longitude: 9.732),
        City(name: "Bremen", latitude: 53.0793, longitude: 8.8017),
        City(name: "Freiburg", latitude: 47.999, longitude: 7.842),
    ]
}

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()

    var userLocation: CLLocation?
    var cityName: String = "Berlin"

    /// When set, overrides user location for API calls
    var selectedCity: City? {
        didSet {
            if let city = selectedCity {
                cityName = city.name
                UserDefaults.standard.set(city.name, forKey: "selectedCity")
            } else {
                UserDefaults.standard.removeObject(forKey: "selectedCity")
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
        // Restore persisted city selection
        if let saved = UserDefaults.standard.string(forKey: "selectedCity"),
           let city = City.all.first(where: { $0.name == saved }) {
            selectedCity = city
            cityName = city.name
        }
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
        manager.stopUpdatingLocation()
        if selectedCity == nil, let loc = locations.last {
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
        if let city = selectedCity {
            return KinoAPIClient.Location(latitude: city.latitude, longitude: city.longitude, radius: 10)
        }
        guard let loc = userLocation else { return nil }
        return KinoAPIClient.Location(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude, radius: 10)
    }

    private func reverseGeocode(_ location: CLLocation) {
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            if let city = placemarks?.first?.locality {
                self?.cityName = city
            }
        }
    }
}
