//
//  ProjectionAnimator.swift
//  MapBottomSheet
//

import QuartzCore

enum AnimationResult {
    case running
    case pause
    case finish
    case cancel
}

final class AnimationRunner {

    var running: Bool { displayLink != nil }
    private var currentAnimation: ((TimeInterval) -> AnimationResult)? = nil
    private var startTimestamp: CFTimeInterval = CACurrentMediaTime()

    func start(with animation: @escaping (TimeInterval) -> AnimationResult) {
        assert(running == false)
        let displayLink = CADisplayLink(target: self, selector: #selector(handleFrame(_:)))
        displayLink.add(to: .main, forMode: RunLoop.Mode.common)
        self.currentAnimation = animation
        self.startTimestamp = CACurrentMediaTime()
        self.displayLink = displayLink
    }

    func pause() {
        displayLink?.invalidate()
    }

    func resume() {
        guard currentAnimation != nil else { return }
        let displayLink = CADisplayLink(target: self, selector: #selector(handleFrame(_:)))
        displayLink.add(to: .main, forMode: RunLoop.Mode.common)
        self.displayLink = displayLink
    }

    func stop() {
        displayLink?.invalidate()
    }

    private func finish() {
        currentAnimation = nil
        displayLink?.invalidate()
    }

    private weak var displayLink: CADisplayLink? = nil

    @objc private func handleFrame(_ displayLink: CADisplayLink) {
        guard running, let animation = currentAnimation else {
            stop()
            return
        }
        switch animation(CACurrentMediaTime() - startTimestamp) {
        case .finish:
            finish()
        default:
            break
        }
    }

    deinit {
        displayLink?.invalidate()
    }
}

final class ProjectionAnimator {

    private let projector: (ProjectionAnimator) -> Void

    private(set) var running: Bool = false
    private(set) var percentComplete: CGFloat = 0
    private var currentAnimation: Animation? = nil

    struct Animation {
        let timingCurve: (TimeInterval) -> CGFloat
        let duration: TimeInterval
        let startAt: CFTimeInterval
        let finalValue: CGFloat
    }

    init(_ projector: @escaping (ProjectionAnimator) -> Void) {
        self.projector = projector
    }

    func start(to value: CGFloat, duration: TimeInterval, timingCurve: @escaping (TimeInterval) -> CGFloat) {
        assert(running == false)
        currentAnimation = Animation(timingCurve: timingCurve, duration: duration, startAt: CACurrentMediaTime(), finalValue: value)
        running = true
        let displayLink = CADisplayLink(target: self, selector: #selector(handleFrame(_:)))
        displayLink.add(to: .main, forMode: RunLoop.Mode.common)
        self.displayLink = displayLink
    }

    func pause() {
        running = false
        displayLink?.invalidate()
    }

    func resume() {
        running = true
        if currentAnimation != nil {
            let displayLink = CADisplayLink(target: self, selector: #selector(handleFrame(_:)))
            displayLink.add(to: .main, forMode: RunLoop.Mode.common)
            self.displayLink = displayLink
        }
    }

    func stop() {
        currentAnimation = nil
        running = false
        displayLink?.invalidate()
        projector(self)
    }

    func update(percent: CGFloat) {
        assert(running == false)
        percentComplete = percent
        projector(self)
    }

    private weak var displayLink: CADisplayLink? = nil

    @objc private func handleFrame(_ displayLink: CADisplayLink) {
        guard running, let animation = currentAnimation else {
            stop()
            return
        }
        let elapsed = (CACurrentMediaTime() - animation.startAt)
        if elapsed > animation.duration {
            percentComplete = animation.finalValue
            stop() // include projector(self)
        } else {
            percentComplete = animation.timingCurve(elapsed)
            projector(self)
        }
    }

    deinit {
        invalidate()
    }

    func invalidate() {
        guard running else { return }
        running = false
        displayLink?.invalidate()
    }
}
