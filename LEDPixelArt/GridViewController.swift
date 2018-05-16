//
//  ViewController.swift
//  LEDPixelArt
//
//  Created by Florian Sorin on 07/02/2017.
//  Copyright © 2017 Florian Sorin. All rights reserved.
//

import UIKit
import CoreBluetooth
import QuartzCore

struct pixelArtData {
    var pixelArtName = "PixelArt"
    var pixelArtGrid = Array(repeating: UInt8(), count: 1024)
    var pixelArtPreview = #imageLiteral(resourceName: "save")
}

var pixelArtDB = [pixelArtData]()
var pixelArtDBSize = 0
var RGBGridArray = Array(repeating: UInt8(), count: 1024)


// Functions to save and load files (used for UIImage)
func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
}
func saveImage(image: UIImage, imageName: String) {
    let fileURL = getDocumentsDirectory().appendingPathComponent(imageName)
    let pngImageData = UIImagePNGRepresentation(image)
    try? pngImageData!.write(to: fileURL)
}
func loadImageFromPath(imageName: String) -> UIImage? {
    let fileURL = getDocumentsDirectory().appendingPathComponent(imageName)
    let image = UIImage(contentsOfFile: fileURL.path)
    return image
}

// Call when the app is launch to recover saved infos
func checkMemory() {
    let defaults = UserDefaults.standard

    if let pixelArtDBSizeMemorized = defaults.object(forKey: "pixelArtDBSizeKey") as? Int {
        pixelArtDBSize = pixelArtDBSizeMemorized
    }

    if pixelArtDBSize != 0 {
        for i in 0...pixelArtDBSize - 1 {
            pixelArtDB.append(pixelArtData())
            
            if let nameMemorized = defaults.object(forKey: "pixelArtName\(i)Key") as? String {
                pixelArtDB[i].pixelArtName = nameMemorized
            }
            
            for j in 0...pixelArtDB[i].pixelArtGrid.count - 1 {
                if let colorMemorized = defaults.object(forKey: "pixelArtGrid\(i)\(j)ColorKey") as? UInt8 {
                   pixelArtDB[i].pixelArtGrid[j] = colorMemorized
                }
            }
            
            if let loadedImage = loadImageFromPath(imageName: "image\(i)") {
                pixelArtDB[i].pixelArtPreview = loadedImage
            }
        }
    } else {
        pixelArtDB.append(pixelArtData()) // Default value for the first element of the table view
    }
}

// Update the data stored for the next launching
func updateMemory() {
    let defaults = UserDefaults.standard
    
    defaults.set(pixelArtDBSize, forKey: "pixelArtDBSizeKey")
    
    if pixelArtDBSize > 0 {
        for i in 0...pixelArtDBSize - 1 {
            defaults.set(pixelArtDB[i].pixelArtName, forKey: "pixelArtName\(i)Key")
            for (index, pixel) in pixelArtDB[i].pixelArtGrid.enumerated() {
                defaults.set(pixel, forKey: "pixelArtGrid\(i)\(index)ColorKey")
            }
            saveImage(image: pixelArtDB[i].pixelArtPreview, imageName: "image\(i)")
        }
    }
}

class GridViewController: UIViewController {
    // Cells parameters (32x32 grid)
    let pixelReuseIdentifier = "pixelCell"
    let pixelCellsPerRow = CGFloat(32)
    let gridMargin = CGFloat(2)
    let colorCellSize = CGFloat(30)
    
    // Saving popup
    var saveView = UIView()
    var nameTextField = UITextField()
    var previewImage = UIImage()
    
    // General buttons
    @IBOutlet weak var connectButton: UIBarButtonItem!
    @IBOutlet weak var ledsGridCollectionView: UICollectionView!
    @IBOutlet weak var selectColorCollectionView: UICollectionView!
    
    // Color buttons
    let colorReuseIdentifier = "colorCell"
    let colorCellsPerRow = CGFloat(4)
    var RGBFromButton = UInt8()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Init bluetooth
        serial = BluetoothSerial(delegate: self)
        serial.writeType = .withResponse
        // Load saved elements
        checkMemory()
        // Init view
        initLayout()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Update the grid
        if pixelArtDBSize > 0 {
            ledsGridCollectionView.reloadData()
        }
        // Update the bluetooth button asset
        if serial.connectedPeripheral != nil {
            connectButton.image = #imageLiteral(resourceName: "NoBluetooth")
        }
    }
   
    @IBAction func manageBluetooth(_ sender: Any) {
        if serial.connectedPeripheral == nil {
            self.performSegue(withIdentifier: "launchScan", sender: sender)
        } else {
            serial.disconnect()
            connectButton.image = #imageLiteral(resourceName: "Bluetooth")
        }
    }
    
    @IBAction func savePixelArtPopUp(_ sender: Any) {
        // Create the save popup
        let width = UIScreen.main.bounds.width
        let height = UIScreen.main.bounds.height
        let defaultMargin = CGFloat(20)
        let saveViewWidth = width * 0.8
        let saveViewHeight = height * 0.27
        saveView = UIView(frame: CGRect(x: 0 , y: 0, width: saveViewWidth, height: saveViewHeight))
        saveView.center = CGPoint(x: width / 2, y: height / 2)
        saveView.backgroundColor = UIColor.lightGray
        saveView.layer.cornerRadius = 10
        
        // Add the title
        let titleLabel = UILabel(frame: CGRect(x: 0 , y: 0, width: saveViewWidth, height: defaultMargin))
        titleLabel.center = CGPoint(x: saveViewWidth / 2, y: defaultMargin)
        titleLabel.text = "Save this PixelArt?"
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18.0)
        saveView.addSubview(titleLabel)
        
        // Add the PixelArt image
        let imageWidth = CGFloat(50)
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: imageWidth, height: imageWidth))
        imageView.center = CGPoint(x: imageWidth / 2 + defaultMargin, y: saveViewHeight / 2 - imageWidth / 2)
        previewImage = takeScreenShot(width: imageWidth)
        imageView.image = previewImage
        saveView.addSubview(imageView)
        
        // Add the textField
        let textFieldWidth = saveViewWidth - imageWidth - 3 * defaultMargin
        let textFieldHeight = defaultMargin * 4 / 3
        nameTextField = UITextField(frame: CGRect(x: 0, y: 0, width: textFieldWidth, height: textFieldHeight))
        nameTextField.center = CGPoint(x: imageWidth + 2 * defaultMargin + textFieldWidth / 2, y: saveViewHeight / 2 - imageWidth / 2)
        nameTextField.placeholder = "Enter a name"
        nameTextField.borderStyle = UITextBorderStyle.roundedRect
        nameTextField.autocapitalizationType = .words
        nameTextField.returnKeyType = UIReturnKeyType.done
        nameTextField.clearButtonMode = UITextFieldViewMode.whileEditing
        nameTextField.text = nil
        nameTextField.backgroundColor = UIColor.white
        nameTextField.tintColor = UIColor.black
        nameTextField.delegate = self
        nameTextField.becomeFirstResponder()
        saveView.addSubview(nameTextField)
        
        // Add the buttons
        let buttonsWidth = saveViewWidth / 2 - 2 * defaultMargin
        let okButton = UIButton()
        okButton.setTitle("OK", for: UIControlState())
        okButton.isEnabled = true
        okButton.setTitleColor(UIColor.white, for: UIControlState())
        okButton.backgroundColor = UIColor.black
        okButton.frame = CGRect(x: 0, y: 0, width: buttonsWidth, height: 2 * defaultMargin)
        okButton.center = CGPoint(x: saveViewWidth / 4, y: saveViewHeight - 2 * defaultMargin)
        okButton.layer.cornerRadius = 10
        okButton.addTarget(self, action: #selector(GridViewController.savePixelArt(_:)), for: .touchUpInside)
        saveView.addSubview(okButton)
        
        let cancelButton = UIButton()
        cancelButton.setTitle("Cancel", for: UIControlState())
        cancelButton.isEnabled = true
        cancelButton.setTitleColor(UIColor.white, for: UIControlState())
        cancelButton.backgroundColor = UIColor.black
        cancelButton.frame = CGRect(x: 0, y: 0, width: buttonsWidth, height: 2 * defaultMargin)
        cancelButton.center = CGPoint(x: saveViewWidth * 3 / 4, y: saveViewHeight - 2 * defaultMargin)
        cancelButton.layer.cornerRadius = 10
        cancelButton.addTarget(self, action: #selector(GridViewController.dismissSavePopUp(_:)), for: .touchUpInside)
        saveView.addSubview(cancelButton)

        self.view.addSubview(saveView)
    }
    
    @objc func savePixelArt(_ sender: UIButton!) {
        if !((nameTextField.text?.isEmpty)!) {
            if pixelArtDBSize != 0 {
                pixelArtDB.append(pixelArtData())
            }
            pixelArtDB[pixelArtDBSize].pixelArtName = nameTextField.text!
            pixelArtDB[pixelArtDBSize].pixelArtGrid = RGBGridArray
            pixelArtDB[pixelArtDBSize].pixelArtPreview = previewImage
            pixelArtDBSize += 1
            updateMemory()
            dismissSavePopUp(sender)
        }
    }
    
    @objc func dismissSavePopUp(_ sender: UIButton!) {
        saveView.removeFromSuperview()
    }
    
    func takeScreenShot(width: CGFloat) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: ledsGridCollectionView.bounds.size.width, height: ledsGridCollectionView.bounds.size.height)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
        ledsGridCollectionView.drawHierarchy(in: rect, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizeImage(image: image!, newWidth: width)
    }
    
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    @IBAction func sendPixelArt(_ sender: UIButton) {
        var isSending = true
        
        // Progression HUD
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud?.mode = MBProgressHUDMode.text
        hud?.labelText = "Sending data..."
        
        // Wait for sending to be completed before hiding the HUD
        DispatchQueue.global(qos: .background).async {
            while isSending {}
            hud?.hide(true)
        }
        
        // Send start byte
        serial.sendBytesToDevice([UInt8(0)])
        
        // Send data line by line
        for startIndex in 0...63 {
            serial.sendBytesToDevice(Array(RGBGridArray[16 * startIndex...16 * startIndex + 15]))
        }
        
        isSending = false // Tells background thread to hide the progression HUD
    }
    
    
    @IBAction func clearAllPixels(_ sender: UIButton) {
        for index in 0...RGBGridArray.count - 1 {
            RGBGridArray[index] = 0
        }
        ledsGridCollectionView.reloadData()
    }
}

extension GridViewController: UICollectionViewDelegate {
    // Handle tap events
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = (indexPath as NSIndexPath).row

        if collectionView == self.ledsGridCollectionView {
            let cell = ledsGridCollectionView.cellForItem(at: indexPath)!
            cell.backgroundColor = UIColor(red: CGFloat((RGBFromButton & 0b100) >> 2), green: CGFloat((RGBFromButton & 0b010) >> 1), blue: CGFloat(RGBFromButton & 0b001), alpha: 1.0)
            RGBGridArray[index] = RGBFromButton
        } else {
            for i in 0...7 {
                let cell = selectColorCollectionView.cellForItem(at:IndexPath(row: i, section: 0))!
                
                if i == index {
                    cell.layer.borderWidth = 3
                } else {
                    cell.layer.borderWidth = 0
                }
            }
            
            RGBFromButton = UInt8(index)
        }
    }
}

extension GridViewController: UICollectionViewDataSource
{
    // Tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.ledsGridCollectionView {
            return Int(pixelCellsPerRow*pixelCellsPerRow)
        } else {
            return Int(2*colorCellsPerRow)
        }
    }
    
    // Make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let index = (indexPath as NSIndexPath).row
        
        if collectionView == self.ledsGridCollectionView {
            let cellWidth = (ledsGridCollectionView.bounds.width - gridMargin * (pixelCellsPerRow + 1)) / pixelCellsPerRow
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: pixelReuseIdentifier, for: indexPath as IndexPath)
            cell.backgroundColor = UIColor(red: CGFloat((RGBGridArray[index] & 0b100) >> 2), green: CGFloat((RGBGridArray[index] & 0b010) >> 1), blue: CGFloat(RGBGridArray[index] & 0b001), alpha: 1.0)
            cell.layer.borderWidth = 1
            cell.layer.cornerRadius = 2
            cell.frame.size = CGSize(width: cellWidth, height: cellWidth)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: colorReuseIdentifier, for: indexPath as IndexPath)
            cell.backgroundColor = UIColor(red: CGFloat((UInt8(index) & 0b100) >> 2), green: CGFloat((UInt8(index) & 0b010) >> 1), blue: CGFloat(UInt8(index) & 0b001), alpha: 1.0)
            if index == 0 {
                cell.layer.borderWidth = 3
            } else {
                cell.layer.borderWidth = 0
            }
            cell.layer.borderColor = selectColorCollectionView.backgroundColor?.cgColor
            cell.layer.cornerRadius = 3
            cell.frame.size = CGSize(width: colorCellSize, height: colorCellSize)
            return cell
        }
    }
}

extension GridViewController: UICollectionViewDelegateFlowLayout {
    func initLayout() {
        guard let gridFlowLayout = ledsGridCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let gridItemWidth = (ledsGridCollectionView.bounds.width - gridMargin * (pixelCellsPerRow + 1)) / pixelCellsPerRow
        gridFlowLayout.minimumInteritemSpacing = gridMargin
        gridFlowLayout.minimumLineSpacing = gridMargin
        gridFlowLayout.sectionInset.top = gridMargin
        gridFlowLayout.sectionInset.bottom = gridMargin
        gridFlowLayout.sectionInset.left = gridMargin
        gridFlowLayout.sectionInset.right = gridMargin
        gridFlowLayout.itemSize = CGSize(width: gridItemWidth, height: gridItemWidth)
        
        guard let colorFlowLayout = selectColorCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        colorFlowLayout.minimumInteritemSpacing = (selectColorCollectionView.bounds.width - colorCellsPerRow * colorCellSize) / (colorCellsPerRow - 1)
        colorFlowLayout.minimumLineSpacing = selectColorCollectionView.bounds.height  - 2 * colorCellSize
        colorFlowLayout.sectionInset.top = 0
        colorFlowLayout.sectionInset.bottom = 0
        colorFlowLayout.sectionInset.left = 0
        colorFlowLayout.sectionInset.right = 0
        colorFlowLayout.itemSize = CGSize(width: 30, height: 30)
    }
}

extension GridViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.ledsGridCollectionView
    }
}

extension GridViewController: UITextFieldDelegate {
    // MARK:- ---> Textfield Delegates
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return true;
    }
    // MARK: Textfield Delegates <---
}

extension GridViewController: BluetoothSerialDelegate {
    // MARK: BluetoothSerialDelegate
    
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud?.mode = MBProgressHUDMode.text
        hud?.labelText = "Disconnected"
        hud?.hide(true, afterDelay: 1.0)
        connectButton.image = #imageLiteral(resourceName: "Bluetooth")
    }
    
    func serialDidChangeState() {
        if serial.centralManager.state != .poweredOn {
            let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            hud?.mode = MBProgressHUDMode.text
            hud?.labelText = "Bluetooth turned off"
            hud?.hide(true, afterDelay: 1.0)
        }
    }
}
