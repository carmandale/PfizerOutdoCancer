//
//  LibraryView.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 12/13/24.
//

import SwiftUI
import WebKit

struct LibraryView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.pushWindow) private var pushWindow
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    var body: some View {
        if appModel.isLibraryWindowOpen {
            // Screen()
           WebView(url: URL(string: "https://cancer.pfizer.com/")!)
        }
            
    }

    
    struct WebView: UIViewRepresentable {
        let url: URL
        
        func makeUIView(context: Context) -> WKWebView {
            WKWebView()
        }
        
        func updateUIView(_ uiView: WKWebView, context: Context) {
            uiView.load(URLRequest(url: url))
        }
    }
}
    //#Preview {
    //    LibraryView()
    //}

