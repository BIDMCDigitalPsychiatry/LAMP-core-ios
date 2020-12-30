//
//  ActivityIndicator.swift
//  lampv2
//
//  Copyright © 2020 lamp. All rights reserved.
//
import SwiftUI
import UIKit

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
