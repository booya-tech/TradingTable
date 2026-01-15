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
        "CRM", "ORCL", "ADBE", "PYPL", "SHOP",
        "SQ", "UBER", "LYFT", "SNAP", "PINS",
        "ROKU", "ZM", "DOCU", "COIN", "HOOD"
    ]
    
    // MARK: - Pagination State
    
    private var currentPage = 0
    private let pageSize = 5  // Smaller page size to see pagination clearly
    private(set) var isLoading = false
    private(set) var hasMoreData = true
    
    // MARK: - Bindings
    
    var onStocksUpdated: ((Int) -> Void)?
    var onError: ((Error) -> Void)?
    var onLoadingStateChanged: ((Bool) -> Void)?
    
    // MARK: - Initialization
    
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
    
    // MARK: - Pagination Check
    
    func shouldLoadMore() -> Bool {
        return hasMoreData && !isLoading
    }
    
    // MARK: - Data Loading
    
    func loadInitialStocks() async {
        currentPage = 0
        stocks = []
        hasMoreData = true
        
        await loadNextPage(isInitialLoad: true)
    }
    
    func loadNextPage(isInitialLoad: Bool = false) async {
        guard !isLoading, hasMoreData else { return }
        
        let startIndex = currentPage * pageSize
        let endIndex = min(startIndex + pageSize, allSymbols.count)
        
        guard startIndex < allSymbols.count else {
            hasMoreData = false
            return
        }
        
        let symbolsToFetch = Array(allSymbols[startIndex..<endIndex])
        
        isLoading = true
        await MainActor.run {
            onLoadingStateChanged?(true)
        }
        
        do {
            let fetchedStocks = try await stockService.fetchStocks(symbols: symbolsToFetch)
            
            let addedCount = fetchedStocks.count
            stocks.append(contentsOf: fetchedStocks)
            currentPage += 1
            
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
}
