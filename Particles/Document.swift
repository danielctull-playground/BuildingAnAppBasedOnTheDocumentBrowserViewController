/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A `Document` instance represents a document at runtime. In order to inherit all the great benefits of `UIDocument`, such as coordinated reads/writes,
 versioning, and many more, `Document` is a subclass of `UIDocument`, augmented by custom state variables.
*/

import UIKit
import SceneKit

class Document: UIDocument {
    
    var particleSystem: SCNParticleSystem?
    
    override func contents(forType typeName: String) throws -> Any {
        guard let particleSystem = particleSystem else { return Data() }
        
        // This method is invoked whenever a document needs to be saved.
        // Particles documents are basically blobs of encoded particle systems.
        
        return try NSKeyedArchiver.archivedData(withRootObject: particleSystem, requiringSecureCoding: true)
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        
        particleSystem = SCNParticleSystem()
        
        // This method is invoked when loading a document from previsouly saved data.
        // Therefore, unarchive the stored data and use it as the particle system.
        
        guard let data = contents as? Data else { return }
        
        let system = try NSKeyedUnarchiver.unarchivedObject(ofClass: SCNParticleSystem.self, from: data)

        particleSystem = system
    }
}
