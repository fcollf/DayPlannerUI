//
//  PlannerTimeScale.swift
//  Created by fcollf on 2/1/24.
//


import Foundation


/// An enum representing the time division in the `DayPlanner` view.
///
/// `PlannerTimeScale` allows for defining the granularity of the time segments displayed in the planner.
///
public enum PlannerTimeScale {
    
    /// Represents an hourly division of the day.
    case hour
    
    /// Represents a division of the day into half-hour segments.
    case half
    
    /// Represents a division of the day into quarter-hour segments.
    case quarter
    
    
    /// The total number of time segments in a day, depending on the time scale chosen.
    public var segments: Int {
        
        switch self {
            case .hour: 24
            case .half: 48
            case .quarter: 96
        }
    }
    
    /// The number of minutes each time segment represents
    public var minutes: Int {
        
        switch self {
            case .hour: 60
            case .half: 30
            case .quarter: 15
        }
    }
    
    /// The precision for time calculations or adjustments, such as dragging and resizing schedule items
    public var precision: Int {
        
        switch self {
            case .hour: 30
            case .half: 15
            case .quarter: 5
        }
    }
}
