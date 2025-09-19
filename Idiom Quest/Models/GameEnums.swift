//
//  GameEnums.swift
//  Idiom Quest
//
//  Created by Ray Zhou on 19/9/2025.
//

import SwiftUI

// MARK: - Game States
enum GameState {
    case waiting
    case playing
    case gameOver
}

// MARK: - Cloud Size Configuration
enum CloudSize {
    case large, medium
    
    var mainSize: CGFloat {
        switch self {
        case .large: return 90  // Increased from 80
        case .medium: return 60
        }
    }
    
    var puffSize: CGFloat {
        switch self {
        case .large: return 75  // Increased from 65
        case .medium: return 45
        }
    }
    
    var topSize: CGFloat {
        switch self {
        case .large: return 65  // Increased from 55
        case .medium: return 40
        }
    }
    
    var smallSize: CGFloat {
        switch self {
        case .large: return 30  // Increased from 25
        case .medium: return 20
        }
    }
    
    // Enhanced sizes for better large cloud details
    var mediumSize: CGFloat {
        switch self {
        case .large: return 42  // Increased from 35
        case .medium: return 28
        }
    }
    
    var bottomSize: CGFloat {
        switch self {
        case .large: return 38  // Increased from 30
        case .medium: return 22
        }
    }
    
    var wispSize: CGFloat {
        switch self {
        case .large: return 15  // Increased from 12
        case .medium: return 8
        }
    }
    
    var wispRange: CGFloat {
        switch self {
        case .large: return 55  // Increased from 45
        case .medium: return 35
        }
    }
    
    var wispCount: Int {
        switch self {
        case .large: return 10  // Increased from 6
        case .medium: return 6
        }
    }
    
    // Blur properties for better scaling
    var mainBlur: Double {
        switch self {
        case .large: return 2.5
        case .medium: return 2.0
        }
    }
    
    var puffBlur: Double {
        switch self {
        case .large: return 2.0
        case .medium: return 1.5
        }
    }
    
    var topBlur: Double {
        switch self {
        case .large: return 1.8
        case .medium: return 1.2
        }
    }
    
    var mediumBlur: Double {
        switch self {
        case .large: return 1.5
        case .medium: return 1.0
        }
    }
    
    var bottomBlur: Double {
        switch self {
        case .large: return 2.2
        case .medium: return 1.8
        }
    }
    
    var smallBlur: Double {
        switch self {
        case .large: return 1.3
        case .medium: return 1.0
        }
    }
    
    var wispBlurMin: Double {
        switch self {
        case .large: return 0.8
        case .medium: return 0.5
        }
    }
    
    var wispBlurMax: Double {
        switch self {
        case .large: return 2.5
        case .medium: return 1.5
        }
    }
    
    var overallBlur: Double {
        switch self {
        case .large: return 0.8
        case .medium: return 0.5
        }
    }
    
    var offset: CGFloat {
        switch self {
        case .large: return 40  // Increased from 35
        case .medium: return 25
        }
    }
    
    var verticalOffset: CGFloat {
        switch self {
        case .large: return 10  // Increased from 8
        case .medium: return 6
        }
    }
    
    var topOffset: CGFloat {
        switch self {
        case .large: return 30  // Increased from 25
        case .medium: return 18
        }
    }
    
    var smallOffset: CGFloat {
        switch self {
        case .large: return 60  // Increased from 50
        case .medium: return 35
        }
    }
    
    var smallVertical: CGFloat {
        switch self {
        case .large: return 18  // Increased from 15
        case .medium: return 12
        }
    }
}
