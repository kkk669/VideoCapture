import AVFondation

struct VideoCaptureDevice {
    let session = AVCaptureSession()
    let output: AVCaptureVideoDataOutput = {
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.alwaysDiscardsLateVideoFrames = true
        return output
    }()
    var delegate: AVCaptureVideoDataOutputSampleBufferDelegate? {
        get {
            return self.output.sampleBufferDelegate
        }
        set {
            if session.isRunning {
                self.session.stopRunning()
            }

            let queue = DispatchQueue(label: "cameraQueue")
            self.output.setSampleBufferDelegate(newValue, queue: queue)

            if let connection = self.output.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .landscapeLeft
                }
            }
        }
    }

    init(preset: AVCaptureSession.Preset) throws {
        self.session.sessionPreset = preset

        let device = getDefaultDevice()!
        try configureDevice(device: device).get()
        let input = try AVCaptureDeviceInput(device: device)

        if self.session.canAddInput(input) {
            self.session.addInput(input)
        }
        if self.session.canAddOutput(self.output) {
            self.session.addOutput(self.output)
        }
    }

    func start() {
        if !self.session.isRunning {
            self.session.startRunning()
        }
    }

    func stop() {
        if self.session.isRunning {
            self.session.stopRunning()
        }
    }
}

func getDefaultDevice() -> AVCaptureDevice? {
    if let device = AVCaptureDevice.default(.builtInDualCamera , for: .video, position: .back) {
        return device
    } else if let device = AVCaptureDevice.default(.builtInWideAngleCamera , for: .video, position: .back) {
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
            if let best = bestFrameRateRange, range.maxFrameRate > best.maxFrameRate {
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
