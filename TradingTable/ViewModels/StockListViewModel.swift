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
    private let allSymbols = [
        "AAPL", "GOOGL", "MSFT", "AMZN", "TSLA",
        "META", "NVDA", "NFLX", "AMD", "INTC",
        "CRM", "ORCL", "ADBE", "PYPL", "SHOP"
    ]

    // MARK: - Pagination State
    private var currentPage = 0
    private let pageSize = 10
    private(set) var isLoading = false
    private(set) var hasMoreData = true

    // MARK: - Bindings (View will listen)
    var onStocksUpdated: ((Int) -> Void)?
    var onError: ((Error) -> Void)?
    var onLoadingStateChanged: ((Bool) -> Void)?

    // MARK: - Initialization(Dependency Injection)
    init(stockService: StockServiceProtocol = StockService()) {
        self.stockService = stockService
    }

    // MARK: - Computed Properties
    var numberOfRows: Int {
        return stocks.count
    }

    var totalAvailableStocks: Int {
        return allSymbols.count
    }

    // MARK: - Data Access
    func stock(at index: Int) -> Stock {
        return stocks[index]
    }

    // MARK: - Data Loading
    func loadInitialStocks() async {
        // Reset state
        currentPage = 0
        stocks = []
        hasMoreData = true

        await loadNextPage(isInitialLoad: true)
    }

    func loadNextPage(isInitialLoad: Bool = false) async {
        // Guard against duplicate loads or no more data
        guard !isLoading, hasMoreData else { return }

        // Calculate which symbols to fetch
        let startIndex = currentPage * pageSize
        let endIndex = min(startIndex + pageSize, allSymbols.count)

        // check if we've reached the end
        guard startIndex < allSymbols.count else {
            hasMoreData = false
            return
        }

        let symbolsToFetch = Array(allSymbols[startIndex..<endIndex])

        // Update loading state
        isLoading = true
        await MainActor.run {
            onLoadingStateChanged?(true)
        }

        do {
            let fetchedStocks = try await stockService.fetchStocks(symbols: symbolsToFetch)

            // Append new stocks (no replace)
            let addedCount = fetchedStocks.count
            stocks.append(contentsOf: fetchedStocks)
            currentPage += 1

            // Check if we've loaded all stocks
            if endIndex >= allSymbols.count {
                hasMoreData = false
            }

            await MainActor.run {
                isLoading = false
                onLoadingStateChanged?(false)
                onStocksUpdated?(isInitialLoad ? 0 : addedCount)
            }
        } catch {
            await MainActor.run {
                isLoading = false
                onLoadingStateChanged?(false)
                onError?(error)
            }
        }
    }

    // check if we should prefetch more data
    func shouldLoadMore(currentIndex: Int) -> Bool {
        // Load more when user is 2 items from the end
        let threshold = stocks.count - 2
        return currentIndex >= threshold && hasMoreData && !isLoading
    }
}
