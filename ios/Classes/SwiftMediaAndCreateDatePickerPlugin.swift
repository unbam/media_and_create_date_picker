import Flutter
import UIKit
import Photos

public class SwiftMediaAndCreateDatePickerPlugin: NSObject, FlutterPlugin, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
  
  var picker: UIImagePickerController! = UIImagePickerController()
  var controller : FlutterViewController?
  var pickResult: FlutterResult?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "media_and_create_date_picker", binaryMessenger: registrar.messenger())
    let instance = SwiftMediaAndCreateDatePickerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    self.controller = UIApplication.shared.keyWindow?.rootViewController as? FlutterViewController;
    self.pickResult = result
    
    if("pickMedia" == call.method) {
      
      if PHPhotoLibrary.authorizationStatus() != .authorized {
          PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
             self.mediaPicker(result: result)
            } else if status == .denied {
             // JSON
             var jsonObj = Dictionary<String, Any>()
             jsonObj["path"] = ""
             jsonObj["createDate"] = ""
             jsonObj["type"] = "unknown"
             jsonObj["error"] = "PERMISSION_DENIED"
              do {
                let jsonData = try JSONSerialization.data(withJSONObject: jsonObj)
                let jsonStr = String(bytes: jsonData, encoding: .utf8)!
                self.pickResult?(jsonStr)
              } catch {
                self.pickResult?(error)
              }
            }
          }
      }
      else {
        self.mediaPicker(result: result)
      }
    }
    else {
      self.pickResult?(FlutterMethodNotImplemented)
    }
  }
  
  public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

    var phAsset: PHAsset? = nil
    if #available(iOS 11.0, *) {
      phAsset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset
      do {
        var path : String = ""
        var type: String = "unknown"

        // image
        if(phAsset!.mediaType == PHAssetMediaType.image) {
          type = "image"
          let url = info[UIImagePickerController.InfoKey.imageURL] as! URL
          path = url.path
          NSLog("imageURL: " + path)
        }
        // video
        else if(phAsset!.mediaType == PHAssetMediaType.video) {
          type = "video"
          let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as! URL
          
          // >= iOS13
          if #available(iOS 13.0, *) {
            path = self.createTemporaryURLforVideoFile(url: videoURL as NSURL).path!
            //NSLog(">=iOS13")
          }
          // < iOS13
          else {
            path = videoURL.path
          }
          
          NSLog("videoURL: " + path)
        }
        else {
          NSLog("unknown")
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let creationDateString = formatter.string(from: (phAsset?.creationDate)!)

        // JSON
        var jsonObj = Dictionary<String, Any>()
        jsonObj["path"] = path
        jsonObj["createDate"] = creationDateString
        jsonObj["type"] = type
        jsonObj["error"] = ""

        let jsonData = try JSONSerialization.data(withJSONObject: jsonObj)
        let jsonStr = String(bytes: jsonData, encoding: .utf8)!
        self.controller?.dismiss(animated: true, completion: nil)
        self.pickResult?(jsonStr)
      } catch(let e) {
        self.pickResult?(e)
      }
    } else {
      self.pickResult?(FlutterMethodNotImplemented)
    }
  }
  
  private func mediaPicker(result: @escaping FlutterResult) {
    self.picker.mediaTypes = ["public.image", "public.movie"]
    self.picker.delegate = self
    self.controller?.present(self.picker, animated: true, completion: nil)
  }
  
  private func createTemporaryURLforVideoFile(url: NSURL) -> NSURL {
      let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
      let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(url.lastPathComponent ?? "")
      do {
          try FileManager().copyItem(at: url.absoluteURL!, to: temporaryFileURL)
      } catch {
          NSLog("There was an error copying the video file to the temporary location.")
      }

      return temporaryFileURL as NSURL
  }
}
