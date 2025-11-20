# iOS Flutter 混合开发项目

本项目是一个原生的 iOS 应用，旨在演示如何将 Flutter 模块集成到一个现有的 iOS App 中。它展示了混合开发的几个关键方面：

1.  **Flutter 集成**: 如何使用 CocoaPods 将 Flutter 模块作为依赖项嵌入。
2.  **预热引擎 (Pre-warmed Engine)**: 如何在 App 启动时初始化一个共享的 `FlutterEngine` 以获得更好的性能。
3.  **页面导航**: 如何从一个原生的 iOS `UIViewController` 启动 Flutter 页面。
4.  **数据传递 (原生到 Flutter)**: 如何在启动时将初始数据（路由和参数）传递给 Flutter 页面。
5.  **双向通信 (MethodChannel)**: 如何在 Swift (iOS) 和 Dart (Flutter) 之间建立通信桥梁，以实现函数调用和数据来回传递。

---

## 项目结构

-   `ios_flutter_hybrid/`: 原生 iOS 应用代码的主目录。
    -   `AppDelegate.swift`: 负责在 App 启动时初始化并运行共享的 `FlutterEngine`。
    -   `ViewController.swift`: 主要的原生视图控制器。它包含一个用于跳转到 Flutter 页面的按钮，并处理所有 `MethodChannel` 的通信逻辑。
-   `Podfile`: 定义 iOS 项目的依赖关系，包括 Flutter 模块。它指向 Flutter 项目的本地路径。
-   `ios_flutter_hybrid.xcodeproj`: Xcode 项目文件。

---

## 工作原理

### 1. Flutter 集成

集成配置在 `Podfile` 文件中。它使用 `flutter_application_path` 来定位您本地机器上的 Flutter 项目，然后使用 Flutter 提供的 `podhelper.rb` 脚本来配置所有必需的依赖项。

```ruby
# Podfile
flutter_application_path = '/Users/zhaoyudong/FlutterProjects/lib_flutter'
load File.join(flutter_application_path, '.ios', 'Flutter', 'podhelper.rb')

target 'ios_flutter_hybrid' do
  use_frameworks!
  install_all_flutter_pods(flutter_application_path)
end
```
**注意**: 您必须将 `flutter_application_path` 更新为您机器上 Flutter 模块的正确路径。

### 2. App 启动与引擎缓存

在 `AppDelegate.swift` 中，一个 `FlutterEngine` 在应用启动完成后立即被创建和运行。这会“预热”Dart 虚拟机并将您的 Flutter 代码加载到内存中。通过使用单个共享引擎，后续展示 Flutter 页面会快得多，并且能够保持其状态。

```swift
// AppDelegate.swift
lazy var flutterEngine = FlutterEngine(name: "my flutter engine")

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    flutterEngine.run()
    return true
}
```

### 3. 启动 Flutter 页面

原生的 `ViewController.swift` 有一个按钮，当被点击时，会执行以下操作：

1.  **定义路由**: 创建一个字符串，用于指定要显示 Flutter 模块中的哪个页面以及要传递什么数据。
    ```swift
    let route = "/custom_flutter_page?id=456&name=DataFromiOS"
    ```
2.  **创建 FlutterViewController**: 初始化一个 `FlutterViewController`，并将 `route` 字符串传递给其 `initialRoute` 属性。这是在特定路由上启动 Flutter 的现代且推荐的方式。
    ```swift
    let flutterViewController = FlutterViewController(project: nil, initialRoute: route, nibName: nil, bundle: nil)
    ```
3.  **展示视图**: 使用标准的 `UINavigationController` 将 `flutterViewController` 推到屏幕上。

### 4. 双向通信

通过建立一个 `FlutterMethodChannel` 来允许 Swift 和 Dart 代码进行通信。通道名称 (`com.example/custom_flutter_activity`) 在原生端和 Flutter 端必须完全相同。

#### Flutter 到原生 (Swift)

`ViewController.swift` 中的 `setMethodCallHandler` 监听从 Flutter 端调用的方法。

```swift
// ViewController.swift
methodChannel.setMethodCallHandler({ (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
    switch call.method {
    case "showNativeToast":
        // 显示一个原生的 iOS toast 消息
    case "finishActivity":
        // 弹出 Flutter 视图控制器以返回原生页面
    case "getInitialRouteParams":
        // 将初始路由数据发送回 Flutter
    default:
        result(FlutterMethodNotImplemented)
    }
})
```

这允许 Flutter UI 触发原生操作，例如显示原生 UI 组件（如 Toast）或关闭 Flutter 屏幕。

---

## 如何运行此项目

1.  **克隆 Flutter 模块**: 确保您已在本地机器上克隆了相应的 Flutter 项目 (`lib_flutter`)。原始项目位于 `https://github.com/zyd806094224/lib_flutter`。

2.  **更新 Podfile 路径**: 打开 `Podfile` 文件，并将 `flutter_application_path` 更改为您计算机上 `lib_flutter` 项目的正确绝对路径。

3.  **安装依赖**: 在您的终端中，导航到项目根目录并运行：
    ```sh
    pod install
    ```

4.  **在 Xcode 中打开**: 打开生成的 `ios_flutter_hybrid.xcworkspace` 文件 (请勿使用 `.xcodeproj` 文件)。

5.  **构建和运行**: 选择一个模拟器或连接的设备，然后按 Xcode 中的“运行”按钮。