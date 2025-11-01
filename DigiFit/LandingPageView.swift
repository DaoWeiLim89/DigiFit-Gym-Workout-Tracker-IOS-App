import SwiftUI

struct LandingPageView: View {
    // dropdown selection
    @State private var selectedOption = "Select Option"
    let options = ["Upper Body", "Lower Body", "Full Body"]

    var body: some View {
        VStack {
            // MARK: Banner
            Text("DIGIFIT")
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.top)

            Spacer().frame(height: 20)

            // MARK: Dropdown menu
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) {
                        selectedOption = option
                    }
                }
            } label: {
                HStack {
                    Text(selectedOption)
                        .foregroundColor(.primary)
                    Image(systemName: "chevron.down")
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }

            Spacer().frame(height: 30)

            // MARK: Placeholder for workout cards
            VStack {
                Text("Workout cards will go here")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: 200)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            .padding(.horizontal)

            Spacer()

            // MARK: Bottom buttons
            HStack {
                Button(action: {
                    // handle Split action
                }) {
                    Text("Split")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(action: {
                    // handle Settings action
                }) {
                    Text("Settings")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

#Preview {
    LandingPageView()
}
