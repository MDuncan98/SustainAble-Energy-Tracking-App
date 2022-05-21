//
//  Device.swift
//  SustainAble (iOS)
//
//  Created by Michael Duncan on 28/02/2022.
//

import Foundation

public class Device: Codable, Identifiable {
    var name: String
    var power: Int
    public var id: String { name }
    
    init(name: String, power: Int) {
        self.name = name
        self.power = power
    }
}
