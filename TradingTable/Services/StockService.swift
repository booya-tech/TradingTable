//
//  StockService.swift
//  TradingTable
//
//  Created by Panachai Sulsaksakul on 1/14/26.
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
}

protocol StockServiceProtocol {
    func fetchStock(symbol: String) async throws -> Stock
    func fetchStocks(symbols: [String]) async throws -> [Stock]
}

class StockService: StockServiceProtocol {
    private let apiKey = Secrets.finnhubAPIKey
    private let baseURL = "https://finnhub.io/api/v1"

    // Fetch company profile for a symbol
    func fetchCompanyProfile(symbol: String) async throws -> CompanyProfile {
        let urlString = "\(baseURL)/stock/profile2?symbol=\(symbol)&token=\(apiKey)"
        guard let url = URL(string: urlString) else { throw NetworkError.invalidURL }
        
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw NetworkError.invalidResponse }

        do {
            return try JSONDecoder().decode(CompanyProfile.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }

    // Fetch quote for a symbol
    func fetchQuote(symbol: String) async throws -> StockQuote {
        let urlString = "\(baseURL)/quote?symbol=\(symbol)&token=\(apiKey)"
        guard let url = URL(string: urlString) else { throw NetworkError.invalidURL }
        
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw NetworkError.invalidResponse }

        do {
            return try JSONDecoder().decode(StockQuote.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }

    // Fetch combined stock (calls both endpoints)
    func fetchStock(symbol: String) async throws -> Stock {
        async let profile = fetchCompanyProfile(symbol: symbol)
        async let quote = fetchQuote(symbol: symbol)

        return Stock(profile: try await profile, quote: try await quote)
    }

    func fetchStocks(symbols: [String]) async throws -> [Stock] {
        try await withThrowingTaskGroup(of: Stock.self) { group in
            for symbol in symbols {
                group.addTask {
                    try await self.fetchStock(symbol: symbol)
                }
            }

            var stocks: [Stock] = []
            for try await stock in group {
                stocks.append(stock)
            }
            return stocks
        }
    }
}
