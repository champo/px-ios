//
//  FooterTableViewCell.swift
//  MercadoPagoSDK
//
//  Created by Eden Torres on 10/26/16.
//  Copyright © 2016 MercadoPago. All rights reserved.
//

import UIKit

class FooterTableViewCell: CallbackCancelTableViewCell {

    @IBOutlet weak var button: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.button.addTarget(self, action: #selector(invokeCallback), for: .touchUpInside)
    }
    func fillCell(payment: Payment){
        if payment.statusDetail.contains("cc_rejected_bad_filled"){
            self.button.setTitle("Cancelar pago y seguir comprando".localized, for: UIControlState.normal)
        }
    }
}
