import AppKit
import PowerCore
import MenuBarWattageUI

@main
enum MenuBarWattageEntryPoint {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.setActivationPolicy(.accessory)
        app.delegate = delegate
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var lifecycle: AppLifecycle?
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let source = IOKitPowerTelemetrySource()
        let engine = SamplingEngine(
            source: source,
            sampleInterval: 1.0
        )

        let viewModel = StatusBarViewModel()
        let lifecycle = AppLifecycle(engine: engine, viewModel: viewModel)
        lifecycle.start()

        self.lifecycle = lifecycle
        statusItemController = StatusItemController(viewModel: viewModel)
    }

    func applicationWillTerminate(_ notification: Notification) {
        lifecycle?.stop()
    }
}
