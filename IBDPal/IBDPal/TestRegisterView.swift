import SwiftUI

struct TestRegisterView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Test Registration Form")
                    .font(.largeTitle)
                    .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.8))
                
                Text("This is a test registration form")
                    .font(.subheadline)
                    .foregroundColor(.ibdSecondaryText)
                
                TextField("Test Email", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.8))
                .padding()
            }
            .padding()
            .navigationTitle("Test Register")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.8))
                }
            }
        }
    }
} 