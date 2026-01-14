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