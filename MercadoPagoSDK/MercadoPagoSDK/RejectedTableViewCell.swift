//
//  RejectedTableViewCell.swift
//  MercadoPagoSDK
//
//  Created by Eden Torres on 10/28/16.
//  Copyright © 2016 MercadoPago. All rights reserved.
//

import UIKit

class RejectedTableViewCell: CallbackCancelTableViewCell {
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subtitile: UILabel!
    @IBOutlet weak var button: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        button.layer.cornerRadius = 3
        self.title.text = "¿Que puedo hacer?".localized
        self.button.addTarget(self, action: #selector(invokeCallback), for: .touchUpInside)
    }

    func fillCell (payment: Payment){
        
        if payment.status == "rejected"{
            
            if payment.statusDetail == "cc_rejected_call_for_authorize"{
                var title = (payment.statusDetail + "_title")
                self.title.text = title.localized
                self.subtitile.text = ""
            } else {
                var title = (payment.statusDetail + "_subtitle_" + payment.paymentTypeId)
                
                if !title.existsLocalized() {
                    title = ""
                }
                self.subtitile.text = title.localized
                if payment.statusDetail.contains("cc_rejected_bad_filled"){
                    status = MPStepBuilder.CongratsState.cancel_RECOVER
                    self.button.setTitle("Ingresalo nuevamente".localized, for: UIControlState.normal)
                }
            }
        } else if payment.statusDetail == "pending_contingency"{
            self.subtitile.text = "En menos de 1 hora te enviaremos por e-mail el resultado.".localized
        } else {
            self.subtitile.text = "En menos de 2 días hábiles te diremos por e-mail si se acreditó o si necesitamos más información.".localized
        }
    }
}
