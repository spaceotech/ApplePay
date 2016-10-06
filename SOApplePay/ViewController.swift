//
//  ViewController.swift
//  SOApplePay
//
//  Created by Hitesh on 10/5/16.
//  Copyright © 2016 myCompany. All rights reserved.
//

import UIKit
import PassKit // apple pay is a part of Passkit framework

class ViewController: UIViewController, PKPaymentAuthorizationViewControllerDelegate {

    @IBOutlet weak var tblShopping: UITableView!
    
    //Array of product with price
    var quotesArray : NSMutableArray = [
        ["Product": "Shirt", "Price": "20", "Note": "Nice Shirt"],
        ["Product": "Shoes", "Price": "12", "Note": "Nice Shoes"],
        ]
    
    var items : NSMutableDictionary = NSMutableDictionary()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    
    //MARK: UITableViewDelegate
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 60
    }
    
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let viewButton : UIView = UIView()
        viewButton.frame = CGRectMake(40, 10, tableView.frame.size.width - 80,  40)
        
        let btnApplePay: PKPaymentButton
        
        if PKPaymentAuthorizationViewController.canMakePayments() {
            btnApplePay = PKPaymentButton(type: .Buy, style: .Black)
        } else {
            btnApplePay = PKPaymentButton(type: .SetUp, style: .Black)
        }
        
        btnApplePay.addTarget(self, action: #selector(ViewController.payByApplePay), forControlEvents: .TouchUpInside)
        btnApplePay.frame = viewButton.frame
        
        viewButton.addSubview(btnApplePay)
        return viewButton
    }
    
    
    //MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return quotesArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        configureCell(cell, forRowAtIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, forRowAtIndexPath: NSIndexPath) {
        let lblProduct : UILabel = cell.contentView.viewWithTag(1) as! UILabel
        let lblPrice : UILabel = cell.contentView.viewWithTag(2) as! UILabel
        let lblNote : UILabel = cell.contentView.viewWithTag(3) as! UILabel
        
        let dict : NSDictionary = quotesArray.objectAtIndex(forRowAtIndexPath.row) as! NSDictionary
        lblProduct.text = dict.valueForKey("Product") as? String
        lblPrice.text = "$" + (dict.valueForKey("Price") as! String)
        lblNote.text = dict.valueForKey("Note") as? String
    }

    
    //MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        items.addEntriesFromDictionary(quotesArray.objectAtIndex(indexPath.row) as! [NSObject : AnyObject])
    }
    
    
    // MARK: - Apple Pay
    func payByApplePay() {
        if items.count == 0 {
            self.showAlertButtonTapped("Please Try Again", strMessage: "Please select a Product.")
            return
        }
        
        // Create a PKPaymentRequest Object
        let request = PKPaymentRequest()
        request.supportedNetworks = [PKPaymentNetworkAmex, PKPaymentNetworkVisa]
        
        //Set countryCode and its currency
        request.countryCode = "US"
        request.currencyCode = "USD"
        
        //Keep your merchange id here (which you have created in your apple developer account)
        request.merchantIdentifier = "merchant.com.soapplepay.app"
        
        //Add merchantCapabilities (EMV, Credit, Debit)
        request.merchantCapabilities = .Capability3DS
        
        //Keep shipping address field (Email, PostalAddress, Name, Phone or All)
        request.requiredShippingAddressFields = .Email
        
        // Create shipping methods
        let freeShipping = PKShippingMethod(label: "Free Shipping", amount: NSDecimalNumber(double: 0.00))
        freeShipping.identifier = "free"
        freeShipping.detail = "Arrive in 1-2 weeks"
        
        let expressShipping = PKShippingMethod(label: "Express Shipping", amount: NSDecimalNumber(double: 2.99))
        expressShipping.identifier = "express"
        expressShipping.detail = "Arrive in 3-4 days"
        
        request.paymentSummaryItems = getPaymentSummary(freeShipping)
        request.shippingMethods = [freeShipping,expressShipping]
        
        //Now present apple payment authorization viewController
        let objApplePay = PKPaymentAuthorizationViewController(paymentRequest: request)
        objApplePay.delegate = self
        self.presentViewController(objApplePay, animated: true, completion: nil)
    }
    
    
    //Add items for purchase with shipping
    func getPaymentSummary(shippingMethod: PKShippingMethod) -> [PKPaymentSummaryItem] {
        
        //Add items summery with title and price
        let objItem = PKPaymentSummaryItem(label: items.valueForKey("Product") as! String , amount: NSDecimalNumber(string: items.valueForKey("Price") as? String))
        
        //Add shipping
        let shippingChargeItem = PKPaymentSummaryItem(label: shippingMethod.label, amount: shippingMethod.amount)
        
        //Get total of item
        let cartTotal = objItem.amount.decimalNumberByAdding(shippingChargeItem.amount)
        let total = PKPaymentSummaryItem(label: "Space-0", amount: cartTotal)
        
        return [objItem, shippingChargeItem , total]
    }
    
    // MARK: - PKPayment Delegate
    //Change shipping method
    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController, didSelectShippingMethod shippingMethod: PKShippingMethod, completion: (PKPaymentAuthorizationStatus, [PKPaymentSummaryItem]) -> Void) {
        completion(.Success, getPaymentSummary(shippingMethod))
    }

    //Handle the Payment completion status from this delegate
    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: (PKPaymentAuthorizationStatus) -> Void) {
        completion(.Success)
    }
    
    //Payment Authorization ViewController is dimissed in case 
    //Payment done or
    //Payment cancelled
    func paymentAuthorizationViewControllerDidFinish(controller: PKPaymentAuthorizationViewController) {
        controller.dismissViewControllerAnimated(true) {
            
        }
    }
    
    //MARK:- AlerViewController
    func showAlertButtonTapped(strTitle:String, strMessage:String) {
        // create the alert
        let alert = UIAlertController(title: strTitle, message: strMessage, preferredStyle: UIAlertControllerStyle.Alert)
        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        // show the alert
        self.presentViewController(alert, animated: true, completion: nil)
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

