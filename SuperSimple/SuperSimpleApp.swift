//
//  SuperSimpleApp.swift
//  SuperSimple
//
//  Created by Andreas Sander on 17.01.26.
//

import SwiftUI

@main
struct SuperSimpleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(.primary)
                .onAppear {
                    LocationManager.shared.requestLocation()
                }
        }
    }
}
