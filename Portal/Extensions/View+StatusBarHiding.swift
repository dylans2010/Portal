// Created by dylan on 1/4/26

import SwiftUI
import UIKit

// View modifier to handle status bar hiding across the entire app
struct StatusBarHidingModifier: ViewModifier {
    @AppStorage("statusBar.hideDefaultStatusBar") private var hideDefaultStatusBar: Bool = true
    
    func body(content: Content) -> some View {
        content
            .statusBar(hidden: hideDefaultStatusBar)
            .onAppear {
                updateStatusBar()
            }
            .onChange(of: hideDefaultStatusBar) { _ in
                updateStatusBar()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("StatusBarHidingPreferenceChanged"))) { _ in
                updateStatusBar()
            }
    }
    
    private func updateStatusBar() {
        // Update all windows using the newer API
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.windows.forEach { window in
                    window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
                    
                    // Recursively update all child view controllers
                    updateViewControllers(window.rootViewController)
                }
            }
        }
    }
    
    private func updateViewControllers(_ viewController: UIViewController?) {
        viewController?.setNeedsStatusBarAppearanceUpdate()
        
        if let nav = viewController as? UINavigationController {
            nav.viewControllers.forEach { updateViewControllers($0) }
        } else if let tab = viewController as? UITabBarController {
            tab.viewControllers?.forEach { updateViewControllers($0) }
        }
        
        viewController?.children.forEach { updateViewControllers($0) }
        viewController?.presentedViewController.map { updateViewControllers($0) }
    }
}

extension View {
    func handleStatusBarHiding() -> some View {
        modifier(StatusBarHidingModifier())
    }
}
