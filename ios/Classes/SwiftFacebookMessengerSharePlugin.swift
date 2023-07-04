import Flutter
import UIKit
import FBSDKShareKit
import FBSDKCoreKit


public class SwiftFacebookMessengerSharePlugin: NSObject, FlutterPlugin {
    var result: FlutterResult?
    
    private func failedWithMessage(_ message: String) -> [String: Any] {
        return ["code": 0, "message": message]
    }
    
    private let succeeded = ["code": 1]
    private let cancelled = ["code": -1]
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        ApplicationDelegate.initialize()
        let channel = FlutterMethodChannel(name: "facebook_messenger_share", binaryMessenger: registrar.messenger())
        let instance = SwiftFacebookMessengerSharePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.result = result
        let method = call.method
        
        if method == "shareUrl", let urlString = call.arguments as? String {
            let sharePhotoList : Array<SharePhoto>
            guard let url = URL(string: urlString) else {
                preconditionFailure("URL is invalid")
            }

            let content = ShareLinkContent()
            content.contentURL = url

            let dialog = MessageDialog(content: content, delegate: self)

            do {
                try dialog.validate()
            } catch {
                print(error)
            }

            dialog.show()
        } else if method == "shareImages", let paths = call.arguments as? [String] {
              for i in 0...4  {

                     // Create URL
                   
                     var imageUi = UIImage(contentsOfFile: listImage?[i] )

                     

                     // statements
                     let photo = SharePhoto(
                       image: imageUi,
                       isUserGenerated: true
                     )
                     sharePhotoList.append(photo)

            }
           
            let content = SharePhotoContent()
            content.photos = sharePhotoList
            
            share(content, result)
        } else if method == "shareDataImage" {
            // guard let flutterData = call.arguments as? FlutterStandardTypedData, let image = UIImage(data: flutterData.data) else {
            //     result(failedWithMessage("Image data couldn't parsed"))
            //     return
            // }
            // let content = SharePhotoContent()
            // content.photos = [SharePhoto(image: image, userGenerated: true)]

            // share(content, result)
            
        } else if method == "shareVideo" {
            guard let flutterData = call.arguments as? FlutterStandardTypedData else {
                result(failedWithMessage("Video data couldn't parsed"))
                return
            }
            let content = ShareVideoContent()
            content.video = ShareVideo(data: flutterData.data)

            share(content, result)
        } else {
            result(failedWithMessage("Function is not implemented with iOS platform"))
        }
    }
    
    private func share(_ content: SharingContent, _ result: FlutterResult) {
        let dialog = MessageDialog(content: content, delegate: self)
        
        do {
            try dialog.validate()
        } catch {
            result(failedWithMessage(error.localizedDescription))
            print(error)
        }

        dialog.show()
    }
    
    /// START ALLOW HANDLE NATIVE FACEBOOK APP
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        var options = [UIApplication.LaunchOptionsKey: Any]()
        for (k, value) in launchOptions {
            let key = k as! UIApplication.LaunchOptionsKey
            options[key] = value
        }
        ApplicationDelegate.shared.application(application,didFinishLaunchingWithOptions: options)
        return true
    }
    
    public func application( _ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:] ) -> Bool {
        let processed = ApplicationDelegate.shared.application(
            app, open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation])
        return processed;
    }
    /// END ALLOW HANDLE NATIVE FACEBOOK APP
}

extension SwiftFacebookMessengerSharePlugin: SharingDelegate {
    public func sharer(_ sharer: Sharing, didCompleteWithResults results: [String : Any]) {
        self.result?(succeeded)
    }
    
    public func sharer(_ sharer: Sharing, didFailWithError error: Error) {
        self.result?(failedWithMessage(error.localizedDescription))
    }
    
    public func sharerDidCancel(_ sharer: Sharing) {
        self.result?(cancelled)
    }
}
