import SwiftUI

struct TogeTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(Theme.muted)
                    .frame(width: 20)
            }

            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(Theme.muted.opacity(0.6)))
                .foregroundColor(Theme.foreground)
                .font(.body)
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
}

struct TogeSecureField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    @State private var showPassword = false

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(Theme.muted)
                    .frame(width: 20)
            }

            Group {
                if showPassword {
                    TextField("", text: $text, prompt: Text(placeholder).foregroundColor(Theme.muted.opacity(0.6)))
                } else {
                    SecureField("", text: $text, prompt: Text(placeholder).foregroundColor(Theme.muted.opacity(0.6)))
                }
            }
            .foregroundColor(Theme.foreground)
            .font(.body)

            Button {
                showPassword.toggle()
            } label: {
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .font(.subheadline)
                    .foregroundColor(Theme.muted)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
}
