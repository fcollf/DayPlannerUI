//
//  SchedulableElement.swift
//  Created by fcollf on 2/1/24.
//


import Foundation
import SwiftUI


/// A protocol representing an element that can be scheduled in the day planner.
///
/// Conforming types must be identifiable and equatable, and they must provide essential scheduling
/// information such as title, subtitle, start time, and duration.
///
public protocol SchedulableElement: Identifiable, Equatable {
    
    /// The title of the scheduled element
    var title: String { get }
    
    /// A subtitle or additional description for the scheduled element
    var subtitle: String { get }
    
    /// The start time of the scheduled element
    var startTime: Date { get set }
    
    /// The duration of the scheduled element  in minutes
    var duration: Int { get set }
    
    /// Display color for the scheduled element
    var color: Color? { get }
}


public extension SchedulableElement {
    
    
    /// The end time of the scheduled element
    var endTime: Date {
        Calendar.current.date(byAdding: .minute, value: duration, to: startTime) ?? startTime
    }
    
    /// A  range representing the interval from the start to the end of the scheduled element,
    /// in minutes since the beginning of the day.
    ///
    /// This property calculates the time span using the start and end times of the encapsulated
    /// `SchedulableElement`. The interval is useful for representing the element's duration
    /// and position within the daily schedule.
    ///
    var interval: PlannerInterval {
        .init(startTime: startTime, endTime: endTime)
    }
}
