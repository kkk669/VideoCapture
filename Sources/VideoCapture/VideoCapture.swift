import AVFoundation

struct VideoCapture {
    let output: AVAssetReaderOutput

    init(url: URL) {
        let asset = AVAsset(url: url)
        let reader = try! AVAssetReader(asset: asset)
        self.output = AVAssetReaderTrackOutput(track: asset.tracks(withMediaType: .video).first!, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange])
        reader.add(output)
        reader.startReading()
    }
}

extension VideoCapture: Sequence, IteratorProtocol {
    typealias Element = CMSampleBuffer

    mutating func next() -> VideoCapture.Element? {
        return self.output.copyNextSampleBuffer()
    }
}
