//
//  DayPlannerViewModel.swift
//  Created by fcollf on 2/1/24.
//


import Foundation
import SwiftUI
import OSLog


extension DayPlannerView {
    
    
    @Observable
    internal final class ViewModel {
        

        // MARK: - Public Properties
        
        
        /// Logger instance
        private (set) var logger: Logger
        
        /// The calendar used for internal date and time calculations
        private (set) var calendar: Calendar
        
        /// The total width of the screen or view area where the schedule is displayed
        private (set) var width: CGFloat
        
        /// The total height of the screen or view area where the schedule is displayed
        private (set) var height: CGFloat
        
        /// The granularity of time division in the planner view.
        private (set) var scale: PlannerTimeScale
        
        /// The number of time segments that are visible at once in the view
        private (set) var visibleSegments: Int
        
        /// The height of each individual time segment in the view
        private (set) var segmentHeight: CGFloat
        
        /// The list of schedulable elements in the planner
        private (set) var elements: [PlannerElement<E>]
        
        /// The time divisions displayed in the planner view
        private (set) var segments: [Date]
        
        /// The currently selected element in the planner
        var selection: PlannerElement<E>?
        
        /// Selected color to highlight selected elements
        var selectionColor: Color = .orange
        
        /// The color to use when rendering the placeholder
        var placeholderColor: Color = .secondary.opacity(0.6)

        /// Indicates if the planner elements are editable
        var isEditable: Bool = true
        
        /// A view builder for customizing the appearance of planner elements
        var elementBuilder: ElementBuilder? = nil
    
        /// An optional closure that is called when an element in the planner is changed
        var onChange: ChangeHandler? = nil
        
        /// The minimum vertical offset for the planner view
        var minOffset: CGFloat = 0.0
        
        /// The maximum vertical offset for the planner view
        var maxOffset: CGFloat {
            CGFloat(scale.segments) * segmentHeight
        }
        
        /// Determines the additional vertical offset needed to align an element to the planner's grid.
        var offsetAdjustment: CGFloat {
            segmentHeight / 2
        }
        
        
        // MARK: - Private Functions
        
        
        /// Connects the given element to other elements in the planner based on their overlap relationships.
        ///
        /// This method goes through all existing elements and establishes a connection (leading or trailing)
        /// if there is an overlap between the given element and each of the existing elements.
        ///
        /// - Parameter element: The `PlannerElement` to connect with other elements.
        ///
        private func connect(_ element: PlannerElement<E>) {
            
            elements.filter { $0.id != element.id }.forEach {
                if $0.overlaps(other: element) != .none {
                    $0.connect(element)
                } else if element.overlaps(other: $0) != .none {
                    element.connect($0)
                }
            }
        }
        
        
        /// Sorts the elements first by their start time and then by their duration in descending order.
        ///
        /// Elements with the same start time are sorted such that the element with the longer duration comes first.
        ///
        private func sort() {

            elements.sort {
                
                // Secondary sort: longer duration comes first
                if $0.interval.lowerBound == $1.interval.lowerBound {
                    return $0.duration > $1.duration
                }
                
                // Primary sort: earlier start time comes first
                return $0.interval.lowerBound < $1.interval.lowerBound
            }
        }
        
        
        // MARK: - Initializer
        
        
        /// Initializes a new ViewModel for the Day Planner.
        ///
        /// This initializer sets up the View Model with the necessary properties based on the provided screen size,
        /// scale, and the number of visible segments. It calculates the width, height, and segment height
        /// based on the view's geometry and prepares the time segments based on the specified scale.
        ///
        /// - Parameters:
        ///   - scale: The `PlannerTimeScale` enum value representing the granularity of the time segments.
        ///   - visibleSegments: The number of time segments visible at once in the planner view.
        ///   - size: A `CGSize` object providing the size information of the view.
        ///
        init(scale: PlannerTimeScale, visibleSegments: Int, size: CGSize) {
            
            let calendar = Calendar.current
            
            /// Subsystem and category for the logger
            let subsystem = Bundle.main.bundleIdentifier!
            let category = String(describing: ViewModel.self)
            
            self.calendar = calendar
            self.logger = Logger(subsystem: subsystem, category: category)
            self.scale = scale
            
            self.width = size.width
            self.height = size.height
            
            self.visibleSegments = visibleSegments
            self.segmentHeight = max(30, size.height/CGFloat(visibleSegments))
            
            self.selection = nil
            
            // Initializes elements and segments
            
            self.elements = .init()
            self.segments = []
            
            for i in 0..<scale.segments + 1 {
                segments.append(startTime(for: i))
            }

            logger.debug("New ViewModel instance...")
            logger.debug("Segment Height: \(self.segmentHeight)")
        }
        
        
        // MARK: - Public Functions
        
        
        /// Updates the current list of `PlannerElement`s with a new sequence of `SchedulableElement`.
        ///
        /// It removes elements not present in the new sequence and adds elements from the new sequence
        /// that are not already present. It ensures all overlapping relationships are accurately maintained.
        ///
        /// - Parameters:
        ///    - sequence: The new collection of elements to synchronize with.
        ///
        func update<L: Sequence>(elements sequence: L) where L.Element == E {
            
            // Removes elements not present in the collection
            
            let elementsToRemove = elements.compactMap { element in
                sequence.contains { $0.id == element.id } ? nil : element
            }
            
            for element in elementsToRemove {
                
                // Remove all overlapping links
                element.detach()
                
                // Removes the element from the list
                elements.removeAll { $0.id == element.id }
            }
            
            // Adds new elements
            
            let elementsToAdd = sequence.compactMap { element in
                elements.contains { $0.id == element.id } ? nil : PlannerElement(content: element)
            }
            
            // Process the new elements to check for overlapping
            for element in elementsToAdd {
                
                // Updates connections
                connect(element)
                
                // Append new element
                elements.append(element)
                
            }
            
            // Sorts the elements
            sort()
        }
        
        
        /// Calculates the start time corresponding to a specific segment index in the planner view.
        ///
        /// This function determines the start time for each segment based on its index.
        ///
        /// - Parameter index: The index of the segment for which to calculate the start time.
        /// - Returns: A `Date` representing the start time of the segment at the given index.
        ///
        func startTime(for index: Int) -> Date {
            
            let factor = scale.segments / visibleSegments
            
            let hours = index / factor
            let minutes = (index % factor) * scale.minutes
            
            let startOfDay = calendar.startOfDay(for: .now)
            
            return calendar.date(bySettingHour: hours, minute: minutes, second: 0, of: startOfDay) ?? startOfDay
        }
        
        
        /// Calculates the start time corresponding to a specific vertical offset in the planner view.
        ///
        /// This function translates a y-coordinate position into a time value, taking into account the start of the day, the interval
        /// used for the planner, and the precision for time calculations.
        ///
        /// - Parameter yOffset: The vertical offset (y-coordinate) in the planner view for which to calculate the start time.
        /// - Returns: A `Date` representing the start time corresponding to the given vertical offset.
        ///
        func startTime(for yOffset: CGFloat) -> Date? {
            
            let startOfDay = calendar.startOfDay(for: .now)
            
            let factor = CGFloat(scale.segments / visibleSegments)
            let segmentIndex = yOffset / segmentHeight
            
            let hours = max(0, segmentIndex / factor)
            let minutes = max(0, ((segmentIndex / factor) - floor(hours)) * 60)
            
            var roundedHours = max(0, Int(floor(hours)))
            var roundedMinutes = Int(round(minutes / CGFloat(scale.precision)) * CGFloat(scale.precision))
            
            // Adjust for the case where roundedMinutes is 60
            if roundedMinutes >= 60 {
                roundedMinutes = 0
                roundedHours += 1
            }
            
            // Makes sure it does not exceed 23:59
            if roundedHours > 23 {
                roundedHours = 23
                roundedMinutes = 59
            }
            
            logger.debug("Segment start time for offset \(yOffset): \(roundedHours):\(roundedMinutes)")
            
            guard let time = calendar.date(bySettingHour: roundedHours, minute: roundedMinutes, second: 0, of: startOfDay) else {
                return nil
            }
            
            return time
        }
        
        
        /// Calculates the maximum vertical offset for a specified planner element.
        ///
        /// This function determines the furthest point to which an element can be moved or dragged
        /// vertically within the planner view. It ensures that the element stays within the viewable
        /// bounds of the planner.
        ///
        /// - Parameter element: The `PlannerElement<E>` for which to calculate the maximum offset.
        /// - Returns: A `CGFloat` representing the maximum vertical offset for the given element.
        ///
        func maxOffset(for element: PlannerElement<E>) -> CGFloat {
            maxOffset - height(for: element.duration)
        }

        
        /// Calculates the vertical offset for a given time in the planner view.
        ///
        /// - Parameters:
        ///    - time: The given time.
        /// - Returns: The vertical offset (y position) of the time within the planner view.
        ///
        func offset(for time: Date) -> CGFloat {
            
            let startOfDay = calendar.startOfDay(for: time)
            let timeDifference = calendar.dateComponents([.hour, .minute], from: startOfDay, to: time)
            let totalMinutes = CGFloat((timeDifference.hour ?? 0) * 60 + (timeDifference.minute ?? 0))
            
            let position = segmentHeight/CGFloat(scale.minutes)
            
            return ( totalMinutes * position )
        }
        
        
        /// Calculates the vertical offset for a given element in the planner view.
        ///
        /// This function determines the position of an element based on its start time and duration, relative to the start of the day.
        ///
        /// - Parameters:
        ///    - element: The schedulable element for which to calculate the offset.
        ///    - adjust: A Boolean value that determines whether to apply the adjustment. Defaults to `true`.
        /// - Returns: The vertical offset (y position) of the element within the planner view.
        ///
        
        func offset(for element: PlannerElement<E>) -> CGFloat {
            offset(for: element.startTime)
        }

        
        /// Calculates the height of a segment for a given schedulable element based on its duration.
        ///
        /// This function determines how much vertical space an element should occupy in the planner view.
        ///
        /// - Parameter element: The schedulable element for which to calculate the segment height.
        /// - Returns: The calculated height of the segment representing the element.
        ///
        func height(for duration: Int) -> CGFloat {
            CGFloat(duration) * (segmentHeight / CGFloat(scale.minutes))
        }
        

        /// Handles changes to a planner element's start time and end time, updates its layout, and notifies about the change.
        ///
        /// This method updates the specified element with new time values, recalculates its connections
        /// with other elements, and invokes a callback to notify about the update.
        ///
        /// - Parameters:
        ///   - element: The `PlannerElement` that has changed.
        ///   - startTime: The new start time for the element.
        ///   - endTime: The new (optional) end time for the element. If not provided, the end time is calculated based on the duration.
        ///   
        func onChange(element: PlannerElement<E>, startTime: Date, endTime: Date?) {
            
            // Updates the element, the update automatically detachs the element
            // from its current relationships
            element.update(startTime: startTime, endTime: endTime)
            
            // Updates connections
            connect(element)
            
            // Calls the handler to notify the change
            onChange?(element.content)
        }
        
        
        /// Toggles the selection state of a given planner segment element.
        ///
        /// If the provided element is already selected, it gets deselected.
        /// If it's not the current selection, it becomes selected.
        ///
        /// - Parameter element: The `PlannerSegmentElement` to be toggled.
        ///
        func onSelect(element: PlannerElement<E>?) {
            selection = selection == element ? nil : element
        }
        
        
        /// Determines if a given planner segment element is currently selected.
        ///
        /// - Parameter element: The `PlannerSegmentElement` to check for selection.
        /// - Returns: `true` if the element is the current selection; otherwise, `false`.
        ///
        func isSelected(_ element: PlannerElement<E>) -> Bool {
            selection == element
        }
        
    }
}
