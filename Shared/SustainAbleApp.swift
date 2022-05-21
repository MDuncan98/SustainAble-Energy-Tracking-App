//
//  SustainAbleApp.swift
//  Shared
//
//  Created by Michael Duncan on 11/02/2022.
//

import SwiftUI
import UIKit
import Firebase
import FirebaseCore


class AppDelegate: NSObject, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions:
        [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct SustainAbleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

