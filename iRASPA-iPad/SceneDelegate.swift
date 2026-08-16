import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate
{
  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions)
  {
    guard let windowScene = scene as? UIWindowScene else { return }
    let window = UIWindow(windowScene: windowScene)
    let browser = DocumentBrowserViewController()
    window.rootViewController = browser
    window.makeKeyAndVisible()
    self.window = window

    if let url = connectionOptions.urlContexts.first?.url
    {
      browser.presentDocument(at: url)
    }
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>)
  {
    guard let url = URLContexts.first?.url else { return }
    (window?.rootViewController as? DocumentBrowserViewController)?.presentDocument(at: url)
  }
}
