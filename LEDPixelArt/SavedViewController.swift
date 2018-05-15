//
//  SavedViewController.swift
//  LEDPixelArt
//
//  Created by Florian Sorin on 08/02/2017.
//  Copyright © 2017 Florian Sorin. All rights reserved.
//

import UIKit
import MGSwipeTableCell

class SavedViewController: UIViewController
{
    @IBOutlet weak var savedTableView: UITableView!
    var noSavedLabel = UILabel()
    
    override func viewDidLoad()
    {
        savedTableView.tableFooterView = UIView(frame: CGRect.zero) // Delete separators for empty cells
        noSavedLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
        noSavedLabel.center = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
        noSavedLabel.text = "No pixel art saved"
        noSavedLabel.textColor = UIColor.white
        noSavedLabel.textAlignment = .center
        noSavedLabel.isHidden = true
        self.view.addSubview(noSavedLabel)
        
        if pixelArtDBSize == 0
        {
            savedTableView.isHidden = true
            noSavedLabel.isHidden = false
        }
        
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        if pixelArtDBSize > 0
        {
            savedTableView.reloadData()
            
            if savedTableView.isHidden
            {
                noSavedLabel.isHidden = true
                savedTableView.isHidden = false
            }
        }
    }
    
    //Delete a pixelArt
    func delPixelArt(index: IndexPath)
    {
        if pixelArtDBSize > 0
        {
            pixelArtDBSize -= 1
            
            if index.row != 0
            {
                pixelArtDB.remove(at: index.row)
            }
            else
            {
                pixelArtDB[0] = pixelArtData()
                savedTableView.isHidden = true
                noSavedLabel.isHidden = false
            }
            
            updateMemory()
            savedTableView.reloadData()
        }
    }
}

extension SavedViewController: UITableViewDelegate
{
    //Manage a simple press on a cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let i = (indexPath as NSIndexPath).row
        
        for (index, pixel) in pixelArtDB[i].pixelArtGrid.enumerated()
        {
            RGBGridArray[index] = pixel
        }
        tabBarController?.selectedIndex = 0 // Go to the grid view
    }
}

extension SavedViewController: UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return pixelArtDB.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "savedTableCell") as! MGSwipeTableCell
        
      
        let index = (indexPath as NSIndexPath).row
        //cell.pixelArtName.text = pixelArtDB[index].pixelArtName
        //cell.pixelArtPreview.image = pixelArtDB[index].pixelArtPreview
        cell.textLabel?.text = pixelArtDB[index].pixelArtName
        // cell.textLabel?.textColor = UIColor.white
        cell.imageView?.image = pixelArtDB[index].pixelArtPreview
        
        //        //configure left buttons
        //        cell.leftButtons = [MGSwipeButton(title: "Edit\nScore", backgroundColor: UIColor.blue, callback: {
        //            (sender: MGSwipeTableCell!) -> Bool in
        //            self.modifyScore(index: indexPath)
        //            return true})]
        //
        //        cell.leftSwipeSettings.transition = MGSwipeTransition.rotate3D
        //
        
        //configure right buttons
        cell.rightButtons = [MGSwipeButton(title: "Delete", backgroundColor: UIColor.red, callback: {
            (sender: MGSwipeTableCell!) -> Bool in
            self.delPixelArt(index: indexPath)
            return true})]
        cell.rightSwipeSettings.transition = MGSwipeTransition.rotate3D
        
        return cell
    }
}
