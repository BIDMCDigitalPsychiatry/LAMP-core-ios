//
//  WebView.swift
//  lampv2
//
//  Copyright © 2020 lamp. All rights reserved.
//

import SwiftUI
import WebKit

struct HomeWebView: UIViewRepresentable {
    
    let viewModel: HomeWebViewModel
    @Binding var contentHeight: CGFloat//+20201222
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel, contentHeight: $contentHeight)
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
        webView.scrollView.isScrollEnabled = false//+20201222

        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        
        let appState = UIApplication.shared.applicationState
        if appState != UIApplication.State.background {
            
            viewModel.isWebpageLoaded = true
            print("viewModel.homeURL = \(viewModel.homeURL.absoluteString)")
            uiView.load(URLRequest(url: viewModel.homeURL))
        }
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        
        weak var viewModel: HomeWebViewModel?
        @Binding var contentHeight: CGFloat
        var resized = false

        init(_ viewModel: HomeWebViewModel, contentHeight: Binding<CGFloat>) {
            self.viewModel = viewModel
            self._contentHeight = contentHeight
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("WebView: navigation finished")
            viewModel?.shouldAnimate = false
            //+20201222
            webView.evaluateJavaScript("document.readyState") { complete, _ in
                            guard complete != nil else { return }
                            webView.evaluateJavaScript("document.body.scrollHeight") { height, _ in
                                guard let height = height as? CGFloat else { return }

                                if !self.resized {
                                    self.contentHeight = height
                                    self.resized = true
                                }
                            }
                        }
        }
    }
}

//struct HomeWebView_Previews: PreviewProvider {
//    static var previews: some View {
//        HomeWebView(viewModel: HomeWebViewModel())
//    }
//}
