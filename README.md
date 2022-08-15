# [Introduction to ReplayKit with Swift 4 - iOS Screencast / Video Tutorial](https://youtu.be/PZc8ZFRDdrE)



```swift
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
```
