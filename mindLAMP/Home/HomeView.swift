//
//  ContentView.swift
//  lampv2
//
//  Copyright © 2020 lamp. All rights reserved.
//

import SwiftUI
import WebKit
import Combine

//struct HiddenNavigationBar: ViewModifier {
//    func body(content: Content) -> some View {
//        content
//        .navigationBarTitle("", displayMode: .inline)
//        .navigationBarHidden(true)
//    }
//}
//
//extension View {
//    func hiddenNavigationBarStyle() -> some View {
//        modifier( HiddenNavigationBar() )
//    }
//}

struct HomeView: View {
    
    
    @ObservedObject var viewModel = HomeWebViewModel()
    //@State var isNavigationBarHidden: Bool = true
    @State var webViewHeight: CGFloat = 0
    
    var body: some View {
        
        return NavigationView {
                ZStack(alignment: Alignment.center) {
                    HomeWebView(viewModel: viewModel, contentHeight: self.$webViewHeight)
                    ActivityIndicator(isAnimating: self.$viewModel.shouldAnimate, style: .large)
                    NavigationLink(destination: NotificationView(viewModel: NotificationWebViewModel(viewModel.notificationPageURL, pageTitle: viewModel.notificationPageTitle)), isActive: $viewModel.pushedByNotification) { EmptyView() }
                }
                .navigationBarTitle("", displayMode: .inline)
                .navigationBarHidden(true)
        
            }.onAppear {
                //self.isNavigationBarHidden = true
                NotificationCenter.default.addObserver(self.viewModel, selector: #selector(self.viewModel.updateWatchOS(_:)),
                                                   name: UIApplication.didBecomeActiveNotification, object: nil)

            }.onDisappear {
                NotificationCenter.default.removeObserver(self.viewModel, name: UIApplication.didBecomeActiveNotification, object: nil)
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}



