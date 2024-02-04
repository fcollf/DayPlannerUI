//
//  DayPlannerView.swift
//  Created by fcollf on 2/1/24.
//


import Foundation
import SwiftUI


/// A view that displays a schedule of items conforming to `SchedulableElement`.
///
/// This generic view is adaptable to various types of schedulable items and supports different levels of time granularity.
/// It presents a visual representation of schedulable elements, allowing for interaction and modification based on user input
///
public struct DayPlannerView<E: SchedulableElement, S: Sequence, V: View>: View where S.Element == E {
    
    
    /// A typealias for a closure that provides a custom view for each element in the planner.
    ///
    /// This closure is used to generate a view for each element, allowing for custom visual representation
    /// based on the element's data and state.
    ///
    /// - Parameters:
    ///   - startTime: The start time of the planner element. This can be used to position or configure the view.
    ///   - element: The planner element, conforming to `SchedulableElement`, for which the view is being generated.
    ///   - isPlaceholder: A Boolean value indicating whether the view to be rendered should be a placeholder view. This is typically
    ///   used to indicate that the primary view is being moved or dragged.
    ///   - isSelected: A Boolean value indicating whether the planner element is currently selected, allowing for visual differentiation of the selected state.
    /// - Returns: A view of type `V` that visually represents the planner element, or a placeholder view if the `placeholder` parameter is true.
    ///
    public typealias ElementBuilder = (_ startTime: Date, _ element: E, _ isPlaceholder: Bool, _ isSelected: Bool) -> V
    
    
    /// A type alias for a closure that handles the change of an element.
    ///
    /// This closure is called when an element is changed.
    /// - Parameters:
    ///    - item: The selected item of type `E`, conforming to `SchedulableElement`.
    ///
    public typealias ChangeHandler = (E) -> ()
    
    
    /// A type alias for a closure that handles the tap of an element.
    ///
    /// This closure is called when an element is tapped.
    /// - Parameters:
    ///    - item: The selected item of type `E`, conforming to `SchedulableElement`.
    ///
    public typealias TapHandler = (E) -> ()
    
    
    // MARK: - Private Properties
    
    
    /// The view model to manage the state and interactions
    @State private var viewModel: ViewModel?
    
    /// The collection of element to be displayed in the schedule
    private var elements: [E]
    
    /// The planner time  scale being used
    private var scale: PlannerTimeScale
    
    /// The total number of segments that can be displayed simultaneously on the screen
    private var visibleSegments: Int
    
    /// The currently selected element in the planner, if any
    @Binding private var selection: E?

    /// The color to use when selecting elements
    private var selectionColor: Color = .orange
    
    /// The color to use when rendering the placeholder
    private var placeholderColor: Color = .secondary.opacity(0.6)
    
    /// Indicates if the planner elements are editable
    private var isEditable: Bool = true
    
    /// A view builder for customizing the appearance of planner elements
    var elementBuilder: ElementBuilder?
    
    /// An optional closure that is called when an element in the planner is changed
    private var onChange: ChangeHandler?
    
    /// An optional closure that is called when an element in the planner is tapped
    private var onTap: TapHandler?
    
    
    // MARK: - Private Functions
    
    
    /// Creates and configures the `DayPlannerViewModel` based on the current view properties.
    ///
    /// - Parameter size: The current size of the view, used to calculate layout parameters.
    /// - Returns: An instance of `DayPlannerViewModel` configured for the current view state.
    ///
    private func viewModel(size: CGSize) -> ViewModel {
        
        let viewModel = ViewModel(scale: scale, visibleSegments: visibleSegments, size: size)
        
        // Assigns the element content builder if any
        viewModel.elementBuilder = elementBuilder
        
        // Assigns the handlers
        viewModel.onChange = onChange
        viewModel.onTap = onTap
        
        // Assigns the colors
        viewModel.selectionColor = selectionColor
        viewModel.placeholderColor = placeholderColor
        
        /// Assigns the `editable` flag
        viewModel.isEditable = isEditable
        
        // Updates the elements
        viewModel.update(elements: elements)
        
        return viewModel
    }
    

    // MARK: - Initializer
    
    
    /// Initializes the `DayScheduleView` with a set of schedulable items, specified granularity, and a default view for each item.
    ///
    /// This initializer sets up the view with a default appearance for each schedulable item.
    ///
    /// - Parameters:
    ///   - elements: A collection of elements conforming to `SchedulableElement`.
    ///   - scale: The scale of the time segments, which determines how the planner is visually divided.
    ///   - visibleSegments: The number of segments to display simultaneously.
    ///   - selection: A binding to the selected element.
    ///   - onChange: An optional closure that is called when an item is changed.
    ///
    public init(elements: S, scale: PlannerTimeScale = .half, visibleSegments: Int = 24, selection: Binding<E?>, onChange: ChangeHandler? = nil) where V == AnyView {
        
        self.elements = Array(elements)
        
        self.scale = scale
        self.visibleSegments = visibleSegments
        self._selection = selection
        self.onChange = onChange
        self.elementBuilder = { startTime, element, isPlaceholder, isSelected in
            AnyView(
                DefaultPlannerElementView(
                    element: element, startTime: startTime, isPlaceholder: isPlaceholder, isSelected: isSelected)
            )
        }
    }
    
    
    /// Initializes the `DayScheduleView` with a set of schedulable items and a specified granularity.
    ///
    /// - Parameters:
    ///   - elements: A collection of elements conforming to `SchedulableElement`.
    ///   - scale: The scale of the time segments, which determines how the planner  is visually divided.
    ///   - visibleSegments: The number of segments to display simultaneously.
    ///   - selection: A binding to the selected element.
    ///   - elementBuilder: A view builder closure to customize the appearance of each planner element.
    ///   - onChange: An optional closure that is called when an item is changed.
    ///
    public init(elements: S, scale: PlannerTimeScale = .half, visibleSegments: Int = 24, selection: Binding<E?>, @ViewBuilder elementBuilder: @escaping ElementBuilder, onChange: ChangeHandler? = nil) {
        
        self.elements = Array(elements)
        
        self.scale = scale
        self.visibleSegments = visibleSegments
        self._selection = selection
        self.elementBuilder = elementBuilder
        self.onChange = onChange
    }
    
    
    /// Initializes the `DayScheduleView` with a set of schedulable items, specified granularity, and a custom element builder.
    ///
    /// This initializer is used when you want a read-only view without interactive features such as element selection or resizing.
    /// It allows for a custom visualization of each element without requiring a selection binding or a change handler.
    ///
    /// - Parameters:
    ///   - elements: A collection of elements conforming to `SchedulableElement`.
    ///   - scale: The scale of the time segments, which determines how the planner  is visually divided.
    ///   - visibleSegments: The number of segments to display simultaneously.
    ///   - elementBuilder: A view builder closure to customize the appearance of each planner element.
    ///
    public init(elements: S, scale: PlannerTimeScale = .half, visibleSegments: Int = 24, @ViewBuilder elementBuilder: @escaping ElementBuilder) {
        
        self.elements = Array(elements)
        
        self.scale = scale
        self.visibleSegments = visibleSegments
        self._selection = .constant(nil)
        self.elementBuilder = elementBuilder
        self.isEditable = false
    }
    
    
    /// Initializes the `DayScheduleView` with a set of schedulable items, specified granularity, and a default view for each item.
    ///
    /// This initializer is suitable when you want a read-only view with a default visualization for each element.
    /// It sets up the view without interactive features, omitting the need for selection binding or change handling.
    ///
    ///
    /// - Parameters:
    ///   - elements: A collection of elements conforming to `SchedulableElement`.
    ///   - scale: The scale of the time segments, which determines how the planner  is visually divided.
    ///   - visibleSegments: The number of segments to display simultaneously.
    ///
    public init(elements: S, scale: PlannerTimeScale = .half, visibleSegments: Int = 24) where V == AnyView {
        
        self.elements = Array(elements)
        
        self.scale = scale
        self.visibleSegments = visibleSegments
        self._selection = .constant(nil)
        self.isEditable = false

        self.elementBuilder = { startTime, element, isPlaceholder, isSelected in
            AnyView(
                DefaultPlannerElementView(
                    element: element, startTime: startTime, isPlaceholder: isPlaceholder, isSelected: isSelected)
            )
        }
    }
    
    
    // MARK: - Body
    
    
    public var body: some View {
        
        GeometryReader { geometry in

            ScrollView {
                
                if let viewModel {
                    
                    // Elements view
                    PlannerElementsView()
                        .environment(viewModel)
                }
            }
            .scrollIndicators(.hidden)
            .onChange(of: geometry.size) {
                viewModel = viewModel(size: geometry.size)
            }
            .onChange(of: viewModel?.selection) {
                selection = viewModel?.selection?.content
            }
            .onChange(of: elements) {
                viewModel?.update(elements: elements)
            }
        }
    }
}


// MARK: - View Modifiers


extension DayPlannerView {
    
    
    /// Sets the selection color for the elements in the `DayPlannerView`.
    ///
    /// This modifier sets the color used to indicate when an element is selected within the `DayPlannerView`.
    ///
    /// - Parameter color: The `Color` to set as the selection color.
    /// - Returns: A `DayPlannerView` with the selection color set to the specified value.
    ///
    public func foregroundStyle(selection color: Color) -> Self {
        
        var view = self
        view.selectionColor = color
        return view
    }
    
    /// Sets the placeholder color for the elements in the `DayPlannerView`.
    ///
    /// - Parameter placeholder: The `Color` to set as the placeholder color.
    /// - Returns: A `DayPlannerView` with the placeholder color set to the specified value.
    ///
    public func foregroundStyle(placeholder color: Color) -> Self {
        
        var view = self
        view.placeholderColor = color
        return view
    }
    
    
    /// Modifies whether the planner elements are editable (movable and resizable).
    ///
    /// - Parameter bool: A Boolean value that determines whether the planner elements are editable.
    /// - Returns: An instance of the view with the modified editable state.
    ///
    public func isEditable(_ bool: Bool) -> Self {
        
        var view = self
        view.isEditable = bool
        return view
    }
    
    
    /// Modifies the view to execute the given closure when an element is tapped.
    ///
    /// - Parameter handler: The closure to execute when an element is tapped.
    /// - Returns: An instance of the view with the modified tap handler.
    /// 
    public func onTapGesture( _ handler: @escaping TapHandler) -> Self {
        
        var view = self
        view.onTap = handler
        return view
    }
}
