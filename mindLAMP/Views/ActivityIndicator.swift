//
//  ActivityIndicator.swift
//  lampv2
//
//  Created by Jijo Pulikkottil on 02/01/20.
//  Copyright © 2020 lamp. All rights reserved.
//
//https://programmingwithswift.com/swiftui-activity-indicator/
//https://peacemoon.de/blog/2019/06/10/activity-indicator-with-swiftui/
import SwiftUI

struct ActivityIndicator: UIViewRepresentable {
    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style

    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        
        let activityView = UIActivityIndicatorView(style: style)
        activityView.hidesWhenStopped = true
        return activityView
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}
