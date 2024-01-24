//
//  PlannerElementsView.swift
//  Created by fcollf on 18/1/24.
//


import Foundation
import SwiftUI



extension DayPlannerView {
    
    
    /// The view representing the elements of a day planner.
    ///
    struct PlannerElementsView: View {
        
        
        // MARK: - Environment
        
        
        /// The environment object that provides the view model containing the planner's state and logic
        @Environment(ViewModel.self) private var viewModel
        
        
        // MARK: - Private Properties
        
        
        /// A namespace for defining matched geometry effects within the view
        @Namespace private var elements
        
        /// Default spacing for elements in the same segment
        private let spacing: CGFloat = 2
        
        
        // MARK: - Private Functions
        
        
        /// Calculates the size for a given planner element.
        ///
        /// - Parameters:
        ///   - element: The `PlannerElement` for which to calculate the size.
        ///   - proxy: A `GeometryProxy` object representing the available space.
        /// - Returns: The size of the element as a `CGSize`.
        /// - Note: If the segment has no elements, the full size of the proxy is returned.
        ///
        private func size(_ element: PlannerElement<E>, proxy: GeometryProxy) -> CGSize {
            
            guard element.columns >= 1 else {
                return proxy.size
            }
            
            let width = (proxy.size.width / CGFloat(element.columns)) - spacing
            let height = viewModel.height(for: element.duration)
            
            return .init(width: width, height: height)
        }
        
        
        /// Calculates the horizontal offset for a given planner  element.
        ///
        /// This function determines the horizontal position of the element.
        /// The offset is based on the element's index which corresponds to the column in which
        /// the element needs to be redered.
        ///
        /// - Parameters:
        ///   - element: The `PlannerElement` for which to calculate the offset.
        ///   - size: The size of the element.
        /// - Returns: The horizontal offset of the element as a `CGFloat`.
        ///
        private func xOffset(_ element: PlannerElement<E>, size: CGSize) -> CGFloat {
            size.width * CGFloat(element.index) + (element.index > 0 ? spacing : 0)
        }
        
        /// Calculates the vertical offset for a given element in the planner view.
        ///
        /// This function determines the position of an element based on its
        /// start time and duration, relative to the start of the day.
        ///
        /// - Parameters:
        ///   - element: The `PlannerSegmentElement` for which to calculate the offset.
        /// - Returns: The vertical offset (y position) of the element within the planner view.
        ///
        private func yOffset(_ element: PlannerElement<E>) -> CGFloat {
            viewModel.offset(for: element)
        }
        
        
        // MARK: - Body
        
        
        var body: some View {
            
            ZStack(alignment: .topTrailing) {
                
                // Background Grid
                PlannerGridView()
                
                // Elements
                GeometryReader { proxy in
                    
                    ForEach(viewModel.elements) { element in
                        
                        let size = size(element, proxy: proxy)
                        let xOffset = xOffset(element, size: size)
                        let yOffset = yOffset(element)
                        
                        PlannerElementView(element: element, size: size, offset: yOffset)
                            .frame(width: size.width)
                            .offset(x: xOffset)
                            .animation(.snappy, value: size.width)
                            .animation(.snappy, value: xOffset)
                            .matchedGeometryEffect(id: element.id, in: elements)
                    }
                }
                .frame(maxWidth: viewModel.width * 0.8)
            }
        }
    }
}
