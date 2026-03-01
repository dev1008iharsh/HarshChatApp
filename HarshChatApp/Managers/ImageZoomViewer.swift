import Photos
import UIKit

final class ImageZoomViewer: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    static let shared = ImageZoomViewer()

    private var originalFrame: CGRect = .zero
    private var originalCornerRadius: CGFloat = 0
    private var zoomImageView: UIImageView?
    private var backgroundView: UIView?
    private var scrollView: UIScrollView?
    private var closeButton: UIButton?
    private var shareButton: UIButton?
    private var saveButton: UIButton?
    private var isControlHidden = false

    private override init() {
        super.init()
    }

    func showFullScreen(from sourceImageView: UIImageView, backgroundColor: UIColor = .black) {
        guard let window = getWindow(), let image = sourceImageView.image else { return }

        self.originalFrame = sourceImageView.convert(sourceImageView.bounds, to: window)
        self.originalCornerRadius = sourceImageView.layer.cornerRadius

        backgroundView = UIView(frame: window.bounds)
        backgroundView?.backgroundColor = backgroundColor
        backgroundView?.alpha = 0
        window.addSubview(backgroundView!)

        let scroll = UIScrollView(frame: window.bounds)
        scroll.minimumZoomScale = 1.0
        scroll.maximumZoomScale = 5.0
        scroll.delegate = self
        scroll.showsVerticalScrollIndicator = false
        scroll.showsHorizontalScrollIndicator = false
        scroll.contentInsetAdjustmentBehavior = .never
        window.addSubview(scroll)
        self.scrollView = scroll

        let iv = UIImageView(frame: originalFrame)
        iv.image = image
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = originalCornerRadius
        iv.isUserInteractionEnabled = true
        scroll.addSubview(iv)
        self.zoomImageView = iv

        setupGestures()
        setupButtons(in: window)

        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseInOut) {
            self.backgroundView?.alpha = 1
            self.zoomImageView?.frame = self.calculateFinalFrame(for: image, in: window.bounds)
            self.zoomImageView?.layer.cornerRadius = 0
        }
    }

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        tapGesture.numberOfTapsRequired = 2
        scrollView?.addGestureRecognizer(tapGesture)

        let singleTap = UITapGestureRecognizer(target: self, action: #selector(toggleControls))
        singleTap.require(toFail: tapGesture)
        scrollView?.addGestureRecognizer(singleTap)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        scrollView?.addGestureRecognizer(panGesture)

        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        rotationGesture.delegate = self
        scrollView?.addGestureRecognizer(rotationGesture)
    }

    private func setupButtons(in window: UIWindow) {
        closeButton = createButton(image: "xmark", action: #selector(dismissViewer), x: 20)
        shareButton = createButton(image: "square.and.arrow.up", action: #selector(shareImage), x: window.frame.width - 60)
        saveButton = createButton(image: "arrow.down.to.line", action: #selector(saveImage), x: window.frame.width - 110)

        [closeButton, shareButton, saveButton].compactMap { $0 }.forEach { window.addSubview($0) }
    }

    private func createButton(image: String, action: Selector, x: CGFloat) -> UIButton {
        let btn = UIButton(frame: CGRect(x: x, y: 60, width: 40, height: 40))
        btn.setImage(UIImage(systemName: image), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        btn.layer.cornerRadius = 20
        btn.addTarget(self, action: action, for: .touchUpInside)
        return btn
    }

    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let view = zoomImageView else { return }
        view.transform = view.transform.rotated(by: gesture.rotation)
        gesture.rotation = 0
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard scrollView?.zoomScale == 1.0, let view = zoomImageView else { return }
        let translation = gesture.translation(in: scrollView)
        let velocity = gesture.velocity(in: scrollView)

        switch gesture.state {
        case .changed:
            view.center = CGPoint(x: scrollView!.center.x + translation.x, y: scrollView!.center.y + translation.y)
            let alpha = 1.0 - (abs(translation.y) / 500)
            backgroundView?.alpha = max(alpha, 0.5)
        case .ended:
            if abs(translation.y) > 140 || abs(velocity.y) > 500 {
                dismissViewer()
            } else {
                UIView.animate(withDuration: 0.3) {
                    view.center = self.scrollView!.center
                    self.backgroundView?.alpha = 1
                }
            }
        default: break
        }
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard let scroll = scrollView else { return }
        if scroll.zoomScale > 1.0 {
            scroll.setZoomScale(1.0, animated: true)
        } else {
            let point = gesture.location(in: zoomImageView)
            let rect = CGRect(origin: point, size: .zero)
            scroll.zoom(to: rect, animated: true)
        }
    }

    @objc private func toggleControls() {
        isControlHidden.toggle()
        UIView.animate(withDuration: 0.25) {
            [self.closeButton, self.shareButton, self.saveButton].forEach { $0?.alpha = self.isControlHidden ? 0 : 1 }
        }
    }

    @objc private func dismissViewer() {
        UIView.animate(withDuration: 0.35, animations: {
            self.zoomImageView?.transform = .identity
            self.zoomImageView?.frame = self.originalFrame
            self.zoomImageView?.layer.cornerRadius = self.originalCornerRadius
            self.backgroundView?.alpha = 0
            [self.closeButton, self.shareButton, self.saveButton].forEach { $0?.alpha = 0 }
        }) { _ in
            self.cleanup()
        }
    }

    private func cleanup() {
        zoomImageView?.removeFromSuperview()
        scrollView?.removeFromSuperview()
        backgroundView?.removeFromSuperview()
        closeButton?.removeFromSuperview()
        shareButton?.removeFromSuperview()
        saveButton?.removeFromSuperview()
        zoomImageView = nil
        scrollView = nil
        backgroundView = nil
    }

    @objc private func shareImage() {
        guard let image = zoomImageView?.image, let topVC = getTopViewController() else { return }
        let vc = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        topVC.present(vc, animated: true)
    }

    @objc private func saveImage() {
        guard let image = zoomImageView?.image else { return }
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }) { success, _ in
                    DispatchQueue.main.async {
                        if success { self?.showAlert(title: "Success", message: "Image saved to Photos.") }
                    }
                }
            }
        }
    }

    private func calculateFinalFrame(for image: UIImage, in bounds: CGRect) -> CGRect {
        let ratio = image.size.width / image.size.height
        let width = bounds.width
        let height = width / ratio
        return CGRect(x: 0, y: (bounds.height - height) / 2, width: width, height: height)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return zoomImageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        zoomImageView?.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
    }

    private func getWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first { $0.isKeyWindow }
    }

    private func getTopViewController(base: UIViewController? = nil) -> UIViewController? {
        let baseVC = base ?? getWindow()?.rootViewController
        if let nav = baseVC as? UINavigationController { return getTopViewController(base: nav.visibleViewController) }
        if let tab = baseVC as? UITabBarController { return getTopViewController(base: tab.selectedViewController) }
        if let presented = baseVC?.presentedViewController { return getTopViewController(base: presented) }
        return baseVC
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        getTopViewController()?.present(alert, animated: true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
