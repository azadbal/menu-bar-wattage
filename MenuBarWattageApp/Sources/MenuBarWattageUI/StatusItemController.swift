import AppKit
import Combine
import PowerCore
import SwiftUI

@MainActor
public final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let viewModel: StatusBarViewModel
    private let launchAtLoginController: LaunchAtLoginControlling
    private var cancellables: Set<AnyCancellable>
    private weak var launchAtLoginItem: NSMenuItem?

    public init(
        viewModel: StatusBarViewModel,
        launchAtLoginController: LaunchAtLoginControlling = SystemLaunchAtLoginController()
    ) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.viewModel = viewModel
        self.launchAtLoginController = launchAtLoginController
        self.cancellables = []
        super.init()

        setupStatusButton()
        setupMenu()
        bindViewModel()
    }

    private func setupStatusButton() {
        guard let button = statusItem.button else {
            return
        }

        button.title = viewModel.statusText
        button.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .medium)
    }

    private func setupMenu() {
        let menu = NSMenu()

        let diagnosticsView = StatusMenuView(viewModel: viewModel)
        let hostingView = NSHostingView(rootView: diagnosticsView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 260, height: 68)

        let graphItem = NSMenuItem()
        graphItem.view = hostingView
        menu.addItem(graphItem)

        menu.addItem(.separator())

        let launchAtLoginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchAtLoginItem.target = self
        launchAtLoginItem.state = launchAtLoginController.isEnabled ? .on : .off
        menu.addItem(launchAtLoginItem)
        self.launchAtLoginItem = launchAtLoginItem

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func bindViewModel() {
        viewModel.$statusText
            .sink { [weak self] statusText in
                self?.statusItem.button?.title = statusText
            }
            .store(in: &cancellables)
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    @objc private func toggleLaunchAtLogin() {
        let enabled = !launchAtLoginController.isEnabled

        do {
            try launchAtLoginController.setEnabled(enabled)
            launchAtLoginItem?.state = launchAtLoginController.isEnabled ? .on : .off
        } catch {
            launchAtLoginItem?.state = launchAtLoginController.isEnabled ? .on : .off
        }
    }
}
