// mindLAMP

import Foundation
import SwiftUI

struct NotificationView: View{
    
    @ObservedObject var viewModel: NotificationWebViewModel
    
    var body: some View {
        return
            ZStack(alignment: Alignment.center) {
                NotificationWebView(viewModel: viewModel)
                //ActivityIndicator(isAnimating: self.$viewModel.shouldAnimate, style: .large)
            }.navigationBarTitle(Text(viewModel.pageTitle ?? ""), displayMode: .inline)
    }
}
