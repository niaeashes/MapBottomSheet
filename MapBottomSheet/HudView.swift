//
//  HudView.swift
//  MapBottomSheet
//

import SwiftUI

struct HudView: View {

    var backgroundColor: Color {
        Color(UIColor.systemBackground.cgColor)
    }

    var body: some View {
        VStack {
            Text("Top")
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12).foregroundColor(backgroundColor))
                .compositingGroup()
            Spacer()
            HStack {
                Text("Bottom")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).foregroundColor(backgroundColor))
                    .compositingGroup()
                Spacer()
            }
        }
        .shadow(radius: 4)
    }
}

struct HudView_Previews: PreviewProvider {
    static var previews: some View {
        HudView()
            .padding()
            .background(Color.gray)
    }
}
