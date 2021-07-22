import UIKit
import XCTest

var currentUserName = "test"
var currentUserEmail = "test"
let kCurrentUserPassword = "512"

enum Common {
    @discardableResult
    static func registerNewUserIfNeeded() -> Bool {
        if currentUserEmail.contains("ios_autotest") {
            return false
        }
        // Register new user
        let timestamp = Int64(Date().timeIntervalSince1970)

        let app = XCUIApplication()
        app.launch()

        app.tabBars["Tab Bar"].buttons["Profile"].tap()

        if !app.buttons["Sign In"].staticTexts["Sign In"].waitForExistence(timeout: 5) {
            XCTFail("No Sign In button in profile tab")
        } else {
            app.buttons["Sign In"].staticTexts["Sign In"].tap()
            app.buttons["Sign Up"].tap()

            app.textFields["Name"].tap()
            app.textFields["Name"].typeText("ios_autotest_\(timestamp)")

            app.textFields["Email"].tap()
            sleep(2)
            self.pasteTextFieldText(
                app: app,
                element: app.textFields["Email"],
                value: "ios_autotest_\(timestamp)@stepik.org"
            )

            app.secureTextFields["Password"].tap()
            sleep(2)
            self.pasteTextFieldText(
                app: app,
                element: app.secureTextFields["Password"],
                value: kCurrentUserPassword
            )

            if app.buttons["Register"].waitForExistence(timeout: 2) {
                app.buttons["Register"].tap()
            } else {
                XCTFail("User setup failed, unable find Register button")
            }

            if self.isUserLoggedIn(app: app) {
                currentUserName = "ios_autotest_\(timestamp)"
                currentUserEmail = "ios_autotest_\(timestamp)@stepik.org"
            } else {
                XCTFail("User setup failed")
            }
        }

        self.logOut(app: app)
        app.terminate()

        return true
    }

    static func isUserLoggedIn(app: XCUIApplication) -> Bool {
        app.tabBars["Tab Bar"].buttons["Profile"].tap()
        if app.buttons["Sign In"].staticTexts["Sign In"].waitForExistence(timeout: 10) {
            return false
        }
        return true
    }

    static func logOut(app: XCUIApplication) {
        if app.tabBars["Tab Bar"].buttons["Profile"].waitForExistence(timeout: 10) {
            app.tabBars["Tab Bar"].buttons["Profile"].tap()
        }

        app.navigationBars["Profile"].buttons["settings"].tap()
        app.swipeUp()
        app.tables.staticTexts["Log Out"].tap()
        app.alerts["Log Out"].scrollViews.otherElements.buttons["Log Out"].tap()

        if !app.buttons["Sign In"].staticTexts["Sign In"].waitForExistence(timeout: 10) {
            XCTFail("Logout failed")
        }
    }

    static func logIn(app: XCUIApplication) {
        app.tabBars["Tab Bar"].buttons["Profile"].tap()
        app.buttons["Sign In"].staticTexts["Sign In"].tap()
        app.buttons["Sign In with e-mail"].tap()

        app.textFields["Email"].tap()
        app.textFields["Email"].typeText(currentUserEmail)

        sleep(5)

        app.secureTextFields["Password"].tap()
        self.pasteTextFieldText(
            app: app,
            element: app.secureTextFields["Password"],
            value: kCurrentUserPassword
        )

        app.buttons["Log in"].tap()
    }

    static func deleteApplication() {
        let appName = "Stepik"

        // Put the app in the background
        // XCUIDevice.shared.press(XCUIDevice.Button.home)

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if springboard.icons[appName].waitForExistence(timeout: 5) {
            springboard.icons[appName].press(forDuration: 1.5)
        }

        if springboard.collectionViews.buttons["Remove App"].waitForExistence(timeout: 5) {
            springboard.collectionViews.buttons["Remove App"].tap()
        }

        if springboard.alerts["Remove “\(appName)”?"]
            .scrollViews.otherElements.buttons["Delete App"].waitForExistence(timeout: 5) {
            springboard.alerts["Remove “\(appName)”?"].scrollViews.otherElements.buttons["Delete App"].tap()
        }

        if springboard.alerts["Delete “\(appName)”?"]
            .scrollViews.otherElements.buttons["Delete"].waitForExistence(timeout: 5) {
            springboard.alerts["Delete “\(appName)”?"].scrollViews.otherElements.buttons["Delete"].tap()
        }
    }

    static func pasteTextFieldText(app: XCUIApplication, element: XCUIElement, value: String, clearText: Bool = false) {
        // Get the password into the pasteboard buffer
        UIPasteboard.general.string = value
        // Bring up the popup menu on the password field
        if clearText {
            element.buttons["Clear text"].tap()
        }
        element.doubleTap()
        // Tap the Paste button to input the password
        app.menuItems["Paste"].tap()
    }
}
