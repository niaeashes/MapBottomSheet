//
//  MapView.swift
//  MapBottomSheet
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {

    func makeUIView(context: Context) -> some UIView {
        MKMapView()
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
