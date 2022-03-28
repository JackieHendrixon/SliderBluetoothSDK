//
//  BLEService.swift
//  
//
//  Created by Frankie on 09/03/2022.
//

import Foundation
import CoreBluetooth

private extension CBUUID {
    static let serviceUUID = CBUUID(string: "0EE0D511-CF55-4E35-9A09-897A737B7C17")
    static let writeCharacteristicUUID = CBUUID(string: "1EE0D511-CF55-4E35-9A09-897A737B7C17")
    static let notifyCharacteristicUUID = CBUUID(string: "2EE0D511-CF55-4E35-9A09-897A737B7C17")
}

protocol BLEServiceDelegate: AnyObject {
    func didConnect()
    func didDisonnect()
    func didUpdateValue(_ value: Data)
}

protocol BLEService {
    var delegate: BLEServiceDelegate? { get set }
    var isConnected: Bool { get }
    func start()
    func readValue(characteristic: CBCharacteristic)
    func write(value: Data)
    func disconnect()
}

final class BLEServiceImpl: NSObject {

    private let centralManager: CBCentralManager
    private var discoveredPeripherals: [CBPeripheral] = []
    private var connectedPeripheral: CBPeripheral?
    private var characteristics: [CBCharacteristic] = []
    var delegate: BLEServiceDelegate?
    var isConnected: Bool {
        connectedPeripheral != nil
    }

    init(centralManager: CBCentralManager = CBCentralManager()) {
        self.centralManager = centralManager
        super.init()
        centralManager.delegate = self
    }
}

extension BLEServiceImpl: BLEService {

    func start() {
        guard centralManager.state == .poweredOn else {
            return
        }
        log(message: "Scanning started..", type: .info)
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }

    func readValue(characteristic: CBCharacteristic) {
        connectedPeripheral?.readValue(for: characteristic)
    }

    func write(value: Data) {
        log(message: "Write data: \(value.hexDesription)", type: .write)
        guard let characteristic = characteristics.first(where: { $0.uuid == .writeCharacteristicUUID }) else {
            return
        }
        connectedPeripheral?.writeValue(value, for: characteristic, type: .withResponse)
    }

    func disconnect() {
        guard let connectedPeripheral = connectedPeripheral else {
            return
        }
        centralManager.cancelPeripheralConnection(connectedPeripheral)
    }
}

private extension BLEServiceImpl {

    private func connect(peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: nil)
    }

    private func discoverServices(peripheral: CBPeripheral) {
        peripheral.discoverServices([.serviceUUID])
    }

    private func discoverCharacteristics(peripheral: CBPeripheral) {
        guard let services = peripheral.services else {
            return
        }

        for service in services {
            peripheral.discoverCharacteristics([.writeCharacteristicUUID, .notifyCharacteristicUUID],
                                               for: service)
        }
    }
}

extension BLEServiceImpl: CBCentralManagerDelegate {

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        log(message: "didDiscoverPeripheral - name: \(peripheral.name ?? "Unknown")", type: .info)
        discoveredPeripherals.append(peripheral)
        guard let name = peripheral.name, name.contains("MSF") else { return }
        connect(peripheral: peripheral)
    }

    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        log(message: "didConnect - name: \(peripheral.name ?? "Unknown")", type: .info)
        connectedPeripheral = peripheral
        peripheral.delegate = self
        delegate?.didConnect()
        discoverServices(peripheral: peripheral)
        centralManager.stopScan()
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        let error = FailedToConnectError()
        log(error: error)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        log(message: "didUpdateState: \(central.state.description)", type: .info)
        switch central.state {
        case .unknown:
            break
        case .resetting:
            break
        case .unsupported:
            log(message: "Bluetooth is not supported on this device.", type: .error)
        case .unauthorized:
            log(message: "Bluetooth is not authorized.", type: .error)
        case .poweredOff:
            log(message: "Bluetooth is turned off.", type: .error)
        case .poweredOn:
            break
        @unknown default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        if let error = error  {
            log(error: error)
            return
        }
        connectedPeripheral = nil
        delegate?.didDisonnect()
    }
}

extension BLEServiceImpl: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            return
        }
        log(message: "didDiscoverServices: \(services)", type: .info)
        discoverCharacteristics(peripheral: peripheral)
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard let characteristics = service.characteristics else {
            return
        }
        log(message: "didDiscoverCharacteristics: \(characteristics)", type: .info)
        self.characteristics.append(contentsOf: characteristics)
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if let error = error  {
            log(error: error)
            return
        }
        guard let value = characteristic.value else {
            return
        }
        log(message: "Received data: \(value.hexDesription)", type: .read)
        delegate?.didUpdateValue(value)
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if let error = error  {
            log(error: error)
            return
        }
        log(message: "didWrite", type: .info)
    }
}

extension BLEServiceImpl {
    struct FailedToConnectError: Error {}
}
