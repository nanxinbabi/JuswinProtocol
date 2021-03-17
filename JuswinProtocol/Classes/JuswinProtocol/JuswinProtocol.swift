//
//  ProtocolUtil.swift
//  project
//
//  Created by Winson Zhang on 2020/2/13.
//  Copyright © 2020 Winson Zhang. All rights reserved.
//

import UIKit
import Photos

// MARK: - 保存到相册
protocol AlbumSavable {}
extension AlbumSavable {
    
    /// 保存图片到相册
    static func jus_save(picture name: UIImage, to album: String? = nil, completion:((_ success: Bool, _ error: String?) -> Void)? = nil) {
        guard let album = jus_loadAlbum(name: album) else {
            completion?(false, "获取相册失败")
            return
        }
        PHPhotoLibrary.shared().performChanges({
            let changeReq = PHAssetChangeRequest.creationRequestForAsset(from: name)
            let placeholderForCreatedAsset = changeReq.placeholderForCreatedAsset
            let req = PHAssetCollectionChangeRequest(for: album)
            req?.addAssets([placeholderForCreatedAsset!] as NSFastEnumeration)
        }) { (success, error) in
            DispatchQueue.main.async {
                completion?(success, error?.localizedDescription)
            }
        }
    }
    
    /// 保存视频到相册
    static func jus_save(video url: URL, to album: String? = nil, completion:((_ success: Bool, _ error: String?) -> Void)? = nil) {
        guard let album = jus_loadAlbum(name: album) else {
            completion?(false, "获取相册失败")
            return
        }
        PHPhotoLibrary.shared().performChanges({
            let changeReq = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            let placeholderForCreatedAsset = changeReq?.placeholderForCreatedAsset
            let req = PHAssetCollectionChangeRequest(for: album)
            req?.addAssets([placeholderForCreatedAsset!] as NSFastEnumeration)
        }) { (success, error) in
            DispatchQueue.main.async {
                completion?(success, error?.localizedDescription)
            }
        }
    }
    
    /// 根据名字获取相册，名字为 nil 时返回相机胶卷，有名字时返回该名字相册
    static func jus_loadAlbum(name: String? = nil) -> PHAssetCollection? {
        
        if PHPhotoLibrary.authorizationStatus() == .denied {
            let alert = UIAlertController(title: "为了方便为您保存图片到相册，需要访问您的相册", message: "请去-> [设置 - 隐私 - 相机 - 项目名称] 打开访问开关", preferredStyle: .alert)
            let cancelAc = UIAlertAction(title: "取消", style: .cancel) { _ in
                
            }
            alert.addAction(cancelAc)
            let settingAc = UIAlertAction(title: "设置", style: .default) { _ in
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:])) { _ in}
                } else {
                    // Fallback on earlier versions
                }
            }
            alert.addAction(settingAc)
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
            return nil
        }
        
        if !(PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.authorized || PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.notDetermined) {
            let alert = UIAlertController(title: "温馨提示", message: "亲！相册未授权～", preferredStyle: .alert)
            let settingAc = UIAlertAction(title: "设置", style: .default) { _ in}
            alert.addAction(settingAc)
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
            
            return nil
        }
        
        var album: PHAssetCollection?
        
        /// 如果指定相册名称，则自动保存到相机胶卷
        guard let name = name else {
            let albumList = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil)
            album = albumList.firstObject
            return album
        }
        
        /// 指定了相册
        ///  获取相册
        var albumList = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        
        albumList.enumerateObjects { (obj, index, stop) in
            if name == obj.localizedTitle {
                album = obj
                stop.initialize(to: true)
            }
        }
        
        if let album = album {
            return album
        }
        /// 如果相册不存在，创建名为 name 的相册
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
        }) { (success, error) in
            albumList = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
            albumList.enumerateObjects({ (obj, index, stop) in
                if name == obj.localizedTitle {
                    album = obj
                    stop.initialize(to: true)
                }
            })
        }
        return album
    }
}


// MARK: - 从XIB中加载
protocol NibLoadable {}
extension NibLoadable {
    static func loadFromNib() -> Self {
        return Bundle.main.loadNibNamed("\(self)", owner: nil, options: nil)?.first as! Self
    }
}

// MARK: - 注册cell
protocol Registerable {}
extension Registerable {
    static var identifier: String { return "\(self)" }
    static var nib: UINib? { return UINib(nibName: "\(self)", bundle: nil) }
    static var isHasNib: Bool { return Bundle.main.path(forResource: "\(self)", ofType: "nib") != nil }
}

protocol SBLoadable {}
extension SBLoadable {
    static func load(SB: String) -> Self {
        let sb = UIStoryboard(name: SB, bundle: Bundle.main)
        let identifier = "\(self)"
        return sb.instantiateViewController(withIdentifier: identifier) as! Self
    }
    
    static func load(from sb: UIStoryboard) -> Self {
        let identifier = "\(self)"
        return sb.instantiateViewController(withIdentifier: identifier) as! Self
    }
}


// MARK: - 获取当前的控制器
protocol ControllerFindable {}
extension ControllerFindable {
    
    /// 获取当前显示的ViewController
    ///
    /// - Parameter from: 从哪个控制器找，默认当前显示的 root VC
    /// - Returns: 当前正在显示的控制器
    static func visiableVc(from: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        
        if let navigationController = from as? UINavigationController {
            return visiableVc(from: navigationController.visibleViewController)
        }
        if let tabBarController = from as? UITabBarController {
            if let selectedController = tabBarController.selectedViewController {
                return visiableVc(from: selectedController)
            }
        }
        if let presentedController = from?.presentedViewController {
            return visiableVc(from: presentedController)
        }
        return from
    }
    
    /// 获取当前的导航栏控制器
    /// - Parameter from: 从哪个控制器找，默认当前显示的 root VC  
    static func visiableNc(from: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UINavigationController? {
        if let navigationController = from as? UINavigationController {
            return navigationController
        }
        if let tabBarController = from as? UITabBarController {
            if let selectedController = tabBarController.selectedViewController {
                return visiableNc(from: selectedController)
            }
        }
        if let presentedController = from?.presentedViewController {
            return visiableNc(from: presentedController)
        }
        return nil
    }
}

// MARK: - Codable 相关
// 扩展 Encodable 协议，添加编码的方法
public extension Encodable {
    
    // 遵守 Codable 协议的对象转 json 字符串
    func jus_toJSONString() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // 对象转 jsonObject
    func jus_toJSONObject() -> Any? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
    }
}

// 扩展 Decodable 协议， 添加解码的方法
public extension Decodable {
    
    // json 字符串转对象、数组
    static func decodeJSON(from string: String?, designatedPath: String? = nil) -> Self? {
        guard let data = string?.data(using: .utf8),
            let jsonData = codaSubObject(inside: data, by: designatedPath) else { return nil }
        
        return try? JSONDecoder().decode(Self.self, from: jsonData)
    }
    
    // jsonObject 转对象、数组
    static func decodeJSON(from jsonObject: Any?, designatedPath: String? = nil) -> Self? {
        guard let jsonObject = jsonObject,
            JSONSerialization.isValidJSONObject(jsonObject),
            let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: []),
            let jsonData = codaSubObject(inside: data, by: designatedPath) else { return nil }
        
        return try? JSONDecoder().decode(Self.self, from: jsonData)
    }
}

// 扩展 Array，添加将 jsonString 或者 jsonObject 解码到对应对象数组的方法
public extension Array where Element: Codable {
    
    static func decodeJSON(from jsonString: String?, designatedPath: String? = nil) -> [Element]? {
        guard let data = jsonString?.data(using: .utf8),
            let jsonData = codaSubObject(inside: data, by: designatedPath),
            let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) else { return nil }
        
        return Array.decodeJSON(from: jsonObject)
    }
    
    static func decodeJSON(from array: [Any]?) -> [Element]? {
        let arr = array.map { (item) -> Element? in
            return Element.decodeJSON(from: item)
        }
        return arr as? [Element]
    }
}


/// 根据 designatedPath 获取 object 中的数据
/// - Parameters:
///   - jsonData: json data
///   - designatedPath: 获取 json object 中指定路径
/// - Returns: 获取到的 data，可能为 nil
fileprivate func codaSubObject(inside jsonData: Data?, by designatedPath: String?) -> Data? {
    
    // 保证 jsonData 不为空，designatedPath有效
    guard let _jsonData = jsonData, let paths = designatedPath?.components(separatedBy: "."), paths.count > 0 else { return jsonData }
    
    // 从 jsonObject中取出 designatedPath 指定的 jsonObject
    let jsonObject = try? JSONSerialization.jsonObject(with: _jsonData, options: .allowFragments)
    var result = jsonObject
    var abort = false
    var next = jsonObject as? [String: Any]
    
    paths.forEach { (seg) in
        if seg.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == "" || abort { return }
        if let _next = next?[seg] {
            result = _next
            next = _next as? [String : Any]
        } else {
            abort = true
        }
    }
    
    // 判断条件保障返回正确结果，确保 jsonObject 转成了 Data 类型
    guard abort == false,
        let resultJsonObject = result,
        let data = try? JSONSerialization.data(withJSONObject: resultJsonObject, options: []) else {
            return nil
    }
    return data
}

// class 的深拷贝
protocol Copyable: Codable {
    
    func copy() -> Self
}

extension Copyable {
    
    func copy() -> Self {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self) else {
            fatalError("Encode fail")
        }
        let decoder = JSONDecoder()
        guard let target = try? decoder.decode(Self.self, from: data) else {
            fatalError("Decode fail")
        }
        return target
    }
}
extension Array: Copyable where Element: Copyable {}

// MARK: - 注册
extension UITableViewCell: Registerable {}
extension UICollectionReusableView: Registerable {}
extension UITableViewHeaderFooterView: Registerable {}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
