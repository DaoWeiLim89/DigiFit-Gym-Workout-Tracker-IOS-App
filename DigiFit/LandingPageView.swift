import SwiftUI
import Charts
import ComponentsKit

struct LandingPageView: View {
    @State private var workoutPages: [WorkoutPage] = [
        WorkoutPage(name: "Chest Day", exercises: [
            UIExercise(name: "Bench Press", sets: 3, reps: 10),
            UIExercise(name: "Dumbbell Fly", sets: 3, reps: 12)
        ]),
        WorkoutPage(name: "Leg Day", exercises: [
            UIExercise(name: "Squats", sets: 4, reps: 8)
        ])
    ]
    
    @State private var selectedPage: WorkoutPage?
    @State private var isAddingExercise = false
    @State private var isReordering = false
    @State private var isAddingSplit = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    // MARK: - Banner
                    Text("DIGIFIT")
                        .font(.system(.largeTitle, design: .rounded).bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.90, green: 0.20, blue: 0.35), // Lighter red
                                    Color(red: 0.86, green: 0.08, blue: 0.24)  // Darker red
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .opacity(0.9)
                        )
                        .foregroundColor(.white)
                    
                    // MARK: - Dropdown + Buttons Row
                    HStack {
                        // Dropdown menu
                        Menu {
                            ForEach(workoutPages) { page in
                                Button(page.name) {
                                    selectedPage = page
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedPage?.name ?? "Select Page")
                                Image(systemName: "chevron.down")
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                        
                        // Add exercise button
                        Button(action: { isAddingExercise = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(.title3, design: .rounded))
                        }
                        .padding(.trailing, 8)
                        
                        // Reorder button
                        Button(action: { isReordering.toggle() }) {
                            Image(systemName: "arrow.up.arrow.down.circle.fill")
                                .font(.system(.title3, design: .rounded))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // MARK: - Scrollable Cards Section
                    if let selectedPageIndex = workoutPages.firstIndex(where: { $0.id == selectedPage?.id }) {
                        if isReordering {
                            // List view for drag and drop reordering (indices-based ForEach)
                            List {
                                ForEach(workoutPages[selectedPageIndex].exercises.indices, id: \.self) { idx in
                                    ExerciseCard(exercise: $workoutPages[selectedPageIndex].exercises[idx])
                                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                        .listRowBackground(Color.clear)
                                }
                                .onMove { source, destination in
                                    // Move items directly in the same array the List is rendering
                                    workoutPages[selectedPageIndex].exercises.move(fromOffsets: source, toOffset: destination)
                                    
                                    // Update selected page reference to trigger SwiftUI view update
                                    if workoutPages[selectedPageIndex].id == selectedPage?.id {
                                        self.selectedPage = workoutPages[selectedPageIndex]
                                    }
                                }
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                            .environment(\.editMode, .constant(.active))
                        } else {
                            // ScrollView for normal viewing
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(Array(workoutPages[selectedPageIndex].exercises.enumerated()), id: \.element.id) { index, exercise in
                                        ExerciseCard(exercise: Binding(
                                            get: { workoutPages[selectedPageIndex].exercises[index] },
                                            set: { 
                                                workoutPages[selectedPageIndex].exercises[index] = $0
                                                if workoutPages[selectedPageIndex].id == selectedPage?.id {
                                                    self.selectedPage = workoutPages[selectedPageIndex]
                                                }
                                            }
                                        ))
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.top)
                                .padding(.bottom, 80) // space for bottom buttons
                            }
                        }
                    } else {
                        Spacer()
                        Text("Select a page to view exercises")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                
                // MARK: - Fixed Bottom Button
                SUButton(model: ButtonVM {
                    $0.title = "Add Split"
                    $0.color = .primary
                    $0.isFullWidth = true
                    $0.size = .large
                    $0.style = .filled
                }, action: {
                    isAddingSplit = true
                })
                .frame(height: 60)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
                .ignoresSafeArea(edges: .bottom)
            }
            .sheet(isPresented: $isAddingExercise) {
                AddExerciseView { newExercise in
                    if let index = workoutPages.firstIndex(where: { $0.id == selectedPage?.id }) {
                        workoutPages[index].exercises.append(newExercise)
                        self.selectedPage = workoutPages[index]
                    }
                }
            }
            .sheet(isPresented: $isAddingSplit) {
                AddSplitView { newSplitName in
                    workoutPages.append(WorkoutPage(name: newSplitName, exercises: []))
                }
            }
        }
    }
}

// MARK: - Exercise Card
struct ExerciseCard: View {
    @Binding var exercise: UIExercise
    @State private var weightInput: String = ""
    @State private var repsInput: String = ""
    @State private var selectedDate: Date?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise name at the top
            Text(exercise.name)
                .font(.system(.headline, design: .rounded))
                .padding(.bottom, 4)
            
            HStack(alignment: .top, spacing: 16) {
                // Left side: Input fields
                VStack(alignment: .leading, spacing: 8) {
                    // Weight input
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weight (lbs)")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                        TextField("0", text: $weightInput)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Reps input
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reps")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                        TextField("0", text: $repsInput)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Enter button
                    Button(action: {
                        if let weight = Double(weightInput), let reps = Int(repsInput), weight > 0, reps > 0 {
                            let newSession = WorkoutSession(
                                date: Date(),
                                weight: weight,
                                reps: reps
                            )
                            exercise.workoutHistory.append(newSession)
                            weightInput = ""
                            repsInput = ""
                        }
                    }) {
                        Text("Enter")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color(red: 0.86, green: 0.08, blue: 0.24))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(weightInput.isEmpty || repsInput.isEmpty)
                }
                .frame(width: 120)
                
                // Right side: Graph
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Progression")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    if exercise.workoutHistory.isEmpty {
                        VStack {
                            Spacer()
                            Text("No data yet")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                            Spacer()
                        }
                        .frame(height: 150)
                    } else {
                        let sortedHistory = exercise.workoutHistory.sorted(by: { $0.date < $1.date })
                        let calendar = Calendar.current
                        
                        // Create array with normalized dates (start of day) for alignment
                        let chartData = sortedHistory.map { session in
                            (date: calendar.startOfDay(for: session.date), weight: session.weight)
                        }
                        
                        Chart(chartData, id: \.date) { item in
                            LineMark(
                                x: .value("Date", item.date, unit: .day),
                                y: .value("Weight", item.weight)
                            )
                            .foregroundStyle(Color(red: 0.86, green: 0.08, blue: 0.24))
                            .interpolationMethod(.catmullRom)
                            
                            PointMark(
                                x: .value("Date", item.date, unit: .day),
                                y: .value("Weight", item.weight)
                            )
                            .foregroundStyle(Color(red: 0.86, green: 0.08, blue: 0.24))
                            .symbolSize(50)
                        }
                        .chartXSelection(value: $selectedDate)
                        .chartXScale(domain: chartData.first!.date...chartData.last!.date)
                        .chartXAxis {
                            // Pin ticks to each data point date
                            AxisMarks(values: chartData.map { $0.date }) { value in
                                AxisGridLine()
                                AxisTick()
                                if let dateValue = value.as(Date.self) {
                                    // Use fixed-width formatting centered under tick
                                    // All date labels will be roughly the same width with monospaced digits
                                    // This offset centers labels under their tick marks
                                    AxisValueLabel {
                                        Text(DateFormatter.shortMD.string(from: dateValue))
                                            .monospacedDigit()
                                            .font(.system(.caption, design: .rounded).bold())
                                            .frame(width: 35, alignment: .center)
                                    }
                                    .offset(x: -17.5) // Shift left by half label width (35/2) to center under tick
                                }
                            }
                        }
                        .chartYAxisLabel("Weight (lbs)", position: .leading)
                        .frame(height: 150)
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { value in
                                                // Find the nearest data point based on drag position
                                                if !chartData.isEmpty {
                                                    let chartWidth = geometry.size.width
                                                    let normalizedX = max(0, min(1, value.location.x / chartWidth))
                                                    
                                                    // Map the x position to a date in the domain
                                                    let domainStart = chartData.first!.date.timeIntervalSince1970
                                                    let domainEnd = chartData.last!.date.timeIntervalSince1970
                                                    let domainRange = max(1, domainEnd - domainStart) // Avoid division by zero
                                                    
                                                    let selectedTime = domainStart + (normalizedX * domainRange)
                                                    let selectedDateValue = Date(timeIntervalSince1970: selectedTime)
                                                    
                                                    // Find the nearest actual data point date
                                                    let nearest = chartData.min(by: { abs($0.date.timeIntervalSince(selectedDateValue)) < abs($1.date.timeIntervalSince(selectedDateValue)) })
                                                    selectedDate = nearest?.date
                                                }
                                            }
                                            .onEnded { _ in
                                                // Keep selection visible briefly, then clear
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                                    selectedDate = nil
                                                }
                                            }
                                    )
                            }
                        )
                        .overlay(alignment: .topTrailing) {
                            if let selectedDate = selectedDate,
                               let selectedData = chartData.first(where: { calendar.isDate($0.date, inSameDayAs: selectedDate) }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Date: \(DateFormatter.shortMD.string(from: selectedData.date))")
                                        .font(.system(.caption, design: .rounded).bold())
                                    Text("Weight: \(Int(selectedData.weight)) lbs")
                                        .font(.system(.caption, design: .rounded))
                                }
                                .padding(8)
                                .background(Color.black.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .padding(.trailing, 8)
                                .padding(.top, 8)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}

// MARK: - Add Exercise View
struct AddExerciseView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    
    var onAdd: (UIExercise) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise Details") {
                    TextField("Name", text: $name)
                }
            }
            .navigationTitle("Add Exercise")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if !name.isEmpty {
                            onAdd(UIExercise(name: name, sets: nil, reps: nil))
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Add Split View
struct AddSplitView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    
    var onAdd: (String) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Split Details") {
                    TextField("Name", text: $name)
                }
            }
            .navigationTitle("Add Split")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if !name.isEmpty {
                            onAdd(name)
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

private extension DateFormatter {
    static let shortMD: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M/d"
        return f
    }()
}

#Preview {
    LandingPageView()
}
