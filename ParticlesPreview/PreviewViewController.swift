/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The `PreviewViewController` is a view controller class that implements `QLPreviewingController` and acts as the main class for a Quick Look Preview
 extension.
*/

import UIKit
import QuickLook

class PreviewViewController: UIViewController, QLPreviewingController {
    
    // Main method to implement in order to provide a preview for a file of a custom file format.
    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        
        let document = Document(fileURL: url)
        document.open(completionHandler: { [weak self](_) in
            
            self?.presentParticleViewController(for: document)
            
            // Call the completion handler to indicate to Quick Look that the preview has been fully loaded.
            // Quick Look will display a loading spinner until the completion handler is called.
            handler(nil)
        })
    }
    
    /// Creates and presents a view controller that shows the contents of the Particles file and allows the user to interact with it.
    func presentParticleViewController(for document: Document) {
        
        // Create the view controller used to preview the file and add it to the view hierarchy.
        // The `ParticleViewController` of the main application is being re-used to get the same visual representation of the document in the preview.
        let particleViewController = ParticleViewController()
        particleViewController.loadViewIfNeeded()
        particleViewController.view.layoutIfNeeded()
        
        addChild(particleViewController)
        view.addSubview(particleViewController.view)
        particleViewController.didMove(toParent: self)
        
        // Pass the document that references the file URL to the `ParticleViewController`, so that it can make use of it to preview the file.
        particleViewController.document = document
        
        if let particleView = particleViewController.view {
            particleView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                particleView.leftAnchor.constraint(equalTo: view.leftAnchor),
                particleView.rightAnchor.constraint(equalTo: view.rightAnchor),
                particleView.topAnchor.constraint(equalTo: view.topAnchor),
                particleView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
    }
}
