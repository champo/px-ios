//
//  PendingPaymentHeaderTableViewCell.swift
//  MercadoPagoSDK
//
//  Created by Maria cristina rodriguez on 12/5/16.
//  Copyright © 2016 MercadoPago. All rights reserved.
//

import UIKit

class PendingPaymentHeaderTableViewCell: UITableViewCell, CongratsFillmentDelegate {

    
    @IBOutlet weak var subtitle: MPLabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.shadowOffset = CGSize(width: 0, height: 1)
        self.layer.shadowColor = UIColor(red: 153, green: 153, blue: 153).cgColor
        self.layer.shadowRadius = 3
        self.layer.shadowOpacity = 0.6

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fillCell(_ payment: Payment, paymentMethod : PaymentMethod, callback : ((Void) -> Void)?) -> UITableViewCell {
        if payment.statusDetail == nil || payment.statusDetail.isEmpty {
            self.subtitle.text = ""
        } else if payment.statusDetail == "pending_contingency" {
            self.subtitle.text = "En menos de 1 hora te enviaremos por e-mail el resultado.".localized
        } else {
            self.subtitle.text = "En poquitas horas te diremos por e-mail si se acreditó o si necesitamos más información.".localized
        }
        return self
    }
    
    func getCellHeight(_ payment: Payment, paymentMethod: PaymentMethod) -> CGFloat {
        return 212
    }
    
}
