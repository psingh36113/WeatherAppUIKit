//
//  ViewController.swift
//  WeatherAppUIKit
//
//  Created by PSingh on 6/4/23.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet weak var conditionImageView: UIImageView!
    @IBOutlet weak var imgNameLbl: UILabel!
    @IBOutlet weak var currentTempLbl: UILabel!
    @IBOutlet weak var minTempLbl: UILabel!
    @IBOutlet weak var maxTempLbl: UILabel!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var searchTextField: UITextField!
    let locationManager = CLLocationManager()
    var location: String = ""
    private var weather: Weather?
    let apiKey = "46c387da00c056042ef733ce3eb4d49c"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocationManager()
        setupTextFieldDelegate()
        fetchWeatherData()
    }
      
      private func setupLocationManager() {
          locationManager.delegate = self
          locationManager.requestWhenInUseAuthorization()
          locationManager.startUpdatingLocation()
      }
      
      private func setupTextFieldDelegate() {
          searchTextField.delegate = self
      }

    @IBAction func searchButtonAction(_ sender: UIButton) {
        searchTextField.resignFirstResponder()
        fetchWeatherData()
    }
        
    private func updateWeatherData() {
        guard let weather = self.weather else {
            return
        }
        
        maxTempLbl.text = "Maximum Temperature: \(weather.main.temp_max)°F"
        minTempLbl.text = "Minimum Temperature: \(weather.main.temp_min)°F"
        currentTempLbl.text = "Current Temperature: \(weather.main.temp)°F"
        imgNameLbl.text = weather.weather.first?.description
        
        if let icon = weather.weather.first?.icon {
            downloadWeatherIcon(icon: icon) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let image):
                        self?.conditionImageView.image = image
                    case .failure(let error):
                        print("Error downloading weather icon: \(error)")
                        // Handle error and display default image or error message
                    }
                }
            }
        }
    }

    private func downloadWeatherIcon(icon: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
        guard let iconURL = URL(string: "https://openweathermap.org/img/w/\(icon).png") else {
            completion(.failure(NSError(domain: "InvalidURL", code: 0, userInfo: nil)))
            return
        }
        
        let task = URLSession.shared.dataTask(with: iconURL) { (data, response, error) in
            if let data = data, let image = UIImage(data: data) {
                completion(.success(image))
            } else if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(NSError(domain: "IconDownloadError", code: 0, userInfo: nil)))
            }
        }
        task.resume()
    }
        
    }

    extension ViewController: UITextFieldDelegate {
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            location = textField.text ?? ""
        }
    }

    extension ViewController {
        
        // To fetch current location weather
        // If location is empty then it will fetch Current location.
        private func fetchWeatherData() {
            if location.isEmpty {
                fetchWeatherDataForCurrentLocation()
            } else {
                fetchWeatherData(for: location)
            }
        }
        
        private func fetchWeatherDataForCurrentLocation() {
            guard let currentLocation = locationManager.location else {
                displayError(message: "Failed to fetch current location.")
                return
            }
            
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(currentLocation) { [weak self] (placemarks, error) in
                if let placemark = placemarks?.first,
                   let cityName = placemark.locality ?? placemark.subAdministrativeArea ?? placemark.administrativeArea {
                    self?.searchTextField.text = cityName
                    self?.fetchWeatherData(for: cityName)
                }
            }
        }
        
        private func fetchWeatherData(for cityName: String) {
            let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(cityName)&appid=\(apiKey)&units=imperial"
            guard let url = URL(string: urlString) else {
                displayError(message: "Invalid URL.")
                return
            }
            
            let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
                if let data = data {
                    do {
                        let decoder = JSONDecoder()
                        let weather = try decoder.decode(Weather.self, from: data)
                        DispatchQueue.main.async {
                            self?.weather = weather
                            self?.updateWeatherData()
                        }
                    } catch {
                        print("Error in parsing JSON: \(error)")
                        self?.displayError(message: "Failed to parse weather data.")
                    }
                } else if let error = error {
                    print("Error in network request: \(error)")
                    self?.displayError(message: "Failed to fetch weather data.")
                }
            }
            task.resume()
        }
        
        // Func to show alert whenever there is an error
        
        private func displayError(message: String) {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

    extension ViewController: CLLocationManagerDelegate {
        
        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            setupLocationManager()
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let currentLocation = locations.last else {
                return
            }
            
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(currentLocation) { [weak self] (placemarks, error) in
                self?.fetchWeatherData()
                manager.stopUpdatingLocation()
            }
        }
        
        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            print("Error - Location manager: \(error.localizedDescription)")
            displayError(message: "Failed to fetch location.")
        }
    }
