import SwiftUI

struct HealthCitationsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Health Information Sources")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("All health recommendations and calculations in IBDPal are based on peer-reviewed research and official medical guidelines.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 10)
                    
                    // Primary Sources Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Primary Research Sources")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        CitationCard(
                            title: "American Gastroenterological Association (AGA)",
                            subtitle: "Clinical Practice Update: Diet and Nutritional Therapies in Patients with IBD",
                            year: "2024",
                            url: "https://www.gastrojournal.org/article/S0016-5085(24)00001-2/fulltext",
                            description: "Official clinical guidelines for IBD nutrition therapy"
                        )
                        
                        CitationCard(
                            title: "National Institutes of Health (NIH)",
                            subtitle: "Dietary Reference Intakes (DRI) for Healthcare Professionals",
                            year: "2023",
                            url: "https://ods.od.nih.gov/HealthInformation/nutrientrecommendations.aspx",
                            description: "Official nutrition standards used by healthcare providers"
                        )
                        
                        CitationCard(
                            title: "Crohn's & Colitis Foundation",
                            subtitle: "Diet and Nutrition in IBD: A Guide for Patients",
                            year: "2024",
                            url: "https://www.crohnscolitisfoundation.org/diet-and-nutrition",
                            description: "Patient-focused nutrition guidance for IBD"
                        )
                        
                        CitationCard(
                            title: "European Society for Clinical Nutrition",
                            subtitle: "ESPEN Guidelines on Clinical Nutrition in IBD",
                            year: "2023",
                            url: "https://www.espen.org/guidelines-home/espen-guidelines",
                            description: "European clinical nutrition standards for IBD"
                        )
                    }
                    
                    // Nutrition Calculations Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Nutrition Calculation Sources")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        CitationCard(
                            title: "Institute of Medicine",
                            subtitle: "Dietary Reference Intakes: Macronutrients",
                            year: "2005",
                            url: "https://www.nationalacademies.org/our-work/dietary-reference-intakes-dris",
                            description: "Calorie, protein, and macronutrient requirements"
                        )
                        
                        CitationCard(
                            title: "NIH Office of Dietary Supplements",
                            subtitle: "Vitamin and Mineral Fact Sheets",
                            year: "2024",
                            url: "https://ods.od.nih.gov/factsheets/list-all/",
                            description: "Micronutrient requirements and deficiency guidelines"
                        )
                        
                        CitationCard(
                            title: "Monash University",
                            subtitle: "FODMAP Research and Food Database",
                            year: "2024",
                            url: "https://www.monashfodmap.com/",
                            description: "Low-FODMAP diet recommendations for IBD"
                        )
                    }
                    
                    // IBD-Specific Research Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("IBD-Specific Research")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        CitationCard(
                            title: "World Journal of Gastroenterology",
                            subtitle: "Nutritional Therapy in Inflammatory Bowel Disease",
                            year: "2023",
                            url: "https://www.wjgnet.com/1007-9327/",
                            description: "Latest research on IBD nutrition interventions"
                        )
                        
                        CitationCard(
                            title: "Clinical Gastroenterology and Hepatology",
                            subtitle: "Dietary Patterns and IBD Risk",
                            year: "2024",
                            url: "https://www.cghjournal.org/",
                            description: "Research on dietary patterns and IBD management"
                        )
                        
                        CitationCard(
                            title: "Gastroenterology",
                            subtitle: "Microbiome and Nutrition in IBD",
                            year: "2024",
                            url: "https://www.gastrojournal.org/",
                            description: "Gut microbiome research and probiotic recommendations"
                        )
                    }
                    
                    // Medical Disclaimer
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Important Medical Disclaimer")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        
                        Text("The health information provided in this app is for educational purposes only and should not replace professional medical advice. Always consult with your healthcare provider before making changes to your diet or treatment plan.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Text("If you experience severe symptoms or have concerns about your health, contact your doctor immediately.")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Health Sources")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct CitationCard: View {
    let title: String
    let subtitle: String
    let year: String
    let url: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(year)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(6)
            }
            
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
            
            Button(action: {
                if let url = URL(string: url) {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "link")
                    Text("View Source")
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    HealthCitationsView()
}



