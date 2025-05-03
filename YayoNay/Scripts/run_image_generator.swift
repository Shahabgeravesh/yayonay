import SwiftUI

struct ImageGeneratorRunner: View {
    let generator = ImageGenerator()
    @State private var isGenerating = false
    
    var body: some View {
        VStack {
            Button("Generate Images") {
                isGenerating = true
                Task {
                    await generator.generateAllImages()
                    isGenerating = false
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isGenerating)
            
            if isGenerating {
                ProgressView()
                    .padding()
            }
        }
        .padding()
    }
}

#Preview {
    ImageGeneratorRunner()
} 