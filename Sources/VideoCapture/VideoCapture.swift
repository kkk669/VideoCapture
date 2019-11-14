import AVFoundation
import Combine

public protocol VideoCapture: Publisher {
    typealias Output = CMSampleBuffer
    typealias Failure = Never

    func receive<S: Subscriber>(subscriber: S)
    where
        Self.Failure == S.Failure,
        Self.Output == S.Input
}
