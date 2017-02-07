//
//  GameScene.swift
//  Game_Firing
//
//  Created by hhh on 2017-01-12.
//  Copyright © 2017 hhh. All rights reserved.
//

import SpriteKit
import GameplayKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    var player: SKSpriteNode?
    var item: SKSpriteNode?
    var enemy: SKSpriteNode?
    var fireRate: TimeInterval = 0.5
    var timeSinceFire: TimeInterval = 0
    var lastUpdateTime: TimeInterval = 0
    var label: SKLabelNode?
    var currentPoints: Int = 0

    let noCategory: UInt32 = 0
    let laserCategory: UInt32 = 0b1
    let playerCategory: UInt32 = 0b1 << 1
    let enemyCategory: UInt32 = 0b1 << 2
    let itemCategory: UInt32 = 0b1 << 3


    override func didMove(to view: SKView) {
        self.physicsWorld.contactDelegate = self

        label = self.childNode(withName: "label") as? SKLabelNode

        player = self.childNode(withName: "player") as? SKSpriteNode
        player?.physicsBody?.categoryBitMask = playerCategory
        player?.physicsBody?.collisionBitMask = noCategory
        player?.physicsBody?.contactTestBitMask = enemyCategory | itemCategory

        item = self.childNode(withName: "item") as? SKSpriteNode
        item?.physicsBody?.categoryBitMask = itemCategory
        item?.physicsBody?.collisionBitMask = noCategory
        item?.physicsBody?.contactTestBitMask = playerCategory

        enemy = self.childNode(withName: "enemy") as? SKSpriteNode
        enemy?.physicsBody?.categoryBitMask = enemyCategory
        enemy?.physicsBody?.collisionBitMask = noCategory
        enemy?.physicsBody?.contactTestBitMask = laserCategory | playerCategory

        let action: SKAction = SKAction.moveBy(x: -200, y: 0, duration: 1)
        action.timingMode = .easeInEaseOut
        let reverseAction: SKAction = action.reversed()
        let sequenceAction: SKAction = SKAction.sequence([action, reverseAction])
        let repeatAction = SKAction.repeatForever(sequenceAction)
        item?.run(repeatAction, withKey: "repeatAction")

        let frame1: SKTexture = SKTexture(imageNamed: "player")
        let frame2: SKTexture = SKTexture(imageNamed: "player_frame2")
        let frame3: SKTexture = SKTexture(imageNamed: "player_frame3")
        let frame4: SKTexture = SKTexture(imageNamed: "player_frame4")
        let animation: SKAction = SKAction.animate(with: [frame1, frame2, frame3, frame4], timePerFrame: 0.1)
        let repeatAnimation: SKAction = SKAction.repeatForever(animation)
        player?.run(repeatAnimation)

        let audio: SKAudioNode = SKAudioNode(fileNamed: "music.m4a")
        self.addChild(audio)

        do {
            let sounds: [String] = ["laser", "explosion"]
            for sound in sounds {
                let path: String = Bundle.main.path(forResource: sound, ofType: "wav")!
                let url: URL = URL(fileURLWithPath: path)
                let playerAudio: AVAudioPlayer = try AVAudioPlayer(contentsOf: url)
                playerAudio.prepareToPlay()
            }
        } catch { print("Audio player error") }


    }

    func didBegin(_ contact: SKPhysicsContact) {
        let contactA: UInt32 = contact.bodyA.categoryBitMask
        let contactB: UInt32 = contact.bodyB.categoryBitMask
        if contactA == playerCategory || contactB == playerCategory {
            let otherNode: SKNode = (contactA == playerCategory) ? contact.bodyB.node! : contact.bodyA.node!
            playerDidCollide(with: otherNode)

        } else {
            let explosion: SKEmitterNode = SKEmitterNode(fileNamed: "Spark")!
            explosion.position = contact.bodyA.node!.position
            self.addChild(explosion)
            self.run(SKAction.playSoundFileNamed("explosion", waitForCompletion: false))
            contact.bodyA.node?.removeFromParent()
            contact.bodyB.node?.removeFromParent()

        }


    }

    func playerDidCollide(with otherNode: SKNode) {
        if otherNode.parent == nil {
            return
        }

        let otherNodeCategory = otherNode.physicsBody?.categoryBitMask
        if otherNodeCategory == enemyCategory {
            otherNode.removeFromParent()
            player?.removeFromParent()
        } else if otherNodeCategory == itemCategory {
            self.currentPoints += otherNode.userData?.value(forKey: "points") as! Int
            didPointChange(update: self.currentPoints)
            otherNode.removeFromParent()

        }
    }

    func didPointChange(update label: Int) {

        self.label?.text = "Score: \(label) points"
    }

    func touchDown(atPoint pos: CGPoint) {
        player?.position = pos
//        item?.removeAction(forKey: "repeatAction")
    }

    func touchMoved(toPoint pos: CGPoint) {

    }

    func touchUp(atPoint pos: CGPoint) {

    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {


        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }


    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        checkLaster(currentTime - lastUpdateTime)
        lastUpdateTime = currentTime

    }

    func checkLaster(_ frameRate: TimeInterval) {
        timeSinceFire += frameRate
        if timeSinceFire < fireRate {
            return
        }

        fire()
        timeSinceFire = 0
    }

    func fire() {
        let scene: SKScene = SKScene(fileNamed: "Laser")!
        let laser = scene.childNode(withName: "fire")
        laser?.position = player!.position
        laser?.move(toParent: self)
        laser?.physicsBody?.categoryBitMask = laserCategory
        laser?.physicsBody?.collisionBitMask = noCategory
        laser?.physicsBody?.contactTestBitMask = enemyCategory
        self.run(SKAction.playSoundFileNamed("laser", waitForCompletion: false))

        let action: SKAction = SKAction.wait(forDuration: 1)
        let removeFromParent: SKAction = SKAction.removeFromParent()
        laser?.run(SKAction.sequence([action, removeFromParent]))
    }
}
