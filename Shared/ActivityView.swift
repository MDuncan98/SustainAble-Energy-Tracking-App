//
//  ActivityView.swift
//  SustainAble
//
//  Created by Michael Duncan on 25/02/2022.
//

import Foundation
import SwiftUI


public class deviceList: ObservableObject {
    @Published var devices: [Device]
    init() {
        self.devices = [
            Device(name: "Laptop", power: 76),
            Device(name: "Phone, Tablet", power: 11),
            Device(name: "PC", power: 250),
            Device(name: "Gaming PC", power: 400),
            Device(name: "PC, VR Headset", power: 600),
            Device(name: "Games Console", power: 90),
            Device(name: "TV", power: 117)
        ]
        //if user is signed in, get online devices.
    }
    
    func getDeviceStrings() -> [String] {
        var ds: [String] = []
        for i in self.devices {
            ds.append(i.name)
        }
        return ds
    }
}


struct ActivityView: View {
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    @StateObject var devicesList = deviceList()
    @State var activities: [String] = [
        "Video Streaming - 4K", //0.1521kWh
        "Video Streaming - HD", //0.0462kWh
        "Video Streaming - 4G, Auto", //0.0102kWh
        "Gaming", // 0.4kWh
        "Social Media",
        "Web Browsing", // } Standard device usage
        "Other"
    ]
    @State var selectedDevice = ""
    @State var selectedActivity: String = ""
    @State var durationString: String = ""
    @ObservedObject var currentLog: log
    @State var toda: String
    @State private var showAlert = false
    
    
    struct deviceItem {
        let device: Device?
    }
    
    func validateEntry(sa: String, sd: String, ds: String)  -> Bool {
        var isValidated = true
        let validationList: [String] = [
            sa,
            sd
        ]
        for vl in validationList {
            if vl.isEmpty == true {
                isValidated = false
            }
        }
        if ds.isEmpty == true {
            isValidated = false
        } else {
            if Float(ds)! <= 0 {
                isValidated = false
            }
        }
        return isValidated
    }


    var body: some View {
        VStack {
            Title(titleText: toda + " Activity")
            Form {
                Section (header: Text("Activity")) {
                    Picker("Select an Activity", selection: $selectedActivity) {
                        Text("Select an Activity:").tag(0)
                        ForEach(activities, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 100)
                }
                Section (header: Text("Device")){
                    Picker("Select a Device", selection: $selectedDevice) {
                        Text("Select an Device:").tag(0)
                        ForEach(devicesList.getDeviceStrings(), id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 100)
                }
                Section {
                    TextField("Duration in minutes", text: $durationString)
                        .keyboardType(.decimalPad)
                        .accentColor(.blue)
                }
                Button (action: {
                    if validateEntry(sa: selectedActivity, sd: selectedDevice, ds: durationString) == true {
                        let currentActivity = Activity(name: selectedActivity, timeOfDay: toda, duration: Float(durationString)!, device: devicesList.devices.first(where: {$0.name == selectedDevice})!)
                        currentLog.addActivity(timeOfDay: toda, activity: currentActivity)
                        self.mode.wrappedValue.dismiss()
                    } else {
                        showAlert = true
                    }
                }) {
                        Text("Confirm")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .ignoresSafeArea()
                .foregroundColor(Color.white)
                .background(Color("SecondaryAccent"))
                .cornerRadius(8)
                .padding(.leading, 10)
                .alert("Invalid Input", isPresented: $showAlert, actions: {
                    Button("OK", role: .cancel) {}
                }, message: {
                    Text("Either some of the fields were empty, or they contained invalid data. Please try again.")
                })
                Text("Please be aware that accurate energy data is used where we can, but it is not always possible. In these instances, we have used our best estimates to judge how much energy would be used. Therefore, we cannot guarantee that this information is 100% accurate!")
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

/*struct ActivityView_Previews: PreviewProvider {
    static var previews: some View {
            ActivityView(currentLog: log(date: Date.init()), toda: @Binding var ""))
    }
}*/
