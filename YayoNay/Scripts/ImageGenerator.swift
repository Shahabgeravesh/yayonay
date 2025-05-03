import SwiftUI
import UIKit

struct ImageGenerator {
    @MainActor
    func generateAllImages() async {
        let generator = TutorialImageGenerator()
        let images = [
            (AnyView(generator.generateWelcomeImage()), "tutorial_welcome"),
            (AnyView(generator.generateHomeImage()), "tutorial_home"),
            (AnyView(generator.generateCategoriesImage()), "tutorial_categories"),
            (AnyView(generator.generateStatsImage()), "tutorial_stats"),
            (AnyView(generator.generateProfileImage()), "tutorial_profile"),
            (AnyView(generator.generateSharingImage()), "tutorial_sharing"),
            (AnyView(generator.generateReadyImage()), "tutorial_ready")
        ]
        
        for (view, name) in images {
            do {
                try await generateImage(view, name: name)
                print("✅ Generated image: \(name)")
            } catch {
                print("❌ Failed to generate image \(name): \(error)")
            }
        }
    }
    
    @MainActor
    func generateImage(_ view: AnyView, name: String) async throws {
        let renderer = ImageRenderer(content: view
            .frame(width: 300, height: 600)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 10)
        )
        
        // Give the renderer time to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms delay
        
        guard let uiImage = renderer.uiImage else {
            throw NSError(domain: "ImageGeneration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate image"])
        }
        
        let fileManager = FileManager.default
        let documentsPath = fileManager.currentDirectoryPath
        let imagePath = "\(documentsPath)/YayoNay/Assets.xcassets/\(name).imageset/\(name).png"
        
        guard let pngData = uiImage.pngData() else {
            throw NSError(domain: "ImageGeneration", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to PNG"])
        }
        
        try pngData.write(to: URL(fileURLWithPath: imagePath))
        
        // Create Contents.json file
        let contentsJson = """
        {
          "images" : [
            {
              "filename" : "\(name).png",
              "idiom" : "universal",
              "scale" : "1x"
            }
          ],
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }
        """
        
        let contentsPath = "\(documentsPath)/YayoNay/Assets.xcassets/\(name).imageset/Contents.json"
        try contentsJson.write(to: URL(fileURLWithPath: contentsPath), atomically: true, encoding: .utf8)
    }
} 