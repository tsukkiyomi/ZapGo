import SwiftUI
import MapKit
import CoreLocation

// ChargingStation Model
struct ChargingStation: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}

// LocationManager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
        }
    }
}

// HomeView
struct HomeView: View {
    @State private var showMap = false
    @State private var showZapz = false
    @State private var showServices = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "bolt.car.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.green)
                    .padding()
                
                Text("Hoşgeldiniz! Şarj istasyonlarını keşfedin.")
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button(action: {
                    showMap = true
                }) {
                    Text("Haritaya Git")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                .fullScreenCover(isPresented: $showMap) {
                    ContentView()
                }
                
                Button(action: {
                    showZapz = true
                }) {
                    Text("Zapz")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                .fullScreenCover(isPresented: $showZapz) {
                    ZapzView()
                }
                
                Button(action: {
                    showServices = true
                }) {
                    Text("Diğer Hizmetler")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                .fullScreenCover(isPresented: $showServices) {
                    ServicesView()
                }
            }
            .padding()
            .navigationTitle("Ana Sayfa")
        }
    }
}

// ZapzView
struct ZapzView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Button("Geri Dön") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
            
            Text("Zapz İçeriği")
                .font(.title)
                .padding()
            
            Spacer()
        }
    }
}

// ServicesView
struct ServicesView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Button("Geri Dön") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
            
            Text("Diğer Hizmetler")
                .font(.title)
                .padding()
            
            Map()
                .frame(height: 300)
                .cornerRadius(10)
                .padding()
            
            SearchBar()
                .padding()
            
            Spacer()
        }
    }
}


// SearchBar
struct SearchBar: View {
    @State private var searchText = ""
    
    var body: some View {
        TextField("Ara...", text: $searchText)
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
}

//ContentView
struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    @State private var showSheet = false
    
    let chargingStations = [
        ChargingStation(name: "İstasyon 1", coordinate: CLLocationCoordinate2D(latitude: 40.002750, longitude: 28.9784)),
        ChargingStation(name: "İstasyon 2", coordinate: CLLocationCoordinate2D(latitude: 41.0150, longitude: 28.9800)),
        ChargingStation(name: "İstasyon 3", coordinate: CLLocationCoordinate2D(latitude: 41.0200, longitude: 28.9750))
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $cameraPosition) {
                UserAnnotation()
                ForEach(chargingStations) { station in
                    Annotation(station.name, coordinate: station.coordinate) {
                        VStack {
                            Image(systemName: "bolt.circle.fill")
                                .foregroundColor(.green)
                                .font(.title)
                            Text(station.name)
                                .font(.caption)
                                .foregroundColor(.black)
                                .padding(5)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(5)
                        }
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
            .onReceive(locationManager.$userLocation) { newLocation in
                if let newLocation = newLocation {
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: newLocation,
                            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                        )
                    )
                }
            }
            
            Button(action: {
                showSheet.toggle()
            }) {
                Text("Şarj İstasyonlarını Gör")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding()
            }
        }
        .sheet(isPresented: $showSheet) {
            ChargingStationListView(stations: chargingStations)
        }
    }
    // MARK: - ChargingStationListView
    struct ChargingStationListView: View {
        let stations: [ChargingStation]
        
        var body: some View {
            VStack {
                Text("Şarj İstasyonları")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                
                List(stations) { station in
                    HStack {
                        Image(systemName: "bolt.circle.fill")
                            .foregroundColor(.green)
                            .font(.title)
                        Text(station.name)
                            .font(.headline)
                        Spacer()
                    }
                    .padding()
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

}
