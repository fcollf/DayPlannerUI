//
//  PlannerElementView.swift
//  Created by fcollf on 3/1/24.
//


import Foundation
import SwiftUI


extension DayPlannerView {
    
    
    // MARK: - Default Element View
    
    
    /// A default view for displaying elements in `DayPlannerView`.
    ///
    /// Displays a schedulable element with title, subtitle, and start time, adapting to its content and selection state.
    ///
    struct DefaultPlannerElementView: View {
        
        
        /// The environment object that provides the view model containing the planner's state and logic
        @Environment(ViewModel.self) private var viewModel
        
        
        // MARK: - Private Properties
        
        
        /// The start time of the element
        private var startTime: Date
        
        /// Represents the schedulable element to be displayed
        private var element: E
        
        /// Indicates whether the element is a placeholder
        private var isPlaceholder: Bool
        
        /// Indicates whether the element is currently selected
        private var isSelected: Bool
        
        /// The color used to highlight the element when selected
        private var selectionColor: Color {
            viewModel.selectionColor
        }
        
        /// Color used to display the element
        private var color: Color {
            isPlaceholder ? viewModel.placeholderColor : element.color ?? .accentColor
        }
        
        
        // MARK: - Initializer
        
        
        /// Initializes a `DefaultElementView` with a given element and its selection state.
        ///
        /// - Parameters:
        ///   - element: The element to be displayed.
        ///   - startTime: The start time of the element.
        ///   - isPlaceholder: A boolean indicating whether the element is a placeholder.
        ///   - isSelected: A boolean indicating whether the element is currently selected.
        ///
        init(element: E, startTime: Date, isPlaceholder: Bool, isSelected: Bool) {
            
            self.element = element
            self.startTime = startTime
            self.isPlaceholder = isPlaceholder
            self.isSelected = isSelected
        }
        
        
        // MARK: - Body
        
        
        var body: some View {
            
            VStack(alignment: .leading) {
                
                HStack(alignment: .firstTextBaseline) {
                    
                    ViewThatFits {
                        
                        VStack(alignment: .leading) {
                            
                            Text(element.title)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            
                            Text(element.subtitle)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(alignment: .leading) {
                            
                            Text(element.title)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                    .padding(.vertical, 5)
                    
                    Spacer()
                    
                    Text(element.startTime.formatted(date: .omitted, time: .shortened))
                }
                .padding(.horizontal, 5)
                .drawingGroup()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(.thinMaterial, in: Rectangle())
                .padding(.leading, 4)
                .padding(.trailing, 1)
            }
            .foregroundStyle(isSelected ? selectionColor : .secondary)
            .font(.footnote.weight(isSelected ? .medium : .regular))
            .background(isSelected ? selectionColor : color, in: RoundedRectangle(cornerRadius: 5))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(isSelected ? selectionColor : color, lineWidth: 1)
            )
        }
    }


    // MARK: - Planner Element View
    
    
    /// A view for displaying an individual  element in the `DayPlannerView`.
    ///
    /// This view represents a single element from the planner, showing its details and allowing interaction through gestures
    ///
    struct PlannerElementView: View {
        
        
        // MARK: - Types
        
        
        /// Represents the state of a drag operation
        ///
        private enum DragState {
            
            /// The  element is not being dragged or resized.
            case inactive
            
            /// The  element is being dragged
            case dragging
            
            /// The element is being resized
            case resizingUp, resizingDown
            
            /// Checks if the element is currently being dragged.
            var isDragging: Bool {
                self == .dragging
            }
            
            /// Checks if the element is currently being resized either from up or down.
            var isResizing: Bool {
                self == .resizingUp || self == .resizingDown
            }
        }
        
        
        // MARK: - Environment
        
        
        /// The environment object that provides the view model containing the planner's state and logic
        @Environment(ViewModel.self) private var viewModel
        

        // MARK: - Private Properties
        
        
        /// A calendar object used for date calculations
        private let calendar = Calendar.current
        
        /// The schedulable element to be displayed
        @Bindable private var element: PlannerElement<E>
        
        /// The size of the element
        private var elementSize: CGSize
        
        /// The occupied rectangle of the element
        private var elementRect: CGRect {
            CGRect(origin: .zero, size: elementSize)
        }
        
        /// Translation for drag gesture
        @GestureState private var translation: CGFloat = 0
        
        /// Translation for resizing drag gesture
        @GestureState private var resizingTranslation: CGFloat = 0
        
        /// State of the drag gesture being performed
        @State private var dragState: DragState = .inactive
        
        /// Offset to display the element in the view
        @State private var offset: CGFloat = 0
        
        /// Long press gesture to toggle element selection
        private var longPressGesture: some Gesture {
            
            LongPressGesture(minimumDuration: 0.35)
                .onEnded { _ in
                    
                    guard viewModel.isEditable else {
                        return
                    }
                    
                    viewModel.onSelect(element: element)
                }
        }
        
        /// A tap gesture recognizer for the planner element
        private var tapGesture: some Gesture {
            
            TapGesture().onEnded { _ in
                viewModel.onTap(element: element)
            }
        }
        
        /// Drag gesture to move the selected segment
        private var dragGesture: some Gesture {
            
            DragGesture()
                .onChanged { value in
                    
                    dragState = dragState(for: value)
                }
                .updating($translation) { value, state, transaction in
                    
                    guard dragState != .inactive else {
                        return
                    }
                    
                    transaction.animation = .interactiveSpring
                
                    // Calculates the new increment
                    let increment = traslationIncrement(for: value.translation.height)
                    
                    // Makes sure the new offset could be valid
                    guard verifyOffsetConstraints(for: increment) else {
                        return
                    }
                    
                    // Makes sure in case of resizing the minimum size is kept
                    guard verifyDragResizeConstraints(for: increment) else {
                        return
                    }
                    
                    // Updates state
                    state = increment
                }
                .onEnded { value in
                    
                    guard dragState != .inactive else {
                        return
                    }
                    
                    // Increment
                    let increment = traslationIncrement(for: value.translation.height)

                    // Makes sure in case of resizing the minimum size is kept
                    guard verifyDragResizeConstraints(for: increment) else {
                        return
                    }
                    
                    // Gets the start time of the element
                    guard let startTime = startTime(for: increment) else {
                        return
                    }
                    
                    // Updates according to the drag state
                    switch dragState {
                            
                        case .inactive:
                            return
                            
                        case .dragging:
                            
                            // Modifies the final offset
                            self.offset = viewModel.offset(for: startTime)
                            
                            // Notifies the change
                            viewModel.onChange(element: element, startTime: startTime, endTime: nil)
                            
                        case .resizingUp:
                            
                            // Modifies the final offset
                            self.offset = viewModel.offset(for: startTime)
                            
                            // Updates the new start time keeping the end time
                            viewModel.onChange(element: element, startTime: startTime, endTime: element.endTime)
                             
                        case .resizingDown:
                            
                            // End time for the element is the start time of the new segment adding the element
                            // current duration
                            let endTime = calendar.date(byAdding: .minute, value: element.duration, to: startTime) ?? element.endTime
                            
                            // Keeps the start time and modifies the end time
                            viewModel.onChange(element: element, startTime: element.startTime, endTime: endTime)
                    }
                    
                    // Dragging ended
                    dragState = .inactive
            }
        }
    
        
        /// The target area for the resize-up gesture, positioned at the upper left,
        /// partially extending above the element's top edge.
        private var resizeUpTargetArea: CGRect {
            
            let targetWidth = elementSize.width * 0.10
            let targetHeight = targetWidth
            
            let targetX = elementRect.origin.x + (elementSize.width * 0.05)
            let targetY = elementRect.origin.y - targetHeight / 2
            
            return CGRect(x: targetX, y: targetY, width: targetWidth, height: targetHeight)
        }
        
        
        /// The target area for the resize-down gesture, positioned at the lower right,
        /// partially extending below the element's bottom edge.
        private var resizeDownTargetArea: CGRect {
            
            let targetWidth = elementSize.width * 0.10
            let targetHeight = targetWidth
            
            let targetX = elementRect.maxX - (elementSize.width * 0.05) - targetWidth
            let targetY = elementRect.maxY - (targetHeight / 2)
            
            return CGRect(x: targetX, y: targetY, width: targetWidth, height: targetHeight)
        }
        
        /// Helper property to get the current translation amount
        private var translationAmount: CGFloat {
            
            switch dragState {
                case .inactive, .resizingDown:
                    CGFloat.zero
                case .dragging:
                    translation
                case .resizingUp:
                    resizeAmount != 0 ? translation : 0
            }
        }
        
        /// Helper property to get the current resize amount
        private var resizeAmount: CGFloat {
            
            return if case dragState = .resizingUp {
                -translation
            } else if case dragState = .resizingDown {
                translation
            } else {
                CGFloat.zero
            }
        }
        
        /// Minimum size allowed when resizing
        private var minimumResizeHeight: CGFloat {
            (viewModel.segmentHeight / CGFloat(viewModel.scale.minutes)) * CGFloat(viewModel.scale.precision)
        }
        
        /// Indicates if this item is selected
        private var isSelected: Bool {
            viewModel.isSelected(element)
        }
        
        /// Color used to highlight the element when selected
        private var selectionColor: Color {
            viewModel.selectionColor
        }
        
        
        // MARK: - Private Functions
        
        
        
        /// Calculates the drag state based on the drag gesture value and element's selection and resize areas.
        ///
        /// This function determines whether the current drag gesture indicates that the element is being
        /// dragged, resized from the top (resizing up), or resized from the bottom (resizing down).
        /// If the drag is not recognized as any of these actions, it returns `.inactive`.
        ///
        /// - Parameter value: The value of the drag gesture, containing the start location and translation.
        /// - Returns: The calculated `DragState` for the current drag gesture.
        ///
        private func dragState(for value: DragGesture.Value) -> DragState {
            
            guard viewModel.isEditable else {
                return .inactive
            }
            
            return if isSelected {
                
                if resizeUpTargetArea.contains(value.startLocation) {
                    .resizingUp
                } else if resizeDownTargetArea.contains(value.startLocation) {
                    .resizingDown
                } else {
                    .dragging
                }
                
            } else {
                
                value.translation.height != 0 ? .dragging : .inactive
            }
        }
        
        
        /// Calculates the vertical translation increment based on a given height from a drag gesture.
        ///
        /// - Parameter height: The vertical height of the drag gesture translation.
        /// - Returns: The calculated increment value.
        ///
        private func traslationIncrement(for height: CGFloat) -> CGFloat {
            
            // Translation in heigth
            let precision = CGFloat(viewModel.scale.minutes / viewModel.scale.precision)
            let preciseInterval = viewModel.segmentHeight / precision
            
            // Calculate the number of precise intervals moved
            let intervalMovement = height / preciseInterval
    
            // Rounds the number of intervals
            let numberOfIntervals = round(intervalMovement)

            // Returns the total increment based on precise intervals
            return numberOfIntervals * preciseInterval
        }
        
        
        /// Verifies if the drag operation meets the offset constraints for the element being moved.
        ///
        /// This function checks whether the new offset of the element being moved
        /// does not violate the minimum and maximum offset constraint.
        ///
        /// - Parameter increment: The increment for the offset of the element as a result of the drag operation.
        /// - Returns: A Boolean value indicating whether the drag operation meets the offset constraints.
        ///
        private func verifyOffsetConstraints(for increment: CGFloat) -> Bool {
            
            // Calculate the new offset based on the original position plus the increment
            let offset = self.offset + increment
            
            if offset >= viewModel.minOffset, offset <= viewModel.maxOffset(for: element) {
                return true
            } else {
                return false
            }
        }
        
        
        /// Verifies if the drag operation meets the size constraints for the element being resized.
        ///
        /// This function checks whether the new size of the element after resizing (up or down)
        /// does not violate the minimum height constraint.
        ///
        /// - Parameter increment: The change in size of the element as a result of the drag operation.
        /// - Returns: A Boolean value indicating whether the resizing operation meets the size constraints.
        ///
        private func verifyDragResizeConstraints(for increment: CGFloat) -> Bool {
            
            if dragState == .resizingUp, elementSize.height - increment <= minimumResizeHeight {
                return false
            }
            
            if dragState == .resizingDown, elementSize.height + increment <= minimumResizeHeight {
                return false
            }
            
            return true
        }
        
        
        /// Calculates the start time for the element based on the drag increment and constrains it within the allowable range.
        ///
        /// This function computes the new offset based on the drag increment, ensures that the offset is within the
        /// allowable range, and then translates that offset to the corresponding start time for the element.
        ///
        /// - Parameter increment: The vertical drag increment which indicates how much the element has been moved or resized.
        /// - Returns: The start time corresponding to the new position of the element, or nil if it can't be determined.
        ///
        private func startTime(for increment: CGFloat) -> Date? {
            
            // Calculate the new offset based on the original position plus the increment
            var offset = self.offset + increment

            // Makes sure the offset does not exceed the boundaries for the current element
            offset = min(max(offset, viewModel.minOffset), viewModel.maxOffset(for: element))
            
            return viewModel.startTime(for: offset)
        }
        
        
        // MARK: - Initializer
        
        
        /// Initializes an `DayPlannerElementView` for displaying a planner segment element.
        ///
        /// - Parameters:
        ///   - element: The `PlannerSegmentElement<E>` to be displayed in the view.
        ///   - size: The size of the element.
        ///
        init(element: PlannerElement<E>, size: CGSize, offset: CGFloat) {
            self.element = element
            self.elementSize = size
            self._offset = State(wrappedValue: offset)
        }
        
        
        // MARK: - Body
        
        
        var body: some View {

            ZStack {
                
                if dragState == .dragging {
                    
                    PlannerElementContentView(element: element, isPlaceholder: true, isSelected: isSelected)
                        .frame(height: elementSize.height + resizeAmount)
                        .clipped()
                        .opacity(0.6)
                        .zIndex(1)
                    
                }
                
                ZStack {
                    
                    if isSelected {
                        
                        GeometryReader { proxy in
                            
                            // Upper left corner
                            
                            Rectangle()
                                .rotation(.degrees(45))
                                .fill(Color.white)
                                .stroke(selectionColor, lineWidth: 1)
                                .frame(width: 7, height: 7)
                                .offset(x: proxy.size.width * 0.10, y: -4)

                            // Lower right corner

                            Rectangle()
                                .rotation(.degrees(45))
                                .fill(Color.white)
                                .stroke(selectionColor, lineWidth: 1)
                                .frame(width: 7, height: 7)
                                .offset(x: proxy.size.width * 0.90, y: proxy.size.height - 3)
                            }
                    }
                    
                    PlannerElementContentView(element: element, isSelected: isSelected)
                        .frame(height: elementSize.height + resizeAmount)
                        .clipped()
                }
                .offset(y: translationAmount)
                .simultaneousGesture(viewModel.isEditable ? longPressGesture : nil)
                .simultaneousGesture(viewModel.isEditable ? dragGesture : nil)
                .simultaneousGesture(tapGesture)//viewModel.isEditable ? nil : tapGesture)
                .sensoryFeedback(.impact, trigger: isSelected)
                .sensoryFeedback(.impact, trigger: dragState)
                .zIndex(3)
            }
            .frame(height: elementSize.height + resizeAmount)
            .offset(y: offset + viewModel.offsetAdjustment)
        }
        
        
        // MARK: - Content
  

        /// Helper view to display the content of the element.
        ///
        private struct PlannerElementContentView: View {
            
            
            // MARK: - Environment
            
            
            /// The environment object that provides the view model containing the planner's state and logic
            @Environment(ViewModel.self) private var viewModel
            
            
            // MARK: - Private Properties
            
            
            /// Element to display
            @Bindable private var element: PlannerElement<E>
            
            /// Selection flag
            private var isPlaceholder: Bool
            
            /// Selection flag
            private var isSelected: Bool
            
            
            // MARK: - Initializer
            
            
            /// Initializes the view with the given element.
            /// - Parameters:
            ///   - element: The given `PlannerSegmentElement<E>`.
            ///   - isSelected: Selection flag.
            ///
            init(element: PlannerElement<E>, isPlaceholder: Bool = false, isSelected: Bool) {
                self.element = element
                self.isPlaceholder = isPlaceholder
                self.isSelected = isSelected
            }
            
            
            // MARK: - Body
            
            
            var body: some View {
                
                if let elementBuilder = viewModel.elementBuilder {
                    elementBuilder(element.startTime, element.content, isPlaceholder, isSelected)
                } else {
                    EmptyView()
                }
            }
        }
    }
}
