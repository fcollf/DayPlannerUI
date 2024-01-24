//
//  PlannerInterval.swift
//  Created by fcollf on 4/1/24.
//


import Foundation


/// Represents the alignment of one entity (interval or planner element) in relation to another.
///
/// - `none`: Indicates no overlap or sequential relationship.
/// - `leading`: Indicates that the entity is positioned before the reference entity.
/// - `trailing`: Indicates that the entity is positioned after the reference entity.
///
public enum EdgeAlignment {
    case none
    case leading
    case trailing
}


/// `PlannerInterval` represents a  interval in the DayPlanner, defined by a range of integers (minutes)
///
/// Each bound of the interval is measured in minutes since the start of the day, providing a precise
/// way to represent time periods within the planner.
///
public struct PlannerInterval {

    
    // MARK: - Private Properties
    
    
    /// The range of integers representing the interval.
    /// The bounds are measured in minutes from the start of the day
    private var range: Range<Int>

    
    // MARK: - Public Properties
    
    
    /// The interval's lower bound, representing the start minute of the interval
    /// since the beginning of the day.
    var lowerBound: Int {
        range.lowerBound
    }
    
    /// The interval's upper bound, representing the end minute of the interval
    /// since the beginning of the day
    var upperBound: Int {
        range.upperBound
    }
    
    /// The total duration of the interval in minutes.
    var duration: Int {
        range.count
    }
    
    
    // MARK: - Initializers
    
    
    /// Initializes a new `PlannerInterval` with start and end times.
    ///
    /// This initializer converts the start and end times into minutes since the start of the day and creates
    /// a range representing the interval.
    ///
    /// - Parameters:
    ///   - startTime: The start time of the interval.
    ///   - endTime: The end time of the interval.
    ///
    init(startTime: Date, endTime: Date) {
        
        let calendar = Calendar.current
        
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        let startMinute = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
        var endMinute = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)
        
        if endMinute < startMinute {
            endMinute = (23 * 60) + 59
        }
        self.range = startMinute..<endMinute
    }

    
    // MARK: - Public Functions
    
    
    /// Updates the end time of the interval.
    ///
    /// This method sets the end time of the interval by converting the provided `endTime` to minutes since
    /// the start of the day. If the calculated end time is earlier than the start time, it defaults to
    /// 23:59 to ensure the interval remains valid.
    ///
    /// - Parameter endTime: The new end time to set for the interval.
    ///
    mutating func set(endTime: Date) {
       
        let calendar = Calendar.current
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        let startMinute = lowerBound
        var endMinute = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)
        
        if endMinute < startMinute {
            endMinute = (23 * 60) + 59
        }
        
        self.range = startMinute..<endMinute
    }
    
    
    /// Determines if the current interval completely contains another interval.
    ///
    /// This method checks if both the lower and upper bounds of the other interval
    /// are contained within the current interval.
    ///
    /// - Parameter other: Another `PlannerInterval` to compare with.
    /// - Returns: A Boolean value indicating whether the current interval completely contains the other interval.
    ///
    func contains(other interval: PlannerInterval) -> Bool {
        contains(minute: interval.lowerBound) && contains(minute: interval.upperBound)
    }
    
    
    /// Determines if the current interval contains a specific minute of the day.
    ///
    /// - Parameter minute: The minute of the day to check for containment.
    /// - Returns: `true` if the minute is within the interval; otherwise, `false`.
    ///
    func contains(minute: Int) -> Bool {
        range.contains(minute)
    }
    
    
    /// Determines if the current interval contains a specific time of the day.
    ///
    /// - Parameter time: The time of the day to check for containment.
    /// - Returns: `true` if the minute is within the interval; otherwise, `false`.
    ///
    func contains(time: Date) -> Bool {
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let minute = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        
        return contains(minute: minute)
    }
    
    
    /// Determines the overlapping relationship between this interval and another interval.
    ///
    /// The function checks if the other interval overlaps leading or trailing relative to this interval.
    ///
    /// - Parameter interval: The `PlannerInterval` to compare with this interval.
    /// - Returns: `.leading` if the other interval overlaps leading up to this interval, `.trailing` if it overlaps trailing after this interval,
    /// and `.none` if there is no overlap.
    ///
    func overlaps(other interval: PlannerInterval) -> EdgeAlignment {
        
        if interval.contains(other: self) {
            .leading
        } else if interval.lowerBound <= lowerBound && interval.contains(minute: upperBound) {
            .leading
        } else if contains(minute: interval.lowerBound) && interval.upperBound >= upperBound {
            .trailing
        } else {
            .none
        }
    }
}
