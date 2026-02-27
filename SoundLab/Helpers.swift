//
//  Helpers.swift
//  SoundLab
    

import SwiftUI


@propertyWrapper
struct EnumStorage<Value: RawRepresentable>: DynamicProperty {
    let key: String
    let defaultValue: Value
    
    @State private var value: Value
    
    init(key: String, defaultValue: Value) {
        self.key = key
        self.defaultValue = defaultValue
        
        let stored = UserDefaults.standard.object(forKey: key) as? Value.RawValue
        _value = State(initialValue:
            stored.flatMap { Value(rawValue: $0) } ?? defaultValue
        )
    }
    
    var wrappedValue: Value {
        get { value }
        nonmutating set {
            value = newValue
            UserDefaults.standard.set(newValue.rawValue, forKey: key)
        }
    }
}


#if canImport(UIKit)
import UIKit
extension Color {
    static let platformBackground  = Color(uiColor: .systemBackground)
    static let platformGray4       = Color(uiColor: .systemGray4)
    static let platformGray5       = Color(uiColor: .systemGray5)
    static let platformGray6       = Color(uiColor: .systemGray6)
    static let platformSecondary   = Color(uiColor: .secondaryLabel)
}
#elseif canImport(AppKit)
import AppKit
extension Color {
    static let platformBackground  = Color(nsColor: .windowBackgroundColor)
    static let platformGray4       = Color(nsColor: .separatorColor)
    static let platformGray5       = Color(nsColor: .separatorColor).opacity(0.5)
    static let platformGray6       = Color(nsColor: .underPageBackgroundColor)
    static let platformSecondary   = Color(nsColor: .secondaryLabelColor)
}
#endif



#if os(macOS)
struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material   = .hudWindow
        v.blendingMode = .behindWindow
        v.state      = .active
        return v
    }
    
    func updateNSView(_ v: NSVisualEffectView, context: Context) {}
}
#endif


public extension View {
    func capsuleBorder(_ opacity: Double = 0.6, lineWidth: CGFloat = 1.5) -> some View {
        self.overlay(
            Capsule().strokeBorder(Color.platformGray4.opacity(opacity), lineWidth: lineWidth)
        )
    }
    
    func linkCursorStyle() -> some View {
        #if os(macOS)
        self.pointerStyle(.link)
        #else
        return self
        #endif
    }
}


#if os(iOS)
class SharePresenter {
    private init() {}
    
    /// Creates a temporary window to present the activity view controller on it
    static func present(with items: [Any], completion: UIActivityViewController.CompletionWithItemsHandler? = nil) {
        let scene = UIApplication.shared.connectedScenes.first as! UIWindowScene
        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        
        // Create a temporary view controller to present the activity view controller
        let tempViewController = UIViewController()
        tempViewController.view.backgroundColor = .clear
        window.rootViewController = tempViewController
        window.makeKeyAndVisible()
        
        
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        activityViewController.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            // Dismiss the window after completion
            window.isHidden = true
            window.rootViewController = nil // Release the root view controller
            completion?(activityType, completed, returnedItems, error)
        }
        
        
        tempViewController.present(activityViewController, animated: true)
    }
}
#endif
