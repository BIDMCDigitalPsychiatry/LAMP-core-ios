//
//  WebView.swift
//  lampv2
//
//  Created by Jijo Pulikkottil on 02/01/20.
//  Copyright © 2020 lamp. All rights reserved.
//

import SwiftUI
import WebKit

struct HomeWebView: UIViewRepresentable {
    
    let viewModel: HomeWebViewModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel)
    }

    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true
        
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WebViewStorage.shared.processPool
        configuration.preferences = preferences
        configuration.websiteDataStore = WebViewStorage.shared.dataStore
        
        configuration.userContentController.add(LeakAvoider(delegate: viewModel), name: ScriptMessageHandler.login.rawValue)
        configuration.userContentController.add(LeakAvoider(delegate: viewModel), name: ScriptMessageHandler.logout.rawValue)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = context.coordinator

        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        
        let appState = UIApplication.shared.applicationState
        if appState != UIApplication.State.background {
            
            viewModel.isWebpageLoaded = true
            uiView.load(URLRequest(url: viewModel.homeURL))
        }
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        
        weak var viewModel: HomeWebViewModel?

        init(_ viewModel: HomeWebViewModel) {
            self.viewModel = viewModel
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("WebView: navigation finished")
            viewModel?.shouldAnimate = false
        }
    }
}

struct HomeWebView_Previews: PreviewProvider {
    static var previews: some View {
        HomeWebView(viewModel: HomeWebViewModel())
    }
}
