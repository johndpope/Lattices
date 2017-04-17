//
//  Float.swift
//  SwiftCrystal
//
//  Created by Jun Narumi on 2016/09/10.
//  Copyright © 2016年 zenithgear. All rights reserved.
//

import Foundation

#if os(OSX)
    typealias FloatType = Double
#elseif os(iOS)
    typealias FloatType = Float
#endif

// 型の種別に応じた等価判定値を用いた等価判定
infix operator =~: ComparisonPrecedence
infix operator !~: ComparisonPrecedence

// float等でsqrt epsilonを用いた等価判定
infix operator =~~: ComparisonPrecedence
infix operator !~~: ComparisonPrecedence

// float等でepsilonを用いた等価判定
infix operator =~~~: ComparisonPrecedence
infix operator !~~~: ComparisonPrecedence

//#if os(OSX)
extension Float {
    var toRadian : Float {
        return self * .pi / 180.0
    }
    var toDegree : Float {
        return self * 180.0 / .pi
    }
}
//#endif

extension Float {
    static let epsilon : Float = .ulpOfOne
}

extension Double {
    var toRadian : Double {
        return self * .pi / 180.0
    }
    var toDegree : Double {
        return self * 180.0 / .pi
    }
    static let epsilon : Double = .ulpOfOne
}

func =~( l:Float, r:Float) -> Bool {
    return abs(l-r) < 0.001
}

func =~( l:Double, r:Double) -> Bool {
    return abs(l-r) < 0.001
}

func =~~( l:Float, r:Float) -> Bool {
    return abs(l-r) < sqrt( Float.epsilon )
}

func =~~( l:Double, r:Double) -> Bool {
    return abs(l-r) < sqrt( Double.epsilon )
}


