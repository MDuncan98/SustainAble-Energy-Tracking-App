//
//  Activity.swift
//  SustainAble (iOS)
//
//  Created by Michael Duncan on 28/02/2022.
//

import Foundation

public class Activity: Identifiable {
    public var id = UUID()
    var name: String
    var timeOfDay: String
    var duration: Float
    var device: Device
    var description: String
    var energyUsage: String
    
    init(name: String, timeOfDay: String, duration: Float, device: Device) {
        self.id = UUID()
        self.name = name
        self.timeOfDay = timeOfDay
        self.duration = duration
        self.device = device
        self.description = "\(name), \(device.name)"
        self.energyUsage = String(format:"%.2f", Float(device.power) * Float(duration/60))
    }
}
