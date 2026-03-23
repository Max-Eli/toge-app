import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    @State private var isSubmitting = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 60)

                    // Logo
                    VStack(spacing: 8) {
                        Text("峠")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundColor(Theme.accent)

                        Text("TŌGE")
                            .font(.system(size: 28, weight: .bold, design: .default))
                            .tracking(6)
                            .foregroundColor(Theme.foreground)

                        Text("The car enthusiast platform")
                            .font(.subheadline)
                            .foregroundColor(Theme.muted)
                    }

                    Spacer().frame(height: 16)

                    // Form
                    VStack(spacing: 16) {
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
                        .textContentType(.password)

                        if let error = authManager.error {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(Theme.destructive)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            Task { await signIn() }
                        } label: {
                            HStack(spacing: 8) {
                                if isSubmitting {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                }
                                Text("Sign In")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Theme.accent)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                        }
                        .disabled(email.isEmpty || password.isEmpty || isSubmitting)
                        .opacity(email.isEmpty || password.isEmpty ? 0.5 : 1)
                    }
                    .padding(.horizontal, 24)

                    // Divider
                    HStack {
                        Rectangle().fill(Theme.border).frame(height: 1)
                        Text("or").font(.caption).foregroundColor(Theme.muted)
                        Rectangle().fill(Theme.border).frame(height: 1)
                    }
                    .padding(.horizontal, 24)

                    // Google Sign In
                    Button {
                        Task { await authManager.signInWithGoogle() }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "g.circle.fill")
                                .font(.title3)
                            Text("Continue with Google")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd, style: .continuous))
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 16)

                    // Sign up link
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundColor(Theme.muted)
                        Button("Sign Up") {
                            showSignUp = true
                        }
                        .foregroundColor(Theme.accent)
                        .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }
                .padding(.bottom, 40)
            }
        }
        .fullScreenCover(isPresented: $showSignUp) {
            SignUpView()
                .environmentObject(authManager)
        }
    }

    private func signIn() async {
        isSubmitting = true
        await authManager.signIn(email: email, password: password)
        isSubmitting = false
    }
}
