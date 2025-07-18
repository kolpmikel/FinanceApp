import Foundation

func makeUserMessage(from error: Error) -> String {
    if let urlErr = error as? URLError {
        switch urlErr.code {
        case .notConnectedToInternet:
            return "Похоже, вы сейчас офлайн. Проверьте соединение с интернетом."
        case .timedOut:
            return "Время ожидания запроса истекло. Попробуйте ещё раз."
        default:
            return urlErr.localizedDescription.components(separatedBy: " (").first ?? "Что-то пошло не так."
        }
    }
    return (error as NSError).localizedFailureReason
    ?? (error as NSError).localizedDescription.components(separatedBy: " (").first
    ?? "Не удалось выполнить операцию."
}
