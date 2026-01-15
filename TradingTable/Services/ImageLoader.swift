//
//  ImageLoader.swift
//  TradingTable
//
//  Created by Panachai Sulsaksakul on 1/15/26.
//

import UIKit

class ImageLoader {
    // Singleton for shared cache
    static let shared = ImageLoader()

    // In-memory cache
    private var cache = NSCache<NSString, UIImage>()

    private init() {}

    func loadImage(from urlString: String) async -> UIImage? {
        // Check cache first (if available, return immediately)
        if let cachedImage = cache.object(forKey: urlString as NSString) {
            return cachedImage
        }

        // Validate URL
        guard let url = URL(string: urlString) else { return nil }

        // Fetch from network
        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            guard let image = UIImage(data: data) else  {
                return nil
            }

            // Cache the image
            cache.setObject(image, forKey: urlString as NSString)

            // Return the image
            return image
        } catch {
            print("Failed to load image: \(error)")
            return nil
        }
    }
}
