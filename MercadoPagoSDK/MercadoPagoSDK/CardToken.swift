//
//  CardToken.swift
//  MercadoPagoSDK
//
//  Created by Matias Gualino on 31/12/14.
//  Copyright (c) 2014 com.mercadopago. All rights reserved.
//

import Foundation
import UIKit

open class CardToken : NSObject, CardInformationForm {
    
    let MIN_LENGTH_NUMBER : Int = 10
    let MAX_LENGTH_NUMBER : Int = 19
    
    open var device : Device?
    open var securityCode : String?
    
    let now = (Calendar.current as NSCalendar).components([.year, .month], from: Date())
    
    open var cardNumber : String?
    open var expirationMonth : Int = 0
    open var expirationYear : Int = 0
    open var cardholder : Cardholder?
    
    
    public override init(){
        super.init()
    }
    
    public init (cardNumber: String?, expirationMonth: Int, expirationYear: Int,
        securityCode: String?, cardholderName: String, docType: String, docNumber: String) {
            super.init()
            self.cardholder = Cardholder()
            self.cardholder?.name = cardholderName
            self.cardholder?.identification = Identification()
            self.cardholder?.identification?.number = docNumber
            self.cardholder?.identification?.type = docType
            self.cardNumber = normalizeCardNumber(cardNumber!.replacingOccurrences(of: " ", with: ""))
            self.expirationMonth = expirationMonth
            self.expirationYear = 2000 + expirationYear
            self.securityCode = securityCode
    }
    
    open func normalizeCardNumber(_ number: String?) -> String? {
        if number == nil {
            return nil
        }
        return number!.trimmingCharacters(in: CharacterSet.whitespaces).replacingOccurrences(of: "\\s+|-", with: "")
    }
    
    open func validate() -> Bool {
        return validate(true)
    }
    
    open func validate(_ includeSecurityCode: Bool) -> Bool {
        var result : Bool = validateCardNumber() == nil  && validateExpiryDate() == nil && validateIdentification() == nil && validateCardholderName() == nil
        if (includeSecurityCode) {
            result = result && validateSecurityCode() == nil
        }
        return result
    }
    
    open func validateCardNumber() -> NSError? {
        if String.isNullOrEmpty(cardNumber) {
            return NSError(domain: "mercadopago.sdk.card.error", code: 1, userInfo: ["cardNumber" : "Ingresa el número de la tarjeta de crédito".localized])
        } else if self.cardNumber!.characters.count < MIN_LENGTH_NUMBER || self.cardNumber!.characters.count > MAX_LENGTH_NUMBER {
            return NSError(domain: "mercadopago.sdk.card.error", code: 1, userInfo: ["cardNumber" : "invalid_field".localized])
        } else {
            return nil
        }
    }
    
    open func validateCardNumber(_ paymentMethod: PaymentMethod) -> NSError? {
        var userInfo : [String : String]?
        cardNumber = cardNumber?.replacingOccurrences(of: "•", with: "")
        let validCardNumber = self.validateCardNumber()
        if validCardNumber != nil {
            return validCardNumber
        } else {
        
            let setting : Setting? = Setting.getSettingByBin(paymentMethod.settings, bin: getBin())
            
            if setting == nil {
                if userInfo == nil {
                    userInfo = [String : String]()
                }
                userInfo?.updateValue("El número de tarjeta que ingresaste no se corresponde con el tipo de tarjeta".localized, forKey: "cardNumber")
            } else {
                
                // Validate card length
                if (cardNumber!.trimSpaces().characters.count != setting?.cardNumber.length) {
                    if userInfo == nil {
                        userInfo = [String : String]()
                    }
                    if let cardNumberLength = setting?.cardNumber.length {
                        userInfo?.updateValue(("invalid_card_length".localized as NSString).replacingOccurrences(of: "%1$s", with: "\(cardNumberLength)"), forKey: "cardNumber")
                        
                    } else {
                        userInfo?.updateValue("El número de tarjeta que ingresaste no se corresponde con el tipo de tarjeta".localized, forKey: "cardNumber")
                    }
                    
                }
                
                // Validate luhn
                if "standard" == setting?.cardNumber.validation && !checkLuhn(cardNumber: (cardNumber?.trimSpaces())!) {
                    if userInfo == nil {
                        userInfo = [String : String]()
                    }
                    userInfo?.updateValue("El número de tarjeta que ingresaste es incorrecto".localized, forKey: "cardNumber")
                }
            }
        }
        
        if userInfo == nil {
            return nil
        } else {
            return NSError(domain: "mercadopago.sdk.card.error", code: 1, userInfo: userInfo)
        }
    }

    open func validateSecurityCode()  -> NSError? {
        return validateSecurityCode(securityCode)
    }
    
    open func validateSecurityCode(_ securityCode: String?) -> NSError? {
        if String.isNullOrEmpty(self.securityCode) || self.securityCode!.characters.count < 3 || self.securityCode!.characters.count > 4 {
            return NSError(domain: "mercadopago.sdk.card.error", code: 1, userInfo: ["securityCode" : "invalid_field".localized])
        } else {
            return nil
        }
    }
    
    open func validateSecurityCodeWithPaymentMethod(_ paymentMethod: PaymentMethod) -> NSError? {
        let validSecurityCode = self.validateSecurityCode(securityCode)
        if validSecurityCode != nil {
            return validSecurityCode
        } else {
            let range = cardNumber!.startIndex ..< cardNumber!.characters.index(cardNumber!.characters.startIndex, offsetBy: 6)
            return validateSecurityCodeWithPaymentMethod(securityCode!, paymentMethod: paymentMethod, bin: cardNumber!.substring(with: range))
        }
    }
    
    open func validateSecurityCodeWithPaymentMethod(_ securityCode: String, paymentMethod: PaymentMethod, bin: String) -> NSError? {
        let setting : Setting? = Setting.getSettingByBin(paymentMethod.settings, bin: getBin())
        // Validate security code length
        let cvvLength = setting?.securityCode.length
        if ((cvvLength != 0) && (securityCode.characters.count != cvvLength)) {
            return NSError(domain: "mercadopago.sdk.card.error", code: 1, userInfo: ["securityCode" : ("invalid_cvv_length".localized as NSString).replacingOccurrences(of: "%1$s", with: "\(cvvLength)")])
        } else {
            return nil
        }
    }
    
    open func validateExpiryDate() -> NSError? {
        return validateExpiryDate(expirationMonth, year: expirationYear)
    }
    
    open func validateExpiryDate(_ month: Int, year: Int) -> NSError? {
        if !validateExpMonth(month) {
			return NSError(domain: "mercadopago.sdk.card.error", code: 1, userInfo: ["expiryDate" : "invalid_field".localized])
        }
        if !validateExpYear(year) {
            return NSError(domain: "mercadopago.sdk.card.error", code: 1, userInfo: ["expiryDate" : "invalid_field".localized])
        }
        
        if hasMonthPassed(self.expirationYear, month: self.expirationMonth) {
            return NSError(domain: "mercadopago.sdk.card.error", code: 1, userInfo: ["expiryDate" : "invalid_field".localized])
        }
        
        return nil
    }
    
    open func validateExpMonth(_ month: Int) -> Bool {
        return (month >= 1 && month <= 12)
    }
    
    open func validateExpYear(_ year: Int) -> Bool {
        return !hasYearPassed(year)
    }
    
    open func validateIdentification() -> NSError? {
        
        let validType = validateIdentificationType()
        if validType != nil {
            return validType
        } else {
            let validNumber = validateIdentificationNumber()
            if validNumber != nil {
                return validNumber
            }
        }
        return nil
    }
    
    open func validateIdentificationType() -> NSError? {
        
        if String.isNullOrEmpty(cardholder!.identification!.type) {
            return NSError(domain: "mercadopago.sdk.card.error", code: 1, userInfo: ["identification" : "invalid_field".localized])
        } else {
            return nil
        }
    }
    
    open func validateIdentificationNumber() -> NSError? {
        
        if String.isNullOrEmpty(cardholder!.identification!.number) {
            return NSError(domain: "mercadopago.sdk.card.error", code: 1, userInfo: ["identification" : "invalid_field".localized])
        } else {
            return nil
        }
    }
    
    open func validateIdentificationNumber(_ identificationType: IdentificationType?) -> NSError? {
        if identificationType != nil {
            if cardholder?.identification != nil && cardholder?.identification?.number != nil {
                let len = cardholder!.identification!.number!.characters.count
                let min = identificationType!.minLength
                let max = identificationType!.maxLength
                if min != 0 && max != 0 {
                    if len > max || len < min {
                        return NSError(domain: "mercadopago.sdk.card.error", code: 1, userInfo: ["identification" : "invalid_field".localized])
                    } else {
                        return nil
                    }
                } else  {
                    return validateIdentificationNumber()
                }
            } else {
                return NSError(domain: "mercadopago.sdk.card.error", code: 1, userInfo: ["identification" : "invalid_field".localized])
            }
        } else {
            return validateIdentificationNumber()
        }
    }
    
    open func validateCardholderName() -> NSError? {
        if String.isNullOrEmpty(self.cardholder?.name) {
            return NSError(domain: "mercadopago.sdk.card.error", code: 1, userInfo: ["cardholder" : "invalid_field".localized])
        } else {
            return nil
        }
    }

    open func hasYearPassed(_ year: Int) -> Bool {
        let normalized : Int = normalizeYear(year)
        return normalized < now.year!
    }
    
    open func hasMonthPassed(_ year: Int, month: Int) -> Bool {
        return hasYearPassed(year) || normalizeYear(year) == now.year! && month < (now.month! + 1)
    }
    
    open func normalizeYear(_ year: Int) -> Int {
        if year < 100 && year >= 0 {
            let currentYear : String = String(describing: now.year)
            let range = currentYear.startIndex ..< currentYear.characters.index(currentYear.characters.endIndex, offsetBy: -2)
            let prefix : String = currentYear.substring(with: range)
			
			let nsReturn : NSString = prefix.appending(String(year)) as NSString
            return nsReturn.integerValue
        }
        return year
    }
    


    public func checkLuhn(cardNumber: String) -> Bool {
        var sum = 0
        let reversedCharacters = cardNumber.characters.reversed().map { String($0) }
        for (idx, element) in reversedCharacters.enumerated() {
            guard let digit = Int(element) else { return false }
            switch ((idx % 2 == 1), digit) {
            case (true, 9): sum += 9
            case (true, 0...8): sum += (digit * 2) % 9
            default: sum += digit

            }
        }
        return sum % 10 == 0
    }
    
    open func getBin() -> String? {
        let range =  cardNumber!.startIndex ..< cardNumber!.characters.index(cardNumber!.characters.startIndex, offsetBy: 6)
        let bin :String? = cardNumber!.characters.count >= 6 ? cardNumber!.substring(with: range) : nil
        return bin
    }
    
    open func toJSONString() -> String {
        
        let card_number : Any = String.isNullOrEmpty(self.cardNumber) ? JSONHandler.null : self.cardNumber!
        let cardholder : Any = (self.cardholder == nil) ? JSONHandler.null : self.cardholder!.toJSON()
        let security_code : Any = String.isNullOrEmpty(self.securityCode) ? JSONHandler.null : self.securityCode!
        let device : Any = self.device == nil ? JSONHandler.null : self.device!.toJSONString()
        let obj:[String:Any] = [
            "card_number": card_number,
            "cardholder":cardholder,
            "security_code" :  security_code,
            "expiration_month" : self.expirationMonth,
            "expiration_year" : self.expirationYear,
            "device" : device
        ]
        return JSONHandler.jsonCoding(obj)
    }
    
    open func getNumberFormated() -> NSString {
        
        //TODO AMEX
        var str : String
        str = (cardNumber?.insert(" ", ind: 12))!
        str = (str.insert(" ", ind: 8))
        str = (str.insert(" ", ind: 4))
        str = (str.insert(" ", ind: 0))
        return str as NSString
    }
    
    open func getExpirationDateFormated() -> NSString {
        
        var str : String
        
        
        str = String(self.expirationMonth) + "/" + String(self.expirationYear).substring(from: String(self.expirationYear).index(before: String(self.expirationYear).characters.index(before: String(self.expirationYear).endIndex)))

        return str as NSString
    }
    
    open func isCustomerPaymentMethod() -> Bool {
        return false
    }
    open func getCardLastForDigits() -> String?{
        let index = cardNumber?.characters.count
        return cardNumber![cardNumber!.index(cardNumber!.startIndex, offsetBy: index!-4)...cardNumber!.index(cardNumber!.startIndex, offsetBy: index!-1)]
    }
    public func getCardBin() -> String? {
        return getBin()
    }

}
