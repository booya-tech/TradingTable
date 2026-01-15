//
//  StockCell.swift
//  TradingTable
//
//  Created by Panachai Sulsaksakul on 1/14/26.
//

import UIKit

class StockCell: UITableViewCell {
    
    // MARK: - Cell Identifier
    static let identifier = "StockCell"
    
    // MARK: - UI Elements
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray6
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let symbolLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let companyNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let changeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup UI
    
    private func setupUI() {
        contentView.addSubview(logoImageView)
        contentView.addSubview(symbolLabel)
        contentView.addSubview(companyNameLabel)
        contentView.addSubview(priceLabel)
        contentView.addSubview(changeLabel)
        
        NSLayoutConstraint.activate([
            // Logo - left side, 60x60
            logoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            logoImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 50),
            logoImageView.heightAnchor.constraint(equalToConstant: 50),
            
            // Symbol - top left of text area
            symbolLabel.leadingAnchor.constraint(equalTo: logoImageView.trailingAnchor, constant: 12),
            symbolLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            
            // Company name - below symbol
            companyNameLabel.leadingAnchor.constraint(equalTo: symbolLabel.leadingAnchor),
            companyNameLabel.topAnchor.constraint(equalTo: symbolLabel.bottomAnchor, constant: 4),
            companyNameLabel.trailingAnchor.constraint(equalTo: priceLabel.leadingAnchor, constant: -8),
            
            // Price - top right
            priceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            priceLabel.topAnchor.constraint(equalTo: symbolLabel.topAnchor),
            
            // Change % - below price
            changeLabel.trailingAnchor.constraint(equalTo: priceLabel.trailingAnchor),
            changeLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 4),
        ])
    }
    
    // MARK: - Configure Cell
    
    func configure(with stock: Stock) {
        symbolLabel.text = stock.symbol
        companyNameLabel.text = stock.companyName
        priceLabel.text = String(format: "$%.2f", stock.price)
        
        // Format change percentage with color
        let changePercent = stock.priceChangePercent
        let sign = changePercent >= 0 ? "+" : ""
        changeLabel.text = String(format: "%@%.2f%%", sign, changePercent)
        changeLabel.textColor = changePercent >= 0 ? .systemGreen : .systemRed
        
        // Load image (we'll implement async loading later)
        logoImageView.image = nil // Reset for reuse
    }
    
    // MARK: - Reuse
    /// Cells are recycled. Reset all content here to avoid showing stale data from previous cell
    override func prepareForReuse() {
        super.prepareForReuse()
        logoImageView.image = nil
        symbolLabel.text = nil
        companyNameLabel.text = nil
        priceLabel.text = nil
        changeLabel.text = nil
    }
}
