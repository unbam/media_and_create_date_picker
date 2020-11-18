import Flutter
import UIKit
import Photos
import PhotosUI

public class SwiftMediaAndCreateDatePickerPlugin: NSObject, FlutterPlugin, UINavigationControllerDelegate, UIImagePickerControllerDelegate, PHPickerViewControllerDelegate {
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
    
    if "pickMedia" == call.method {
      // >= iOS14
      if #available(iOS 14.0, *) {
        //NSLog(">=iOS14")
        if PHPhotoLibrary.authorizationStatus(for: .readWrite) != .authorized {
          self.requestAuthorization(result: result)
        }
        else {
          self.mediaPicker(result: result)
        }
      }
      // < iOS13
      else {
        //NSLog("<iOS14")
        if PHPhotoLibrary.authorizationStatus() != .authorized {
          self.requestAuthorization(result: result)
        }
        else {
          self.mediaPicker(result: result)
        }
      }
    }
    else {
      self.pickResult?(FlutterMethodNotImplemented)
    }
  }
  
  // For [ < iOS14 ]
  public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

    var phAsset: PHAsset? = nil
    if #available(iOS 11.0, *) {
      phAsset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset
      
      var path : String = ""
      var type: String = "unknown"

      // image
      if phAsset!.mediaType == PHAssetMediaType.image {
        type = "image"
        let url = info[UIImagePickerController.InfoKey.imageURL] as! URL
        path = url.path
      }
      // video
      else if phAsset!.mediaType == PHAssetMediaType.video {
        type = "video"
        let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as! URL
        
        // >= iOS13
        if #available(iOS 13.0, *) {
          path = self.createTemporaryURLforVideoFile(url: videoURL as NSURL).path!
        }
        // < iOS13
        else {
          path = videoURL.path
        }
      }
      
      self.result(type: type, asset: phAsset!, path: path)
    } else {
      self.pickResult?(FlutterMethodNotImplemented)
    }
  }
  
  // For [ < iOS14 ]
  public func imagePickerControllerDidCancel(_ picker: UIImagePickerController){
    picker.dismiss(animated: true)
    self.errorResult(resultType: "cancel", errMessage: "")
  }
  
  // For [ >= iOS14 ]
  @available(iOS 14, *)
  public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)
 
    if results.count == 0 {
      self.errorResult(resultType: "cancel", errMessage: "")
      return
    }
    
    let itemProviders = results.compactMap(\.assetIdentifier)
    let fetchResults = PHAsset.fetchAssets(withLocalIdentifiers: itemProviders, options: nil)

    if let phAsset = fetchResults.firstObject as PHAsset? {
      var type: String = "unknown"
      if phAsset.mediaType == .image {
        type = "image"
      }
      else if phAsset.mediaType == .video {
        type = "video"
      }
      
      phAsset.getURL(completionHandler: {url in
        self.result(type: type, asset: phAsset, path: url!.path)
      })
    }
    else {
      self.errorResult(resultType: "error", errMessage: "PERMISSION_SELECTION_DENIED")
    }
  }
  
  private func requestAuthorization(result: @escaping FlutterResult) {
    if PHPhotoLibrary.authorizationStatus() != .authorized {
        PHPhotoLibrary.requestAuthorization { status in
          if status == .authorized {
            self.mediaPicker(result: result)
          }
          else if status == .denied {
            self.errorResult(resultType: "error", errMessage: "PERMISSION_DENIED")
          }
        }
    }
    else {
      self.mediaPicker(result: result)
    }
  }
  
  private func mediaPicker(result: @escaping FlutterResult) {
    if #available(iOS 14.0, *) {
      let photoLibrary = PHPhotoLibrary.shared()
      var config = PHPickerConfiguration(photoLibrary: photoLibrary)
      config.selectionLimit = 1
      config.filter = .any(of: [.images, .videos])
      let picker = PHPickerViewController(configuration: config)
      picker.delegate = self
      self.controller?.present(picker, animated: true, completion: nil)
    }
    else {
      let picker: UIImagePickerController! = UIImagePickerController()
      picker.mediaTypes = ["public.image", "public.movie"]
      picker.delegate = self
      self.controller?.present(picker, animated: true, completion: nil)
    }
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
  
  private func result(type: String, asset: PHAsset, path: String) {
    do {
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
      let creationDateString = formatter.string(from: (asset.creationDate)!)

      // Result JSON
      var jsonObj = Dictionary<String, Any>()
      jsonObj["path"] = path
      jsonObj["createDate"] = creationDateString
      jsonObj["mediaType"] = type
      jsonObj["resultType"] = "success"
      jsonObj["error"] = ""

      let jsonData = try JSONSerialization.data(withJSONObject: jsonObj)
      let jsonStr = String(bytes: jsonData, encoding: .utf8)!
      self.controller?.dismiss(animated: true, completion: nil)
      self.pickResult?(jsonStr)
    } catch let e {
      self.pickResult?(e)
    }
  }
  
  private func errorResult(resultType: String, errMessage: String) {
    do {
      // Result JSON
      var jsonObj = Dictionary<String, Any>()
      jsonObj["path"] = ""
      jsonObj["createDate"] = ""
      jsonObj["mediaType"] = "unknown"
      jsonObj["resultType"] = resultType
      jsonObj["error"] = errMessage
      let jsonData = try JSONSerialization.data(withJSONObject: jsonObj)
      let jsonStr = String(bytes: jsonData, encoding: .utf8)!
      self.pickResult?(jsonStr)
    } catch {
      self.pickResult?(error)
    }
  }
}

extension PHAsset {

    func getURL(completionHandler : @escaping ((_ responseURL : URL?) -> Void)){
        if self.mediaType == .image {
            let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
            options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
                return true
            }
            self.requestContentEditingInput(with: options, completionHandler: {(contentEditingInput: PHContentEditingInput?, info: [AnyHashable : Any]) -> Void in
                completionHandler(contentEditingInput!.fullSizeImageURL as URL?)
            })
        } else if self.mediaType == .video {
            let options: PHVideoRequestOptions = PHVideoRequestOptions()
            options.version = .original
            PHImageManager.default().requestAVAsset(forVideo: self, options: options, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
                if let urlAsset = asset as? AVURLAsset {
                    let localVideoUrl: URL = urlAsset.url as URL
                    completionHandler(localVideoUrl)
                } else {
                    completionHandler(nil)
                }
            })
        }
    }
}
