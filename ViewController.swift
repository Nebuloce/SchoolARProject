//
//  ViewController.swift
//  FinalTerm
//
//  Created by Travis Chiasson on 2018-08-06.
//  Copyright © 2018 Travis Chiasson. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

import SceneKit


enum BodyType : Int {
    case box = 1
    case plane = 2
    case sphere = 3
    case bullet = 4
    case barrier = 5
    case cylinderL = 6
    case cylinderR = 7
    case rectangleL = 8
//    case rectangleR = 9
//    case rectangleT = 10
    case coneL = 11
    case coneR = 12
}



struct CollisionMask: OptionSet {
    let rawValue: Int
    
    static let rigidBody = CollisionMask(rawValue: 1)
    
    static let ball = CollisionMask(rawValue: 4)
}


class ViewController: UIViewController, ARSCNViewDelegate {
    

    @IBOutlet var sceneView: ARSCNView!
    var lastContactNode :SCNNode!
    var planes = [OverlayPlane]()
    
//    private var hud :MBProgressHUD!
    

    private var newAngleY :Float = 0.0
    private var currentAngleY :Float = 0.0
    private var localTranslatePosition :CGPoint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//
//        self.hud = MBProgressHUD.showAdded(to: self.sceneView, animated: true)
//        self.hud.label.text = "Detecting Plane..."
        
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints,ARSCNDebugOptions.showWorldOrigin]
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        sceneView.scene = scene
        
        registerGestureRecognizers()
    }
    
    public func degToRadians(degrees:Double) -> Double
    {
        return degrees * (Double.pi / 180);
    }
    
    
    
    func setupCamera() {
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }

        camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = -1
        camera.maximumExposure = 3
    }
    
    struct myCameraCoordinates {
        var x = Float()
        var y = Float()
        var z = Float()
    }
    
    func getCameraCoordinates(sceneView: ARSCNView) -> myCameraCoordinates {
        let cameraTransform = sceneView.session.currentFrame?.camera.transform
        let cameraCoordinates = MDLTransform(matrix: cameraTransform!)
        
        var cc = myCameraCoordinates()
        cc.x = cameraCoordinates.translation.x
        cc.y = cameraCoordinates.translation.y
        cc.z = cameraCoordinates.translation.z
        
        return cc
    }
    
    func randomFloat(min: Float, max: Float) -> Float {
        return (Float(arc4random()) / 0xFFFFFFFF) * (max - min) + min
    }
    
    @IBAction func createCone(_ sender: Any) {
        
        guard let currentFrame = self.sceneView.session.currentFrame else {
            return
        }
        
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -0.7
        
        
        let coneL = SCNCone(topRadius: 0.0, bottomRadius: 0.1, height: 0.1)
        
        let cobbleCone = SCNMaterial()
        cobbleCone.diffuse.contents = UIImage(named :"./cobbleCone.jpeg")
        
        let coneLNode = SCNNode()
        coneLNode.geometry = coneL
        coneLNode.geometry?.materials = [cobbleCone]
        coneLNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: coneL, options: [:]))
        coneLNode.physicsBody?.categoryBitMask = BodyType.coneL.rawValue
  
        coneLNode.simdTransform = matrix_multiply(currentFrame.camera.transform, translation)
        
        
        self.sceneView.scene.rootNode.addChildNode(coneLNode)
        
    }
    
    @IBAction func createRec(_ sender: Any) {
        
        guard let currentFrame = self.sceneView.session.currentFrame else {
            return
        }

        var translation = matrix_identity_float4x4
        translation.columns.3.z = -0.7

        
        let cobbleRec = SCNMaterial()
        cobbleRec.diffuse.contents = UIImage(named :"./cobbleRec.jpeg")
        
        let rectangleL = SCNBox(width: 0.13, height: 0.18, length: 0.13, chamferRadius: 0)
        
        let rectangleLNode = SCNNode()
        rectangleLNode.geometry = rectangleL
        rectangleLNode.geometry?.materials = [cobbleRec]
        rectangleLNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: rectangleL, options: [:]))
        rectangleLNode.physicsBody?.categoryBitMask = BodyType.rectangleL.rawValue
        
        rectangleLNode.simdTransform = matrix_multiply(currentFrame.camera.transform, translation)
        
        self.sceneView.scene.rootNode.addChildNode(rectangleLNode)
        
    }
    @IBAction func createCastle(_ sender: Any) {
        
                guard let currentFrame = self.sceneView.session.currentFrame else {
                    return
                }
        
                var translation = matrix_identity_float4x4
                translation.columns.3.z = -0.9
        

                let cobble1 = SCNMaterial()
                cobble1.diffuse.contents = UIImage(named :"./cobble1.jpeg")
        
                let cylinderL = SCNCylinder(radius: 0.06, height: 0.2)
        

                let cylinderLNode = SCNNode()
                cylinderLNode.geometry = cylinderL
                cylinderLNode.geometry?.materials = [cobble1]
        
                cylinderLNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: cylinderL, options: [:]))
                cylinderLNode.physicsBody?.categoryBitMask = BodyType.cylinderL.rawValue
        
                cylinderLNode.simdTransform = matrix_multiply(currentFrame.camera.transform, translation)
        
        

                self.sceneView.scene.rootNode.addChildNode(cylinderLNode)
        
    }
    
    private func registerGestureRecognizers() {
        
        //        let doubleTappedGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        //        doubleTappedGestureRecognizer.numberOfTapsRequired = 2
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        tapGestureRecognizer.numberOfTapsRequired = 1
        
        let tapGestureRecognizer2 = UITapGestureRecognizer(target: self, action: #selector(shoot))
        tapGestureRecognizer2.numberOfTapsRequired = 2
        
//        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector
//            (longPressed))
//
//        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panned))
        
        tapGestureRecognizer.require(toFail: tapGestureRecognizer2)
        
//        self.sceneView.addGestureRecognizer(panGestureRecognizer)
//        self.sceneView.addGestureRecognizer(longPressGestureRecognizer)
        self.sceneView.addGestureRecognizer(tapGestureRecognizer2)
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)

    }
    
//    @objc func longPressed(recognizer :UILongPressGestureRecognizer) {
//
//        guard let sceneView = recognizer.view as? ARSCNView else {
//            return
//        }
//
//        let touch = recognizer.location(in: sceneView)
//
//        let hitTestResults = self.sceneView.hitTest(touch, options: nil)
//
//        if let hitTest = hitTestResults.first {
//
//            if let parentNode = hitTest.node.parent {
//
//                if recognizer.state == .began {
//                    localTranslatePosition = touch
//                } else if recognizer.state == .changed {
//
//                    let deltaX = Float(touch.x - self.localTranslatePosition.x)/700
//                    let deltaY = Float(touch.y - self.localTranslatePosition.y)/700
//
//                    parentNode.localTranslate(by: SCNVector3(deltaX,0.0,deltaY))
//                    self.localTranslatePosition = touch
//
//                }
//
//            }
//
//        }
//
//    }
//
//    @objc func panned(recognizer :UIPanGestureRecognizer) {
//
//        if recognizer.state == .changed {
//
//            guard let sceneView = recognizer.view as? ARSCNView else {
//                return
//            }
//
//            let touch = recognizer.location(in: sceneView)
//            let translation = recognizer.translation(in: sceneView)
//
//            let hitTestResults = self.sceneView.hitTest(touch, options: nil)
//
//            if let hitTest = hitTestResults.first {
//
//                if let parentNode = hitTest.node.parent {
//
//                    self.newAngleY = Float(translation.x) * (Float) (Double.pi)/180
//                    self.newAngleY += self.currentAngleY
//                    parentNode.eulerAngles.y = self.newAngleY
//
//                }
//
//            }
//
//        }
//        else if recognizer.state == .ended {
//            self.currentAngleY = self.newAngleY
//        }
//    }
    
    
    @objc func tapped(recognizer :UIGestureRecognizer) {
        
        let sceneView = recognizer.view as! ARSCNView
        let touch = recognizer.location(in: sceneView)
        
        let hitResults = sceneView.hitTest(touch, types: .existingPlaneUsingExtent)
        
        
        if !hitResults.isEmpty {
            
            guard let hitResult = hitResults.first else {
                return
            }
            
            
            addBox(hitResult :hitResult)
        }
    }

    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
        var contactNode :SCNNode!
        
        if contact.nodeA.name == "Bullet" {
            contactNode = contact.nodeB
        } else {
            contactNode = contact.nodeA
        }
        
        if self.lastContactNode != nil && self.lastContactNode == contactNode {
            return
        }
        
        self.lastContactNode = contactNode
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.green
        
        self.lastContactNode.geometry?.materials = [material]
    }

    
    @objc func shoot(recognizer :UIGestureRecognizer) {
        
        guard let currentFrame = self.sceneView.session.currentFrame else {
            return
        }
        
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -0.3
        
        let box = SCNBox(width: 0.05, height: 0.05, length: 0.05, chamferRadius: 0.05)
        
        let bullet = SCNMaterial()
        bullet.diffuse.contents = UIImage(named :"./cannonball.jpeg")
        
        let boxNode = SCNNode(geometry: box)
        boxNode.name = "Bullet"
        boxNode.geometry?.materials = [bullet]
        boxNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        boxNode.physicsBody?.categoryBitMask = BodyType.bullet.rawValue
        boxNode.physicsBody?.contactTestBitMask = BodyType.barrier.rawValue
        boxNode.physicsBody?.mass = 20.0
        boxNode.physicsBody?.isAffectedByGravity = false
        
        boxNode.simdTransform = matrix_multiply(currentFrame.camera.transform, translation)
        
        let forceVector = SCNVector3(boxNode.worldFront.x * 40 ,boxNode.worldFront.y * 40 ,boxNode.worldFront.z * 40)
        
        boxNode.physicsBody?.applyForce(forceVector, asImpulse: true)
        self.sceneView.scene.rootNode.addChildNode(boxNode)
        
    }
    
    private func addBox(hitResult :ARHitTestResult) {
        
        let offsetY = 0.5
        let box = SCNBox(width: 0.13, height: 0.13, length: 0.13, chamferRadius: 0)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named :"./block.jpeg")
        
        
        let node = SCNNode()
        node.name = "BOX"
        node.geometry = box
        node.geometry?.materials = [material]
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: box, options: [:]))
        node.physicsBody?.categoryBitMask = BodyType.box.rawValue
        
        
        node.position = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y + Float(offsetY), hitResult.worldTransform.columns.3.z)
        
        
        self.sceneView.scene.rootNode.addChildNode(node)
        
    }
    
    //    private func addSphere(hitResult :ARHitTestResult) {
    //
    //        let offsetY = 0.5
    //
    ////        let sphereMaterial = SCNMaterial()
    ////        sphereMaterial.diffuse.contents = UIImage(named :"./soccer.png")
    //
    //        let sphere = SCNSphere(radius: 0.08)
    //
    //
    //        let sphereNode = SCNNode()
    //        sphereNode.geometry = sphere
    ////        sphereNode.geometry?.materials = [sphereMaterial]
    //        sphereNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: sphere, options: [:]))
    //        sphereNode.physicsBody?.categoryBitMask = BodyType.sphere.rawValue
    //        sphereNode.physicsBody?.applyForce(SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y + Float(offsetY), hitResult.worldTransform.columns.3.z), asImpulse: true)
    //
    //
    //        sphereNode.position = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y + Float(offsetY), hitResult.worldTransform.columns.3.z)
    //
    //
    //        self.sceneView.scene.rootNode.addChildNode(sphereNode)
    //
    //    }
    
    //    @objc func doubleTapped(recognizer :UIGestureRecognizer) {
    //        let sceneView = recognizer.view as! ARSCNView
    //        let touch = recognizer.location(in: sceneView)
    //
    //        let hitResults = sceneView.hitTest(touch, types: .existingPlaneUsingExtent)
    //
    //        if !hitResults.isEmpty {
    //            guard let hitResult = hitResults.first else {
    //                return
    //            }
    //
    //            addSphere(hitResult :hitResult)
    //
    //        }
    //    }
    //
    
    
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {

        let plane = self.planes.filter { plane in
            return plane.anchor.identifier == anchor.identifier
            }.first

        if plane == nil {
            return
        }

        plane?.update(anchor: anchor as! ARPlaneAnchor)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        if !(anchor is ARPlaneAnchor) {
            return
        }
        
        let plane = OverlayPlane(anchor: anchor as! ARPlaneAnchor)
        self.planes.append(plane)
        node.addChildNode(plane)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
}
