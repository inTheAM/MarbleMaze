//
//  GameScene.swift
//  MarbleMaze
//
//  Created by Ahmed Mgua on 06/09/2021.
//

import CoreMotion
import SpriteKit
import GameplayKit

class GameScene: SKScene {
    let game = Game()
	var motionManager: CMMotionManager!
	var player: SKSpriteNode!
	var lastTouchPosition: CGPoint?
	var scoreLabel: SKLabelNode!
	
    override func didMove(to view: SKView) {
		let background = SKSpriteNode(imageNamed: "background.jpg")
		background.position = CGPoint(x: 512, y: 384)
		background.blendMode = .replace
		background.zPosition = -1
		addChild(background)
		physicsWorld.gravity = .zero
		game.delegate = self
		game.loadLevel()
		createPLayer()
		motionManager = CMMotionManager()
		motionManager.startAccelerometerUpdates()
		scoreLabel = SKLabelNode(text: "Score: 0")
		scoreLabel.fontName = "Chalkduster"
		scoreLabel.horizontalAlignmentMode = .left
		scoreLabel.position = CGPoint(x: 16, y: 16)
		scoreLabel.zPosition = 2
		addChild(scoreLabel)
		physicsWorld.contactDelegate = self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first else { return }
		lastTouchPosition = touch.location(in: self)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first else { return }
		lastTouchPosition = touch.location(in: self)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPosition = nil
    }
	
    override func update(_ currentTime: TimeInterval) {
		guard !game.isGameOver else { return }
		#if targetEnvironment(simulator)
		if let currentTouch = lastTouchPosition {
			let difference = CGPoint(x: currentTouch.x - player.position.x, y: currentTouch.y - player.position.y)
			physicsWorld.gravity = CGVector(dx: difference.x / 100, dy: difference.y / 100)
		}
		#else
		if let acceleration = motionManager.accelerometerData?.acceleration {
			physicsWorld.gravity = CGVector(dx: acceleration.y * -50, dy: acceleration.x * 50)
		}
		
		#endif
    }
}

extension GameScene: SKPhysicsContactDelegate	{
	func didBegin(_ contact: SKPhysicsContact) {
		guard let nodeA = contact.bodyA.node else { return }
		guard let nodeB = contact.bodyB.node else { return }
		
		if nodeA == player {
			playerCollided(with: nodeB)
		} else if nodeB == player {
			playerCollided(with: nodeA)
		}
	}
	
	func playerCollided(with node: SKNode)	{
		if node.name == "vortex" {
			player.physicsBody?.isDynamic = false
			game.endGame()
			game.decreaseScore()
			let move = SKAction.move(to: node.position, duration: 0.25)
			let scale = SKAction.scale(to: 0.0001, duration: 0.25)
			let remove = SKAction.removeFromParent()
			let sequence = SKAction.sequence([move, scale, remove])
			player.run(sequence) { [weak self] in
				self?.createPLayer()
				self?.game.restart()
			}
		} else if node.name == "star" {
			node.removeFromParent()
			game.increaseScore()
			
		}	else if node.name == "finish"	{
//			load next level
		}
	}
}

extension GameScene: GameDelegate	{
	func didUpdateScore(_ score: Int) {
		scoreLabel.text = "Score: \(score)"
	}
	func didLoadLevel(_ level: EnumeratedSequence<ReversedCollection<[String]>>) {
		for (row, line) in level {
			for (column, letter) in line.enumerated()	{
				let position = CGPoint(x: (64 * column) + 32, y: (64 * row) + 32)
				
				if letter == "x" {
					let node = SKSpriteNode(imageNamed: "block")
					node.position = position
					
					node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
					node.physicsBody?.categoryBitMask = Game.ObjectType.wall.rawValue
					node.physicsBody?.isDynamic = false
					
					addChild(node)
					
				}	else if letter ==	"v"	{
					let node = SKSpriteNode(imageNamed: "vortex")
					node.name = "vortex"
					node.position = position
					node.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 1)))
					
					node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
					node.physicsBody?.isDynamic = false
					node.physicsBody?.categoryBitMask = Game.ObjectType.vortex.rawValue
					node.physicsBody?.contactTestBitMask = Game.ObjectType.player.rawValue
					node.physicsBody?.collisionBitMask = 0
					
					addChild(node)
					
				}	else if letter == 	"s"	{
					let node = SKSpriteNode(imageNamed: "star")
					node.name = "star"
					node.position = position
					
					node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
					node.physicsBody?.isDynamic = false
					node.physicsBody?.categoryBitMask = Game.ObjectType.star.rawValue
					node.physicsBody?.contactTestBitMask = Game.ObjectType.player.rawValue
					node.physicsBody?.collisionBitMask = 0
					
					addChild(node)
					
				}	else if letter ==	"f"	{
					let node = SKSpriteNode(imageNamed: "finish")
					node.name = "finish"
					node.position = position
					
					node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
					node.physicsBody?.isDynamic = false
					node.physicsBody?.categoryBitMask = Game.ObjectType.finish.rawValue
					node.physicsBody?.contactTestBitMask = Game.ObjectType.player.rawValue
					node.physicsBody?.collisionBitMask = 0
					
					addChild(node)
					
				}	else if letter ==	" "	{
					
				}	else	{
					fatalError("Unknown character in level file")
				}
			}
		}
	}
	
	func createPLayer()	{
		player = SKSpriteNode(imageNamed: "player")
		player.position = CGPoint(x: 96, y: 672)
		player.zPosition = 1
		
		player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
		player.physicsBody?.allowsRotation = false
		player.physicsBody?.linearDamping = 0.5
		player.physicsBody?.categoryBitMask = Game.ObjectType.player.rawValue
		player.physicsBody?.contactTestBitMask = Game.ObjectType.star.rawValue | Game.ObjectType.vortex.rawValue | Game.ObjectType.finish.rawValue
		player.physicsBody?.collisionBitMask = Game.ObjectType.wall.rawValue
		
		addChild(player)
	}
}
