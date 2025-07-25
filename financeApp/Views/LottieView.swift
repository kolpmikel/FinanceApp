import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    let name: String
    var onCompletion: () -> Void

    func makeUIView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView(name: name)
        view.contentMode = .scaleAspectFit
        view.loopMode = .playOnce
        view.animationSpeed = 1.0
        view.play { finished in
            if finished {
                DispatchQueue.main.async {
                    onCompletion()
                }
            }
        }
        return view
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {}
}
