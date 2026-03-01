import Photos
import UIKit

final class ImageViewerManager: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    static let shared = ImageViewerManager()
    private override init() {}

    private var originalFrame: CGRect = .zero
    private var originalCornerRadius: CGFloat = 0

    private var zoomImageView: UIImageView?
    private var backgroundView: UIView?
    private var scrollView: UIScrollView?

    private var closeButton: UIButton?
    private var shareButton: UIButton?
    private var saveButton: UIButton?

    private var isControlHidden = false
    private var customPanGesture: UIPanGestureRecognizer?
    private var customRotationGesture: UIRotationGestureRecognizer?
    private var initialRotation: CGFloat = 0.0

    func showFullScreen(from sourceImageView: UIImageView) {
        guard let window = getWindow(), let image = sourceImageView.image else { return }

        originalFrame = sourceImageView.superview?.convert(sourceImageView.frame, to: nil) ?? .zero
        originalCornerRadius = sourceImageView.layer.cornerRadius

        let bgView = UIView(frame: window.bounds)
        bgView.backgroundColor = .black
        bgView.alpha = 0
        window.addSubview(bgView)
        backgroundView = bgView

        let scView = UIScrollView(frame: window.bounds)
        scView.delegate = self
        scView.minimumZoomScale = 1.0
        scView.maximumZoomScale = 4.0
        scView.showsVerticalScrollIndicator = false
        scView.showsHorizontalScrollIndicator = false
        scView.contentInsetAdjustmentBehavior = .never
        window.addSubview(scView)
        scrollView = scView

        let imgView = UIImageView(frame: originalFrame)
        imgView.image = image
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
        imgView.layer.cornerRadius = originalCornerRadius
        imgView.isUserInteractionEnabled = true
        scView.addSubview(imgView)
        zoomImageView = imgView

        setupFloatingControls(in: window)
        setupGestures()

        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseInOut) {
            self.backgroundView?.alpha = 1
            self.toggleControlsVisibility(isHidden: false, animated: false)

            let width = window.frame.width
            let height = image.size.height * (width / image.size.width)
            let yPosition = max(0, (window.frame.height - height) / 2)

            self.zoomImageView?.frame = CGRect(x: 0, y: yPosition, width: width, height: height)
            self.zoomImageView?.layer.cornerRadius = 0
        } completion: { _ in
            self.scrollView?.contentSize = self.zoomImageView?.frame.size ?? .zero
            self.centerImage()
        }
    }

    private func setupFloatingControls(in window: UIWindow) {
        let safeArea = window.safeAreaLayoutGuide

        closeButton = createButton(iconName: "xmark", action: #selector(dismissFullScreen))
        shareButton = createButton(iconName: "square.and.arrow.up", action: #selector(handleShare))
        saveButton = createButton(iconName: "arrow.down.to.line", action: #selector(handleSave))

        [closeButton, shareButton, saveButton].compactMap { $0 }.forEach { window.addSubview($0) }

        NSLayoutConstraint.activate([
            closeButton!.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 10),
            closeButton!.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -20),
            closeButton!.widthAnchor.constraint(equalToConstant: 44),
            closeButton!.heightAnchor.constraint(equalToConstant: 44),

            shareButton!.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -20),
            shareButton!.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 20),
            shareButton!.widthAnchor.constraint(equalToConstant: 44),
            shareButton!.heightAnchor.constraint(equalToConstant: 44),

            saveButton!.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -20),
            saveButton!.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -20),
            saveButton!.widthAnchor.constraint(equalToConstant: 44),
            saveButton!.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        toggleControlsVisibility(isHidden: true, animated: false)
    }

    private func createButton(iconName: String, action: Selector) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: iconName)
        config.baseBackgroundColor = .white.withAlphaComponent(0.8)
        config.baseForegroundColor = .black
        config.cornerStyle = .capsule
        let button = UIButton(configuration: config)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    private func setupGestures() {
        guard let scrollView = scrollView, let zoomImageView = zoomImageView else { return }

        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
        scrollView.addGestureRecognizer(singleTap)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        zoomImageView.addGestureRecognizer(doubleTap)
        singleTap.require(toFail: doubleTap)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        scrollView.addGestureRecognizer(pan)
        customPanGesture = pan

        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        rotation.delegate = self
        scrollView.addGestureRecognizer(rotation)
        customRotationGesture = rotation
    }

    @objc private func handleSingleTap() {
        isControlHidden.toggle()
        toggleControlsVisibility(isHidden: isControlHidden, animated: true)
    }

    @objc private func handleDoubleTap(_ sender: UITapGestureRecognizer) {
        if scrollView?.zoomScale ?? 1.0 > 1.0 {
            scrollView?.setZoomScale(1.0, animated: true)
        } else {
            let point = sender.location(in: zoomImageView)
            let zoomRect = zoomRectForScale(scale: scrollView?.maximumZoomScale ?? 4.0, center: point)
            scrollView?.zoom(to: zoomRect, animated: true)
        }
    }

    @objc private func handleRotation(_ sender: UIRotationGestureRecognizer) {
        guard let zoomImageView = zoomImageView else { return }
        if sender.state == .began {
            initialRotation = atan2(zoomImageView.transform.b, zoomImageView.transform.a)
        } else if sender.state == .changed {
            zoomImageView.transform = CGAffineTransform(rotationAngle: initialRotation + sender.rotation)
        } else if sender.state == .ended {
            UIView.animate(withDuration: 0.3) { zoomImageView.transform = .identity }
        }
    }

    @objc private func handlePan(_ sender: UIPanGestureRecognizer) {
        guard let zoomImageView = zoomImageView, let window = getWindow(), scrollView?.zoomScale == 1.0 else { return }
        let translation = sender.translation(in: window)
        
        if sender.state == .changed {
            let scale = max(0.8, 1.0 - (abs(translation.y) / 1000.0))
            zoomImageView.center = CGPoint(x: window.center.x + translation.x, y: window.center.y + translation.y)
            zoomImageView.transform = CGAffineTransform(scaleX: scale, y: scale)
            backgroundView?.alpha = max(0, 1.0 - (abs(translation.y) / 500.0))
        } else if sender.state == .ended {
            if abs(translation.y) > 120 { dismissFullScreen() }
            else {
                UIView.animate(withDuration: 0.3) {
                    zoomImageView.center = window.center
                    zoomImageView.transform = .identity
                    self.backgroundView?.alpha = 1.0
                }
            }
        }
    }

    @objc private func dismissFullScreen() {
        UIView.animate(withDuration: 0.4, animations: {
            self.zoomImageView?.frame = self.originalFrame
            self.zoomImageView?.layer.cornerRadius = self.originalCornerRadius
            self.backgroundView?.alpha = 0
            self.toggleControlsVisibility(isHidden: true, animated: true)
        }) { _ in
            self.cleanup()
        }
    }

    @objc private func handleSave() {
        guard let image = zoomImageView?.image else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        // You can add a toast here: ToastManager.shared.show(message: "Saved to Photos")
    }

    @objc private func handleShare() {
        guard let image = zoomImageView?.image, let topVC = getTopViewController() else { return }
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        topVC.present(activityVC, animated: true)
    }

    private func cleanup() {
        [zoomImageView, scrollView, backgroundView, closeButton, shareButton, saveButton].forEach { $0?.removeFromSuperview() }
        zoomImageView = nil; scrollView = nil; backgroundView = nil
        closeButton = nil; shareButton = nil; saveButton = nil
    }

    private func toggleControlsVisibility(isHidden: Bool, animated: Bool) {
        let alpha: CGFloat = isHidden ? 0 : 1
        UIView.animate(withDuration: animated ? 0.2 : 0) {
            self.closeButton?.alpha = alpha
            self.shareButton?.alpha = alpha
            self.saveButton?.alpha = alpha
        }
    }

    private func centerImage() {
        guard let scrollView = scrollView, let zoomImageView = zoomImageView else { return }
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        zoomImageView.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { zoomImageView }
    func scrollViewDidZoom(_ scrollView: UIScrollView) { centerImage() }

    private func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        let w = (scrollView?.frame.size.width ?? 0) / scale
        let h = (scrollView?.frame.size.height ?? 0) / scale
        return CGRect(x: center.x - (w/2), y: center.y - (h/2), width: w, height: h)
    }

    private func getWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first
    }

    private func getTopViewController() -> UIViewController? {
        var top = getWindow()?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { true }
}
