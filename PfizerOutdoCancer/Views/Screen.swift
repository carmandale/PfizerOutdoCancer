//
//  Screen.swift
//  PfizerOutdoCancer
//
//  Created by Dale Carman on 2/13/25.
//

import SwiftUI

struct Screen: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
                    Image("screen")
                        .resizable()          // Makes the image scalable.
                        .scaledToFit()        // Keeps the aspect ratio while fitting the width.
                        .frame(maxWidth: .infinity)
                }
    }
}

#Preview {
    Screen()
}
