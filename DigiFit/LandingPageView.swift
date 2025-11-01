import SwiftUI

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
        VStack {
            // MARK: - Banner
            Text("DIGITFIT")
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.top)
            
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
            
            // MARK: - Cards Section
            if let selectedPage = selectedPage {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(selectedPage.exercises) { exercise in
                            ExerciseCard(exercise: exercise)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
            } else {
                Spacer()
                Text("Select a page to view exercises")
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            Spacer()
            
            // MARK: - Bottom Buttons
            HStack {
                Button("Split") {}
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                
                Button("Settings") {}
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            .padding(.bottom)
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

// MARK: - Exercise Card
struct ExerciseCard: View {
    var exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name)
                .font(.headline)
            Text("\(exercise.sets)x\(exercise.reps)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
    @State private var sets = ""
    @State private var reps = ""
    
    var onAdd: (Exercise) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise Details") {
                    TextField("Name", text: $name)
                    TextField("Sets", text: $sets)
                        .keyboardType(.numberPad)
                    TextField("Reps", text: $reps)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add Exercise")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let s = Int(sets), let r = Int(reps), !name.isEmpty {
                            onAdd(Exercise(name: name, sets: s, reps: r))
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