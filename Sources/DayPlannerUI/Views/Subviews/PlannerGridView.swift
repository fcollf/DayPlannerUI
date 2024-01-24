//
//  PlannerGridView.swift
//  Created by fcollf on 3/1/24.
//


import Foundation
import SwiftUI


extension DayPlannerView {
    
    
    /// The view representing the grid layout of time segments in the day planner.
    ///
    struct PlannerGridView: View {
        
        
        // MARK: - Environment
        
        
        /// The environment object that provides the view model containing the planner's state and logic
        @Environment(ViewModel.self) private var viewModel

        
        // MARK: - Body
        
        
        var body: some View {
            
            LazyVStack(spacing: 0) {
                
                ForEach(viewModel.segments, id:\.self) { time in
                    
                    HStack(alignment: .center) {
                        
                        Text(time.formatted(date: .omitted, time: .shortened))
                            .font(.caption).fontWeight(.light)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                            .frame(maxWidth: viewModel.width * 0.20)
                        
                        Rectangle()
                            .fill(Color.secondary.opacity(0.15))
                            .frame(maxWidth: .infinity)
                            .frame(height: 1)
                            .frame(maxWidth: viewModel.width * 0.80)
                            .padding(.trailing, 5)
                    }
                    .frame(height: viewModel.segmentHeight)
                }
            }
        }
    }
    
}
