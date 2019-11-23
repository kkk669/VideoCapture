import AVFoundation
import Combine

public struct VideoCaptureFile {
    let output: AVAssetReaderOutput

    public init(url: URL) throws {
        let asset = AVAsset(url: url)
        let reader = try AVAssetReader(asset: asset)
        self.output = AVAssetReaderTrackOutput(
            track: asset.tracks(withMediaType: .video).first!,
            outputSettings: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
            ]
        )
        reader.add(self.output)
        reader.startReading()
    }
}

extension VideoCaptureFile: Sequence, IteratorProtocol {
    public typealias Element = Self.Output

    public mutating func next() -> Self.Element? {
        self.output.copyNextSampleBuffer()
    }
}

extension VideoCaptureFile: VideoCapture {
    public func receive<S: Subscriber>(subscriber: S)
    where
        VideoCaptureFile.Failure == S.Failure,
        VideoCaptureFile.Output == S.Input
    {
        DispatchQueue.global().async {
            self.publisher.receive(subscriber: subscriber)
        }
    }
}
