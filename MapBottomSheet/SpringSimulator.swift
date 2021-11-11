//
//  SpringTimeCurve.swift
//  MapBottomSheet
//

import UIKit

struct Spring {
    let mass: CGFloat
    let stiffness: CGFloat
    let dampingRatio: CGFloat

    var damping: CGFloat {
        2 * dampingRatio * sqrt(mass * stiffness)
    }

    var beta: CGFloat {
        damping / (2 * mass)
    }

    var dampedNaturalFrequency: CGFloat {
        sqrt(stiffness / mass) * sqrt(1 - dampingRatio * dampingRatio)
    }

    static let defualt = Spring(mass: 1, stiffness: 200, dampingRatio: 1)
}

struct SpringSimulator {
    let spring: Spring
    let displacement: CGFloat
    let initialVelocity: CGFloat
    let threshold: CGFloat = 0.5 / UIScreen.main.scale

    var duration: TimeInterval {
        if displacement == 0 && initialVelocity == 0 {
            return 0
        }

        let b = spring.beta
        let e = CGFloat(M_E)

        let t1 = 1 / b * log(2 * abs(c1) / threshold)
        let t2 = 2 / b * log(4 * abs(c2) / (e * b * threshold))

        return TimeInterval(max(t1, t2))
    }

    func translate(at time: TimeInterval) -> CGFloat {
        let t = CGFloat(time)
        return exp(-spring.beta * t) * (c1 + c2 * t)
    }

    private var c1: CGFloat {
        displacement
    }

    private var c2: CGFloat {
        initialVelocity + spring.beta * displacement
    }
}
