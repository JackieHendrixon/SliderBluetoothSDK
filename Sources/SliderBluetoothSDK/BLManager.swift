//
//  File.swift
//  
//
//  Created by Frankie on 09/03/2022.
//

import Foundation
import CoreBluetooth

protocol BLEManagerDelegate: AnyObject {
    func didUpdateValue(_ value: Data)
}

final class BLEManager: NSObject {

    private let centralManager: CBCentralManager
    private var discoveredPeripherals: [CBPeripheral] = []
    private var connectedPeripheral: CBPeripheral?
    private var characteristics: [CBCharacteristic] = []
    var delegate: BLEManagerDelegate?

    init(centralManager: CBCentralManager = CBCentralManager()) {
        self.centralManager = centralManager
        super.init()
        centralManager.delegate = self
    }

    func startScan() {
        log(message: "Scanning started", type: .info)
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }

    func connect(peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: nil)
    }

    func discoverServices(peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }

    func discoverCharacteristics(peripheral: CBPeripheral) {
        guard let services = peripheral.services else {
            return
        }

        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func readValue(characteristic: CBCharacteristic) {
        connectedPeripheral?.readValue(for: characteristic)
    }

    func write(value: Data, characteristic: CBCharacteristic) {
        connectedPeripheral?.writeValue(value, for: characteristic, type: .withResponse)
    }

    func disconnect() {
        guard let connectedPeripheral = connectedPeripheral else {
            return
        }
        centralManager.cancelPeripheralConnection(connectedPeripheral)
    }
}

extension BLEManager: CBCentralManagerDelegate {

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        log(message: "didDiscoverPeripheral - name: \(peripheral.name ?? "Unknown")", type: .info)
        discoveredPeripherals.append(peripheral)
        if let name = peripheral.name, name.contains("MSF") {
            connect(peripheral: peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log(message: "didConnect", type: .info)
        connectedPeripheral = peripheral
        peripheral.delegate = self
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
            startScan()
        @unknown default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error = error  {
            log(error: error)
            return
        }
    }
}

extension BLEManager: CBPeripheralDelegate {

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
        delegate?.didUpdateValue(value)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error  {
            log(error: error)
            return
        }
    }
}

extension BLEManager {
    struct FailedToConnectError: Error {}
}
