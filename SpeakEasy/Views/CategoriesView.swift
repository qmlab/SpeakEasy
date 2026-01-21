//
//  CategoriesView.swift
//  SpeakEasy
//

import SwiftUI

struct CategoriesView: View {
    @EnvironmentObject var progressManager: ProgressManager
    @State private var categoryObjectCounts: [String: Int] = [:]
    @State private var categoryObjects: [String: [ObjectListResponse]] = [:]
    @State private var isLoading = true
    
    let columns = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                if isLoading {
                    ProgressView("Loading categories...")
                        .padding(.top, 50)
                } else {
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(ObjectCategory.allCases, id: \.self) { category in
                            NavigationLink(destination: FlashcardListView(category: category)) {
                                APICategoryCard(
                                    category: category,
                                    objectCount: categoryObjectCounts[category.rawValue] ?? 0,
                                    objects: categoryObjects[category.rawValue] ?? []
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Categories")
            .task {
                await loadCategoryData()
            }
        }
    }
    
    private func loadCategoryData() async {
        do {
            let allObjects = try await APIService.shared.getObjects()
            var counts: [String: Int] = [:]
            var objects: [String: [ObjectListResponse]] = [:]
            
            for category in ObjectCategory.allCases {
                let categoryObjs = allObjects.filter { $0.category == category.rawValue }
                counts[category.rawValue] = categoryObjs.count
                objects[category.rawValue] = categoryObjs
            }
            
            await MainActor.run {
                self.categoryObjectCounts = counts
                self.categoryObjects = objects
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

struct CategoryCard: View {
    let category: ObjectCategory
    @EnvironmentObject var progressManager: ProgressManager
    
    var body: some View {
        VStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.2))
                    .frame(width: 70, height: 70)
                
                Image(systemName: category.icon)
                    .font(.system(size: 35))
                    .foregroundColor(category.color)
            }
            
            Text(category.rawValue)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            let objectCount = ObjectData.objects(for: category).count
            Text("\(objectCount) objects")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
            
            ProgressBar(progress: progressManager.progressForCategory(category), color: category.color)
                .frame(height: 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(color: category.color.opacity(0.3), radius: 10)
        )
    }
}

struct APICategoryCard: View {
    let category: ObjectCategory
    let objectCount: Int
    let objects: [ObjectListResponse]
    @EnvironmentObject var progressManager: ProgressManager
    
    var body: some View {
        VStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.2))
                    .frame(width: 70, height: 70)
                
                Image(systemName: category.icon)
                    .font(.system(size: 35))
                    .foregroundColor(category.color)
            }
            
            Text(category.rawValue)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("\(objectCount) objects")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
            
            let objectIds = objects.map { $0.id }
            ProgressBar(progress: progressManager.progressForCategoryById(category, objectIds: objectIds), color: category.color)
                .frame(height: 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(color: category.color.opacity(0.3), radius: 10)
        )
    }
}

struct ProgressBar: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(color)
                    .frame(width: geometry.size.width * progress)
                    .animation(.spring(), value: progress)
            }
        }
    }
}

struct CategoriesView_Previews: PreviewProvider {
    static var previews: some View {
        CategoriesView()
            .environmentObject(ProgressManager())
    }
}
