//
//  Game.swift
//  MarbleMaze
//
//  Created by Ahmed Mgua on 06/09/2021.
//

import Foundation

protocol	GameDelegate	{
	func didLoadLevel(_ level: EnumeratedSequence<ReversedCollection<[String]>>)
	func didUpdateScore(_ score: Int)
}

class Game	{
	var delegate: GameDelegate?
	var score = 0 {
		didSet	{
			delegate?.didUpdateScore(score)
		}
	}
	var isGameOver = false
}

extension Game {
	func loadLevel()	{
		guard let levelURL = Bundle.main.url(forResource: "level1", withExtension: "txt") else {
			fatalError("Could not find level 1 in bundle")
		}
		
		guard let levelString = try? String(contentsOf: levelURL) else {
			fatalError("Could not parse level file")
		}
		let lines = levelString.components(separatedBy: "\n").reversed().enumerated()
		delegate?.didLoadLevel(lines)
	}
	
	func increaseScore()	{
		score += 1
	}
	func decreaseScore()	{
		score -= 1
	}
	
	func endGame()	{
		isGameOver = true
	}
	func restart()	{
		isGameOver = false
	}
}

extension Game {
	enum ObjectType:	UInt32	{
		case player =	1,
			 wall	=	2,
			 star	=	4,
			 vortex	=	8,
			 finish	=	16
	}
}
