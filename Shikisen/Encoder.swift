// Copyright 2026 Cii
//
// This file is part of Shikisen.
//
// Shikisen is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Shikisen is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Shikisen.  If not, see <http://www.gnu.org/licenses/>.

//#if anyAppleOS
import AVFoundation
import VideoToolbox
import CoreImage
//#elseif os(linux) && os(windows)
//#endif

struct Caption: Hashable, Codable {
    var string = ""
    var origin = Point()
    var orientation = Orientation.horizontal
    var isTitle = false
    var secRange = 0 ..< Rational(0)
}
extension Caption {
    enum FileType: FileTypeProtocol, CaseIterable {
        case itt
        var name: String {
            switch self {
            case .itt: "ITT"
            }
        }
        var utType: UTType {
            switch self {
            case .itt: UTType.init(filenameExtension: "itt")!
            }
        }
    }
    
    func move(sec: Rational) -> Self {
        var n = self
        n.secRange.start += sec
        return n
    }
    
    static let defaultPadding = 8.0, defaultOutlineWidth = 3.0
    func pathAndPosition(withFontSize fontSize: Double = Font.defaultSize,
                         in bounds: Rect,
                         padding: Double = defaultPadding) -> (path: Path, position: Point)? {
        let ratio = switch orientation {
        case .horizontal: bounds.width < 444 ? bounds.width / 444 : 1
        case .vertical: bounds.height < 330 ? bounds.height / 330 : 1
        }
        let fontSize =  (isTitle ? fontSize * 1.25 : fontSize) * ratio
        let padding = padding * ratio
        
        guard let tb = Text(string: string, size: fontSize,
                            widthCount: bounds.width).bounds else { return nil }
        switch orientation {
        case .horizontal:
            let tp = isTitle ?
            bounds.centerPoint + Point(-tb.width / 2, 0) :
            bounds.midXMinYPoint + Point(-tb.width / 2, padding + fontSize)
            
            let text = Text(string: string, size: fontSize, widthCount: bounds.width)
            var typebute = text.typobute
            typebute.font.isProportional = isTitle
            typebute.orientation = .horizontal
            typebute.maxTypelineWidth = .infinity
            typebute.alignment = .center
            let path = Typesetter(string: string, typobute: typebute).path()
            return (path, tp)
        case .vertical:
            let tp = isTitle ?
            bounds.centerPoint + Point(0, tb.width / 2) :
            bounds.maxXMidYPoint + Point(-padding - fontSize * 2, tb.width / 2)
            
            let text = Text(string: string, size: fontSize, widthCount: bounds.width)
            var typebute = text.typobute
            typebute.font.isProportional = isTitle
            typebute.orientation = .vertical
            typebute.alignment = .center
            typebute.maxTypelineWidth = .infinity
            let path = Typesetter(string: string, typobute: typebute).path()
            return (path, tp)
        }
    }
    
    static func cpuNodes(withFontSize fontSize: Double = Font.defaultSize,
                         in bounds: Rect,
                         padding: Double = defaultPadding,
                         outlineWidth: Double = defaultOutlineWidth,
                         from captions: [Caption]) -> [CPUNode] {
        captions
            .sorted {
                let s0 = $0.secRange.start, s1 = $1.secRange.start
                return s0 == s1 ? $0.origin.y > $1.origin.y : s0 < s1
            }
            .enumerated().flatMap { $0.element.cpuNodes(withFontSize: fontSize,
                                                        in: bounds,
                                                        padding: padding * .init($0.offset * 3 + 1),
                                                        outlineWidth: outlineWidth) }
    }
    func cpuNodes(withFontSize fontSize: Double, in bounds: Rect, padding: Double,
                  outlineWidth: Double) -> [CPUNode] {
        guard let (path, tp) = pathAndPosition(withFontSize: fontSize,
                                               in: bounds,
                                               padding: padding) else { return [] }
        return [.init(attitude: .init(position: tp), path: path,
                      lineWidth: outlineWidth, lineType: .color(.captionOutline)),
                .init(attitude: .init(position: tp), path: path,
                      fillType: .color(.background))]
    }
    
    static func nodes(withFontSize fontSize: Double = Font.defaultSize,
                      in bounds: Rect,
                      padding: Double = defaultPadding,
                      outlineWidth: Double = defaultOutlineWidth,
                      from captions: [Caption]) -> [Node] {
        captions
            .sorted {
                let s0 = $0.secRange.start, s1 = $1.secRange.start
                return s0 == s1 ? $0.origin.y > $1.origin.y : s0 < s1
            }
            .enumerated().flatMap { $0.element.nodes(withFontSize: fontSize,
                                                     in: bounds,
                                                     padding: padding * .init($0.offset * 3 + 1),
                                                     outlineWidth: outlineWidth) }
    }
    func nodes(withFontSize fontSize: Double,
               in bounds: Rect, padding: Double, outlineWidth: Double) -> [Node] {
        guard let (path, tp) = pathAndPosition(withFontSize: fontSize, in: bounds,
                                               padding: padding) else { return [] }
        return [.init(attitude: .init(position: tp), path: path,
                      lineWidth: outlineWidth, lineType: .color(.captionOutline)),
                .init(attitude: .init(position: tp), path: path,
                      fillType: .color(.background))]
    }
    
    static func captions(atSec sec: Rational, in captions: [Caption]) -> [Caption] {
        captions.filter { $0.secRange.contains(sec) }
    }
    static func captions(atFrame i: Int, frameRate: Int, startSec: Rational,
                         in captions: [Caption]) -> [Caption] {
        captions.filter {
            (Animation.frame(fromSec: $0.secRange.start + startSec, frameRate: frameRate)
             ..< Animation.frame(fromSec: $0.secRange.end + startSec, frameRate: frameRate))
                .contains(i)
        }
    }
}

extension AVFileType: FileTypeProtocol {
    var name: String { rawValue }
    var utType: UTType { UTType(UniformTypeIdentifiers.UTType(rawValue)!) }
}

final class MovieEncoder {
    enum FileType: FileTypeProtocol, CaseIterable {
        case mov, mp4
        var name: String {
            switch self {
            case .mov: "MOV (HEVC with Alpha)".localized
            case .mp4: "MP4 (H.264)"
            }
        }
        var utType: UTType {
            switch self {
            case .mov: AVFileType.mov.utType
            case .mp4: AVFileType.mp4.utType
            }
        }
    }
    
    private struct Setting {
        var loopCount = 1
        var soundTuples = [(startTime: Rational, inTimeRange: Range<Rational>, sound: Content)]()
        var time = Rational(), duration = Rational()
        
        var isEmpty: Bool {
            loopCount <= 1 && soundTuples.isEmpty
        }
        var loopedDuration: Rational {
            duration * Rational(loopCount)
        }
    }
    
    static let exportingError = NSError(domain: AVFoundationErrorDomain,
                                        code: AVError.Code.exportFailed.rawValue)
    
    let url: URL
    let fileType: AVFileType, codec: AVVideoCodecType
    let renderSize: Size, isHDR: Bool
    let sampleRate = Audio.defaultSampleRate, audioChannelCount = 2
    private let colorSpace: CGColorSpace, colorSpaceProfile: CFData
    private let writer: AVAssetWriter
    private let videoInput: AVAssetWriterInput
    private let audioInput: AVAssetWriterInput?
    private let pbReceiver: AVAssetWriterInput.PixelBufferReceiver
    private let audioSBReceiver: AVAssetWriterInput.SampleBufferReceiver?
    let isEnabledAudio, isAlphaChannel: Bool
    
    private var isAppend = true, isStop = false
    private var settings = [Setting](), currentTime = CMTime(value: 0, timescale: 1)
    
    init(url: URL, renderSize: Size, isAlphaChannel: Bool,
         _ colorSpace: ColorSpace, frameRate: Int,
         isEnabledAudio: Bool, isLinearPCM: Bool) throws {
        self.url = url
        self.renderSize = renderSize
        
        isHDR = colorSpace.isHDR
        fileType = isAlphaChannel ? AVFileType.mov : AVFileType.mp4
        codec = isAlphaChannel ?
        AVVideoCodecType.hevcWithAlpha :
        (isHDR ? AVVideoCodecType.hevc : AVVideoCodecType.h264)
        
         guard let colorSpace = isHDR ?
                CGColorSpace.itur2020HLGColorSpace : CGColorSpace.sRGBColorSpace,
              let colorSpaceProfile = colorSpace.copyICCData() else { throw Self.exportingError }
        self.colorSpace = colorSpace
        self.colorSpaceProfile = colorSpaceProfile
        self.isAlphaChannel = isAlphaChannel
        self.isEnabledAudio = isEnabledAudio
        
        try FileManager.default.removeItemIfFileExists(url)
        
        writer = try AVAssetWriter(outputURL: url, fileType: fileType)
        let width = Int(renderSize.width), height = Int(renderSize.height)
        let setting: [String: Any] = isHDR ?
            [AVVideoCodecKey: codec,
             AVVideoWidthKey: width,
             AVVideoHeightKey: height,
             AVVideoColorPropertiesKey: [AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_2020,
                                         AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_2100_HLG,
                                         AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_2020],
             AVVideoCompressionPropertiesKey: [AVVideoProfileLevelKey: kVTProfileLevel_HEVC_Main10_AutoLevel,
                                               AVVideoExpectedSourceFrameRateKey: frameRate]]
            : [AVVideoCodecKey: codec,
               AVVideoWidthKey: width,
               AVVideoHeightKey: height,
               AVVideoColorPropertiesKey: [AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
                                           AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
                                           AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2],
               AVVideoCompressionPropertiesKey: [AVVideoExpectedSourceFrameRateKey: frameRate]]
        
        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: setting)
        
        if isEnabledAudio {
            let audioSettings = Sequencer.audioSettings(isLinearPCM: isLinearPCM,
                                                        channelCount: audioChannelCount,
                                                        sampleRate: sampleRate)
            let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            audioInput.languageCode = nil
            self.audioInput = audioInput
        } else {
            audioInput = nil
        }
        
        let pixelBufferAttributes = isHDR ?
        CVPixelBufferCreationAttributes(pixelFormatType: .init(rawValue: kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange),
                                        size: .init(width: width, height: height)) :// AVFondation or Core Image bug?: height % 2 == 0 ? height + 1 : height
        CVPixelBufferCreationAttributes(pixelFormatType: .init(rawValue: kCVPixelFormatType_32ARGB),
                                        size: .init(width: width, height: height),
                                        compatibility: [.cgBitmapContext])
        if isEnabledAudio, let audioInput {
            (pbReceiver, _) = writer.inputPixelBufferReceiverRequestingMultiPass(for: videoInput,
                                                                                 pixelBufferAttributes: pixelBufferAttributes)
            (audioSBReceiver, _) = writer.inputReceiverRequestingMultiPass(for: audioInput)
        } else {
            pbReceiver = writer.inputPixelBufferReceiver(for: videoInput,
                                                         pixelBufferAttributes: pixelBufferAttributes)
            audioSBReceiver = nil
        }
        
        try writer.start()
        writer.startSession(atSourceTime: .zero)
    }
    
    func write(_ image: Image, duration: Int, timeScale: Int) async throws {
        guard let bufferPool = pbReceiver.pixelBufferPool else { throw Self.exportingError }
        let pixelBuffer = try bufferPool.makeMutablePixelBuffer()
        pixelBuffer.withUnsafeBuffer { pb in
            if isAlphaChannel {
                CVBufferSetAttachment(pb,
                                      kCVImageBufferAlphaChannelModeKey,
                                      kCVImageBufferAlphaChannelMode_PremultipliedAlpha,
                                      .shouldPropagate)
            }
            CVBufferSetAttachment(pb,
                                  kCVImageBufferICCProfileKey,
                                  colorSpaceProfile,
                                  .shouldPropagate)
            CVPixelBufferLockBaseAddress(pb,
                                         CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
            
            if isHDR {
                let ciImage = CIImage(cgImage: image.cg)
                let ctx = CIContext(options: [.workingColorSpace: colorSpace])
                ctx.render(ciImage, to: pb)
            } else {
                let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
                if let ctx
                    = CGContext(data: CVPixelBufferGetBaseAddress(pb),
                                width: CVPixelBufferGetWidth(pb),
                                height: CVPixelBufferGetHeight(pb),
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(pb),
                                space: colorSpace,
                                bitmapInfo: bitmapInfo.rawValue) {
                    if isAlphaChannel {
                        ctx.clear(.init(x: 0, y: 0, width: ctx.width, height: ctx.height))
                    }
                    ctx.draw(image.cg,
                             in: CGRect(x: 0, y: 0,
                                        width: image.size.width,
                                        height: image.size.height))
                }
            }
            
            CVPixelBufferUnlockBaseAddress(pb,
                                           CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        }
        if currentTime.value == 0 {
            currentTime = .init(value: 0, timescale: .init(timeScale))
        }
        try await pbReceiver.append(.init(pixelBuffer), with: currentTime)
        
        currentTime = currentTime + .init(value: .init(duration), timescale: .init(timeScale))
    }
    
    func writeAudio(from seq: Sequencer,
                    progressHandler: (Double) throws -> ()) async throws {
        guard let audioSBReceiver else { throw Self.exportingError }
        let buffer = try seq.buffer(sampleRate: sampleRate, progressHandler: progressHandler)
        guard let cmBuffer = buffer.cmSampleBuffer() else { throw Self.exportingError }
        try await audioSBReceiver.append(.init(unsafeBuffer: cmBuffer))
    }
    
    func cancel() {
        writer.cancelWriting()
    }
    func finish() async throws {
        writer.endSession(atSourceTime: currentTime)
        videoInput.markAsFinished()
        audioInput?.markAsFinished()
        await writer.finishWriting()
        if let error = writer.error { throw error }
    }
}

extension Caption {
    static func avCaptions(from captions: [Caption], frameRate: Int,
                           deltaSec: Rational) -> [AVCaption] {
        captions.map { caption in
            let startTime = (caption.secRange.start + deltaSec)
                .cm(timescale: Int32(frameRate))
            let duration = caption.secRange.length.cm(timescale: Int32(frameRate))
            let range = CMTimeRange(start: startTime, duration: duration)
            let avCaption = AVMutableCaption(caption.string, timeRange: range)
            avCaption.region = caption.orientation == .vertical ? .appleITTRight : .appleITTBottom
            return avCaption
        }
    }
}

final class CaptionEncoder {
    let url: URL, frameRate: Int
    private let writer: AVAssetWriter,
                captionInput: AVAssetWriterInput,
                captionReceiver: AVAssetWriterInput.CaptionReceiver
    private var currentSec = Rational()
    
    init(url: URL, frameRate: Int) throws {
        self.url = url
        self.frameRate = frameRate
        
        try FileManager.default.removeItemIfFileExists(url)
        
        writer = try AVAssetWriter(outputURL: url, fileType: .appleiTT)
        captionInput = AVAssetWriterInput(mediaType: .text,
                                          outputSettings: [AVCaptionSettingsKey.timeCodeFrameDuration.rawValue: CMTime(value: 1, timescale: CMTimeScale(frameRate))])
        captionInput.languageCode = Locale.current.language.languageCode?.identifier
        captionReceiver = writer.inputCaptionReceiver(for: captionInput)
        
        try writer.start()
        writer.startSession(atSourceTime: .zero)
    }
    
    func write(captions: [Caption], duration: Rational = Rational(),
               progressHandler: (Double) throws -> ()) async throws {
        let avCaptions = Caption.avCaptions(from: captions, frameRate: frameRate,
                                            deltaSec: currentSec)
        for (i, avCaption) in avCaptions.enumerated() {
            try await captionReceiver.append(avCaption)
            try progressHandler(Double(i + 1) / Double(avCaptions.count))
        }
        currentSec += duration
    }
    func cancel() {
        writer.cancelWriting()
    }
    func finish() async throws {
        captionInput.markAsFinished()
        writer.endSession(atSourceTime: currentSec.cm(timescale: CMTimeScale(frameRate)))
        await writer.finishWriting()
        if let error = writer.error { throw error }
    }
}

extension Rational {
    fileprivate func cm(timescale: CMTimeScale) -> CMTime {
        CMTime(value: CMTimeValue(p * Int(timescale) / q),
               timescale: timescale)
    }
}
extension Double {
    fileprivate func cm(timescale: CMTimeScale) -> CMTime {
        CMTime(value: CMTimeValue(self * Double(timescale)),
               timescale: timescale)
    }
}
extension Range where Bound == Rational {
    fileprivate func cm(timescale: CMTimeScale) -> CMTimeRange {
        CMTimeRange(start: start.cm(timescale: timescale),
                    duration: length.cm(timescale: timescale))
    }
}
extension Range where Bound == Double {
    fileprivate func cm(timescale: CMTimeScale) -> CMTimeRange {
        CMTimeRange(start: start.cm(timescale: timescale),
                    duration: length.cm(timescale: timescale))
    }
}

extension MovieEncoder {
    static func m4aFromMP4(from fromUrl: URL, to toUrl: URL,
                           isRemoveFromUrl: Bool = true) async throws {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: toUrl.path) {
            try fileManager.removeItem(at: toUrl)
        }
        
        let asset = AVURLAsset(url: fromUrl)
        guard let session = AVAssetExportSession(asset: asset,
                                                 presetName: AVAssetExportPresetPassthrough)
        else { throw Self.exportingError }
        try await session.export(to: toUrl, as: .m4a)
        if isRemoveFromUrl {
            try fileManager.removeItem(at: fromUrl)
        }
    }
}

@MovieActor final class MovieImageGenerator {
    nonisolated(unsafe) private var generator: AVAssetImageGenerator
    
    init(url: URL) {
        let asset = AVURLAsset(url: url)
        generator = AVAssetImageGenerator(asset: asset)
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
    }
    func thumbnail(atSec sec: Rational = .init(0, 1)) async throws -> Image {
        let cgImage = try await generator.image(at: .init(value: .init(sec.p), timescale: .init(sec.q))).image
        return Image(cgImage: cgImage)
    }
}
extension MovieEncoder {
    static func size(from url: URL) async throws -> Size? {
        let asset = AVURLAsset(url: url)
        return try await asset.load(.tracks).first?.load(.naturalSize).my
    }
    static func durSec(from url: URL) async throws -> Rational {
        let asset = AVURLAsset(url: url)
        return try await asset.load(.duration).my
    }
    static func frameRate(from url: URL) async throws -> Float? {
        let asset = AVURLAsset(url: url)
        return try await asset.load(.tracks).first?.load(.nominalFrameRate)
    }
}

extension CMTime {
    var my: Rational {
        .init(Int(value), Int(timescale))
    }
}

extension MovieEncoder {
    static func toMP4(from url: URL, to outputURL: URL) async throws {
        let asset = AVURLAsset(url: url)
        
        let mTracks = try await asset.loadTracks(withMediaType: .video)
        guard !mTracks.isEmpty else { throw Self.exportingError }
        let aTracks = try await asset.loadTracks(withMediaType: .audio)
        
        let comp = AVMutableComposition()
        
        guard let nmTrack = comp.addMutableTrack(withMediaType: .video,
                                                 preferredTrackID: kCMPersistentTrackID_Invalid)
        else { throw Self.exportingError }
        
        for mTrack in mTracks {
            guard let timeRange = try? await mTrack.load(.timeRange) else { continue }
            try? nmTrack.insertTimeRange(timeRange, of: mTrack, at: CMTime())
        }
        
        if !aTracks.isEmpty, let naTrack = comp.addMutableTrack(withMediaType: .audio,
                                                                preferredTrackID: kCMPersistentTrackID_Invalid) {
            for aTrack in aTracks {
                guard let timeRange = try? await aTrack.load(.timeRange) else { continue }
                try? naTrack.insertTimeRange(timeRange, of: aTrack, at: CMTime())
            }
        }
        
        guard let session = AVAssetExportSession(asset: comp,
                                                 presetName: AVAssetExportPresetHighestQuality)
        else { throw Self.exportingError }
        try await session.export(to: outputURL, as: .mp4)
        try FileManager.default.removeItem(at: url)
    }
}

final class MoviePlayer {
    struct MoviePlayerError: Error {}
    static func images(url: URL, handler: (Double, CGImage) -> ()) async throws {
        let asset = AVURLAsset(url: url)
        
        let reader = try AVAssetReader(asset: asset)
        let vTracks = try await asset.loadTracks(withMediaType: .video)
        guard let videoTrack = vTracks.first else { throw MoviePlayerError() }
        let fps = Double(try await videoTrack.load(.nominalFrameRate))
        
        let outputSettings = [String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32ARGB)]
        let readerTrackOutput = AVAssetReaderTrackOutput(track: videoTrack,
                                                         outputSettings: outputSettings)
        let (arop, rac) = reader.outputProviderWithRandomAccess(for: readerTrackOutput)
        try reader.start()
        
        var time = 0.0
        while let sampleBuffer = try await arop.next() {
            switch sampleBuffer.content {
            case .pixelBuffer(let rpb):
                rpb.withUnsafeBuffer { pb in
                    let ciImage = CIImage(cvPixelBuffer: pb)
                    let b = CGRect(x: 0, y: 0,
                                   width: CVPixelBufferGetWidth(pb),
                                   height: CVPixelBufferGetHeight(pb))
                    let ctx = CIContext()
                    if let cgImage = ctx.createCGImage(ciImage, from: b) {
                        handler(time, cgImage)
                    }
                }
            default: break
            }
            time += 1 / fps
        }
        rac.markConfigurationAsFinal()
        reader.cancelReading()
    }
}
