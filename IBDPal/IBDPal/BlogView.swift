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
        NavigationView {
            VStack(spacing: 0) {
                // Header with Tab Selector
                VStack(spacing: 16) {
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
                .padding()
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
                CreateStoryView(userData: userData)
            }
            .onAppear {
                loadStories()
            }
        }
    }
    
    private func loadStories() {
        isLoading = true
        // TODO: Load stories from API
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            stories = getSampleStories()
            isLoading = false
        }
    }
    
    private func getSampleStories() -> [BlogStory] {
        return [
            BlogStory(
                id: "1",
                userId: "user1",
                userName: "Sarah M.",
                userAge: 24,
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
                userAge: 31,
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
                userAge: 19,
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
                            StoryCard(story: story)
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
    @State private var showingFullStory = false
    @State private var isLiked: Bool
    
    init(story: BlogStory) {
        self.story = story
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
                        Text("\(story.userAge) years old")
                            .font(.caption)
                            .foregroundColor(.ibdSecondaryText)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.ibdSecondaryText)
                        
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
                    isLiked.toggle()
                    // TODO: Update like count via API
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
                    // TODO: Show comments
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
                
                Button("Read More") {
                    showingFullStory = true
                }
                .font(.caption)
                .foregroundColor(.ibdPrimary)
            }
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
        .sheet(isPresented: $showingFullStory) {
            StoryDetailView(story: story)
        }
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
        NavigationView {
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
                    }
                    
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Story Title")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.ibdPrimaryText)
                        
                        TextField("Enter a compelling title for your story...", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
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
                            
                            Button("Add") {
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
                    
                    // Submit Button
                    Button(action: submitStory) {
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
                        dismiss()
                    }
                }
            }
            .alert("Story Published!", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your story has been published successfully. Thank you for sharing your experience with the IBD community!")
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            newTag = ""
        }
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    private func submitStory() {
        guard let userData = userData else {
            errorMessage = "User data not available"
            showingErrorAlert = true
            return
        }
        
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a title for your story"
            showingErrorAlert = true
            return
        }
        
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please write your story content"
            showingErrorAlert = true
            return
        }
        
        isLoading = true
        
        let storyData: [String: Any] = [
            "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
            "content": content.trimmingCharacters(in: .whitespacesAndNewlines),
            "disease_type": selectedDiseaseType.rawValue,
            "tags": tags
        ]
        
        guard let url = URL(string: "\(apiBaseURL)/blogs") else {
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
        } catch {
            errorMessage = "Failed to prepare request data"
            showingErrorAlert = true
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 201 {
                        showingSuccessAlert = true
                    } else {
                        if let data = data,
                           let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let message = errorResponse["error"] as? String {
                            errorMessage = message
                        } else {
                            errorMessage = "Failed to publish story"
                        }
                        showingErrorAlert = true
                    }
                }
            }
        }.resume()
    }
}

// MARK: - Story Detail View

struct StoryDetailView: View {
    let story: BlogStory
    @Environment(\.dismiss) private var dismiss
    @State private var isLiked: Bool
    @State private var showingComments = false
    
    init(story: BlogStory) {
        self.story = story
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
                            
                            Text("\(story.userAge) years old")
                                .font(.subheadline)
                                .foregroundColor(.ibdSecondaryText)
                            
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
                            isLiked.toggle()
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
                CommentsView(storyId: story.id)
            }
        }
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
    @Environment(\.dismiss) private var dismiss
    @State private var comments: [BlogComment] = []
    @State private var newComment = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading comments...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if comments.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No comments yet")
                            .font(.headline)
                            .foregroundColor(.ibdSecondaryText)
                        
                        Text("Be the first to share your thoughts")
                            .font(.subheadline)
                            .foregroundColor(.ibdSecondaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(comments) { comment in
                                CommentCard(comment: comment)
                            }
                        }
                        .padding()
                    }
                }
                
                // Add Comment
                HStack {
                    TextField("Add a comment...", text: $newComment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Post") {
                        postComment()
                    }
                    .disabled(newComment.isEmpty)
                    .foregroundColor(.ibdPrimary)
                }
                .padding()
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
            .onAppear {
                loadComments()
            }
        }
    }
    
    private func loadComments() {
        isLoading = true
        // TODO: Load comments from API
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            comments = getSampleComments()
            isLoading = false
        }
    }
    
    private func postComment() {
        // TODO: Post comment to API
        let newCommentObj = BlogComment(
            id: UUID().uuidString,
            storyId: storyId,
            userId: "currentUser",
            userName: "You",
            content: newComment,
            createdAt: Date(),
            likes: 0
        )
        comments.insert(newCommentObj, at: 0)
        newComment = ""
    }
    
    private func getSampleComments() -> [BlogComment] {
        return [
            BlogComment(
                id: "1",
                storyId: storyId,
                userId: "user1",
                userName: "Alex K.",
                content: "Thank you for sharing your story! It's so inspiring to hear about your journey to remission.",
                createdAt: Date().addingTimeInterval(-3600),
                likes: 5
            ),
            BlogComment(
                id: "2",
                storyId: storyId,
                userId: "user2",
                userName: "Maria S.",
                content: "I can relate to so much of what you've written. The diet changes really made a difference for me too.",
                createdAt: Date().addingTimeInterval(-7200),
                likes: 3
            )
        ]
    }
}

// MARK: - Comment Card

struct CommentCard: View {
    let comment: BlogComment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(comment.userName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.ibdPrimaryText)
                
                Spacer()
                
                Text(timeAgoString(from: comment.createdAt))
                    .font(.caption)
                    .foregroundColor(.ibdSecondaryText)
            }
            
            Text(comment.content)
                .font(.subheadline)
                .foregroundColor(.ibdPrimaryText)
            
            HStack {
                Button(action: {
                    // TODO: Like comment
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                            .font(.caption)
                            .foregroundColor(.ibdSecondaryText)
                        Text("\(comment.likes)")
                            .font(.caption)
                            .foregroundColor(.ibdSecondaryText)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(8)
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
    let likes: Int
    let comments: Int
    let createdAt: Date
    let isLiked: Bool
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