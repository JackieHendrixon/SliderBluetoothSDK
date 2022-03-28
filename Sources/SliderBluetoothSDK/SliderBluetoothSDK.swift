import Foundation

public class SliderBluetoothSDK {
    private let bleService: BLEService
    public let slider: Slider

    public var isConnected: Bool {
        bleService.isConnected
    }

    public init() {
        bleService = BLEServiceImpl()
        slider = SliderImpl(bleService: bleService)
    }

    public func start() {
        bleService.start()
    }

    public func write(value: Data) {
        bleService.write(value: value)
    }

    public func disconnect() {
        bleService.disconnect()
    }
}

extension SliderBluetoothSDK: BLEServiceDelegate {

    func didConnect() {
    }

    func didDisonnect() {
    }

    func didUpdateValue(_ value: Data) {
    }
}
