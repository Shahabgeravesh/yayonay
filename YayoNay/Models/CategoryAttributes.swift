struct CategoryAttribute {
    let name: String
    var yayText: String = "Yay!"
    var nayText: String = "Nay!"
}

extension Category {
    var attributes: [CategoryAttribute] {
        switch name.lowercased() {
        case "food":
            return [
                CategoryAttribute(name: "Taste"),
                CategoryAttribute(name: "Presentation"),
                CategoryAttribute(name: "Value")
            ]
        case "fruit":
            return [
                CategoryAttribute(name: "Taste"),
                CategoryAttribute(name: "Texture"),
                CategoryAttribute(name: "Freshness")
            ]
        case "drink":
            return [
                CategoryAttribute(name: "Taste"),
                CategoryAttribute(name: "Aroma"),
                CategoryAttribute(name: "Value")
            ]
        case "art":
            return [
                CategoryAttribute(name: "Creativity", yayText: "Creative!", nayText: "Basic"),
                CategoryAttribute(name: "Technique", yayText: "Skilled!", nayText: "Amateur"),
                CategoryAttribute(name: "Impact", yayText: "Powerful!", nayText: "Weak")
            ]
        case "travel":
            return [
                CategoryAttribute(name: "Beauty"),
                CategoryAttribute(name: "Culture"),
                CategoryAttribute(name: "Activities")
            ]
        case "sports":
            return [
                CategoryAttribute(name: "Excitement"),
                CategoryAttribute(name: "Skill Level"),
                CategoryAttribute(name: "Accessibility")
            ]
        default:
            return [
                CategoryAttribute(name: "Overall"),
                CategoryAttribute(name: "Experience")
            ]
        }
    }
} 