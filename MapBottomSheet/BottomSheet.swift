//
//  BottomSheet.swift
//  MapBottomSheet
//

import Combine
import SwiftUI

private let BOTTOM_SHEET_MIN_HEIGHT: CGFloat = 48
private let BOTTOM_SHEET_MIDDLE_HEIGHT: CGFloat = 300

private class BottomSheetOverlayView: UIScrollView, UIScrollViewDelegate {

    private let bottomSheetAnimator = AnimationRunner()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        backgroundColor = .clear
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        alwaysBounceVertical = true

        delegate = self
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view === self ? nil : view
    }

    var position: CGFloat {
        get { contentInset.top + contentOffset.y }
        set {
            contentOffset.y = newValue - contentInset.top
            didUpdatePosition()
        }
    }

    var positionPublisher = PassthroughSubject<CGFloat, Never>()

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        bottomSheetAnimator.stop()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        didUpdatePosition()
    }

    func didUpdatePosition() {
        positionPublisher.send(position)
        // topCurtain.layer.opacity = max(0, min(1, 1 - Float((topPosition - position) / safeAreaInsets.top)))
    }

    var topPosition: CGFloat {
        contentInset.top - safeAreaInsets.top
    }
    var middlePosition: CGFloat {
        BOTTOM_SHEET_MIDDLE_HEIGHT
    }
    var bottomPosition: CGFloat {
        0
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let targetPosition = contentInset.top + targetContentOffset.pointee.y

        if targetPosition < middlePosition / 2 { // will animate to bottom of position
            return startSpringAnimation(to: bottomPosition, velocity: velocity.y)
        }

        if targetPosition < middlePosition * 3 / 2 {
            return startSpringAnimation(to: middlePosition, velocity: velocity.y)
        }

        if targetPosition < topPosition {
            return startSpringAnimation(to: topPosition, velocity: velocity.y)
        }

        if position < middlePosition * 3 / 2, topPosition < targetPosition {
            return startSpringAnimation(to: topPosition, velocity: velocity.y)
        }
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        if bottomSheetAnimator.running {
            // Stop default decelerating animation
            setContentOffset(contentOffset, animated: false)
        }
    }

    func startSpringAnimation(to targetPosition: CGFloat, velocity initialVelocity: CGFloat) {
        let spring = SpringSimulator(spring: .defualt, displacement: position - targetPosition, initialVelocity: initialVelocity)
        return bottomSheetAnimator.start { [weak self] t in
            self?.position = targetPosition + (t <= spring.duration ? spring.translate(at: t) : 0)
            return t <= spring.duration ? .running : .finish
        }
    }
}

private class BottomSheetController<Content: View, BottomSheet: View>: UIViewController, UIGestureRecognizerDelegate {

    var contentViewController: UIHostingController<Content>
    var content: Content {
        get { contentViewController.rootView }
        set { contentViewController.rootView = newValue }
    }

    var bottomSheetViewController: UIHostingController<BottomSheet>
    var bottomSheet: BottomSheet {
        get { bottomSheetViewController.rootView }
        set { bottomSheetViewController.rootView = newValue }
    }

    let bottomSheetOverlay = BottomSheetOverlayView()
    let bottomSheetCurtain = UIView()
    let bottomSheetBackground = UIView()
    var bottomSheetPositionCancellable: AnyCancellable? = nil

    init(content: Content, bottomSheet: BottomSheet) {
        contentViewController = UIHostingController<Content>(rootView: content)
        bottomSheetViewController = UIHostingController<BottomSheet>(rootView: bottomSheet)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        addChild(contentViewController)
        addChild(bottomSheetViewController)

        view.addSubview(contentViewController.view)
        view.addSubview(bottomSheetOverlay)
        view.addSubview(bottomSheetCurtain)

        bottomSheetOverlay.addSubview(bottomSheetBackground)
        bottomSheetOverlay.addSubview(bottomSheetViewController.view)

        contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        contentViewController.view.isUserInteractionEnabled = true

        bottomSheetViewController.view.translatesAutoresizingMaskIntoConstraints = false
        bottomSheetViewController.view.insetsLayoutMarginsFromSafeArea = false
        bottomSheetViewController.view.backgroundColor = .systemBackground
        bottomSheetViewController.view.clipsToBounds = true
        bottomSheetViewController.view.layer.cornerRadius = 6
        bottomSheetViewController.view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]

        bottomSheetOverlay.translatesAutoresizingMaskIntoConstraints = false
        bottomSheetOverlay.insetsLayoutMarginsFromSafeArea = false
        bottomSheetOverlay.contentInsetAdjustmentBehavior = .never

        bottomSheetCurtain.translatesAutoresizingMaskIntoConstraints = false
        bottomSheetCurtain.backgroundColor = .systemBackground
        bottomSheetCurtain.accessibilityIdentifier = "BottomSheet Curtain"

        bottomSheetBackground.translatesAutoresizingMaskIntoConstraints = false
        bottomSheetBackground.backgroundColor = .systemBackground

        NSLayoutConstraint.activate([

            contentViewController.view
                .topAnchor.constraint(equalTo: view.topAnchor),
            contentViewController.view
                .bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentViewController.view
                .leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentViewController.view
                .trailingAnchor.constraint(equalTo: view.trailingAnchor),

            bottomSheetViewController.view
                .topAnchor.constraint(equalTo: bottomSheetOverlay.contentLayoutGuide.topAnchor),
            bottomSheetViewController.view
                .bottomAnchor.constraint(equalTo: bottomSheetOverlay.contentLayoutGuide.bottomAnchor)
                .priority(value: .defaultLow),
            bottomSheetViewController.view
                .leadingAnchor.constraint(equalTo: bottomSheetOverlay.contentLayoutGuide.leadingAnchor),
            bottomSheetViewController.view
                .trailingAnchor.constraint(equalTo: bottomSheetOverlay.contentLayoutGuide.trailingAnchor),
            bottomSheetOverlay.contentLayoutGuide
                .heightAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.heightAnchor),

            bottomSheetOverlay
                .topAnchor.constraint(equalTo: view.topAnchor),
            bottomSheetOverlay
                .bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomSheetOverlay
                .leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomSheetOverlay
                .trailingAnchor.constraint(equalTo: view.trailingAnchor),

            bottomSheetOverlay.contentLayoutGuide
                .widthAnchor.constraint(equalTo: view.widthAnchor),

            bottomSheetOverlay.frameLayoutGuide
                .topAnchor.constraint(equalTo: view.topAnchor),
            bottomSheetOverlay.frameLayoutGuide
                .bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomSheetOverlay.frameLayoutGuide
                .leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomSheetOverlay.frameLayoutGuide
                .trailingAnchor.constraint(equalTo: view.trailingAnchor),

            bottomSheetCurtain
                .topAnchor.constraint(equalTo: view.topAnchor),
            bottomSheetCurtain
                .leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomSheetCurtain
                .trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomSheetCurtain
                .bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),

            bottomSheetBackground
                .topAnchor.constraint(equalTo: bottomSheetViewController.view.topAnchor, constant: 12),
            bottomSheetBackground
                .leadingAnchor.constraint(equalTo: bottomSheetOverlay.frameLayoutGuide.leadingAnchor),
            bottomSheetBackground
                .trailingAnchor.constraint(equalTo: bottomSheetOverlay.frameLayoutGuide.trailingAnchor),
            bottomSheetBackground
                .bottomAnchor.constraint(equalTo: bottomSheetOverlay.frameLayoutGuide.bottomAnchor),

        ])

        update(position: bottomSheetOverlay.position)

        contentViewController.didMove(toParent: self)
        bottomSheetViewController.didMove(toParent: self)

        bottomSheetPositionCancellable = bottomSheetOverlay.positionPublisher.sink { [weak self] position in self?.update(position: position) }
    }

    private func update(position: CGFloat) {
        contentViewController.additionalSafeAreaInsets.bottom = min(BOTTOM_SHEET_MIDDLE_HEIGHT + BOTTOM_SHEET_MIN_HEIGHT, position + BOTTOM_SHEET_MIN_HEIGHT)
        bottomSheetViewController.view.layer.cornerRadius = max(0, min(6, bottomSheetOverlay.topPosition - position))
        bottomSheetCurtain.layer.opacity = max(0, min(1, 1 - Float((bottomSheetOverlay.topPosition - position) / view.safeAreaInsets.top * 2)))
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        bottomSheetOverlay.contentInset.top = view.frame.height - view.safeAreaInsets.bottom - BOTTOM_SHEET_MIN_HEIGHT
        bottomSheetOverlay.contentInset.bottom = 0

        bottomSheetViewController.additionalSafeAreaInsets.top = .zero
        bottomSheetViewController.additionalSafeAreaInsets.bottom = view.safeAreaInsets.bottom
    }
}


extension NSLayoutConstraint {

    func priority(value: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = value
        return self
    }
}

private struct BottomSheetContainer<Content: View, BottomSheet: View>: UIViewControllerRepresentable {

    let content: Content
    let bottomSheet: BottomSheet

    init(content: Content, bottomSheet: BottomSheet) {
        self.content = content
        self.bottomSheet = bottomSheet
    }

    func makeUIViewController(context: Context) -> BottomSheetController<Content, BottomSheet> {
        return BottomSheetController(content: content, bottomSheet: bottomSheet)
    }

    func updateUIViewController(_ uiViewController: BottomSheetController<Content, BottomSheet>, context: Context) {
        uiViewController.content = content
        uiViewController.bottomSheet = bottomSheet
    }
}

private struct BottomSheet<Content: View>: View {

    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .foregroundColor(Color(.label))
                .frame(width: 40, height: 4)
                .padding(8)
                .opacity(0.5)
            content()
        }
        .edgesIgnoringSafeArea(.top)
    }
}

extension View {

    func bottomSheet<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        BottomSheetContainer(content: self, bottomSheet: BottomSheet(content: content))
            .ignoresSafeArea()
    }
}

struct BottomSheet_Previews: PreviewProvider {
    static var previews: some View {
        Text("Content")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray)
            .bottomSheet {
                ForEach(0...10, id: \.self) { _ in
                    Text("Bottom Sheet")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
    }
}
