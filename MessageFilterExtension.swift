//
//  MessageFilterExtension.swift
//  SilentSMS Extension
//
//  Created by Mustafa on 2/7/26.
//

import IdentityLookup

final class MessageFilterExtension: ILMessageFilterExtension {
    
    // Extension başlatıldığında çalışır
}

extension MessageFilterExtension: ILMessageFilterQueryHandling {
    
    func handle(_ queryRequest: ILMessageFilterQueryRequest, context: ILMessageFilterExtensionContext, completion: @escaping (ILMessageFilterQueryResponse) -> Void) {
        
        let response = ILMessageFilterQueryResponse()
        let logic = FilterLogic.shared
        
        // App Group veritabanını tazele (En son kuralları al)
        logic.loadRules()
        
        // Sender ve Body verilerini al
        let sender = queryRequest.sender
        let body = queryRequest.messageBody
        
        // Filtreleme mantığını çalıştır
        let action = logic.checkMessage(body: body, sender: sender)
        
        if action == .junk {
            logic.incrementBlockedCount()
        }
        
        response.action = action
        
        completion(response)
    }
}
