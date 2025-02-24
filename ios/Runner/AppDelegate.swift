import Flutter
import UIKit
import GoogleMaps // Google Maps SDK'sını ekleyin

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps API anahtarını burada sağlayın
    GMSServices.provideAPIKey("AIzaSyCJ1LSqoi3NmgYLE0kXzKm698-ODaI9Nk8")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}