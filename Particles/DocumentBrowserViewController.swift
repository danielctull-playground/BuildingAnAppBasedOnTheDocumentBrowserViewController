/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The `DocumentBrowserViewController` is a subclass of the `UIDocumentBrowserViewController` and acts as the root view controller of the application.
*/

import UIKit
import os.log

class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate, UIViewControllerTransitioningDelegate {
    
    // This key is used to encode the bookmark data of the URL of the opened document as part of the state restoration data.
    static let bookmarkDataKey = "bookmarkData"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // The `UIDocumentBrowserViewController` needs a delegate that is notified about the user's interaction with their files.
        // In this case, the view controller itself is assigned as its delegate.
        delegate = self
        
        // Since the application allows creating Particles documents, document creation is enabled on the `UIDocumentBrowserViewController`.
        allowsDocumentCreation = true
        
        // In this application, selecting multiple items is not supported. Instead, only one document at a time can be opened.
        allowsPickingMultipleItems = false
        
        // Particles documents look great in a dark user interface. Therefore, the style of the `UIDocumentBrowserViewController` is set to "dark".
        browserUserInterfaceStyle = .dark
        
        // Additionally, the tint color of the `UIDocumentBrowserViewController` is set to Orange, which works well with the "dark" style.
        view.tintColor = .orange
        
        // Define one custom `UIDocumentBrowserAction`, which will show up when interacting with a selection of items. In this case, the action is
        // configured to be presented both in the navigation bar of the `UIDocumentBrowserViewController`, and the menu controller, which appears
        // when long-pressing items.
        let action = UIDocumentBrowserAction(identifier: "com.example.particles.export-gif",
                                             localizedTitle: "Export as GIF",
                                             availability: [.menu, .navigationBar],
                                             handler: { (_) in
            NSLog("Exporting a GIF is not actually implemented.")
        })
        
        // By specifying the supported content types of the action, the action can only be performed on Particles files, but not on any other type of
        // file.
        action.supportedContentTypes = ["com.example.particles"]
        
        // Last but not least, the newly created action is assigned to the `UIDocumentBrowserViewController`.
        customActions = [action]
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        
        // Since the `UIDocumentBrowserViewController` is configured to use the "dark" browser user interface style, using the "lightContent" for the
        // status bar is a good choice.
        return .lightContent
    }
    
    // MARK: UIDocumentBrowserViewControllerDelegate
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController,
                         didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        
        // When the user wants to create a new document, a blank version of a new Partiles file needs to be provided to the
        // `UIDocumentBrowserViewController`. In this case, obtain the URL of the "BlankFile.particles", which is part of the application bundle, and
        // afterwards, perform the importHandler on the URL with a Copy operation.
        let newDocumentURL: URL? = Bundle.main.url(forResource: "BlankFile", withExtension: "particles")
        
        // Make sure the importHandler is always called, even if the user cancels the creation request.
        if newDocumentURL != nil {
            importHandler(newDocumentURL, .copy)
        } else {
            importHandler(nil, .none)
        }
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentURLs documentURLs: [URL]) {
        guard let sourceURL = documentURLs.first else { return }
        
        // When the user has chosen an existing document, a new `DocumentViewController` is presented for the first document that was picked.
        presentDocument(at: sourceURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        
        // When a new document has been imported by the `UIDocumentBrowserViewController`, a new `DocumentViewController` is presented as well.
        presentDocument(at: destinationURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, applicationActivitiesForDocumentURLs documentURLs: [URL]) -> [UIActivity] {
        // Whenever one or more items are being shared by the user, the default activities of the `UIDocumentBrowserViewController` can be augmented
        // with custom ones. In this case, no additional activities are added.
        return []
    }
    
    // MARK: UIViewControllerTransitioningDelegate
    
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        // Since the `UIDocumentBrowserViewController` has been set up to be the transitioning delegate of `DocumentViewController` instances (see
        // implementation of `presentDocument(at:)`), it is being asked for a transition controller.
        // Therefore, return the transition controller, that previously was obtained from the `UIDocumentBrowserViewController` when a
        // `DocumentViewController` instance was presented.
        return transitionController
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        // The same zoom transition is needed when closing documents and returning to the `UIDocumentBrowserViewController`, which is why the the
        // existing transition controller is returned here as well.
        return transitionController
    }
    
    // MARK: Document Presentation
    
    var transitionController: UIDocumentBrowserTransitionController?
    
    func presentDocument(at documentURL: URL, animated: Bool = true) {
        
        // To present a document, instantiate a `DocumentViewController` instance from the Storyboard.
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let instantiatedViewController = storyBoard.instantiateViewController(withIdentifier: "DocumentViewController")
        guard let documentViewController = instantiatedViewController as? DocumentViewController else { fatalError() }
        
        // In order to get a proper animation when opening and closing documents, the DocumentViewController needs a custom view controller
        // transition. The `UIDocumentBrowserViewController` provides a `transitionController`, which takes care of the zoom animation. Therefore, the
        // `UIDocumentBrowserViewController` is registered as the `transitioningDelegate` of the `DocumentViewController`. Next, obtain the
        // transitionController, and store it for later (see `animationController(forPresented:presenting:source:)` and
        // `animationController(forDismissed:)`).
        documentViewController.transitioningDelegate = self
        transitionController = transitionController(forDocumentURL: documentURL)
        
        // Now load the contents of the presented document, and once that is done, present the `DocumentViewController` instance.
        // In order for the transition animation to work, the transition controller needs a view to zoom into, which is the particle system on the
        // left side of the main application user interface.
        documentViewController.setDocument(Document(fileURL: documentURL), completion: {
            self.transitionController?.targetView = documentViewController.documentView
            self.present(documentViewController, animated: animated, completion: nil)
        })
        
    }
    
    // MARK: State Preservation and Restoration
    
    override func encodeRestorableState(with coder: NSCoder) {
        
        // The system will call this method on the view controller when the application state needs to be preserved.
        // Encode relevant information using the coder instance, that is provided.
        
        if let documentViewController = presentedViewController as? DocumentViewController,
           let documentURL = documentViewController.document?.fileURL {
            do {
                // Obtain the bookmark data of the URL of the document that is currently presented, if there is any.
                let didStartAccessing = documentURL.startAccessingSecurityScopedResource()
                defer {
                    if didStartAccessing {
                        documentURL.stopAccessingSecurityScopedResource()
                    }
                }
                let bookmarkData = try documentURL.bookmarkData()
                
                // Encode it with the coder.
                coder.encode(bookmarkData, forKey: DocumentBrowserViewController.bookmarkDataKey)
                
            } catch {
                // Make sure to handle the failure appropriately, e.g., by showing an alert to the user
                os_log("Failed to get bookmark data from URL %@: %@", log: OSLog.default, type: .error, documentURL as CVarArg, error as CVarArg)
            }
        }
        
        super.encodeRestorableState(with: coder)
    }
    
    override func decodeRestorableState(with coder: NSCoder) {
        
        // This method is called when the system attempts to restore application state.
        // Try decoding the bookmark data, obtain a URL instance from it, and present the document.
        if let bookmarkData = coder.decodeObject(forKey: DocumentBrowserViewController.bookmarkDataKey) as? Data {
            do {
                var bookmarkDataIsStale: Bool = false
                if let documentURL = try URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &bookmarkDataIsStale) {
                    presentDocument(at: documentURL, animated: false)
                }
            } catch {
                // Make sure to handle the failure appropriately, e.g., by showing an alert to the user
                os_log("Failed to create document URL from bookmark data: %@, error: %@",
                       log: OSLog.default, type: .error, bookmarkData as CVarArg, error as CVarArg)
            }
        }
        super.decodeRestorableState(with: coder)
    }
}
