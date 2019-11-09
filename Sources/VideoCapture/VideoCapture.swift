import AVFoundation

public struct VideoCapture {
    let output: AVAssetReaderOutput

    public init(url: URL) {
        let asset = AVAsset(url: url)
        let reader = try! AVAssetReader(asset: asset)
        self.output = AVAssetReaderTrackOutput(track: asset.tracks(withMediaType: .video).first!, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange])
        reader.add(output)
        reader.startReading()
    }
}

extension VideoCapture: Sequence, IteratorProtocol {
    public typealias Element = CMSampleBuffer

    mutating public func next() -> VideoCapture.Element? {
        return self.output.copyNextSampleBuffer()
    }
}
