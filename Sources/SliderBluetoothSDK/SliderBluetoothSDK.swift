import Foundation

public class SliderBluetoothSDK {
    let manager: BLEManager

    public init() {
        manager = BLEManager()
    }

    public func start() {
        manager.startScan()
    }

}

extension SliderBluetoothSDK: BLEManagerDelegate {

    func didUpdateValue(_ value: Data) {
        log(message: "Did update value: \(value)", type: .info)
    }
}
