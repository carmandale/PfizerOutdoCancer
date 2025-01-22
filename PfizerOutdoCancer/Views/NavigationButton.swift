struct NavigationButton: View {
    let title: String
    let action: () async -> Void
    
    var body: some View {
        Button {
            Task { await action() }
        } label: {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding(16)
        }
//        .padding(16)
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .hoverEffect { effect, isActive, proxy in
                effect.scaleEffect(!isActive ? 1.0 : 1.2)
            }
    }
}