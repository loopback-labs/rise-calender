import AuthenticationServices
// MARK: - Crypto helpers
import CryptoKit
import Foundation

struct OAuthTokens: Codable, Equatable {
  let accessToken: String
  let refreshToken: String
  let idToken: String?
  let expiryDate: Date
}

struct OAuthConfig: Codable {
  let clientId: String
  let redirectScheme: String
}

enum GoogleOAuthError: Error {
  case configurationMissing, invalidRedirectURL, authFailed, tokenExchangeFailed, tokenRefreshFailed
}

final class GoogleOAuthService: NSObject {
  static let shared = GoogleOAuthService()
  private override init() {}

  private let authURL = URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!
  private let tokenURL = URL(string: "https://oauth2.googleapis.com/token")!
  private let scopes = [
    "openid",
    "email",
    "https://www.googleapis.com/auth/calendar.readonly",
  ]
  private var currentPresentationAnchor: ASPresentationAnchor?

  func loadConfig() throws -> OAuthConfig {
    // First try environment variables
    if let clientId = ProcessInfo.processInfo.environment["GOOGLE_CLIENT_ID"],
      let redirectScheme = ProcessInfo.processInfo.environment["GOOGLE_REDIRECT_SCHEME"],
      !clientId.isEmpty, !redirectScheme.isEmpty
    {
      return OAuthConfig(clientId: clientId, redirectScheme: redirectScheme)
    }

    // Fallback to plist file (optional)
    if let url = Bundle.main.url(forResource: "OAuthConfig", withExtension: "plist"),
      let data = try? Data(contentsOf: url),
      let dict = try? PropertyListSerialization.propertyList(from: data, format: nil)
        as? [String: Any],
      let clientId = dict["CLIENT_ID"] as? String, !clientId.isEmpty,
      let scheme = dict["REDIRECT_SCHEME"] as? String, !scheme.isEmpty
    {
      return OAuthConfig(clientId: clientId, redirectScheme: scheme)
    }

    // If neither environment variables nor plist file are available
    throw GoogleOAuthError.configurationMissing
  }

  func signIn(startingAnchor: ASPresentationAnchor) async throws -> (
    email: String, tokens: OAuthTokens
  ) {
    let config = try loadConfig()
    currentPresentationAnchor = startingAnchor
    let (code, codeVerifier) = try await authorize(config: config, startingAnchor: startingAnchor)
    let tokens = try await exchangeCodeForTokens(
      code: code, codeVerifier: codeVerifier, clientId: config.clientId,
      redirectScheme: config.redirectScheme)

    // Extract email from ID token if available
    let email = idTokenEmail(tokens.idToken) ?? "unknown@google"
    return (email, tokens)
  }

  func refreshTokens(_ tokens: OAuthTokens, clientId: String) async throws -> OAuthTokens {
    let body: [String: String] = [
      "client_id": clientId,
      "grant_type": "refresh_token",
      "refresh_token": tokens.refreshToken,
    ]
    let request = Self.urlEncodedRequest(url: tokenURL, body: body)
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
      throw GoogleOAuthError.tokenRefreshFailed
    }
    let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    guard let access = decoded?["access_token"] as? String,
      let expiresIn = decoded?["expires_in"] as? Double
    else { throw GoogleOAuthError.tokenRefreshFailed }
    let idToken = decoded?["id_token"] as? String
    return OAuthTokens(
      accessToken: access, refreshToken: tokens.refreshToken, idToken: idToken,
      expiryDate: Date().addingTimeInterval(expiresIn - 60))
  }

  // MARK: - Private

  private func authorize(config: OAuthConfig, startingAnchor: ASPresentationAnchor) async throws
    -> (code: String, codeVerifier: String)
  {
    let codeVerifier = Self.randomBase64URL(length: 64)
    let codeChallenge = Self.sha256Base64URL(codeVerifier)
    // Google recommends ":/oauth2redirect/google" for installed apps (iOS)
    let redirectURI = "\(config.redirectScheme):/oauth2redirect/google"

    var components = URLComponents(url: authURL, resolvingAgainstBaseURL: false)!
    components.queryItems = [
      URLQueryItem(name: "response_type", value: "code"),
      URLQueryItem(name: "client_id", value: config.clientId),
      URLQueryItem(name: "redirect_uri", value: redirectURI),
      URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
      URLQueryItem(name: "code_challenge", value: codeChallenge),
      URLQueryItem(name: "code_challenge_method", value: "S256"),
      URLQueryItem(name: "access_type", value: "offline"),
      URLQueryItem(name: "prompt", value: "consent"),
    ]

    let callbackScheme = config.redirectScheme
    guard let authURL = components.url else { throw GoogleOAuthError.authFailed }

    return try await withCheckedThrowingContinuation { continuation in
      let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackScheme) {
        url, error in
        if let error = error {
          continuation.resume(throwing: error)
          return
        }
        guard let url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        else {
          continuation.resume(throwing: GoogleOAuthError.authFailed)
          return
        }
        continuation.resume(returning: (code, codeVerifier))
      }
      session.prefersEphemeralWebBrowserSession = false
      session.presentationContextProvider = self
      session.start()
    }
  }

  private func exchangeCodeForTokens(
    code: String, codeVerifier: String, clientId: String, redirectScheme: String
  ) async throws -> OAuthTokens {
    let redirectURI = "\(redirectScheme):/oauth2redirect/google"
    let body: [String: String] = [
      "grant_type": "authorization_code",
      "code": code,
      "client_id": clientId,
      "code_verifier": codeVerifier,
      "redirect_uri": redirectURI,
    ]
    let request = Self.urlEncodedRequest(url: tokenURL, body: body)
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
      throw GoogleOAuthError.tokenExchangeFailed
    }
    let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    guard let access = decoded?["access_token"] as? String,
      let refresh = decoded?["refresh_token"] as? String,
      let expiresIn = decoded?["expires_in"] as? Double
    else { throw GoogleOAuthError.tokenExchangeFailed }
    let idToken = decoded?["id_token"] as? String
    return OAuthTokens(
      accessToken: access, refreshToken: refresh, idToken: idToken,
      expiryDate: Date().addingTimeInterval(expiresIn - 60))
  }

  private func idTokenEmail(_ idToken: String?) -> String? {
    guard let idToken else { return nil }
    let parts = idToken.split(separator: ".")
    guard parts.count == 3, let data = Data(base64URL: String(parts[1])) else { return nil }
    let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    return json?["email"] as? String
  }

  private static func urlEncodedRequest(url: URL, body: [String: String]) -> URLRequest {
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.httpBody = body.map {
      "\($0.key)=\(($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed))!)"
    }.joined(separator: "&").data(using: .utf8)
    return request
  }

  private static func randomBase64URL(length: Int) -> String {
    var bytes = [UInt8](repeating: 0, count: length)
    _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
    return Data(bytes).base64URLEncodedString()
  }

  private static func sha256Base64URL(_ input: String) -> String {
    let data = Data(input.utf8)
    let digest = sha256(data)
    return digest.base64URLEncodedString()
  }
}

extension GoogleOAuthService: ASWebAuthenticationPresentationContextProviding {
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return currentPresentationAnchor ?? ASPresentationAnchor()
  }
}

private func sha256(_ data: Data) -> Data { Data(SHA256.hash(data: data)) }

extension Data {
  fileprivate init?(base64URL: String) {
    self.init(
      base64Encoded: base64URL.replacingOccurrences(of: "-", with: "+").replacingOccurrences(
        of: "_", with: "/") + String(repeating: "=", count: (4 - base64URL.count % 4) % 4))
  }

  fileprivate func base64URLEncodedString() -> String {
    return self.base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }
}
