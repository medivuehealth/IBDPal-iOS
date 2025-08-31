import SwiftUI

struct BlogView: View {
    let userData: UserData?
    
    @State private var selectedTab: BlogTab = .read
    @State private var showingCreatePost = false
    @State private var selectedDiseaseType: IBDDiseaseType = .crohns
    @State private var searchText = ""
    @State private var selectedFilter: BlogFilter = .all
    @State private var isLoading = false
    @State private var stories: [BlogStory] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Tab Selector
            VStack(spacing: 8) {
                // Tab Selector
                HStack(spacing: 0) {
                    ForEach(BlogTab.allCases, id: \.self) { tab in
                        Button(action: {
                            selectedTab = tab
                            if tab == .write {
                                showingCreatePost = true
                            }
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: tab.icon)
                                    .font(.title2)
                                    .foregroundColor(selectedTab == tab ? .ibdPrimary : .ibdSecondaryText)
                                
                                Text(tab.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(selectedTab == tab ? .ibdPrimary : .ibdSecondaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                Rectangle()
                                    .fill(selectedTab == tab ? Color.ibdPrimary.opacity(0.1) : Color.clear)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .background(Color.ibdSurfaceBackground)
                .cornerRadius(12)
                
                // Disease Type Filter (only for Read tab)
                if selectedTab == .read {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(IBDDiseaseType.allCases, id: \.self) { diseaseType in
                                DiseaseTypeChip(
                                    diseaseType: diseaseType,
                                    isSelected: selectedDiseaseType == diseaseType
                                ) {
                                    selectedDiseaseType = diseaseType
                                    loadStories()
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 4)
            .background(Color.ibdBackground)
            
            // Content Area
            if selectedTab == .read {
                ReadStoriesView(
                    userData: userData,
                    selectedDiseaseType: selectedDiseaseType,
                    searchText: $searchText,
                    selectedFilter: $selectedFilter,
                    isLoading: $isLoading,
                    stories: $stories
                )
            }
        }
        .navigationTitle("IBD Stories")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingCreatePost) {
            NavigationView {
                CreateStoryView(userData: userData, onStoryCreated: {
                    // Switch back to Read tab and refresh stories
                    selectedTab = .read
                    loadStories()
                })
            }
        }
        .onAppear {
            loadStories()
        }
    }
    
    private func loadStories() {
        isLoading = true
        
        guard let userData = userData else {
            // Fallback to sample data if no user data
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                stories = getSampleStories()
                isLoading = false
            }
            return
        }
        
        let apiBaseURL = AppConfig.apiBaseURL
        let urlString = "\(apiBaseURL)/blogs/stories?diseaseType=\(selectedDiseaseType.rawValue)&filter=\(selectedFilter.rawValue)&userId=\(userData.email)"
        
        print("🔍 BlogView: Loading stories from URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("🔍 BlogView: Invalid URL")
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(userData.token)", forHTTPHeaderField: "Authorization")
        
        print("🔍 BlogView: Starting network request for stories")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                print("🔍 BlogView: Network response received for stories")
                isLoading = false
                
                if let error = error {
                    print("🔍 BlogView: Error loading stories: \(error)")
                    // Fallback to sample data on error
                    stories = getSampleStories()
                    return
                }
                
                if let data = data {
                    print("🔍 BlogView: Received data length: \(data.count)")
                    do {
                        if let response = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            print("🔍 BlogView: Parsed response: \(response)")
                            
                            if let success = response["success"] as? Bool, success,
                               let dataDict = response["data"] as? [String: Any],
                               let storiesData = dataDict["stories"] as? [[String: Any]] {
                                
                                print("🔍 BlogView: Found \(storiesData.count) stories")
                                
                                // Parse stories from API response
                                stories = storiesData.compactMap { storyData in
                                    guard let id = storyData["id"] as? Int,
                                          let username = storyData["username"] as? String,
                                          let user_name = storyData["user_name"] as? String,
                                          let title = storyData["title"] as? String,
                                          let content = storyData["content"] as? String,
                                          let diseaseTypeString = storyData["disease_type"] as? String else {
                                        print("🔍 BlogView: Failed to parse story data: \(storyData)")
                                        return nil
                                    }
                                    
                                    let diseaseType: IBDDiseaseType
                                    switch diseaseTypeString {
                                    case "crohns": diseaseType = .crohns
                                    case "ulcerative_colitis": diseaseType = .ulcerativeColitis
                                    case "indeterminate": diseaseType = .indeterminate
                                    default: diseaseType = .crohns
                                    }
                                    
                                    let createdAt: Date
                                    if let createdAtString = storyData["created_at"] as? String {
                                        let dateFormatter = ISO8601DateFormatter()
                                        createdAt = dateFormatter.date(from: createdAtString) ?? Date()
                                    } else {
                                        createdAt = Date()
                                    }
                                    
                                    let likes = storyData["likes"] as? Int ?? 0
                                    let comments = storyData["comments_count"] as? Int ?? 0
                                    let isLiked = storyData["is_liked"] as? Bool ?? false
                                    let tags = storyData["tags"] as? [String] ?? []
                                    
                                    return BlogStory(
                                        id: String(id),
                                        userId: username,
                                        userName: user_name,
                                        userAge: 0, // Not displayed
                                        diseaseType: diseaseType,
                                        title: title,
                                        content: content,
                                        tags: tags,
                                        likes: likes,
                                        comments: comments,
                                        createdAt: createdAt,
                                        isLiked: isLiked
                                    )
                                }
                                
                                print("🔍 BlogView: Successfully parsed \(stories.count) stories")
                            } else {
                                print("🔍 BlogView: Response structure not as expected")
                                // Fallback to sample data if parsing fails
                                stories = getSampleStories()
                            }
                        } else {
                            print("🔍 BlogView: Could not parse JSON response")
                            // Fallback to sample data if parsing fails
                            stories = getSampleStories()
                        }
                    } catch {
                        print("🔍 BlogView: Error parsing response: \(error)")
                        // Fallback to sample data if parsing fails
                        stories = getSampleStories()
                    }
                } else {
                    print("🔍 BlogView: No data received")
                    // Fallback to sample data if parsing fails
                    stories = getSampleStories()
                }
            }
        }.resume()
    }
    
    private func getSampleStories() -> [BlogStory] {
        return [
            BlogStory(
                id: "1",
                userId: "user1",
                userName: "Sarah M.",
                userAge: 0,
                diseaseType: .crohns,
                title: "My Journey to Remission",
                content: "After being diagnosed with Crohn's disease at 18, I struggled for years to find the right treatment. Through diet changes, medication, and support from the IBD community, I finally achieved remission last year. Here's my story...",
                tags: ["remission", "diet", "support"],
                likes: 45,
                comments: 12,
                createdAt: Date().addingTimeInterval(-86400 * 7),
                isLiked: false
            ),
            BlogStory(
                id: "2",
                userId: "user2",
                userName: "Mike T.",
                userAge: 0,
                diseaseType: .ulcerativeColitis,
                title: "Managing UC as a Working Parent",
                content: "Balancing ulcerative colitis with a demanding job and family responsibilities has been challenging. I've learned to prioritize self-care and communicate openly with my employer about my condition...",
                tags: ["work", "family", "self-care"],
                likes: 32,
                comments: 8,
                createdAt: Date().addingTimeInterval(-86400 * 3),
                isLiked: true
            ),
            BlogStory(
                id: "3",
                userId: "user3",
                userName: "Emma L.",
                userAge: 0,
                diseaseType: .crohns,
                title: "College Life with Crohn's",
                content: "Starting college with Crohn's disease was intimidating, but I've found amazing support from my roommates and the campus health center. Here are my tips for navigating university life with IBD...",
                tags: ["college", "young-adults", "support"],
                likes: 28,
                comments: 15,
                createdAt: Date().addingTimeInterval(-86400 * 1),
                isLiked: false
            )
        ]
    }
}

// MARK: - Read Stories View

struct ReadStoriesView: View {
    let userData: UserData?
    let selectedDiseaseType: IBDDiseaseType
    @Binding var searchText: String
    @Binding var selectedFilter: BlogFilter
    @Binding var isLoading: Bool
    @Binding var stories: [BlogStory]
    
    var filteredStories: [BlogStory] {
        stories.filter { story in
            let diseaseMatch = selectedDiseaseType == .all || story.diseaseType == selectedDiseaseType
            let searchMatch = searchText.isEmpty || 
                story.title.localizedCaseInsensitiveContains(searchText) ||
                story.content.localizedCaseInsensitiveContains(searchText) ||
                story.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            
            let filterMatch: Bool
            switch selectedFilter {
            case .all:
                filterMatch = true
            case .recent:
                filterMatch = Calendar.current.isDate(story.createdAt, inSameDayAs: Date()) ||
                    Calendar.current.isDate(story.createdAt, inSameDayAs: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
            case .popular:
                filterMatch = story.likes > 20
            case .myStories:
                filterMatch = story.userId == userData?.id
            }
            
            return diseaseMatch && searchMatch && filterMatch
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and Filter Bar
            VStack(spacing: 12) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search stories...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(BlogFilter.allCases, id: \.self) { filter in
                            FilterChip(
                                filter: filter,
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .background(Color.ibdBackground)
            
            // Stories List
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView("Loading stories...")
                        .scaleEffect(1.2)
                    Text("Finding inspiring stories from the IBD community")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.ibdBackground)
            } else if filteredStories.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("No stories found")
                        .font(.headline)
                        .foregroundColor(.ibdSecondaryText)
                    
                    Text("Try adjusting your search or filters")
                        .font(.subheadline)
                        .foregroundColor(.ibdSecondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.ibdBackground)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredStories) { story in
                            StoryCard(
                                story: story, 
                                userData: userData, 
                                onLikeToggled: { storyId, isLiked in
                                    if let index = stories.firstIndex(where: { $0.id == storyId }) {
                                        stories[index].isLiked = isLiked
                                        if isLiked {
                                            stories[index].likes += 1
                                        } else {
                                            stories[index].likes = max(0, stories[index].likes - 1)
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                }
                .background(Color.ibdBackground)
            }
        }
    }
}

// MARK: - Story Card

struct StoryCard: View {
    let story: BlogStory
    let userData: UserData?
    let onLikeToggled: (String, Bool) -> Void
    
    @State private var showingFullStory = false
    @State private var showingComments = false
    @State private var isLiked: Bool
    
    init(story: BlogStory, userData: UserData?, onLikeToggled: @escaping (String, Bool) -> Void) {
        self.story = story
        self.userData = userData
        self.onLikeToggled = onLikeToggled
        self._isLiked = State(initialValue: story.isLiked)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(story.userName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    HStack(spacing: 8) {
                        Text(story.diseaseType.displayName)
                            .font(.caption)
                            .foregroundColor(.ibdPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.ibdPrimary.opacity(0.1))
                            .cornerRadius(4)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.ibdSecondaryText)
                        
                        Text(timeAgoString(from: story.createdAt))
                            .font(.caption)
                            .foregroundColor(.ibdSecondaryText)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    // TODO: Share story
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                }
            }
            
            // Title
            Text(story.title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.ibdPrimaryText)
                .lineLimit(2)
            
            // Content Preview
            Text(story.content)
                .font(.subheadline)
                .foregroundColor(.ibdSecondaryText)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            // Tags
            if !story.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(story.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .foregroundColor(.ibdPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.ibdPrimary.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
            }
            
            // Actions
            HStack {
                Button(action: {
                    toggleLike()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .ibdSecondaryText)
                        Text("\(story.likes + (isLiked ? 1 : 0))")
                            .font(.caption)
                            .foregroundColor(.ibdSecondaryText)
                    }
                }
                
                Button(action: {
                    showingComments = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                            .foregroundColor(.ibdSecondaryText)
                        Text("\(story.comments)")
                            .font(.caption)
                            .foregroundColor(.ibdSecondaryText)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    // TODO: Share story
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                }
            }
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
        .sheet(isPresented: $showingFullStory) {
            StoryDetailView(story: story, userData: userData)
        }
        .sheet(isPresented: $showingComments) {
            CommentsView(storyId: story.id, userData: userData)
        }
    }
    
    private func toggleLike() {
        guard let userData = userData else { return }
        
        let apiBaseURL = AppConfig.apiBaseURL
        let urlString = "\(apiBaseURL)/blogs/stories/\(story.id)/like"
        
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(userData.token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("🔍 StoryCard: Error toggling like: \(error)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    isLiked.toggle()
                    onLikeToggled(story.id, isLiked)
                }
            }
        }.resume()
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Create Story View

struct CreateStoryView: View {
    let userData: UserData?
    let onStoryCreated: (() -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var content = ""
    @State private var selectedDiseaseType: IBDDiseaseType = .crohns
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var isLoading = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    private let apiBaseURL = AppConfig.apiBaseURL
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Share Your Story")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text("Help others by sharing your IBD journey and experiences")
                        .font(.title3)
                        .foregroundColor(.ibdSecondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top)
                .onAppear {
                    print("🔍 CreateStoryView: Header appeared")
                }
                
                // Disease Type Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your IBD Type")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Picker("Disease Type", selection: $selectedDiseaseType) {
                        ForEach(IBDDiseaseType.allCases, id: \.self) { diseaseType in
                            if diseaseType != .all {
                                Text(diseaseType.displayName).tag(diseaseType)
                            }
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedDiseaseType) { _, newValue in
                        print("🔍 CreateStoryView: Disease type changed to \(newValue.rawValue)")
                    }
                }
                .onAppear {
                    print("🔍 CreateStoryView: Disease type picker appeared")
                }
                
                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Story Title")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    TextField("Enter a compelling title for your story...", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: title) { _, newValue in
                            print("🔍 CreateStoryView: Title changed to '\(newValue)'")
                        }
                        .onTapGesture {
                            print("🔍 CreateStoryView: Title field tapped")
                        }
                }
                .onAppear {
                    print("🔍 CreateStoryView: Title field appeared")
                }
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Story")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text("Share your experiences, challenges, victories, and insights that could help others.")
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                    
                    TextField("Write your story here...", text: $content, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(8...15)
                        .onChange(of: content) { _, newValue in
                            print("🔍 CreateStoryView: Content changed, length: \(newValue.count)")
                        }
                        .onTapGesture {
                            print("🔍 CreateStoryView: Content field tapped")
                        }
                }
                .onAppear {
                    print("🔍 CreateStoryView: Content field appeared")
                }
                
                // Tags
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tags")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text("Add relevant tags to help others find your story")
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                    
                    // Add new tag
                    HStack {
                        TextField("Add a tag...", text: $newTag)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: newTag) { _, newValue in
                                print("🔍 CreateStoryView: New tag changed to '\(newValue)'")
                            }
                            .onTapGesture {
                                print("🔍 CreateStoryView: New tag field tapped")
                            }
                        
                        Button("Add") {
                            print("🔍 CreateStoryView: Add tag button tapped")
                            addTag()
                        }
                        .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .foregroundColor(.ibdPrimary)
                    }
                    
                    // Display existing tags
                    if !tags.isEmpty {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                HStack {
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.ibdPrimary.opacity(0.1))
                                        .foregroundColor(.ibdPrimary)
                                        .cornerRadius(8)
                                    
                                    Button(action: {
                                        print("🔍 CreateStoryView: Remove tag button tapped for '\(tag)'")
                                        removeTag(tag)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                }
                .onAppear {
                    print("🔍 CreateStoryView: Tags section appeared")
                }
                
                // Submit Button
                Button(action: {
                    print("🔍 CreateStoryView: Submit button tapped")
                    submitStory()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                        
                        Text(isLoading ? "Publishing..." : "Publish Story")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ibdPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isLoading || title.isEmpty || content.isEmpty)
                .padding(.top)
                
                Spacer(minLength: 50)
            }
            .padding()
        }
        .background(Color.ibdBackground)
        .navigationTitle("Write Story")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    print("🔍 CreateStoryView: Cancel button tapped")
                    dismiss()
                }
            }
        }
        .alert("Story Published!", isPresented: $showingSuccessAlert) {
            Button("OK") {
                print("🔍 CreateStoryView: Success alert OK tapped")
                dismiss()
                onStoryCreated?()
            }
        } message: {
            Text("Your story has been published successfully! You'll now see it in the stories list.")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { 
                print("🔍 CreateStoryView: Error alert OK tapped")
            }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            print("🔍 CreateStoryView: View appeared")
        }
        .onDisappear {
            print("🔍 CreateStoryView: View disappeared")
        }
    }
    
    private func addTag() {
        print("🔍 CreateStoryView: addTag() called")
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            newTag = ""
            print("🔍 CreateStoryView: Tag '\(trimmedTag)' added successfully")
        } else {
            print("🔍 CreateStoryView: Tag not added - empty or duplicate")
        }
    }
    
    private func removeTag(_ tag: String) {
        print("🔍 CreateStoryView: removeTag() called for '\(tag)'")
        tags.removeAll { $0 == tag }
        print("🔍 CreateStoryView: Tag '\(tag)' removed successfully")
    }
    
    private func submitStory() {
        print("🔍 CreateStoryView: submitStory() called")
        guard let userData = userData else {
            print("🔍 CreateStoryView: Error - User data not available")
            errorMessage = "User data not available"
            showingErrorAlert = true
            return
        }
        
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("🔍 CreateStoryView: Error - Title is empty")
            errorMessage = "Please enter a title for your story"
            showingErrorAlert = true
            return
        }
        
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("🔍 CreateStoryView: Error - Content is empty")
            errorMessage = "Please write your story content"
            showingErrorAlert = true
            return
        }
        
        print("🔍 CreateStoryView: Starting story submission")
        isLoading = true
        
        let storyData: [String: Any] = [
            "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
            "content": content.trimmingCharacters(in: .whitespacesAndNewlines),
            "disease_type": selectedDiseaseType.rawValue,
            "tags": tags
        ]
        
        print("🔍 CreateStoryView: Story data prepared: \(storyData)")
        
        guard let url = URL(string: "\(apiBaseURL)/blogs") else {
            print("🔍 CreateStoryView: Error - Invalid URL")
            errorMessage = "Invalid URL"
            showingErrorAlert = true
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(userData.token)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: storyData)
            print("🔍 CreateStoryView: Request body prepared successfully")
        } catch {
            print("🔍 CreateStoryView: Error preparing request body: \(error)")
            errorMessage = "Failed to prepare request data"
            showingErrorAlert = true
            isLoading = false
            return
        }
        
        print("🔍 CreateStoryView: Starting network request")
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                print("🔍 CreateStoryView: Network response received")
                isLoading = false
                
                if let error = error {
                    print("🔍 CreateStoryView: Network error: \(error)")
                    errorMessage = "Network error: \(error.localizedDescription)"
                    showingErrorAlert = true
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("🔍 CreateStoryView: Invalid response from server")
                    errorMessage = "Invalid response from server"
                    showingErrorAlert = true
                    return
                }
                
                print("🔍 CreateStoryView: HTTP status code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 201 {
                    print("🔍 CreateStoryView: Story created successfully")
                    showingSuccessAlert = true
                } else {
                    print("🔍 CreateStoryView: Server error with status \(httpResponse.statusCode)")
                    // Try to parse error message from response
                    if let data = data {
                        do {
                            if let errorResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                                if let message = errorResponse["message"] as? String {
                                    errorMessage = message
                                    print("🔍 CreateStoryView: Server error message: \(message)")
                                } else if let error = errorResponse["error"] as? String {
                                    errorMessage = error
                                    print("🔍 CreateStoryView: Server error: \(error)")
                                } else {
                                    errorMessage = "Server error: \(httpResponse.statusCode)"
                                    print("🔍 CreateStoryView: Generic server error")
                                }
                            } else {
                                errorMessage = "Server error: \(httpResponse.statusCode)"
                                print("🔍 CreateStoryView: Could not parse error response")
                            }
                        } catch {
                            errorMessage = "Server error: \(httpResponse.statusCode)"
                            print("🔍 CreateStoryView: Error parsing response: \(error)")
                        }
                    } else {
                        errorMessage = "Server error: \(httpResponse.statusCode)"
                        print("🔍 CreateStoryView: No response data")
                    }
                    showingErrorAlert = true
                }
            }
        }.resume()
    }
}

// MARK: - Story Detail View

struct StoryDetailView: View {
    let story: BlogStory
    let userData: UserData?
    
    @Environment(\.dismiss) private var dismiss
    @State private var isLiked: Bool
    @State private var showingComments = false
    
    init(story: BlogStory, userData: UserData?) {
        self.story = story
        self.userData = userData
        self._isLiked = State(initialValue: story.isLiked)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(story.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.ibdPrimaryText)
                        
                        HStack {
                            Text("By \(story.userName)")
                                .font(.subheadline)
                                .foregroundColor(.ibdPrimary)
                            
                            Text("•")
                                .foregroundColor(.ibdSecondaryText)
                            
                            Text(story.diseaseType.displayName)
                                .font(.subheadline)
                                .foregroundColor(.ibdPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.ibdPrimary.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        Text(timeAgoString(from: story.createdAt))
                            .font(.caption)
                            .foregroundColor(.ibdSecondaryText)
                    }
                    
                    // Content
                    Text(story.content)
                        .font(.body)
                        .foregroundColor(.ibdPrimaryText)
                        .lineSpacing(4)
                    
                    // Tags
                    if !story.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.headline)
                                .foregroundColor(.ibdPrimaryText)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                                ForEach(story.tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.caption)
                                        .foregroundColor(.ibdPrimary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.ibdPrimary.opacity(0.1))
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                    
                    // Actions
                    HStack {
                        Button(action: {
                            toggleLike()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .foregroundColor(isLiked ? .red : .ibdSecondaryText)
                                Text("\(story.likes + (isLiked ? 1 : 0))")
                                    .foregroundColor(.ibdSecondaryText)
                            }
                        }
                        
                        Button(action: {
                            showingComments = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "bubble.left")
                                    .foregroundColor(.ibdSecondaryText)
                                Text("\(story.comments)")
                                    .foregroundColor(.ibdSecondaryText)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            // TODO: Share story
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.ibdSecondaryText)
                                Text("Share")
                                    .foregroundColor(.ibdSecondaryText)
                            }
                        }
                    }
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingComments) {
                CommentsView(storyId: story.id, userData: userData)
            }
        }
    }
    
    private func toggleLike() {
        guard let userData = userData else { return }
        
        let apiBaseURL = AppConfig.apiBaseURL
        let urlString = "\(apiBaseURL)/blogs/stories/\(story.id)/like"
        
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(userData.token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("🔍 StoryDetailView: Error toggling like: \(error)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    isLiked.toggle()
                }
            }
        }.resume()
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Comments View

struct CommentsView: View {
    let storyId: String
    let userData: UserData?
    
    @Environment(\.dismiss) private var dismiss
    @State private var comments: [BlogComment] = []
    @State private var newComment = ""
    @State private var isLoading = false
    @State private var isSubmitting = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    private let apiBaseURL = AppConfig.apiBaseURL
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading comments...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack {
                        // Comments List
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(comments) { comment in
                                    CommentCard(comment: comment)
                                }
                            }
                            .padding()
                        }
                        
                        // Add Comment Section
                        VStack(spacing: 12) {
                            Divider()
                            
                            HStack {
                                TextField("Add a comment...", text: $newComment, axis: .vertical)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .lineLimit(3...6)
                                
                                Button(action: submitComment) {
                                    if isSubmitting {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "paperplane.fill")
                                            .foregroundColor(.ibdPrimary)
                                    }
                                }
                                .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                            }
                            .padding(.horizontal)
                        }
                        .background(Color.ibdSurfaceBackground)
                    }
                }
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadComments()
            }
        }
    }
    
    private func loadComments() {
        isLoading = true
        
        let urlString = "\(apiBaseURL)/blogs/stories/\(storyId)/comments"
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    print("🔍 CommentsView: Error loading comments: \(error)")
                    return
                }
                
                if let data = data,
                   let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = response["success"] as? Bool,
                   success,
                   let dataDict = response["data"] as? [String: Any],
                   let commentsData = dataDict["comments"] as? [[String: Any]] {
                    
                    comments = commentsData.compactMap { commentData in
                        guard let id = commentData["id"] as? Int,
                              let username = commentData["username"] as? String,
                              let content = commentData["content"] as? String,
                              let createdAtString = commentData["created_at"] as? String else {
                            return nil
                        }
                        
                        let dateFormatter = ISO8601DateFormatter()
                        let createdAt = dateFormatter.date(from: createdAtString) ?? Date()
                        let isAuthor = commentData["is_author"] as? Bool ?? false
                        let likes = commentData["likes"] as? Int ?? 0
                        
                        return BlogComment(
                            id: String(id),
                            storyId: storyId,
                            userId: username,
                            userName: username,
                            content: content,
                            createdAt: createdAt,
                            likes: likes
                        )
                    }
                }
            }
        }.resume()
    }
    
    private func submitComment() {
        guard let userData = userData else { return }
        
        let commentText = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !commentText.isEmpty else { return }
        
        isSubmitting = true
        
        let urlString = "\(apiBaseURL)/blogs/stories/\(storyId)/comments"
        
        guard let url = URL(string: urlString) else {
            isSubmitting = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(userData.token)", forHTTPHeaderField: "Authorization")
        
        let commentData = ["content": commentText]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: commentData)
        } catch {
            isSubmitting = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSubmitting = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                    newComment = ""
                    loadComments() // Reload comments to show the new one
                } else {
                    errorMessage = "Failed to add comment"
                    showingErrorAlert = true
                }
            }
        }.resume()
    }
}

// MARK: - Comment Card

struct CommentCard: View {
    let comment: BlogComment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(comment.userName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text(timeAgoString(from: comment.createdAt))
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                }
                
                Spacer()
                
                if comment.likes > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                        Text("\(comment.likes)")
                            .font(.caption)
                            .foregroundColor(.ibdSecondaryText)
                    }
                }
            }
            
            Text(comment.content)
                .font(.body)
                .foregroundColor(.ibdPrimaryText)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Supporting Views

struct DiseaseTypeChip: View {
    let diseaseType: IBDDiseaseType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(diseaseType.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.ibdPrimary : Color.ibdSurfaceBackground)
                .foregroundColor(isSelected ? .white : .ibdPrimaryText)
                .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FilterChip: View {
    let filter: BlogFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(filter.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.ibdPrimary : Color.ibdSurfaceBackground)
                .foregroundColor(isSelected ? .white : .ibdPrimaryText)
                .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Data Models

enum BlogTab: String, CaseIterable {
    case read = "read"
    case write = "write"
    
    var displayName: String {
        switch self {
        case .read: return "Read"
        case .write: return "Write"
        }
    }
    
    var icon: String {
        switch self {
        case .read: return "book.fill"
        case .write: return "square.and.pencil"
        }
    }
}

enum IBDDiseaseType: String, CaseIterable {
    case all = "all"
    case crohns = "crohns"
    case ulcerativeColitis = "ulcerative_colitis"
    case indeterminate = "indeterminate"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .crohns: return "Crohn's"
        case .ulcerativeColitis: return "Ulcerative Colitis"
        case .indeterminate: return "Indeterminate"
        }
    }
}

enum BlogFilter: String, CaseIterable {
    case all = "all"
    case recent = "recent"
    case popular = "popular"
    case myStories = "my_stories"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .recent: return "Recent"
        case .popular: return "Popular"
        case .myStories: return "My Stories"
        }
    }
}

struct BlogStory: Identifiable {
    let id: String
    let userId: String
    let userName: String
    let userAge: Int
    let diseaseType: IBDDiseaseType
    let title: String
    let content: String
    let tags: [String]
    var likes: Int
    let comments: Int
    let createdAt: Date
    var isLiked: Bool
}

struct BlogComment: Identifiable {
    let id: String
    let storyId: String
    let userId: String
    let userName: String
    let content: String
    let createdAt: Date
    let likes: Int
}

#Preview {
    BlogView(userData: UserData(id: "1", email: "test@example.com", name: "Test User", phoneNumber: nil, token: "token"))
} 