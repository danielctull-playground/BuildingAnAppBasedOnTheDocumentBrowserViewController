/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The `DocumentViewController` is in charge of presenting the contents of a document. The view controller is a compound of a `ParticleViewController`
 on the left, and an `EditorViewController` on the right.
*/

import UIKit
import MobileCoreServices

class DocumentViewController: UIViewController {
    
    private(set) var document: Document?
    
    var documentView: UIView {
        // This is the view that is used for the zoom transition (see DocumentBrowserViewController class).
        return particleNavigationController.view
    }
    
    private let particleNavigationController = UINavigationController()
    private let particleViewController = ParticleViewController()
    private let editorViewController = EditorViewController()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        view.tintColor = .orange
        view.backgroundColor = #colorLiteral(red: 0.1176470588, green: 0.1176470588, blue: 0.1176470588, alpha: 1)
        
        let topInsets: CGFloat = 25.0
        let sidebarWidth: CGFloat = 300.0
        
        particleNavigationController.pushViewController(particleViewController, animated: false)
        particleNavigationController.navigationBar.barStyle = .blackTranslucent
        
        embed(particleNavigationController, constraintsBlock: { (subview: UIView, container: UIView) in
            return [subview.topAnchor.constraint(equalTo: container.topAnchor, constant: topInsets),
                    subview.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20.0),
                    subview.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20.0),
                    subview.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -(sidebarWidth + 20.0))]
        })
        
        let editorNavigationController = UINavigationController()
        editorNavigationController.pushViewController(editorViewController, animated: false)
        editorNavigationController.navigationBar.barStyle = .blackTranslucent
        embed(editorNavigationController, constraintsBlock: { (subview: UIView, container: UIView) in
            return [subview.topAnchor.constraint(equalTo: container.topAnchor, constant: topInsets),
                    subview.leadingAnchor.constraint(equalTo: particleNavigationController.view.trailingAnchor, constant: 20.0),
                    subview.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20.0),
                    subview.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20.0)]
        })
    }
    
    func embed(_ viewController: UIViewController, constraintsBlock: (UIView, UIView) -> [NSLayoutConstraint]) {
        guard let subview = viewController.view else { return }
        
        addChild(viewController)
        subview.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(viewController.view)
        NSLayoutConstraint.activate(constraintsBlock(subview, view))
        viewController.didMove(toParent: self)
        
        subview.layer.cornerRadius = 8.0
        subview.layer.masksToBounds = true
        subview.clipsToBounds = true
    }
    
    func setDocument(_ document: Document, completion: @escaping () -> Void) {
        
        // Once the `DocumentViewController` is given a reference to its document, it loads its view, and opens the document.
        // This ensures that a coordinated read is performed on the document, which is necessary when dealing with documents that can be accessed by
        // multiple processes.
        self.document = document
        loadViewIfNeeded()
        
        document.open(completionHandler: { (success) in
            
            // Make sure to implement handleError(_:userInteractionPermitted:) in your UIDocument subclass to handle errors appropriately.
            if success {
                self.particleViewController.document = self.document
                self.editorViewController.document = self.document
            }
            completion()
        })
        
    }
    
    // UI Actions
    
    @IBAction func dismissDocumentViewController() {
        document?.close(completionHandler: { (_) in
            self.dismiss(animated: true)
        })
    }
}

import SceneKit

// The view controller hosts a SceneKit view (`SCNView`), in which the particle system is being rendered.
class ParticleViewController: UIViewController {
    
    private let sceneView = SCNView()
    
    var document: Document? {
        didSet {
            navigationItem.title = document?.presentedItemURL?.lastPathComponent
            
            loadViewIfNeeded()
            updateScene()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = document?.presentedItemURL?.lastPathComponent
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTaped))
        
        let scene = SCNScene()
        scene.background.contents = UIColor.darkGray
        
        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 3, z: 6)
        scene.rootNode.addChildNode(cameraNode)
        
        // Scene View
        sceneView.scene = scene
        sceneView.allowsCameraControl = true
        
        view.addSubview(sceneView)
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sceneView.scene?.isPaused = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sceneView.scene?.isPaused = false
    }
    
    func updateScene() {
        guard let document = document,
            let particleSystem = document.particleSystem else { return }
        
        particleSystem.warmupDuration = 2.0
        particleSystem.particleImage = #imageLiteral(resourceName: "spark.png")
        
        let particleSystemNode = SCNNode()
        particleSystemNode.addParticleSystem(particleSystem)
        sceneView.scene?.rootNode.addChildNode(particleSystemNode)
    }
    
    // MARK: UI Actions
    
    @objc
    func doneButtonTaped() {
        guard let documentViewController = navigationController?.parent as? DocumentViewController else { return }
        documentViewController.dismissDocumentViewController()
    }
    
    // MARK: Thumbnailing
    
    func snapshot() -> UIImage {
        
        // Particles file thumbnails are simply a visual snapshot the `sceneView`.
        return sceneView.snapshot()
    }
}

// This view controller hosts a table view that has a list of settings to modify properties of the particle system.
class EditorViewController: UITableViewController, UIDocumentPickerDelegate {
    
    private struct EditorSetting {
        let keyPath: String
        let label: String
        let min: Float
        let max: Float
        let transformer: ValueTransformer?
        
        func value(_ slider: UISlider) -> Any? {
            return transformer == nil ? slider.value : transformer!.transformedValue(slider.value)
        }
        
        func reversedValue(_ value: Any) -> Float {
            if transformer == nil {
                guard let value = value as? Float else { fatalError() }
                return value
            } else {
                if let reverseTransformedValue = transformer!.reverseTransformedValue(value) {
                    guard let reverseTransformedValue = reverseTransformedValue as? Float else { fatalError() }
                    return reverseTransformedValue
                } else {
                    return 0.0
                }
            }
        }
    }
    
    private class PETableViewCell: UITableViewCell {
        var label = UILabel()
        var slider = UISlider()
        
        override func prepareForReuse() {
            super.prepareForReuse()
            for subview in contentView.subviews {
                subview.removeFromSuperview()
            }
        }
    }
    
    private class FloatToColorTransformer: ValueTransformer {
        
        override func transformedValue(_ value: Any?) -> Any? {
            guard let floatValue = value as? Float else { return nil }
            return UIColor(hue: CGFloat(floatValue), saturation: 0.75, brightness: 1.0, alpha: 1.0)
        }
        
        override func reverseTransformedValue(_ value: Any?) -> Any? {
            guard let color = value as? UIColor else { return nil }
            var hue: CGFloat = 0
            if color.getHue(&hue, saturation: nil, brightness: nil, alpha: nil) {
                return Float(hue)
            } else {
                return nil
            }
        }
    }
    
    var document: Document? {
        didSet {
            // Feed the Inspector with the values of the particle system.
            readValues()
        }
    }
    
    private var particleSystem: SCNParticleSystem? {
        return document?.particleSystem
    }
    
    private var settings = [
        EditorSetting(keyPath: "birthRate",
                      label: "Birth Rate",
                      min: 0.1, max: 100.0,
                      transformer: nil),
        EditorSetting(keyPath: "particleLifeSpan",
                      label: "Lifespan",
                      min: 0.1, max: 100.0,
                      transformer: nil),
        EditorSetting(keyPath: "particleSize",
                      label: "Size",
                      min: 0.1, max: 5.0,
                      transformer: nil),
        EditorSetting(keyPath: "particleSizeVariation",
                      label: "Size Variation",
                      min: 0.1, max: 10.0,
                      transformer: nil),
        EditorSetting(keyPath: "particleAngle",
                      label: "Spreading Angle",
                      min: 0.1, max: 100.0,
                      transformer: nil),
        EditorSetting(keyPath: "particleColor",
                      label: "Color",
                      min: 0.0, max: 1.0,
                      transformer: FloatToColorTransformer())
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsSelection = false
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .darkGray
        tableView.separatorStyle = .none
        tableView.register(PETableViewCell.self, forCellReuseIdentifier: "SettingsRow")
        
        navigationItem.title = "Inspector"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(pickParticleImage))
    }
    
    @objc
    func scheduleAutosave() {
        document?.updateChangeCount(.done)
    }
    
    func readValues() {
        guard let particleSystem = particleSystem else { return }
        for (idx, setting) in settings.enumerated() {
            if let cell = tableView.cellForRow(at: IndexPath(row: idx, section: 0)) as? PETableViewCell {
                if let value = particleSystem.value(forKey: setting.keyPath) {
                    cell.slider.value = setting.reversedValue(value)
                }
            }
        }
    }
    
    // MARK: UI Actions
    
    @objc
    func valuedChanged(_ slider: UISlider) {
        let setting = settings[slider.tag]
        guard let value = setting.value(slider) else { return }
        
        // Apply the value and trigger a deferred save.
        particleSystem?.setValue(value, forKey: setting.keyPath)
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        perform(#selector(scheduleAutosave), with: nil, afterDelay: 1.0)
    }
    
    // MARK: UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let setting = settings[indexPath.row]
        let reusableCell = tableView.dequeueReusableCell(withIdentifier: "SettingsRow") as? PETableViewCell
        let cell = reusableCell ?? PETableViewCell()
        let contentView = cell.contentView
        let horizontalInset: CGFloat = 15.0
        
        // Label
        let label = cell.label
        label.textColor = .white
        label.text = setting.label
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalInset),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10.0)
            ])
        
        // Slider
        let slider = cell.slider
        slider.maximumValue = setting.max
        slider.minimumValue = setting.min
        slider.tag = indexPath.row
        slider.addTarget(self, action: #selector(valuedChanged(_:)), for: .valueChanged)
        slider.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(slider)
        NSLayoutConstraint.activate([
            slider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalInset),
            slider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalInset),
            slider.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10.0)
            ])
        
        // Apply the current value of the particle system.
        if let particleSystem = particleSystem, let value = particleSystem.value(forKey: setting.keyPath) {
            slider.value = setting.reversedValue(value)
        }
        
        cell.backgroundColor = indexPath.row % 2 == 0 ? .darkGray : #colorLiteral(red: 0.4777468443, green: 0.4777468443, blue: 0.4777468443, alpha: 1)
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75.0
    }
    
    @objc
    func pickParticleImage(sender: UIBarButtonItem) {
        let pickerViewController = UIDocumentPickerViewController(documentTypes: [kUTTypeImage as String], in: .import)
        pickerViewController.delegate = self
        present(pickerViewController, animated: true)
    }
    
    // MARK: UIDocumentPickerDelegate
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        assert(urls.count == 1)
        let image = UIImage(contentsOfFile: urls.first!.path)
        particleSystem?.particleImage = image
    }
}
