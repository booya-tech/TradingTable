//
//  ViewController.swift
//  TradingTable
//
//  Created by Panachai Sulsaksakul on 1/14/26.
//

import UIKit

class ViewController: UIViewController {
    
    // MARK: - Properties
    
    private let viewModel = StockListViewModel()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.rowHeight = 70
        table.separatorStyle = .singleLine
        return table
    }()
    
    // Footer loading indicator (shown at BOTTOM when loading more)
    private lazy var footerLoadingView: UIView = {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 50))
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.center = CGPoint(x: footerView.bounds.midX, y: footerView.bounds.midY)
        spinner.tag = 100 // Tag to find it later
        footerView.addSubview(spinner)
        return footerView
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        bindViewModel()
        fetchData()
    }
    
    // MARK: - Setup UI
    
    private func setupUI() {
        title = "Stocks"
        view.backgroundColor = .systemBackground
    }
    
    // MARK: - Setup TableView
    
    private func setupTableView() {
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(StockCell.self, forCellReuseIdentifier: StockCell.identifier)
    }
    
    // MARK: - Bind ViewModel
    
    private func bindViewModel() {
        viewModel.onStocksUpdated = { [weak self] addedCount in
            guard let self = self else { return }
            
            if addedCount > 0 {
                let startIndex = self.viewModel.numberOfRows - addedCount
                let endIndex = self.viewModel.numberOfRows
                let indexPaths = (startIndex..<endIndex).map { IndexPath(row: $0, section: 0) }
                
                self.tableView.performBatchUpdates {
                    self.tableView.insertRows(at: indexPaths, with: .automatic)
                }
            } else {
                self.tableView.reloadData()
            }
            
            self.updateTitle()
        }
        
        viewModel.onError = { [weak self] error in
            self?.showError(error)
        }
        
        // Show/hide footer loading indicator
        viewModel.onLoadingStateChanged = { [weak self] isLoading in
            self?.updateLoadingFooter(isLoading: isLoading)
        }
    }
    
    // MARK: - Loading Footer
    
    private func updateLoadingFooter(isLoading: Bool) {
        if isLoading && viewModel.hasMoreData {
            // Show footer with spinner
            tableView.tableFooterView = footerLoadingView
            if let spinner = footerLoadingView.viewWithTag(100) as? UIActivityIndicatorView {
                spinner.startAnimating()
            }
        } else {
            // Hide footer
            if let spinner = footerLoadingView.viewWithTag(100) as? UIActivityIndicatorView {
                spinner.stopAnimating()
            }
            tableView.tableFooterView = nil
        }
    }
    
    // MARK: - Load Data
    
    private func fetchData() {
        Task {
            await viewModel.loadInitialStocks()
        }
    }
    
    private func updateTitle() {
        title = "Stocks (\(viewModel.numberOfRows)/\(viewModel.totalAvailableStocks))"
    }
    
    // MARK: - Error Handling
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: StockCell.identifier,
            for: indexPath
        ) as? StockCell else {
            return UITableViewCell()
        }
        
        let stock = viewModel.stock(at: indexPath.row)
        cell.configure(with: stock)
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let stock = viewModel.stock(at: indexPath.row)
        print("Selected: \(stock.symbol)")
    }
}

// MARK: - UIScrollViewDelegate (Pagination Trigger)

extension ViewController {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height
        
        // Trigger when user scrolls to BOTTOM (100 points from end)
        let distanceFromBottom = contentHeight - offsetY - frameHeight
        
        if distanceFromBottom < 100 && viewModel.shouldLoadMore() {
            Task {
                await viewModel.loadNextPage()
            }
        }
    }
}
