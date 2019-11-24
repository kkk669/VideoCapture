import AVFoundation
import Combine

public struct VideoCaptureDevice {
    let session = AVCaptureSession()
    let output: AVCaptureVideoDataOutput = {
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        output.alwaysDiscardsLateVideoFrames = true
        return output
    }()
    let delegate = SampleBufferDelegate()
    public var mirrored: Bool? {
        get {
            self.output.connection(with: .video)?.isVideoMirrored
        }
        set {
            if let val = newValue, let connection = self.output.connection(with: .video), connection.isVideoMirroringSupported {
                connection.isVideoMirrored = val
            }
        }
    }
    public var position: AVCaptureDevice.Position {
        didSet {
            if let device = getDefaultDevice(position: self.position) {
                configureDevice(device: device)
                if let input = try? AVCaptureDeviceInput(device: device) {
                    while let first = self.session.inputs.first {
                        self.session.removeInput(first)
                    }
                    if self.session.canAddInput(input) {
                        self.session.addInput(input)
                    }
                }
            }
        }
    }

    public init(
        preset: AVCaptureSession.Preset,
        position: AVCaptureDevice.Position,
        mirrored: Bool
    ) throws {
        self.session.sessionPreset = preset
        self.position = position

        let device = getDefaultDevice(position: self.position)!
        try configureDevice(device: device).get()
        let input = try AVCaptureDeviceInput(device: device)

        if self.session.canAddInput(input) {
            self.session.addInput(input)
        }
        if self.session.canAddOutput(self.output) {
            self.session.addOutput(self.output)
        }

        let queue = DispatchQueue(label: "cameraQueue")
        self.output.setSampleBufferDelegate(self.delegate, queue: queue)

        if let connection = self.output.connection(with: .video) {
            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .auto
            }
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .landscapeLeft
            }
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = mirrored
            }
        }
    }

    public func start() {
        if !self.session.isRunning {
            self.session.startRunning()
        }
    }

    public func stop() {
        if self.session.isRunning {
            self.session.stopRunning()
        }
    }

    public func rotate(orientation: AVCaptureVideoOrientation) {
        if let connection = self.output.connection(with: .video), connection.isVideoOrientationSupported {
            connection.videoOrientation = orientation
        }
    }
}

extension VideoCaptureDevice {
    class SampleBufferDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        let subject = PassthroughSubject<VideoCaptureDevice.Output, VideoCaptureDevice.Failure>()

        func captureOutput(
            _ output: AVCaptureOutput,
            didOutput sampleBuffer: CMSampleBuffer,
            from connection: AVCaptureConnection
        ) {
            self.subject.send(sampleBuffer)
        }
    }
}

extension VideoCaptureDevice: VideoCapture {
    public func receive<S: Subscriber>(subscriber: S)
    where
        VideoCaptureDevice.Failure == S.Failure,
        VideoCaptureDevice.Output == S.Input
    {
        self.delegate.subject.receive(subscriber: subscriber)
        self.start()
    }
}

func getDefaultDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
    if let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: position) {
        return device
    } else if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
        return device
    } else {
        return nil
    }
}

enum ConfigureDeviceError: Error {
    case formatNotFound
    case deviceLockFailed
}

func configureDevice(device: AVCaptureDevice) -> Result<(), ConfigureDeviceError> {
    var bestFormat: AVCaptureDevice.Format? = nil
    var bestFrameRateRange: AVFrameRateRange? = nil
    for format in device.formats {
        for range in format.videoSupportedFrameRateRanges {
            if range.maxFrameRate > bestFrameRateRange?.maxFrameRate ?? -Float64.greatestFiniteMagnitude {
                bestFormat = format
                bestFrameRateRange = range
            }
        }
    }

    guard let format = bestFormat, let range = bestFrameRateRange else {
        return .failure(.formatNotFound)
    }

    let lock = Result { try device.lockForConfiguration() }
    guard case .success = lock else {
        return .failure(.deviceLockFailed)
    }

    device.activeFormat = format
    device.activeVideoMinFrameDuration = range.maxFrameDuration
    device.activeVideoMaxFrameDuration = range.maxFrameDuration
    device.unlockForConfiguration()

    return .success(())
}
