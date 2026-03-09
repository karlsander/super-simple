import CoreLocation

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()

    var userLocation: CLLocation?

    private let manager = CLLocationManager()

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
        manager.stopUpdatingLocation()
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
        guard let loc = userLocation else { return nil }
        return KinoAPIClient.Location(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude, radius: 10)
    }
}
