//
//  PlannerElement.swift
//  Created by fcollf on 18/1/24.
//


import Foundation
import OSLog


/// Represents an element in a planner view.
///
@Observable
final class PlannerElement<E: SchedulableElement>: Identifiable {
    
    
    public typealias Element = PlannerElement<E>
    
    
    // MARK: - Private Properties
    
    
    /// Calendar for internal operations
    private let calendar = Calendar.current
    
    /// Logger instance for logging information, warnings, and errors
    private let logger: Logger
    
    /// An array of `Element` instances that represent elements overlapping leading up to the current element
    private var leading: [Element]
    
    /// An array of `Element` instances that represent elements overlapping trailing after the current element
    private var trailing: [Element]
    
    /// The set of elements leading up to this element, with no preceding elements
    private var root: Set<Element> {
        
        var root = Set<Element>()
        
        var pending = Set<Element>()
        var visited = Set<Element>()
        
        // Starts with the current element
        pending.insert(self)
        
        while let element = pending.popFirst() {
            
            if visited.contains(element) {
                continue
            }
            
            visited.insert(element)

            if element.leading.isEmpty {
                root.insert(element)
            } else {
                pending.formUnion(element.leading)
            }
        }
            
        return root
    }
    
    /// The depth of overlapping elements leading up to the current element.
    /// This depth represents the maximum distance to the farthest leading element.
    ///
    private var leadingDepth: Int {
        
        guard !leading.isEmpty else {
            return 0
        }
        
        return leading.map { $0.leadingDepth + 1 }.max() ?? 1
    }
    
    /// The depth of overlapping elements trailing after the current element.
    /// This depth represents the maximum distance to the farthest trailing element
    ///
    private var trailingDepth: Int {
        
        guard !trailing.isEmpty else {
            return 0
        }
        
        return trailing.map { $0.trailingDepth + 1 }.max() ?? 1
    }
    
    
    // MARK: - Public Properties
    
    
    /// The actual content of the planner element
    private (set) var content: E
    
    /// The unique identifier for the planner element
    var id: E.ID {
        content.id
    }

    /// The title of the planner element
    var title: String {
        content.title
    }
    
    /// A subtitle or additional description of the planner element
    var subtitle: String {
        content.subtitle
    }
    
    /// The start time of the planner element
    private (set) var startTime: Date
    
    /// The end time of the planner element
    private (set) var endTime: Date
    
    /// The duration of the planner element, in minutes
    private (set) var duration: Int
    
    /// A range representing the time interval of the planner element, in minutes from the start of the day
    private (set) var interval: PlannerInterval
    
    /// The index of the planner element relative to the total number of columns
    private (set) var index: Int
    
    /// The total number of columns required to display this planner element and its overlapping elements
    private (set) var columns: Int
    
    
    // MARK: - Private Functions

    
    /// Recalculates the position (index and columns) for a specific element and its trailing elements recursively.
    ///
    /// - Parameters:
    ///   - element: The `PlannerElement` whose position is being recalculated.
    ///   - visited: A set to keep track of visited elements and avoid cycles.
    ///
    private func recalculatePosition(_ element: Element, visited: inout Set<E.ID>) {
        
        logger.debug("Updating position properties for: \(element.title)")
        
        guard !visited.contains(element.id) else {
            logger.debug("No changes"); return
        }
        
        let leadingDepth = element.leadingDepth
        let trailingDepth = element.trailingDepth
        
        // Updates the column index
        element.index = leadingDepth
        
        // Updates the number of columns
        element.columns = 1 + leadingDepth + trailingDepth
        
        logger.debug("Index: \(element.index) / Columns: \(element.columns)")
        
        visited.insert(element.id)
        
        // Recursively update for trailing elements
        for element in element.trailing {
            recalculatePosition(element, visited: &visited)
        }
    }
    
    
    /// Recalculates the position (index and columns) of this element and all related elements.
    ///
    /// This function serves as the entry point for layout updates, starting from the root elements.
    ///
    private func recalculatePosition() {
        
        var visited: Set<E.ID> = .init()
        
        root.forEach {
            recalculatePosition($0, visited: &visited)
        }
    }
    
    
    /// Attempts to append an element to the current element's leading array.
    ///
    /// This method places the element as far to the leading edge as possible by checking recursively.
    /// If the element cannot be placed further, it's appended to the current element's leading array.
    ///
    /// - Parameter element: The `PlannerElement` to append.
    /// - Returns: `true` if the element was successfully appended, `false` otherwise.
    ///
    @discardableResult
    private func appendLeading(_ element: Element) -> Bool {
        
        guard id != element.id, overlaps(other: element) == .leading  else {
            return false
        }
        
        // If there are leading elements, try to place the new element to their leading arrays recursively
        let isPlaced = leading.map { $0.appendLeading(element) }.contains(true)
        
        // When the item overlaps and there are no other items to the
        // leading edge, we connect the element
        if !isPlaced, !leading.contains(element) {
            
            // Appends to the leading edge
            leading.append(element)
            
            // Keeps the reference also in the element trailing edge
            element.trailing.append(self)
            
            // The items is already placed
            return true
        }
        
        return isPlaced
    }
    
    
    /// Attempts to append an element to the current element's trailing array.
    ///
    /// This method places the element as far to the trailing edge as possible by checking recursively.
    /// If the element cannot be placed further, it's appended to the current element's trailing array.
    ///
    /// - Parameter element: The `PlannerElement` to append.
    /// - Returns: `true` if the element was successfully appended, `false` otherwise.
    ///
    @discardableResult
    private func appendTrailing(_ element: Element) -> Bool {
        
        guard id != element.id, overlaps(other: element) == .trailing else {
            return false
        }
        
        // Check against all trailing elements and append the element to all where it fits
        let isPlaced = trailing.map {$0.appendTrailing(element) }.contains(true)
        
        // When the item overlaps and there are no other items to the
        // trailing edge, we connect the element
        if !isPlaced, !trailing.contains(element) {
            
            // Append to the trailing array
            trailing.append(element)
            
            // Keep the reference also in the new element's leading array
            element.leading.append(self)
            
            // Element is placed
            return true
        }
        
        return isPlaced
    }
    
    
    // MARK: - Initializer
    
    
    /// Initializes a new `PlannerElement` instance with the specified content.
    ///
    /// - Parameter content: The content of the element, conforming to `SchedulableElement`.
    ///
    init(content: E) {
        
        let subsystem = Bundle.main.bundleIdentifier!
        let category = String(describing: PlannerElement.self)
        
        self.logger = Logger(subsystem: subsystem, category: category)
        
        self.content = content
        self.interval = content.interval
        
        self.startTime = content.startTime
        self.endTime = content.endTime
        self.duration = content.duration
        self.leading = []
        self.trailing = []
        
        self.index = 0
        self.columns = 1
    }
    
    
    // MARK: - Public Functions
    

    /// Checks whether the current element overlaps with the specified element.
    ///
    /// An overlap occurs if the current element overlaps leading up to or trailing after the other element.
    ///
    /// - Parameter element: The `PlannerElement` to compare with the current element.
    /// - Returns: `true` if an overlap exists; otherwise, `false`.
    ///
    func overlaps(other element: Element) -> EdgeAlignment {
        
        guard id != element.id else {
            return .none
        }
        
        return interval.overlaps(other: element.interval)
    }
    
    
    /// Connects an element to the appropriate array (leading or trailing) based on its overlap with the current element.
    /// Updates the layout properties after connecting the element  to reflect the new structural relationships.
    ///
    /// - Parameter element: The `PlannerElement` to be connected.
    ///
    func connect(_ element: Element) {
        
        let placedLeading = appendLeading(element)
        let placedTrailing = appendTrailing(element)
        
        if placedLeading || placedTrailing {
            recalculatePosition()
        }
    }
    
    
    /// Detaches the current element from its leading and trailing connections.
    ///
    /// This method removes the current element from the leading and trailing arrays of connected elements.
    /// To maintain graph integrity, it tries to connect each leading element of the current element
    /// directly to each of its trailing elements. It also updates the layout properties of all affected elements.
    ///
    func detach() {
        
        // Attempt to reconnect leading elements with trailing elements
        
        leading.forEach { leading in
            trailing.forEach { trailing in
                if leading.overlaps(other: trailing) == .trailing {
                    leading.appendTrailing(trailing)
                }
            }
        }
        
        // Remove the current element from its leading elements' trailing arrays
        leading.forEach { element in
            element.trailing.removeAll { $0.id == id }
            element.recalculatePosition()
        }
        
        // Remove the current element from its trailing elements' leading arrays
        trailing.forEach { element in
            element.leading.removeAll { $0.id == id }
            element.recalculatePosition()
        }
        
        leading = []
        trailing = []
        
        // Updates the index
        self.index = 0
        
        // Updates the number of columns
        self.columns = 1
    }
    
    
    /// Updates the start and end times of the element and recalculates the related properties.
    ///
    /// Optionally, only the start time can be provided, and the end time will be calculated based on the duration.
    /// After updating, it detaches the element from its current connections in preparation for reinsertion or deletion.
    ///
    /// - Parameters:
    ///   - startTime: The new start time for the element.
    ///   - endTime: The new end time for the element, if not provided, it will be calculated based on the duration.
    ///
    func update(startTime: Date, endTime: Date? = nil) {
        
        self.startTime = startTime
        
        if let endTime = endTime {
            self.endTime = endTime
        } else {
            self.endTime = calendar.date(byAdding: .minute, value: self.duration, to: startTime) ?? self.endTime
        }
        
        self.interval = .init(startTime: self.startTime, endTime: self.endTime)
        self.duration = self.interval.duration
        
        self.content.startTime = self.startTime
        self.content.duration = self.duration
        
        // Removes current connections
        detach()
    }
}


// MARK: - Hashable


extension PlannerElement: Hashable {
    
    
    /// Hashes the `id` of this element by feeding it into the given hasher.
    /// - Parameter hasher: The hasher to use when combining the components of this instance.
    ///
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


// MARK: - Equatable


extension PlannerElement: Equatable {
    
    
    /// Compares two `PlannerElement` instances for equality.
    ///
    /// Two elements are considered equal if their `id` properties are the same.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side `PlannerElement` instance.
    ///   - rhs: The right-hand side `PlannerElement` instance.
    /// - Returns: A Boolean value indicating whether the two instances are equal.
    ///
    static func ==(_ lhs: PlannerElement<E>, _ rhs: PlannerElement<E>) -> Bool {
        lhs.id == rhs.id
    }
    
}
