//
//  ViewController.swift
//  ios_flutter_hybrid
//
//  Created by zhaoyudong on 2025/11/19.
//

import UIKit
import Flutter

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Native iOS Page"
        self.view.backgroundColor = .white
        
        let label = UILabel()
        label.text = "hello"
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        let button = UIButton(type: .system)
        button.setTitle("Go to Flutter Page", for: .normal)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20)
        ])
    }

    /// 当按钮被点击时触发此方法
    @objc func buttonTapped() {
        // 1. 定义要传递给 Flutter 页面的路由地址和参数。
        //    这个字符串的格式需要和安卓端以及Flutter端解析的格式完全一致。
        let route = "/custom_flutter_page?id=456&name=DataFromiOS"
        
        // 2. 创建 FlutterViewController。
        //    这是 Flutter 官方推荐的、用于展示 Flutter 页面的标准方式。
        //    我们直接在构造函数中传入 `initialRoute`，这比旧的 `setInitialRoute` 方法更可靠。
        let flutterViewController = FlutterViewController(project: nil, initialRoute: route, nibName: nil, bundle: nil)
        
        // 3. 为即将打开的 Flutter 页面设置原生通信通道。
        setupMethodChannel(for: flutterViewController, route: route)
        
        // 4. 使用导航控制器 (UINavigationController) 跳转到 Flutter 页面。
        self.navigationController?.pushViewController(flutterViewController, animated: true)
    }
    
    /// 为 Flutter 视图控制器设置方法通道 (MethodChannel)
    /// - Parameters:
    ///   - flutterViewController: 要设置通信的 Flutter 视图控制器实例。
    ///   - route: 启动时使用的路由，用于 `getInitialRouteParams` 方法。
    private func setupMethodChannel(for flutterViewController: FlutterViewController, route: String) {
        // 定义通道名称，这个名称必须和 Flutter 端以及安卓端完全一致，才能建立通信。
        let channelName = "com.example/custom_flutter_activity"
        
        // 创建方法通道实例。
        // `binaryMessenger` 是 Flutter 和原生之间传递二进制消息的信使。
        let methodChannel = FlutterMethodChannel(name: channelName, binaryMessenger: flutterViewController.binaryMessenger)
        
        // 设置方法调用的处理器。当 Flutter 端调用 `platform.invokeMethod(...)` 时，这里的闭包会被执行。
        methodChannel.setMethodCallHandler({
            // `[weak self]` 防止循环引用，是一种内存管理的最佳实践。
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            
            // 使用 switch 判断 Flutter 调用的是哪个方法。
            switch call.method {
            // 处理 "showNativeToast" 方法
            case "showNativeToast":
                // 从 `call.arguments` 中解析出 Flutter 传递过来的参数。
                guard let args = call.arguments as? [String: Any],
                      let message = args["message"] as? String else {
                    // 如果参数解析失败，返回一个错误。
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Message argument not found or not a string", details: nil))
                    return
                }
                // 调用我们自己写的 showToast 方法来显示原生提示。
                self?.showToast(message: message)
                // 向 Flutter 返回成功状态。
                result(true)

            // 处理 "finishActivity" 方法
            case "finishActivity":
                // 在iOS中，"finish" 对应的操作是 "pop" 导航控制器，即返回上一页。
                self?.navigationController?.popViewController(animated: true)
                result(true)

            // 处理 "getInitialRouteParams" 方法
            case "getInitialRouteParams":
                // 直接将启动时使用的路由字符串返回给 Flutter。
                result(route)

            // 如果 Flutter 调用的方法在这里没有定义，则返回 "未实现" 状态。
            default:
                result(FlutterMethodNotImplemented)
            }
        })
    }
    
    /// 一个辅助函数，用于在屏幕上显示一个类似安卓 Toast 的消息提示。
    /// - Parameter message: 要显示的消息文本。
    private func showToast(message: String) {
        // --- 获取主窗口 ---
        // 为了确保 Toast 能显示在最上层，我们必须把它添加到当前应用的 "key window" (主窗口) 上。
        // 'windows' 在 iOS 15 中被废弃，所以我们使用新的 API 来获取主窗口，并兼容旧版本。
        let keyWindow: UIWindow?
        if #available(iOS 13.0, *) {
            // 从所有连接的场景中，找到前台活跃的场景，然后获取它的主窗口。
            keyWindow = UIApplication.shared.connectedScenes
                .filter({$0.activationState == .foregroundActive})
                .compactMap({$0 as? UIWindowScene})
                .first?.windows
                .first(where: {$0.isKeyWindow})
        } else {
            // 对于 iOS 13 之前的版本，使用旧的 API。
            keyWindow = UIApplication.shared.keyWindow
        }
        
        // 确保我们成功获取到了主窗口。
        guard let window = keyWindow else {
            print("无法找到主窗口来显示Toast。")
            return
        }
        
        // --- 创建和设置 UILabel ---
        let toastLabel = UILabel()
        toastLabel.text = message
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont.systemFont(ofSize: 14)
        toastLabel.textColor = UIColor.white
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6) // 半透明黑色背景
        toastLabel.numberOfLines = 0 // 允许自动换行
        
        // --- 计算 Toast 的尺寸 ---
        let maxSize = CGSize(width: window.bounds.width - 40, height: window.bounds.height)
        var expectedSize = toastLabel.sizeThatFits(maxSize)
        expectedSize.width += 20
        expectedSize.height += 20
        
        // --- 定位 Toast ---
        toastLabel.frame = CGRect(x: (window.bounds.width - expectedSize.width) / 2, // 水平居中
                                  y: window.bounds.height - expectedSize.height - 60, // 垂直方向上，距离屏幕底部60点
                                  width: expectedSize.width,
                                  height: expectedSize.height)
        toastLabel.layer.cornerRadius = expectedSize.height / 2
        toastLabel.layer.masksToBounds = true
        
        // 将 Toast 标签添加到主窗口上。
        window.addSubview(toastLabel)
        
        // --- 创建并执行动画 ---
        UIView.animate(withDuration: 2.0, delay: 1.5, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
}

