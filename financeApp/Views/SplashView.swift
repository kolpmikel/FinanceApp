import SwiftUI

struct SplashView: View {
    /// Будем вызывать, когда анимация закончилась
    let onFinished: () -> Void

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            LottieView(name: "upload", onCompletion: onFinished)
                .frame(width: 200, height: 200)
        }
    }
}
