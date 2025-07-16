//
//  ContentView.swift
//  Flyte
//
//  Created by Balogh Barnabás on 2025. 07. 16..
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            MainTabView()
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
