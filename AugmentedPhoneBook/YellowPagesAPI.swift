//
//  YellowPagesAPI.swift
//  AugmentedPhoneBook
//
//  Created by Stephen Heaps on 2017-07-30.
//  Copyright © 2017 Stephen Heaps. All rights reserved.
//

import Foundation

struct Summary {
    let province: String
    let currentPage: Int
    let firstListing: Int
    let lastListing: Int
    let listingsPerPage: Int
    let pageCount: Int
    let totalListings: Int
    let what: String
    let whereString: String
    let location: (latitude: Double, longitude: Double)
}
extension Summary {
    init?(json: [String: Any]) {
        guard let province = json["Prov"] as? String,
            let currentPage = json["currentPage"] as? Int,
            let firstListing = json["firstListing"] as? Int,
            let lastListing = json["lastListing"] as? Int,
            let listingsPerPage = json["listingsPerPage"] as? Int,
            let pageCount = json["pageCount"] as? Int,
            let totalListings = json["totalListings"] as? Int,
            let what = json["what"] as? String,
            let longitude = json["longitude"] as? String,
            let latitude = json["latitude"] as? String,
            let whereString = json["where"] as? String else {
                return nil
        }
        
        self.province = province
        self.currentPage = currentPage
        self.firstListing = firstListing
        self.lastListing = lastListing
        self.listingsPerPage = listingsPerPage
        self.pageCount = pageCount
        self.totalListings = totalListings
        self.what = what
        
        if let latitudeDouble = Double(latitude), let longitudeDouble = Double(longitude) {
            self.location = (latitudeDouble, longitudeDouble)
        } else {
            self.location = (0, 0)
        }
        self.whereString = whereString
    }
}

struct Category {
    let id: String
    let value: String
}
extension Category {
    init?(json: [String: Any]) {
        guard let id = json["id"] as? String,
            let value = json["value"] as? String else {
                return nil
        }
        
        self.id = id
        self.value = value
    }
}
struct Address {
    let city: String
    let postalCode: String
    let province: String
    let street: String
}
extension Address {
    init?(json: [String: Any]) {
        guard let city = json["city"] as? String,
            let postalCode = json["pcode"] as? String,
            let province = json["prov"] as? String,
            let street = json["street"] as? String else {
                return nil
        }
        
        self.city = city
        self.postalCode = postalCode
        self.province = province
        self.street = street
    }
}

public struct Business {
    var categories: [Category]
    let address: Address
    let distance: Double
    let location: (latitude: Double, longitude: Double)
    let id: String
    let url: URL?
    let name: String
    let phoneNumber: Int
}
extension Business {
    init?(json: [String: Any]) {
        guard let categories = json["Categories"] as? [[String: Any]],
            let address = json["address"] as? [String:Any],
            let distance = json["distance"] as? String,
            let geoCode = json["geoCode"] as? [String:String],
            let id = json["id"] as? String,
            let merchantURL = json["merchantUrl"] as? String,
            let name = json["name"] as? String,
            let phone = json["phone"] as? [String:String]
            else { return nil }
        
        self.categories = []
        for category in categories {
            if let categoryStruct = Category(json: category) {
                self.categories.append(categoryStruct)
            }
        }
        
        self.address = Address(json: address) ?? Address(city: "", postalCode: "", province: "", street: "")
        
        if let distanceDouble = Double(distance) {
            self.distance = distanceDouble
        } else {
            self.distance = -1
        }
        
        if let latitude = geoCode["latitude"],
            let longitude = geoCode["longitude"] {
            if let latitudeDouble = Double(latitude), let longitudeDouble = Double(longitude) {
                self.location = (latitudeDouble, longitudeDouble)
            } else {
                self.location = (0, 0)
            }
        } else {
            self.location = (0, 0)
        }
        
        self.id = id
        
        self.url = URL(string: merchantURL)
        self.name = name
        if let phoneNumber = phone["dispNum"] {
            if let phoneDouble = Int(phoneNumber) {
                self.phoneNumber = phoneDouble
            } else {
                self.phoneNumber = 0
            }
        } else {
            self.phoneNumber = 0
        }
    }
}

