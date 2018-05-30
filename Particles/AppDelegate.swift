/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Contains the application's delegate.
*/

import UIKit
import os.log

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ app: UIApplication, open inputURL: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        
        // This delegate method is invoked when the Particles app is externally asked to open a document at a specific URL.
        // Ensure that the URL is an actual file URL.
        guard inputURL.isFileURL else { return false }
        
        // Next, obtain the `UIDocumentBrowserViewController` instance of the application, in order to be able to invoke the
        // `revealDocument(at:,importIfNeeded:completion:)` method with the given URL.
        // The `UIDocumentBrowserViewController` will prepare the file at the URL, and notify once the document is ready to be presented, which in
        // this case is making a call to the `presentDocument(at:)` method, similarly to when opening documents chosen by the user from within the
        // application.
        guard let documentBrowserViewController = window?.rootViewController as? DocumentBrowserViewController else { return false }
        documentBrowserViewController.revealDocument(at: inputURL, importIfNeeded: true) { (revealedDocumentURL, error) in
            if let error = error {
                
                // Handle the error appropriately
                
                os_log("Failed to reveal document at URL %@, error: '%@'", log: OSLog.default, type: .error, inputURL as CVarArg, error as CVarArg)
                
                let alertController = UIAlertController(title: "An error occurred",
                                                        message: "The app was unable to reveal a document.",
                                                        preferredStyle: .alert)
                documentBrowserViewController.present(alertController, animated: true, completion: nil)
                
                return
            }
            
            // Present the Document View Controller for the revealed URL.
            documentBrowserViewController.presentDocument(at: revealedDocumentURL!)
        }
        
        return true
    }
    
    // MARK: State Preservation and Restoration
    
    // See also `encodeRestorableState(with:)` and `decodeRestorableState(with:)` in the implementation of `DocumentBrowserViewController`.
    
    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        
        // This delegate method is called by the system when dealing with application state preservation and restoration.
        // Return true in order to indicate that the application state should be preserved.
        return true
    }
    
    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        
        // Similarly, return true in order to indicate that the application should attempt to restore the saved application state.
        return true
    }
}
