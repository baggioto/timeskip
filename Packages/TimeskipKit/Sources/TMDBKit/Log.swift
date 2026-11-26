import OSLog

/// Unified logging categories. Request URLs are logged as `.public` because they contain no user data
/// (the token travels in a header and is never logged).
public nonisolated enum Log {
    public static let subsystem = "com.baggioto.Timeskip"
    public static let network = Logger(subsystem: subsystem, category: "Network")
    public static let images = Logger(subsystem: subsystem, category: "Images")
    public static let persistence = Logger(subsystem: subsystem, category: "Persistence")
    public static let notifications = Logger(subsystem: subsystem, category: "Notifications")
    public static let metrics = Logger(subsystem: subsystem, category: "Metrics")
}
