//
//  ContentView.swift
//  lampv2
//
//  Created by Jijo Pulikkottil on 02/01/20.
//  Copyright © 2020 lamp. All rights reserved.
//

import SwiftUI
import WebKit

class WebViewModel: NSObject, ObservableObject {
    
    @Published var shouldAnimate = true
    var url = URL(string: "http://127.0.0.1:5000/")!
    var messageHandler = "scriptMessageHandler"

}

//MARK: - WKNavigationDelegate

extension WebViewModel: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        shouldAnimate = false
    }
}

//MARK: - WKScriptMessageHandler

extension WebViewModel: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "scriptMessageHandler" {
            guard let dictBody = message.body as? [String: Any] else {
                print("Message body not in expected format.")
                return
            }
            print("Message body recieved: \(dictBody)")
            let isLogin = dictBody["isLogin"] as? Bool
            if isLogin == true {
                SensorManager.shared().startSensors()
            } else {
                SensorManager.shared().stopSensors()
            }
        }
    }
}

struct ContentView: View {
    
    @State var isNodeServerStarted = false
    @ObservedObject var viewModel = WebViewModel()
    var splashView = SplashView()

    var body: some View {
        
        return ZStack(alignment: Alignment.center) {
            if self.isNodeServerStarted {
                self.splashView.hidden()
                WebView(viewModel: viewModel)
                ActivityIndicator(isAnimating: self.$viewModel.shouldAnimate, style: .large)
            } else {
                self.splashView.onAppear {
                    NodeManager.shared.startNodeServer()
                    let deadlineTime = DispatchTime.now() + .seconds(2)
                    DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                        NodeManager.shared.getServerStatus()
                        self.isNodeServerStarted.toggle()
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
