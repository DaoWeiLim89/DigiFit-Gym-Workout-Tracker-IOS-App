import SwiftUI
import Charts

struct LandingPageView: View {
    @State private var workoutPages: [WorkoutPage] = [
        WorkoutPage(name: "Chest Day", exercises: [
            Exercise(name: "Bench Press", sets: 3, reps: 10),
            Exercise(name: "Dumbbell Fly", sets: 3, reps: 12)
        ]),
        WorkoutPage(name: "Leg Day", exercises: [
            Exercise(name: "Squats", sets: 4, reps: 8)
        ])
    ]
    
    @State private var selectedPage: WorkoutPage?
    @State private var isAddingExercise = false
    @State private var isReordering = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    // MARK: - Banner
                    Text("DIGIFIT")
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.8))
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
                                .font(.title3)
                        }
                        .padding(.trailing, 8)
                        
                        // Reorder button
                        Button(action: { isReordering.toggle() }) {
                            Image(systemName: "arrow.up.arrow.down.circle.fill")
                                .font(.title3)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // MARK: - Scrollable Cards Section
                    if let selectedPageIndex = workoutPages.firstIndex(where: { $0.id == selectedPage?.id }) {
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
                    } else {
                        Spacer()
                        Text("Select a page to view exercises")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                
                // MARK: - Fixed Bottom Buttons
                HStack(spacing: 0) {
                    Button(action: {}) {
                        Text("Split")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {}) {
                        Text("Settings")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.black)
                    }
                }
                .frame(height: 60)
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
        }
    }
}

// MARK: - Exercise Card
struct ExerciseCard: View {
    @Binding var exercise: Exercise
    @State private var weightInput: String = ""
    @State private var repsInput: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise name at the top
            Text(exercise.name)
                .font(.headline)
                .padding(.bottom, 4)
            
            HStack(alignment: .top, spacing: 16) {
                // Left side: Input fields
                VStack(alignment: .leading, spacing: 8) {
                    // Weight input
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weight (lbs)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("0", text: $weightInput)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Reps input
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reps")
                            .font(.caption)
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
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(weightInput.isEmpty || repsInput.isEmpty)
                }
                .frame(width: 120)
                
                // Right side: Graph
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Progression")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .offset(x: 20)
                        .offset(y: -10)
                    
                    if exercise.workoutHistory.isEmpty {
                        VStack {
                            Spacer()
                            Text("No data yet")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .offset(x: 20)
                            Spacer()
                        }
                        .frame(height: 150)
                    } else {
                        Chart {
                            ForEach(exercise.workoutHistory.sorted(by: { $0.date < $1.date })) { session in
                                LineMark(
                                    x: .value("Date", session.date, unit: .day),
                                    y: .value("Weight", session.weight)
                                )
                                .foregroundStyle(.blue)
                                .interpolationMethod(.catmullRom)
                                
                                PointMark(
                                    x: .value("Date", session.date, unit: .day),
                                    y: .value("Weight", session.weight)
                                )
                                .foregroundStyle(.blue)
                                .symbolSize(50)
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: max(1, exercise.workoutHistory.count / 5))) { value in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.month().day())
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisGridLine()
                                AxisValueLabel()
                            }
                        }
                        .chartYAxisLabel("Weight (lbs)", position: .leading)
                        .frame(height: 150)
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
    
    var onAdd: (Exercise) -> Void
    
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
                            onAdd(Exercise(name: name, sets: nil, reps: nil))
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

#Preview {
    LandingPageView()
}
