// mindLAMP

import Foundation
import SwiftUI
import WebKit

struct NotificationWebView: UIViewRepresentable {
    
    let viewModel: NotificationWebViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel)
    }

    func makeUIView(context: Context) -> WKWebView {
        
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true
        let configuration = WebConfiguration.getWebViewConfiguration()
        configuration.preferences = preferences

        
        configuration.processPool = WebViewStorage.shared.processPool
        configuration.websiteDataStore = WebViewStorage.shared.dataStore
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = context.coordinator

        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = viewModel.pageURL {
            uiView.load(URLRequest(url: url))
        }
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        
        weak var viewModel: NotificationWebViewModel?

        init(_ viewModel: NotificationWebViewModel) {
            self.viewModel = viewModel
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("Push finish navigation")
            viewModel?.shouldAnimate = false
        }
    }
}
