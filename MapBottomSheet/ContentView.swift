//
//  ContentView.swift
//  MapBottomSheet
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            MapView()
                .ignoresSafeArea()
            HudView()
                .padding(8)
                .padding(.bottom, 24)
        }
        .bottomSheet {
            VStack {
                ForEach(0...1, id: \.self) { _ in
                    Text("Bottom Sheet")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
