import Foundation
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import FirebaseCore

@MainActor
final class AuthManager: ObservableObject {
    @Published var user: FirebaseAuth.User?
    @Published var isLoading = true
    @Published var error: String?

    private var listener: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    init() {
        listener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.isLoading = false
        }
    }

    deinit {
        if let listener { Auth.auth().removeStateDidChangeListener(listener) }
    }

    var isSignedIn: Bool { user != nil }

    // MARK: - Email Sign Up (matches web createUserDocument)
    func signUp(email: String, password: String, displayName: String) async {
        error = nil
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            // Update Firebase Auth profile
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()

            // Create Firestore user doc — same schema as web app
            try await createUserDocument(user: result.user, displayName: displayName)
            self.user = result.user
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Email Sign In
    func signIn(email: String, password: String) async {
        error = nil
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.user = result.user
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Google Sign In
    func signInWithGoogle() async {
        error = nil
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            self.error = "Missing Firebase client ID"
            return
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            self.error = "Unable to find root view controller"
            return
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            guard let idToken = result.user.idToken?.tokenString else {
                self.error = "Missing Google ID token"
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )

            let authResult = try await Auth.auth().signIn(with: credential)
            try await createUserDocument(user: authResult.user)
            self.user = authResult.user
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Create User Document (matches web AuthContext)
    private func createUserDocument(user: FirebaseAuth.User, displayName: String? = nil) async throws {
        let userRef = db.collection("users").document(user.uid)
        let snap = try await userRef.getDocument()

        if !snap.exists {
            try await userRef.setData([
                "uid": user.uid,
                "email": user.email ?? "",
                "displayName": displayName ?? user.displayName ?? "",
                "username": "",
                "profileImageURL": user.photoURL?.absoluteString ?? "",
                "bio": "",
                "location": "",
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp(),
            ])
        }
    }
}
