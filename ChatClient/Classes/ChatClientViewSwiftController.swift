//
//  ChatClientViewSwiftController.swift
//  ChatClient
//
//  Created by KHUN NINE on 11/2/15.
//
//

import Foundation
import UIKit

class ChatClientViewSwiftController: UIViewController, NSStreamDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var inputNameField: UITextField!
    @IBOutlet weak var inputMessageField: UITextField!
    @IBOutlet weak var tView: UITableView!
    
    var inputStream: NSInputStream!
    var outputStream: NSOutputStream!
    var messages: [String]!
    
    override func viewDidLoad() {
        
        initNetworkCommunication()
        inputNameField.text = "iOS Device"
        
        messages = [String]();
        
        self.tView.delegate = self;
        self.tView.dataSource = self;
    }
    
    // READ MORE: stackoverflow.com/questions/24028995/toll-free-bridging-and-pointer-access-in-swift
    func initNetworkCommunication () {
        
        let serverAddress: CFString = "localhost"
        let serverPort: UInt32 = 80
        
        var readStream:  Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        
        CFStreamCreatePairWithSocketToHost(nil, serverAddress, serverPort, &readStream, &writeStream)
        
        self.inputStream = readStream!.takeRetainedValue()
        self.outputStream = writeStream!.takeRetainedValue()
        
        self.inputStream.delegate = self
        self.outputStream.delegate = self
        
        self.inputStream.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        self.outputStream.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        
        self.inputStream.open()
        self.outputStream.open()
        
    }
    
    @IBAction func joinChat () {
        
        let response: String = "iam:" + inputNameField.text!
        let data: NSData = NSData(data: response.dataUsingEncoding(NSASCIIStringEncoding)!)
        outputStream.write(UnsafePointer(data.bytes), maxLength: data.length)
        
    }
    
    
    @IBAction func sendMessage () {
        
        let response: String = "msg:" + inputMessageField.text!
        let data: NSData = NSData(data: response.dataUsingEncoding(NSASCIIStringEncoding)!)
        outputStream.write(UnsafePointer(data.bytes), maxLength: data.length)
        inputMessageField.text = "";
        
    }
    
    
    // READ MORE: stackoverflow.com/questions/26360962/receiving-data-from-nsinputstream-in-swift
    func stream(stream: NSStream, handleEvent streamEvent: NSStreamEvent) {
        
        print("stream event \(streamEvent)");
        
        switch (streamEvent) {
            
        case NSStreamEvent.OpenCompleted:
            
            print("Stream opened")
            break;
            
        case NSStreamEvent.HasBytesAvailable:
            
            print("HasBytesAvaible")
            if (stream == inputStream){
                var buffer = [UInt8](count: 4096, repeatedValue: 0)
                while (inputStream.hasBytesAvailable){
                    let len = inputStream.read(&buffer, maxLength: buffer.count)
                    if(len > 0){
                        let output = NSString(bytes: &buffer, length: buffer.count, encoding: NSUTF8StringEncoding)
                        if (output != ""){
                            print("server said: \(output!)")
                            self.messageReceived(output as! String)
                        }
                    }
                }
            }
            break
            
        case NSStreamEvent.ErrorOccurred:
            
            print("Can not connect to the host!");
            break;
            
        case NSStreamEvent.EndEncountered:
            
            stream.close()
            stream.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
            break;
            
        default:
            
            print("Unknown event");
            
        }
        
    }
    
    func messageReceived (message: String) {
        
        messages.append(message)
        self.tView.reloadData()
        
        let topIndexPath: NSIndexPath = NSIndexPath(forRow: messages.count-1, inSection: 0)
        self.tView.scrollToRowAtIndexPath(topIndexPath, atScrollPosition: UITableViewScrollPosition.Middle, animated: true)
        
    }
    
    // MARK: - Table view delegate
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let msg = messages[indexPath.row]
        let cellIdentifier = "ChatCellIdentifier"
        
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
        
        if (cell == nil) {
            cell = UITableViewCell(style: .Default, reuseIdentifier: cellIdentifier)
        }
        
        cell?.textLabel?.text = msg
        
        return cell!
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
}
