//
//  Weather.swift
//  WeatherAPP
//
//  Created by PSingh on 6/4/23.
//

import Foundation


struct Weather: Codable {
    struct WeatherInfo: Codable {
        let description: String
        let icon: String
    }
    let weather: [WeatherInfo]
    let main: Main

    struct Main: Codable {
        let temp: Double
        let temp_min: Double
        let temp_max: Double
    }
}
