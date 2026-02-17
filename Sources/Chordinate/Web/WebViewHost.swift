import SwiftUI
import WebKit
import AppKit

struct WebAppView: NSViewRepresentable {
    let store: ChordStore
    let engine: ChordEngine
    let recorder: ChordRecorder

    func makeNSView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.suppressesIncrementalRendering = false

        // Install a bootstrap script to expose a small API to JS for native->JS events
        let bootstrap = """
        window.chordinate = window.chordinate || {};
        (function(){
          const listeners = new Set();
          window.chordinate.on = function(handler){ listeners.add(handler); return () => listeners.delete(handler); }
          window.chordinate.__dispatch = function(type, payload){ listeners.forEach(h => { try { h({type, payload}); } catch(e) {} }); };
        })();
        """
        contentController.addUserScript(WKUserScript(source: bootstrap, injectionTime: .atDocumentStart, forMainFrameOnly: true))

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        let bridge = WebBridge(webView: webView, store: store, engine: engine, recorder: recorder)
        contentController.add(bridge, name: "bridge")
        context.coordinator.bridge = bridge

        loadApp(into: webView)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var bridge: WebBridge?
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Notify JS we're ready; JS should post {type: 'ready'} back to receive state
            let js = "window.chordinate && window.chordinate.__dispatch('nativeReady', {});"
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    private func loadApp(into webView: WKWebView) {
        // Dev mode: set WEB_DEV_SERVER_URL env var to http://localhost:5173 and the app will load it.
        if let devURL = ProcessInfo.processInfo.environment["WEB_DEV_SERVER_URL"], let url = URL(string: devURL) {
            webView.load(URLRequest(url: url))
            return
        }
        // Load bundled index.html from SPM resources: Sources/Chordinate/Resources/Web/index.html
        // We locate the folder and use loadFileURL to grant file URL access.
        let bundle = Bundle.module
        if let index = bundle.url(forResource: "index", withExtension: "html", subdirectory: "Web") {
            let folder = index.deletingLastPathComponent()
            webView.loadFileURL(index, allowingReadAccessTo: folder)
            return
        }
        // Fallback: simple inline HTML if resources are missing
        let html = """
        <!doctype html>
        <html><head><meta charset=\"utf-8\"><title>Chordinate</title></head>
        <body>
          <h1 style=\"font-family: -apple-system;\">Chordinate</h1>
          <p>No web assets found. Create <code>Sources/Chordinate/Resources/Web/index.html</code> or set <code>WEB_DEV_SERVER_URL</code>.</p>
          <script>
            window.chordinate = window.chordinate || {};
            (function(){
              const listeners = new Set();
              window.chordinate.on = function(h){ listeners.add(h); return () => listeners.delete(h); }
              window.chordinate.__dispatch = function(type, payload){ listeners.forEach(h => h({type, payload})); };
            })();
          </script>
        </body></html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}
