import SwiftUI

/// Razer-Synapse-inspired dark theme. Signature Razer green on near-black, with
/// charcoal cards and hairline borders. Brand-neutral names so it can be re-themed.
enum Theme {
    static let green   = Color(red: 0.267, green: 0.839, blue: 0.173)   // #44D62C Razer green
    static let greenDim = Color(red: 0.267, green: 0.839, blue: 0.173).opacity(0.15)

    static let bg      = Color(red: 0.055, green: 0.055, blue: 0.058)   // #0E0E0F
    static let sidebar = Color(red: 0.086, green: 0.086, blue: 0.090)   // #161617
    static let card    = Color(red: 0.106, green: 0.106, blue: 0.110)   // #1B1B1C
    static let cardHi  = Color(red: 0.145, green: 0.145, blue: 0.150)   // hover/selected
    static let border  = Color.white.opacity(0.07)
    static let borderHi = green.opacity(0.55)

    static let text    = Color.white
    static let text2   = Color.white.opacity(0.55)
    static let text3   = Color.white.opacity(0.30)
}

/// Section header: uppercase, tracked, dim — the Synapse label style.
struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .bold))
            .tracking(1.6)
            .foregroundStyle(Theme.text2)
    }
}

/// A dark content card with a hairline border.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 16) { content }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Theme.border, lineWidth: 1)
            )
    }
}

/// A labelled row used inside cards (label left, control right).
struct Row<Control: View>: View {
    let label: String
    var sub: String? = nil
    @ViewBuilder var control: Control
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.text)
                if let sub { Text(sub).font(.system(size: 11)).foregroundStyle(Theme.text3) }
            }
            Spacer(minLength: 16)
            control
        }
    }
}

/// Left-sidebar navigation item, Synapse style: icon + label, green bar when active.
struct NavItem: View {
    let icon: String
    let title: String
    let active: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Rectangle()
                    .fill(active ? Theme.green : .clear)
                    .frame(width: 3)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 18)
                    .foregroundStyle(active ? Theme.green : Theme.text2)
                Text(title)
                    .font(.system(size: 13, weight: active ? .semibold : .regular))
                    .foregroundStyle(active ? Theme.text : Theme.text2)
                Spacer()
            }
            .frame(height: 42)
            .padding(.trailing, 12)
            .background(active ? Theme.cardHi : .clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Top mode tab (Control / Lab / Console).
struct ModeTab: View {
    let title: String
    let active: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(active ? Theme.text : Theme.text2)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(alignment: .bottom) {
                    Rectangle().fill(active ? Theme.green : .clear).frame(height: 2)
                }
        }
        .buttonStyle(.plain)
    }
}
