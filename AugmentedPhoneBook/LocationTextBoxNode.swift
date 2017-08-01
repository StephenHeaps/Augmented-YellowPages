//
//  LocationNode+Extensions.swift
//  AugmentedPhoneBook
//
//  Created by Stephen Heaps on 2017-08-01.
//  Copyright © 2017 Stephen Heaps. All rights reserved.
//

import Foundation
import UIKit
import ARKit
import SceneKit
import CoreLocation
import ARCL

// subclass of LocationNode to allow us to draw a box with text and an image, instead of just drawing an image at the Node's location
public class LocationTextBoxNode: LocationNode {
    public let annotationNode: SCNNode
    public var scaleRelativeToDistance = false
    
    public init(location: CLLocation?, business: Business) {
        annotationNode = BusinessSCNNode(business: business)
        
        let text = business.name
        let nsString = text as NSString
        let size = nsString.size(withAttributes: [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 24)])
        
        let layer = CALayer()
        layer.frame = CGRect(x: 0, y: 0, width: round(size.width) + 20, height: 100)
        layer.backgroundColor = UIColor.yellow.cgColor
        
        let imageLayer = CALayer()
        if let image = UIImage(named: "book") {
            imageLayer.contents = image.cgImage
            imageLayer.contentsGravity = kCAGravityResizeAspect
            imageLayer.frame = CGRect(origin: CGPoint(x: 10, y: 10), size: CGSize(width: 80, height: 80))
            layer.frame = CGRect(x: 0, y: 0, width: layer.bounds.width + imageLayer.bounds.width + 10, height: 100)
        }
        layer.addSublayer(imageLayer)
        
        let textLayer = VerticallyCentredTextLayer()
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.frame = CGRect(x: (imageLayer.bounds.width > 0) ? 10 + imageLayer.bounds.width + 10 : 10, y: 0, width: size.width, height: 100)
        textLayer.fontSize = 24
        textLayer.string = text
        textLayer.alignmentMode = kCAAlignmentLeft
        textLayer.foregroundColor = UIColor.black.cgColor
        textLayer.display()
        layer.addSublayer(textLayer)
        
        let box = SCNBox(width: layer.bounds.width, height: 100, length: 10, chamferRadius: 0.5)
        
        layer.shouldRasterize = true
        
        let material = SCNMaterial()
        material.diffuse.contents = layer
        material.specular.contents = layer
        material.ambient.contents = layer
        material.transparency = 1
        
        let material2 = SCNMaterial()
        material2.diffuse.contents = UIColor.darkGray
        let material3 = SCNMaterial()
        material3.diffuse.contents = UIColor.darkGray
        let material4 = SCNMaterial()
        material4.diffuse.contents = UIColor.darkGray
        let material5 = SCNMaterial()
        material5.diffuse.contents = UIColor.darkGray
        let material6 = SCNMaterial()
        material6.diffuse.contents = UIColor.darkGray
        box.materials = [material, material2, material3, material4, material5, material6]
        
        annotationNode.geometry = box
        
        super.init(location: location)
        
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        constraints = [billboardConstraint]
        
        addChildNode(annotationNode)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// allow us to store a business within a SCNNode for easy retrieval
public class BusinessSCNNode: SCNNode {
    public let business: Business
    public init(business: Business) {
        self.business = business
        
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class VerticallyCentredTextLayer: CATextLayer {
    override init() {
        super.init()
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(layer: aDecoder)
    }
    
    override func draw(in ctx: CGContext) {
        let height = self.bounds.size.height
        let fontSize = self.fontSize
        let yDiff = (height-fontSize)/2 - fontSize/10
        
        ctx.saveGState()
        ctx.translateBy(x: 0, y: yDiff)
        super.draw(in: ctx)
        ctx.restoreGState()
    }
}
