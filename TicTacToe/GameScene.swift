/// Copyright (c) 2017 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import SpriteKit
import GameplayKit
import ReplayKit

class GameScene: SKScene {
  
  // MARK: - Properties
  
  var boardNode: SKSpriteNode!
  var informationLabel: SKLabelNode!
	var recordButton: SKSpriteNode!
  var gamePieceNodes = [SKNode]()
	weak var viewController: UIViewController!
	
	var cameraButton: SKSpriteNode!
	var cameraView: UIView?
	var cameraFrame: CGRect!
	
  var board = Board()
  var strategist: Strategist!

  // MARK: - Scene Loading
  
  override func didMove(to view: SKView) {
    super.didMove(to: view)
    
    anchorPoint = CGPoint(x: 0.5, y: 0.5)
    
    let backgroundNode = SKSpriteNode(imageNamed: "wood-bg")
    addChild(backgroundNode)
    
    let boardWidth = view.frame.width - 24
    let borderHeight = ((view.frame.height - boardWidth) / 2) - 24
    
    boardNode = SKSpriteNode(
      texture: SKTexture(imageNamed: "board"),
      size: CGSize(width: boardWidth, height: boardWidth)
    )
    addChild(boardNode)
    
    let headerNode = SKSpriteNode(
      color: UIColor(red: 46/255, green: 46/255, blue: 46/255, alpha: 1),
      size: CGSize(width: view.frame.width, height: borderHeight)
    )
    headerNode.alpha = 0.65
    headerNode.position.y = (view.frame.height / 2) - (borderHeight / 2)
    addChild(headerNode)
    
    informationLabel = SKLabelNode(fontNamed: "HandDrawnShapes")
    informationLabel.fontSize = UIDevice.current.userInterfaceIdiom == .pad ? 63 : 40
    informationLabel.fontColor = .white
    informationLabel.position = headerNode.position
    informationLabel.verticalAlignmentMode = .center
    addChild(informationLabel)
		
		recordButton = SKSpriteNode(imageNamed: "record")
		recordButton.position = CGPoint(x: (-boardWidth / 2.0) + 16, y: -(view.frame.height / 2) + 28)
		addChild(recordButton)
		
		cameraButton = SKSpriteNode(imageNamed: "camera")
		cameraButton.position = CGPoint(x: (-boardWidth / 2.0) + 64, y: -(view.frame.height / 2) + 26)
		cameraButton.isHidden = true
		addChild(cameraButton)
		
		cameraFrame = CGRect(x: view.frame.width - 112, y: view.frame.height - 132, width: 100.0, height: 120.0)
    strategist = Strategist(board: board)

    resetGame()
    updateGame()
  }
  
  // MARK: - Game Logic
  
  fileprivate func resetGame() {
    let actions = [
      SKAction.scale(to: 0, duration: 0.25),
      SKAction.customAction(withDuration: 0.5, actionBlock: { node, duration in
        node.removeFromParent()
      })
    ]
    gamePieceNodes.forEach { node in
      node.run(SKAction.sequence(actions))
    }
    gamePieceNodes.removeAll()
    
    board = Board()
    strategist.board = board

  }
  
  fileprivate func updateGame() {
    var gameOverTitle: String? = nil
    
    if let winner = board.winningPlayer, winner == board.currentPlayer {
      gameOverTitle = "\(winner.name) Wins!"
    } else if board.isFull {
      gameOverTitle = "Draw"
    }
    
    if gameOverTitle != nil {
      let alert = UIAlertController(title: gameOverTitle, message: nil, preferredStyle: .alert)
      let alertAction = UIAlertAction(title: "Play Again", style: .default) { _ in
        self.resetGame()
        self.updateGame()
      }
      
      alert.addAction(alertAction)
      view?.window?.rootViewController?.present(alert, animated: true)
      
      return
    }
    
    board.currentPlayer = board.currentPlayer.opponent
    informationLabel.text = "\(board.currentPlayer.name)'s Turn"
    
    if board.currentPlayer.value == .brain {
      processAIMove()
    }
  }
  
  fileprivate func updateBoard(with x: Int, y: Int) {
    guard board[x, y] == .empty else { return }
    
    board[x, y] = board.currentPlayer.value
    let sizeValue = boardNode.size.width / 3 - 20
    let spriteSize = CGSize(
      width: sizeValue,
      height: sizeValue
    )
    
    var nodeImageName: String
    
    if board.currentPlayer.value == .zombie {
      nodeImageName = "zombie-head"
    } else {
      nodeImageName = "brain"
    }
    
    let pieceNode = SKSpriteNode(imageNamed: nodeImageName)
    pieceNode.size = CGSize(
      width: spriteSize.width / 2,
      height: spriteSize.height / 2
    )
    pieceNode.position = position(for: CGPoint(x: x, y: y))
    addChild(pieceNode)
    
    gamePieceNodes.append(pieceNode)
    
    pieceNode.run(SKAction.scale(by: 2, duration: 0.25))
    
    updateGame()
  }
  
  fileprivate func position(for boardCoordinate: CGPoint) -> CGPoint {
    let boardWidth = boardNode.size.width
    let halfThirdOfBoard = (boardWidth / 3) / 2
    
    var xPosition: CGFloat = 0
    var yPosition: CGFloat = 0
    
    if boardCoordinate.x == 0 {
      xPosition = -((boardWidth / 2) - halfThirdOfBoard)
    } else if boardCoordinate.x == 1 {
      xPosition = 0
    } else if boardCoordinate.x == 2 {
      xPosition = (boardWidth / 2) - halfThirdOfBoard
    }
    
    if boardCoordinate.y == 0 {
      yPosition = (boardWidth / 2) - halfThirdOfBoard
    } else if boardCoordinate.y == 1 {
      yPosition = 0
    } else if boardCoordinate.y == 2 {
      yPosition = -((boardWidth / 2) - halfThirdOfBoard)
    }
    
    return CGPoint(x: xPosition, y: yPosition + boardNode.position.y)
  }
  
  
  fileprivate func processAIMove() {
    // 1
    DispatchQueue.global().async { [unowned self] in
      // 2
      let strategistTime = CFAbsoluteTimeGetCurrent()
      guard let bestCoordinate = self.strategist.bestCoordinate else {
        return
      }
      // 3
      let delta = CFAbsoluteTimeGetCurrent() - strategistTime
      
      let aiTimeCeiling = 0.75
      // 4
      let delay = max(delta, aiTimeCeiling)
      // 5
      DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        self.updateBoard(with: Int(bestCoordinate.x), y: Int(bestCoordinate.y))
      }
    }
  }
  
  // MARK: - Touches
  
  fileprivate func processTouchOnBoard(touch: UITouch) {
    let locationInBoard = touch.location(in: boardNode)
    let halfThirdOfBoard = (boardNode.size.width / 3) / 2
    
    var boardCoordinate: CGPoint = .zero
    
    if locationInBoard.x > halfThirdOfBoard {
      boardCoordinate.x = 2
    } else if locationInBoard.x < -halfThirdOfBoard {
      boardCoordinate.x = 0
    } else {
      boardCoordinate.x = 1
    }
    
    if locationInBoard.y > halfThirdOfBoard {
      boardCoordinate.y = 0
    } else if locationInBoard.y < -halfThirdOfBoard {
      boardCoordinate.y = 2
    } else {
      boardCoordinate.y = 1
    }
    
    updateBoard(with: Int(boardCoordinate.x), y: Int(boardCoordinate.y))
  }
    
  fileprivate func handleTouchEnd(_ touches: Set<UITouch>, with event: UIEvent?) {
    
    guard board.currentPlayer.value == .zombie else {
      return
    }
    
    for touch in touches {
      for node in nodes(at: touch.location(in: self)) {
        if node == boardNode {
          processTouchOnBoard(touch: touch)
				} else if node == recordButton {
					processTouchRecord()
				} else if node == cameraButton {
					processTouchCamera()
				}
      }
    }
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    
    handleTouchEnd(touches, with: event)
  }
  
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesCancelled(touches, with: event)
    
    handleTouchEnd(touches, with: event)
  }
	
	// MARK: - ReplayKit
	fileprivate func processTouchRecord() {
    let recorder = RPScreenRecorder.shared()
    if !recorder.isRecording {
      recorder.startRecording() { (error) in
        guard error == nil else {
          print("Failed to start recording")
          return
        }
        self.recordButton.texture = SKTexture(imageNamed: "stop")
      }
    } else {
      recorder.stopRecording(handler:  { (previewController, error) in
        guard error == nil else {
          print("Failed to stop recording")
          return
        }
        previewController?.previewControllerDelegate = self
        self.viewController.present(previewController!, animated: true)
        self.recordButton.texture = SKTexture(imageNamed: "record")
        
      })
    }

	}
	
	fileprivate func processTouchCamera() {
		// TODO: Handle camera button
	}
}

extension GameScene: RPPreviewViewControllerDelegate {
  
  func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
    viewController.dismiss(animated: true)
  }
}
