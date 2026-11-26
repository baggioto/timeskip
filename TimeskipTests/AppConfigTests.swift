import Testing

@testable import TMDBKit
@testable import Timeskip

struct AppConfigTests {
    @Test func rejectsEmptyAndPlaceholderTokens() {
        #expect(!AppConfig.isUsableToken(""))
        #expect(!AppConfig.isUsableToken("   "))
        #expect(!AppConfig.isUsableToken("paste-your-token-here"))
    }

    @Test func acceptsRealLookingToken() {
        #expect(AppConfig.isUsableToken("eyJhbGciOiJIUzI1NiJ9.example"))
    }
}
