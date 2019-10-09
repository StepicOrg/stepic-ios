import Foundation

enum ProfileEdit {
    /// Present form for edit
    enum ProfileEditLoad {
        struct Request { }

        struct Response {
            let profile: Profile
        }

        struct ViewModel {
            let viewModel: ProfileEditViewModel
        }
    }

    /// Try to update remote profile in API
    enum RemoteProfileUpdate {
        struct Request {
            let firstName: String
            let lastName: String
            let shortBio: String
            let details: String
        }

        struct Response {
            let isSuccessful: Bool
        }

        struct ViewModel {
            let isSuccessful: Bool
        }
    }

    /// Handle HUD
    enum BlockingWaitingIndicatorUpdate {
        struct Response {
            let shouldDismiss: Bool
        }

        struct ViewModel {
            let shouldDismiss: Bool
        }
    }
}
