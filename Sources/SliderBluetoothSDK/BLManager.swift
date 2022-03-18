//
//  File.swift
//  
//
//  Created by Frankie on 09/03/2022.
//

import Foundation
import CoreBluetooth

private struct Constants {

}

protocol BLEManagerDelegate: AnyObject {
    func didConnect()
    func didDisonnect()
    func didUpdateValue(_ value: Data)
}

protocol BLEManager {
    var delegate: BLEManagerDelegate? { get set }
    func startScan()
    func connect(peripheral: CBPeripheral)
    func readValue(characteristic: CBCharacteristic)
    func write(value: Data, characteristic: CBCharacteristic)
    func _testWrite(value: Data)
    func disconnect()
}

final class BLEManagerImpl: NSObject {

    private let centralManager: CBCentralManager
    private var discoveredPeripherals: [CBPeripheral] = []
    private var connectedPeripheral: CBPeripheral?
    var characteristics: [CBCharacteristic] = []
    var delegate: BLEManagerDelegate?

    init(centralManager: CBCentralManager = CBCentralManager()) {
        self.centralManager = centralManager
        super.init()
        centralManager.delegate = self
    }
}

extension BLEManagerImpl: BLEManager {

    func startScan() {
        log(message: "Scanning started", type: .info)
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }

    func connect(peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: nil)
    }

    func readValue(characteristic: CBCharacteristic) {
        connectedPeripheral?.readValue(for: characteristic)
    }

    func write(value: Data, characteristic: CBCharacteristic) {
        connectedPeripheral?.writeValue(value, for: characteristic, type: .withResponse)
    }

    func _testWrite(value: Data) {
        log(message: "_testWrite: \(value)", type: .info)
        guard let testCharacteristic = characteristics.first(where: { $0.properties.contains(.write) }) else { return }
        connectedPeripheral?.writeValue(value, for: testCharacteristic, type: .withResponse)
    }

    func disconnect() {
        guard let connectedPeripheral = connectedPeripheral else {
            return
        }
        centralManager.cancelPeripheralConnection(connectedPeripheral)
    }
}

private extension BLEManagerImpl {

    private func discoverServices(peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }

    private func discoverCharacteristics(peripheral: CBPeripheral) {
        guard let services = peripheral.services else {
            return
        }

        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
}

extension BLEManagerImpl: CBCentralManagerDelegate {

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        log(message: "didDiscoverPeripheral - name: \(peripheral.name ?? "Unknown")", type: .info)
        discoveredPeripherals.append(peripheral)
        if let name = peripheral.name, name.contains("MSF") {
            connect(peripheral: peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log(message: "didConnect - name: \(peripheral.name ?? "Unknown")", type: .info)
        connectedPeripheral = peripheral
        peripheral.delegate = self
        delegate?.didConnect()
        centralManager.stopScan()
        discoverServices(peripheral: peripheral)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let error = FailedToConnectError()
        log(error: error)

    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            break
        case .resetting:
            break
        case .unsupported:
            break
        case .unauthorized:
            break
        case .poweredOff:
            break
        case .poweredOn:
            break
        @unknown default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error = error  {
            log(error: error)
            return
        }
        delegate?.didDisonnect()
    }
}

extension BLEManagerImpl: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            return
        }
        log(message: "didDiscoverServices: \(services)", type: .info)
        discoverCharacteristics(peripheral: peripheral)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            return
        }
        log(message: "didDiscoverCharacteristics: \(characteristics)", type: .info)
        self.characteristics.append(contentsOf: characteristics)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error  {
            log(error: error)
            return
        }
        guard let value = characteristic.value else {
            return
        }
        log(message: "didUpdateValue: \(value)", type: .info)
        delegate?.didUpdateValue(value)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        log(message: "didWrite", type: .info)
        if let error = error  {
            log(error: error)
            return
        }
    }
}

extension BLEManagerImpl {
    struct FailedToConnectError: Error {}
}
