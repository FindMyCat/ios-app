//
//  SharedData.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 6/25/23.
//

import Foundation

class SharedData: ObservableObject {
    @Published var devices: [Device] = []
}
