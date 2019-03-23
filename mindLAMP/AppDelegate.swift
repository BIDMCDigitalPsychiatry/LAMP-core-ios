import UIKit
import WebKit
import NodeMobile

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		let node = Thread { node_exec("console.log('hi')") }
		node.stackSize = 2 * 1024 * 1024 /* 2MB */
		node.start()
        return true
    }
}

class ViewController: UIViewController {
    @IBOutlet var webView: WKWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
		self.webView.isOpaque = false
		self.webView.backgroundColor = .clear
		self.webView.configuration.websiteDataStore = WKWebsiteDataStore.default()
		let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "build")!
		self.webView.loadFileURL(url, allowingReadAccessTo: url)
		self.webView.load(URLRequest(url: url))
    }
}
