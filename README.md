# Particles: Building a UIDocumentBrowserViewController Based Application

Manages user interactions with files saved on different iCloud storage providers, and implements a custom document file format.

## Overview

Users store their documents on different cloud storage providers, such as iCloud Drive. With document browser view controller, they can browse through and access their documents, no matter where they are stored. The document browser view controller lets them create new documents, and acts as a springboard into your application's main user interface.  

This example app illustrates the usage of the document browser view controller. It registers a custom file format called Particles in the system, and allows the user to create new Particles documents on any of the the user's activated file providers. When choosing a document, the app presents an editor view, in which the document contents can be modified. Once the user is done with the modifications, the document is saved, and the user returns to the document browser view controller again. Apart from proper file handling using the `UIDocument` class, the app also illustrates the customization of the look of the document browser view controller, the usage of custom browser actions and the way it presents document view controllers with a custom zoom transition.

## Getting Started

The `UIDocumentBrowserViewController` and this Particles app require at least iOS 11.

### Starting a New Document Based App from Scratch

When starting a new iOS project, Xcode offers to create a document based app. This template comes with everything needed to implement a great document based application. Use it as a starting point, if you want to create a document based application from scratch.

Once you have instantiated the template, the project provides a storyboard, which uses a  `UIDocumentBrowserViewController` as its entry point. Additionally, the template creates a `UIDocument` subclass, Document, which acts as the representation of a document of your application at runtime. The logic in order to create new documents is already in place. When the user creates a new document, or opens an existing one by tapping a file in the document browser view controller, a `DocumentViewController` is presented, which has a reference to a `Document` instance. This `DocumentViewController` acts as the main user interface to modify the contents of a document.

### Migrating an Existing Document Based Application

If you would like instead to migrate an existing document based application to use the `UIDocumentBrowserViewController`, make sure to present the document browser view controller full-screen as the first user interface that the user sees when launching your application. Make sure to implement the `UIDocumentBrowserViewControllerDelegate` protocol and assign an instance of it to the document browser view controller. 

### Customize the Document Browser View Controller, Document View Controller and Document Classes

From here, the project needs to be extended to fit your needs. Set up a custom file format in the exported UTIs of your application, if needed, or configure one or more existing UTIs in the imported UTIs section instead. The document types of the application need to be configured as well, in order for the document browser view controller to decide which files to display to the user.

Next, the document to start with when the user creates a new document needs to be provided, e.g., by copying a file of the application bundle, which represents a blank version of a new document. Hand over the blank file to the document browser view controller via the import handler.

In order to provide proper document saving and loading, augment the `UIDocument` subclass with the logic needed in order to encode and decode the data of a document properly.

Last but not least, if needed, the document browser view controller can be configured to show custom browser actions, which are shown to the user when selecting one or more documents at once, or when long-pressing a document to reveal the menu.

### Animated View Controller transitions

When presenting a document view controller after creating a new, or choosing an existing document, a transition controller can be used in order to animate the view controller change with an elegant zoom transition. Therefore, the `UIDocumentBrowserViewController` class provides a method to obtain a transition controller. The transition controller has a reference to a document, so that its thumbnail can be used as the starting point or end point of the animation.

Therefore, assign a transitioning delegate object to the document view controller, that is, the view controller that is presented to display the contents of a document. This transitioning delegate is an object that needs to conform to the `UIViewControllerTransitioningDelegate` protocol and will be asked for an animation controller whenever the view controller is about to be presented or dismissed. In that moment, return a transition controller obtained from the document browser view controller, which needs to be configured to fit your needs. The transition controller then will drive the zoom animation when opening or closing documents.


## Configure a Custom File Format

This sample illustrates how to introduce a custom file format to the system. 
* For registering "Particles" as a new file format system-wide, the Particles app has an exported UTI configured in the Info panel of the target. Using the `public.filename-extension` in the additional exported UTI properties, the "particles" filename extension is bound to the new file format. 
* To link the Particles app with the Particles file format, in the same panel the same UTI information is used for configuring the supported document types of the Particles app.

## Preview Custom Documents

The sample provides two Quick Look extensions:
* The ParticlesPreview extension, which generates preview views,
* The ParticlesThumbnails extension, which generates thumbnails for files of the newly registered file format.
In order for Quick Look to choose the extensions when dealing with Particles documents, the the `Info.plist` file, of both extensions, are configured with the data of the Particles file format.


## Apply Best Practices

Follow the tips below to avoid common pitfalls when working with files on iOS.

**Use the `UIDocumentBrowserViewController` together with `UIDocument`.** The `UIDocument` class helps you to provide the commonly expected features of a document based application, such as saving and loading documents, asynchronous reading and writing of data, versioning with conflict detection, and much more. Additionally, `UIDocument` provides automatic coordinated reading and writing, which is needed to avoid problems when accessing a file on disk, which could be attempted to be read or written by other processes at the same time. If you need to access a file manually, make sure to use file coordination, in order to not risk data-loss or other severe data inconsistencies.

**Claim only the UTIs your app actually supports.** Avoid listing high-level UTIs in the document types configured for your application. Only the UTIs that your application can actually handle should be listed. Otherwise, the document browser view controller will display files of unsupported file formats, e.g., in the Recents section, or in the search results, which are irrelevant to the user.

**Configure the document types correctly.** Make sure to configure the document types, the exported and imported UTIs in your application's `Info.plist` file correctly. This is needed for dynamic sections such as Recent Documents, collections of tagged documents, and the popover of your application on the Home screen to work properly. 

**Know the difference.** The `UIDocumentPickerViewController` and `UIDocumentBrowserViewController` are two different view controllers, each with their own purpose. Use the `UIDocumentPickerViewController` to allow the user to quickly pick an existing file to, e.g., insert into the currently opened document, or to export a document to a certain location. Use the `UIDocumentBrowserViewController` as the entry point in your application to let the users create new or choose an existing document.

