//
//  JoinFamilyReactor.swift
//  App
//
//  Created by 마경미 on 12.01.24.
//

import Core
import Domain

import ReactorKit

public final class JoinFamilyReactor: Reactor {
    // MARK: - Action
    public enum Action {
        case makeFamily
        case joinFamily
    }
    
    // MARK: - Mutate
    public enum Mutation {
        case setShowHome(Bool)
        case setShowJoineFamily(Bool)
    }
    
    // MARK: - State
    public struct State {
        var isShowHome: Bool = false
        var isShowJoinFamily: Bool = false
        var showToastMessage: String = ""
    }
    
    // MARK: - Properties
    public let initialState: State
    private let familyUseCase: FamilyViewUseCaseProtocol
    
    init(initialState: State, familyUseCase: FamilyViewUseCaseProtocol) {
        self.initialState = initialState
        self.familyUseCase = familyUseCase
    }
}

extension JoinFamilyReactor {
    
    // MARK: - Mutate
    public func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .makeFamily:
            MPEvent.Account.creatGroup.track(with: nil)
            return familyUseCase.executeCreateFamily()
                .flatMap {
                    guard let familyResponse: FamilyResponse = $0 else {
                        // 여기 왜 뭐지?
                        return Observable.just(Mutation.setShowHome(false))
                    }
                    App.Repository.member.familyId.accept(familyResponse.familyId)
                    return Observable.just(Mutation.setShowHome(true))
                }
        case .joinFamily:
            MPEvent.Account.invitedGroup.track(with: nil)
            return Observable.just(Mutation.setShowJoineFamily(true))
        }
    }
    
    // MARK: - Reduce
    public func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case let .setShowHome(isShow):
            newState.isShowHome = isShow
        case let .setShowJoineFamily(isShow):
            newState.isShowJoinFamily = isShow
        }
        return newState
    }
}
