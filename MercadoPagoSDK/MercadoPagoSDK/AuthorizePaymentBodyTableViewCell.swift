//
//  AuthorizePaymentBodyTableViewCell.swift
//  MercadoPagoSDK
//
//  Created by Maria cristina rodriguez on 9/5/16.
//  Copyright © 2016 MercadoPago. All rights reserved.
//

import UIKit

class AuthorizePaymentBodyTableViewCell: CallbackCancelTableViewCell, CongratsFillmentDelegate {

    static let ROW_HEIGHT = CGFloat(150)
    
    @IBOutlet weak var completeCardButton: MPButton!
    @IBOutlet weak var cancelButton: MPButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.cancelButton.titleLabel?.text = "Elegí otro medio de pago".localized
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fillCell(payment: Payment, paymentMethod : PaymentMethod,callback : (Void -> Void)?) -> UITableViewCell {
        self.defaultCallback = callback
        self.cancelButton.addTarget(self, action: "invokeDefaultCallback", forControlEvents: .TouchUpInside)
        self.completeCardButton.setTitle("Ya hablé con " + paymentMethod.name.localized + " y me autorizó".localized, forState: .Normal)
        self.completeCardButton.addTarget(self, action: "invokeDefaultCallback", forControlEvents: .TouchUpInside)
        return self
    }
    
    func getCellHeight(payment: Payment, paymentMethod: PaymentMethod) -> CGFloat {
        return 150
    }

}