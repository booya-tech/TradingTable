//
//  StockListViewModel.swift
//  TradingTable
//
//  Created by Panachai Sulsaksakul on 1/14/26.
//

import Foundation

class StockListViewModel {
    // MARK: - Properties
    private let stockService: StockServiceProtocol
    private(set) var stocks: [Stock] = []

    // Stock symbols to fetch
    private let symbols = ["AAPL", "GOOGL", "MSFT", "AMZN", "TSLA", "META", "NVDA", "NFLX"]

    // MARK: - Bindings (View will listen)
    var onStocksUpdated: (() -> Void)?
    var onError: ((Error) -> Void)?

    // MARK: - Initialization(Dependency Injection)
    init(stockService: StockServiceProtocol = StockService()) {
        self.stockService = stockService
    }

    // MARK: - Computed Properties
    var numberOfRows: Int {
        return stocks.count
    }

    // MARK: - Data Loading
    func stock(at index: Int) -> Stock {
        return stocks[index]
    }

    func loadStocks() async {
        do {
            let fetchedStocks = try await stockService.fetchStocks(symbols: symbols)
            self.stocks = fetchedStocks

            // Notify view on main thread
            await MainActor.run {
                self.onStocksUpdated?()
            }
        } catch {
            await MainActor.run {
                self.onError?(error)
            }
        }
    }

}
