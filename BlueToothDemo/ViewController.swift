//
//  ViewController.swift
//  BlueToothDemo
//
//  Created by Gavin on 16/2/17.
//  Copyright © 2016年 Gavin. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate ,CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource{

    @IBOutlet weak var tableView: UITableView!
    
    var manager:CBCentralManager? //主设备
    var devices:[CBPeripheral]? = [] //设备列表
    
    var identifires:[String]?=[]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manager = CBCentralManager(delegate: self, queue: dispatch_get_main_queue())
        // Do any additional setup after loading the view, typically from a nib.
    }
    //写入数据
    func writeCharacteristic(peripheral:CBPeripheral, characteristic:CBCharacteristic,value:NSData){
        
        //只有 characteristic.properties 有write的权限才可以写
        if characteristic.properties.contains(CBCharacteristicProperties.Write) {
            peripheral.writeValue(value, forCharacteristic: characteristic, type: CBCharacteristicWriteType.WithResponse)
        }else{
            print("该字段不可写")
        }
    }
    //设置通知
    func notifyCharacteristic(peripheral:CBPeripheral, characteristic:CBCharacteristic){
        peripheral.setNotifyValue(true, forCharacteristic: characteristic)
    }
    //取消通知
    func cancelNotifyCharacteristic(peripheral:CBPeripheral, characteristic:CBCharacteristic){
        peripheral.setNotifyValue(false, forCharacteristic: characteristic)
    }
    
    //断开连接
    func disconnectPeripheral(manager:CBCentralManager,peripheral:CBPeripheral)
    {
        manager.stopScan()
        manager.cancelPeripheralConnection(peripheral)
    }
    //TODO:ManagerDelegate
    
    //状态改变
    func centralManagerDidUpdateState(central: CBCentralManager)
    {
        print("状态发生改变：state\(central.state)")
        switch central.state {
        case CBCentralManagerState.Unknown:
            print("unknown device：state\(central.state)")
        case CBCentralManagerState.PoweredOn:
            manager?.scanForPeripheralsWithServices(nil, options: nil)
        case CBCentralManagerState.PoweredOff:
            print("电源关闭")
        case CBCentralManagerState.Unsupported:
            print("不支持的设备")
        case CBCentralManagerState.Unauthorized:
            print("授权失败")
        default:
            print("--------")
        }
    }
    //发现设备
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber)
    {
        print("发现设备：\(peripheral.name),\(peripheral.identifier)")
        if identifires?.contains(peripheral.identifier.UUIDString) == false{
            identifires?.append(peripheral.identifier.UUIDString)
            devices?.append(peripheral)
        }
        tableView.reloadData()
//        manager?.connectPeripheral(peripheral, options: nil)
    }
    
    //连接成功
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral)
    {
        print("连接\(peripheral.name)成功")
        peripheral.discoverServices(nil)
        tableView.reloadData()
    }
    //连接失败
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?)
    {
        print("连接\(peripheral.name)失败")
        tableView.reloadData()
        
    }
    //断开连接
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?)
    {
        print("连接\(peripheral.name)断开")
    }
    
    //TODO:peripheralDelegate
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?){
        for service:CBService? in peripheral.services! {
            print("service id ==  \(service!.UUID)")
            peripheral.discoverCharacteristics(nil, forService: service!)
        };
        print("开始连接设备")
    }
    //扫描到Characteristics
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?){
        if error != nil {
            print("error Discovered characteristics for \(service.UUID) with error: \(error?.description)")
        }
        for character:CBCharacteristic? in service.characteristics! {
            print("service:\(service.UUID) 的 Characteristic: \(character?.UUID)")
            peripheral.readValueForCharacteristic(character!)
            peripheral.discoverDescriptorsForCharacteristic(character!)
        }
        
    }
    //获取的charateristic的值
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?)
    {
        print("Characteristic: \(characteristic.UUID)")
        
    }
    //搜索到Characteristic的Descriptors
    func peripheral(peripheral: CBPeripheral, didDiscoverDescriptorsForCharacteristic characteristic: CBCharacteristic, error: NSError?)
    {
        print("Characteristic: \(characteristic.UUID)")

        for descriptor:CBDescriptor? in characteristic.descriptors! {
            print("Descriptor uuid: \(descriptor?.UUID)");
        }
    }
    //获取到Descriptors的值
    func peripheral(peripheral: CBPeripheral, didUpdateValueForDescriptor descriptor: CBDescriptor, error: NSError?)
    {
        print("characteristic uuid: \(descriptor.UUID) value :\(descriptor.value)");
    }
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1;
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return (devices?.count)!
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")
        let device = (devices?[indexPath.row])! as CBPeripheral?
        let title = device!.name;
        let descr = device?.identifier.UUIDString;
        cell?.textLabel?.text = title
        cell?.detailTextLabel?.text = descr
        if device?.state == CBPeripheralState.Connected || device?.state == CBPeripheralState.Connecting{
            cell?.accessoryType = UITableViewCellAccessoryType.Checkmark
        }else{
            cell?.accessoryType = UITableViewCellAccessoryType.None
        }
        return cell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let device = (devices?[indexPath.row])! as CBPeripheral?
        manager?.connectPeripheral(device!, options: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

