import UIKit

protocol CourseInfoTabInfoPresenterProtocol {
    func presentCourseInfo(response: CourseInfoTabInfo.InfoLoad.Response)
}

final class CourseInfoTabInfoPresenter: CourseInfoTabInfoPresenterProtocol {
    weak var viewController: CourseInfoTabInfoViewControllerProtocol?

    func presentCourseInfo(response: CourseInfoTabInfo.InfoLoad.Response) {
        var viewModel: CourseInfoTabInfo.InfoLoad.ViewModel

        if let course = response.course {
            viewModel = .init(state: .result(data: self.makeViewModel(course: course)))
        } else {
            viewModel = .init(state: .loading)
        }

        self.viewController?.displayCourseInfo(viewModel: viewModel)
    }

    private func makeViewModel(course: Course) -> CourseInfoTabInfoViewModel {
        let instructorsViewModel = course.instructors.map { user in
            CourseInfoTabInfoInstructorViewModel(
                id: user.id,
                avatarImageURL: URL(string: user.avatarURL),
                title: "\(user.firstName) \(user.lastName)",
                description: user.bio
            )
        }

        let certificateText = course.isCertificatesAutoIssued
            ? self.makeFormattedCertificateText(course: course)
            : nil
        let certificateDetailsText = course.isCertificatesAutoIssued
            ? self.makeFormattedCertificateDetailsText(
                conditionPoints: course.certificateRegularThreshold,
                distinctionPoints: course.certificateDistinctionThreshold
            )
            : nil

        return CourseInfoTabInfoViewModel(
            author: self.makeFormattedAuthorText(authors: course.authors),
            introVideoURL: self.makeIntroVideoURL(course: course),
            introVideoThumbnailURL: URL(string: course.introVideo?.thumbnailURL ?? ""),
            aboutText: course.summary.trimmingCharacters(in: .whitespaces),
            requirementsText: course.requirements.trimmingCharacters(in: .whitespaces),
            targetAudienceText: course.audience.trimmingCharacters(in: .whitespaces),
            timeToCompleteText: self.makeFormattedTimeToCompleteText(timeToComplete: course.timeToComplete),
            languageText: self.makeLocalizedLanguageText(code: course.languageCode),
            certificateText: certificateText,
            certificateDetailsText: certificateDetailsText,
            instructors: instructorsViewModel
        )
    }

    private func makeIntroVideoURL(course: Course) -> URL? {
        if let introVideo = course.introVideo, !introVideo.urls.isEmpty {
            // FIXME: VideosInfo dependency
            return introVideo.getUrlForQuality(VideosInfo.watchingVideoQuality)
        } else {
            return URL(string: course.introURL)
        }
    }

    private func makeFormattedAuthorText(authors: [User]) -> String {
        if authors.isEmpty {
            return ""
        } else {
            var authorString = authors.reduce(into: "") { result, user in
                result += "\(user.firstName) \(user.lastName), "
            }.trimmingCharacters(in: .whitespaces)
            authorString.removeLast()

            return authorString
        }
    }

    private func makeFormattedTimeToCompleteText(timeToComplete: Int?) -> String {
        if let timeToComplete = timeToComplete {
            return FormatterHelper.hoursInSeconds(TimeInterval(timeToComplete))
        } else {
            return ""
        }
    }

    private func makeLocalizedLanguageText(code: String) -> String {
        return Locale.current.localizedString(forLanguageCode: code)?.capitalized ?? ""
    }

    private func makeFormattedCertificateText(course: Course) -> String {
        let certificateText = course.certificate.trimmingCharacters(in: .whitespaces)
        if certificateText.isEmpty {
            return course.certificateRegularThreshold ?? 0 > 0 && course.certificateDistinctionThreshold ?? 0 > 0
                ? NSLocalizedString("Yes", comment: "")
                : NSLocalizedString("No", comment: "")
        } else {
            return certificateText
        }
    }

    private func makeFormattedCertificateDetailsText(conditionPoints: Int?, distinctionPoints: Int?) -> String {
        let formattedCondition = self.makeFormattedCertificateDetailTitle(
            NSLocalizedString("CertificateCondition", comment: ""),
            points: conditionPoints
        )
        let formattedDistinction = self.makeFormattedCertificateDetailTitle(
            NSLocalizedString("WithDistinction", comment: ""),
            points: distinctionPoints
        )

        return "\(formattedCondition)\n\(formattedDistinction)".trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private func makeFormattedCertificateDetailTitle(_ title: String, points: Int?) -> String {
        if let points = points, points > 0 {
            return "\(title): \(FormatterHelper.pointsCount(points))"
        } else {
            return ""
        }
    }
}
