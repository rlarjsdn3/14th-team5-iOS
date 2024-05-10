//
//  BalloonReactor.swift
//  App
//
//  Created by 마경미 on 10.05.24.
//

import Foundation

import Core
import Domain

import ReactorKit

enum BalloonType: Equatable {
    static func == (lhs: BalloonType, rhs: BalloonType) -> Bool {
        switch (lhs, rhs) {
        case (.normal, .normal):
            return true
        case (.picks, .picks):
            return true
        default:
            return false
        }
    }
    
    case normal
    case picks([Picker])
}

final class BalloonReactor: Reactor {
    enum Action {
        case setType(BalloonType)
    }
    
    enum Mutation {
        case updateType(BalloonType)
    }
    
    struct State {
        var type: BalloonType = .normal
    }
    
    let initialState: State = State()
}

extension BalloonReactor {
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .setType(let type):
            return Observable.just(.updateType(type))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .updateType(let type):
            newState.type = type
        }
        
        return newState
    }
}
