import ARKit
import Combine

public struct VideoCaptureAR {
    let session = ARSession()
    let delegate = SampleBufferDelegate()

    public init() {
        self.session.delegate = self.delegate
    }

    public func start(_ configuration: ARConfiguration) {
        self.session.run(configuration)
    }

    public func stop() {
        self.session.pause()
    }
}

extension VideoCaptureAR {
    class SampleBufferDelegate: NSObject, ARSessionDelegate {
        let subject = PassthroughSubject<Output, Failure>()
        var frameCount = 0

        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            let imageBuffer = frame.capturedImage
            let transform = frame.camera.transform

            var formatOut: CMVideoFormatDescription?
            CMVideoFormatDescriptionCreateForImageBuffer(
                allocator: kCFAllocatorDefault,
                imageBuffer: imageBuffer,
                formatDescriptionOut: &formatOut
            )
            guard let format = formatOut else {
                fatalError()
            }

            let duration = format.frameDuration
            let timeStamp = CMTimeMake(
                value: Int64(self.frameCount),
                timescale: duration.timescale
            )
            var timingInfo = CMSampleTimingInfo(
                duration: duration,
                presentationTimeStamp: timeStamp,
                decodeTimeStamp: .invalid
            )
            self.frameCount += 1

            var sampleBufferOut: CMSampleBuffer?
            CMSampleBufferCreateReadyWithImageBuffer(
                allocator: kCFAllocatorDefault,
                imageBuffer: imageBuffer,
                formatDescription: format,
                sampleTiming: &timingInfo,
                sampleBufferOut: &sampleBufferOut
            )
            guard let sampleBuffer = sampleBufferOut else {
                fatalError()
            }

            self.subject.send(sampleBuffer)
        }
    }
}

extension VideoCaptureAR: VideoCapture {
    public func receive<S: Subscriber>(subscriber: S)
    where
        Failure == S.Failure,
        Output == S.Input
    {
        self.delegate.subject.receive(subscriber: subscriber)
        self.start(AROrientationTrackingConfiguration())
    }
}
