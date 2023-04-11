//
//  GraphOptions.swift
//  SwiftToGraphMacTool
//
//  Created by Umar Haroon on 3/16/23.
//

import Foundation

struct GraphOptions: OptionSet {
    let rawValue: Int
    
    static let tred       = GraphOptions(rawValue: 1 << 0)
    static let liveBuild  = GraphOptions(rawValue: 1 << 1)
    static let priority   = GraphOptions(rawValue: 1 << 2)
    static let standard   = GraphOptions(rawValue: 1 << 3)
    
    static let express: GraphOptions = [.tred, .liveBuild]
    static let all: GraphOptions = [.express, .priority, .standard]
}

enum Options: String, CaseIterable {
    case tred = "tred"
    case liveBuild
}
