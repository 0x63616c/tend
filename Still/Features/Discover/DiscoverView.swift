import SwiftUI

private struct Editorial: Identifiable {
    let id: String
    let category: String
    let title: String
    let summary: String
    let duration: String
    let symbol: String
    let sections: [(String, String)]
    static let collection: [Editorial] = [
        .init(id: "journal", category: "Everyday", title: "A little routine.\nA clearer picture.", summary: "Make room for a two-minute check-in.", duration: "2 min read", symbol: "sun.horizon.fill", sections: [
            ("Keep it easy", "Choose a moment that already belongs to your day: after brushing your teeth, before breakfast, or when you put your phone on charge. Open your journal and record what you want to remember."),
            ("Leave yourself a useful note", "A short observation is enough. You might note when you weighed yourself, how your appetite felt, or a question you want to take to your next appointment."),
            ("Come back without catching up", "A missed entry does not need a perfect reconstruction. Add what you remember, choose the actual date, and carry on from today.")]),
        .init(id: "bowl", category: "Recipes", title: "The five-minute\nyogurt bowl", summary: "Yogurt, berries and a little crunch.", duration: "5 min · 1 serving", symbol: "carrot.fill", sections: [
            ("Ingredients", "150 g plain Greek yogurt\n½ cup berries, washed\n2 tablespoons rolled oats\n1 tablespoon chopped nuts, optional\nA pinch of cinnamon"),
            ("Put it together", "Spoon the yogurt into a bowl. Add the berries and oats, then finish with nuts and cinnamon. Use a dairy-free alternative or leave out the nuts if needed for your dietary preferences or allergies."),
            ("Make it yours", "Swap the berries for chopped peach or pear. For softer oats, stir them into the yogurt the night before and refrigerate. This is a recipe idea, not a personalized meal plan.")]),
        .init(id: "appointment", category: "Everyday", title: "Your next appointment,\na little more prepared", summary: "Turn your notes into questions that matter.", duration: "2 min read", symbol: "text.book.closed.fill", sections: [
            ("Start with your journal", "Look back at your recorded doses, dates and notes. If something is missing or uncertain, mark that down instead of guessing."),
            ("Pick your questions", "What has been easy? What has been difficult? Is there a pattern you would like your clinician to help explain? Bring questions about your medication and schedule to the person prescribing it."),
            ("Keep estimates in context", "The medication graph is a simplified model based on your entries, not a measurement. Share your actual dose records and observations alongside any chart.")])
    ]
}

struct DiscoverView: View {
    @State private var category = "All"
    private var articles: [Editorial] { Editorial.collection.filter { category == "All" || $0.category == category } }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("A little inspiration for your everyday.").font(.subheadline).foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        ForEach(["All", "Everyday", "Recipes"], id: \.self) { item in
                            Button { category = item } label: {
                                Text(item).font(.subheadline.weight(.semibold)).padding(.horizontal, 18).padding(.vertical, 10)
                                    .background(category == item ? Theme.pine.opacity(0.2) : Theme.card, in: Capsule())
                                    .foregroundStyle(category == item ? Theme.pine : .secondary)
                            }.buttonStyle(.plain)
                        }
                    }
                    ForEach(articles) { article in
                        NavigationLink { ArticleView(article: article) } label: {
                            VStack(alignment: .leading, spacing: 0) {
                                EditorialArtwork(symbol: article.symbol).frame(height: article.id == "journal" ? 180 : 120).clipped()
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(article.category.uppercased()).font(.caption2.weight(.bold)).tracking(1.5).foregroundStyle(Theme.pine)
                                    Text(article.title).font(.title2.weight(.bold)).fixedSize(horizontal: false, vertical: true).foregroundStyle(.primary)
                                    Text(article.summary).font(.subheadline).foregroundStyle(.secondary)
                                    HStack { Text(article.duration); Spacer(); Image(systemName: "arrow.up.right") }.font(.caption).foregroundStyle(.secondary).padding(.top, 5)
                                }.padding(20)
                            }.background(Theme.card, in: RoundedRectangle(cornerRadius: 24)).clipShape(RoundedRectangle(cornerRadius: 24))
                        }.buttonStyle(.plain)
                    }
                    NavigationLink { AssistantPreview() } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "sparkles").font(.title2).foregroundStyle(Theme.pine)
                            VStack(alignment: .leading, spacing: 5) { Text("A space to talk").font(.headline); Text("Assistant · Coming soon").font(.caption).foregroundStyle(.secondary) }
                            Spacer(); Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                        }.card()
                    }.buttonStyle(.plain)
                }.padding(16).padding(.bottom, 16)
            }.background(Theme.background).navigationTitle("Discover")
        }
    }
}

private struct EditorialArtwork: View {
    let symbol: String
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(colors: [Theme.pine.opacity(0.22), Theme.aqua.opacity(0.09), Theme.card], startPoint: .topLeading, endPoint: .bottomTrailing)
                Circle().stroke(Theme.pine.opacity(0.13), lineWidth: 1).frame(width: 220, height: 220).offset(x: 100, y: 35)
                Circle().stroke(Theme.pine.opacity(0.15), lineWidth: 1).frame(width: 150, height: 150).offset(x: 100, y: 35)
                Image(systemName: symbol).font(.system(size: 64, weight: .ultraLight)).foregroundStyle(Theme.pine).offset(x: -geometry.size.width * 0.24)
            }.frame(width: geometry.size.width, height: geometry.size.height)
        }.accessibilityHidden(true)
    }
}

private struct ArticleView: View {
    let article: Editorial
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                EditorialArtwork(symbol: article.symbol).frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 24))
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(article.category) · \(article.duration)").font(.caption.weight(.semibold)).foregroundStyle(Theme.pine)
                    Text(article.title).font(.largeTitle.bold()).fixedSize(horizontal: false, vertical: true)
                    Text("Tend editorial").font(.caption).foregroundStyle(.secondary)
                }
                ForEach(article.sections.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(article.sections[index].0).font(.title3.bold())
                        Text(article.sections[index].1).font(.body).lineSpacing(6).foregroundStyle(.secondary)
                    }
                }
            }.padding(20).padding(.bottom, 24)
        }.background(Theme.background).navigationBarTitleDisplayMode(.inline)
    }
}
