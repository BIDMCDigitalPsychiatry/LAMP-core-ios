//
//  WebView.swift
//  lampv2
//
//  Created by Jijo Pulikkottil on 02/01/20.
//  Copyright © 2020 lamp. All rights reserved.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    
    let viewModel: WebViewModel
    
    func makeCoordinator() -> WebViewModel {
        return viewModel
    }

    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true

        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.userContentController.add(viewModel, name: viewModel.messageHandler)
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        
        webView.navigationDelegate = context.coordinator

        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.load(URLRequest(url: viewModel.url))
    }
}

struct WebView_Previews: PreviewProvider {
    static var previews: some View {
        WebView(viewModel: WebViewModel())
    }
}
