import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSubmitting = false

    private var passwordsMatch: Bool {
        !confirmPassword.isEmpty && password == confirmPassword
    }

    private var canSubmit: Bool {
        !displayName.isEmpty && !email.isEmpty && !password.isEmpty && passwordsMatch && !isSubmitting
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 20)

                    // Header
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title3)
                                .foregroundColor(Theme.muted)
                                .frame(width: 36, height: 36)
                                .background(Theme.card)
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)

                    VStack(spacing: 8) {
                        Text("Join Tōge")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Theme.foreground)

                        Text("Create your account and start building")
                            .font(.subheadline)
                            .foregroundColor(Theme.muted)
                    }

                    // Form
                    VStack(spacing: 16) {
                        TogeTextField(
                            placeholder: "Display Name",
                            text: $displayName,
                            icon: "person"
                        )
                        .textContentType(.name)

                        TogeTextField(
                            placeholder: "Email",
                            text: $email,
                            icon: "envelope"
                        )
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                        TogeSecureField(
                            placeholder: "Password",
                            text: $password,
                            icon: "lock"
                        )
                        .textContentType(.newPassword)

                        TogeSecureField(
                            placeholder: "Confirm Password",
                            text: $confirmPassword,
                            icon: "lock.fill"
                        )
                        .textContentType(.newPassword)

                        if !confirmPassword.isEmpty && !passwordsMatch {
                            Text("Passwords don't match")
                                .font(.caption)
                                .foregroundColor(Theme.destructive)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if let error = authManager.error {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(Theme.destructive)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            Task { await signUp() }
                        } label: {
                            HStack(spacing: 8) {
                                if isSubmitting {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                }
                                Text("Create Account")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Theme.accent)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                        }
                        .disabled(!canSubmit)
                        .opacity(canSubmit ? 1 : 0.5)
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 16)

                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundColor(Theme.muted)
                        Button("Sign In") {
                            dismiss()
                        }
                        .foregroundColor(Theme.accent)
                        .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }
                .padding(.bottom, 40)
            }
        }
    }

    private func signUp() async {
        isSubmitting = true
        await authManager.signUp(email: email, password: password, displayName: displayName)
        if authManager.error == nil {
            dismiss()
        }
        isSubmitting = false
    }
}
