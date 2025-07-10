//
//  AppRouter.swift
//  P2PKitDemo
//
//  Created by 이주현 on 7/8/25.
//
import Foundation
import SwiftUI

enum AppScreen {
    case gameStart
    case duo
    case triple
    case squad
}

class AppRouter: ObservableObject {
    @Published var currentScreen: AppScreen = .gameStart
}


