//
//  RootView.swift
//  PomodoroApp
//
//  Created by Archit Joshi on 6/23/26.
//

import Foundation
import SwiftUI

struct RootView: View {
    @State private var isShowingSplash = true
    
    var body: some View {
        if isShowingSplash {
            SplashView()
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeOut(duration: 0.4)) {
                            isShowingSplash = false
                        }
                    }
                }
        } else {
            ContentView()
                .transition(.opacity)
        }
    }
}
