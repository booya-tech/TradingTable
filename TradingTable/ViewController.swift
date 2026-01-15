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

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
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
        tableView.prefetchDataSource = self // enable prefetching
        tableView.register(StockCell.self, forCellReuseIdentifier: StockCell.identifier)
    }

    // MARK: - Bind ViewModel
    private func bindViewModel() {
        viewModel.onStocksUpdated = { [weak self] addedCount in
            guard let self = self else { return }

            if addedCount > 0 {
                // Calculate index paths for new rows
                let startIndex = self.viewModel.numberOfRows - addedCount
                let endIndex = self.viewModel.numberOfRows
                let indexPaths = (startIndex..<endIndex).map { IndexPath(row: $0, section: 0) }

                // Insert only new rows (preserves scroll position!)
                self.tableView.insertRows(at: indexPaths, with: .automatic)
            } else {
                // Initial load or reset - use reloadData
                self.tableView.reloadData()
            }

            self.updateTitle()
        }

        viewModel.onError = { [weak self] error in
            self?.showError(error)
        }

        viewModel.onLoadingStateChanged = { [weak self] isLoading in
            if isLoading {
                self?.loadingIndicator.startAnimating()
            } else {
                self?.loadingIndicator.stopAnimating()
            }
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
            message: error.localizedDescription, preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(
                title: "OK",
                style: .default
            )
        )
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: StockCell.identifier, for: indexPath) as? StockCell else {
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
        let stock = viewModel.stock(at: indexPath.row)
        print("Selected stock: \(stock.symbol)")
    }
}

// MARK: - UITableViewDataSourcePrefetching
extension ViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        // Find the maximum row being prefetched
        guard let maxIndex = indexPaths.map({ $0.row }).max() else { return }

        // Check if we should load more
        if viewModel.shouldLoadMore(currentIndex: maxIndex) {
            Task {
                await viewModel.loadNextPage()
            }
        }
    }
}
