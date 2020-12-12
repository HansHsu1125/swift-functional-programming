//
//  Curry_Semigroup.playground
//
//  Created by Hans Hsu on 2020/12/1.
//  Copyright © 2020 Hans Hsu. All rights reserved.
//

import UIKit

// The example is to use curry api for builder. it can inject parameter by async way.

typealias TickGenerator = (String) -> (String) -> (String) -> () -> TicketInfo

struct TicketInfo {
    let from:String
    let destination:String
    let transportation:String
}

extension TicketInfo : CustomStringConvertible {
    var description: String {
        return "The ticket info is from: \(from) to: \(destination) by \(transportation)."
    }
}

class TicketBuilder { }

extension TicketBuilder {
    class func getTicketGenerator() -> TickGenerator {
        return {
            (from) in {
                (destination) in {
                    (transportation) in {
                        .init(from: from, destination: destination, transportation: transportation)
                    }
                }
            }
        }
    }
}

// Get generator for enter from
let enterFromGenerator = TicketBuilder.getTicketGenerator()

// Get result for enter destination
let enterDestination = enterFromGenerator("Taipei")

// Get generator for enter transportation
let enterTransportation = enterDestination("Kaohsiung")

// Get generator for create info
let ticketGenerator = enterTransportation("Train")

let ticket:TicketInfo = ticketGenerator()
print(ticket.description)



