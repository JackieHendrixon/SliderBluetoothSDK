import Foundation

public class SliderBluetoothSDK {
    private let bleManager: BLEManager
    public let slider: Slider
    var isConnected = false

    public init() {
        bleManager = BLEManagerImpl()
        slider = SliderImpl(bleManager: bleManager)
    }

    public func start() {
        bleManager.startScan()
    }

    public func write(value: Data) {
        bleManager._testWrite(value: value)
    }
}

extension SliderBluetoothSDK: BLEManagerDelegate {

    func didConnect() {
        isConnected = true
    }

    func didDisonnect() {
        isConnected = false
    }

    func didUpdateValue(_ value: Data) {
        log(message: "Did update value: \(value)", type: .info)
    }
}
