//
//  Stock.swift
//  TradingTable
//
//  Created by Panachai Sulsaksakul on 1/14/26.
//

import Foundation

// Domain Model
struct Stock {
    let symbol: String
    let companyName: String
    let logoURL: String
    let price: Double
    let priceChange: Double
    let priceChangePercent: Double

    // Convenience init from API models
    init(profile: CompanyProfile, quote: StockQuote) {
        self.symbol = profile.ticker
        self.companyName = profile.name
        self.logoURL = profile.logo
        self.price = quote.currentPrice
        self.priceChange = quote.change
        self.priceChangePercent = quote.percentChange
    }
}

// External Models
struct CompanyProfile: Codable {
    let ticker: String
    let name: String
    let logo: String
}

struct StockQuote: Codable {
    let currentPrice: Double
    let change: Double
    let percentChange: Double

    enum CodingKeys: String, CodingKey {
        case currentPrice = "c"
        case change = "d"
        case percentChange = "dp"
    }
}