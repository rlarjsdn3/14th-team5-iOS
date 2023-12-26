//
//  ProfileViewReactor.swift
//  App
//
//  Created by Kim dohyun on 12/17/23.
//

import Foundation

import Core
import Domain
import ReactorKit


public final class ProfileViewReactor: Reactor {
    public var initialState: State
    private let profileUseCase: ProfileViewUsecaseProtocol
    
    public enum Action {
        case viewDidLoad
    }
    
    public enum Mutation {
        case setLoading(Bool)
        case setFeedCategroySection([ProfileFeedSectionItem])
        case setProfileMemberItems(ProfileMemberResponse)
        case setProfilePostItems(ProfilePostResponse)
    }
    
    public struct State {
        var isLoading: Bool
        @Pulse var feedSection: [ProfileFeedSectionModel]
        @Pulse var profileMemberEntity: ProfileMemberResponse?
        @Pulse var profilePostEntity: ProfilePostResponse?
    }
    
    init(profileUseCase: ProfileViewUsecaseProtocol) {
        self.profileUseCase = profileUseCase
        self.initialState = State(
            isLoading: false,
            feedSection: [.feedCategory([])],
            profileMemberEntity: nil
        )
    }
    
    
    public func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            
            let query: ProfilePostQuery = ProfilePostQuery(page: 1, size: 10)
            
            return .concat(
                .just(.setLoading(true)),
                profileUseCase.executeProfileMemberItems()
                    .asObservable()
                    .flatMap { entity -> Observable<ProfileViewReactor.Mutation> in
                            .just(.setProfileMemberItems(entity))
                    },
                
                
                profileUseCase.executeProfilePostItems(query: query, parameters: ProfilePostDefaultValue(date: "2023-12-05", memberId: "01HJBNXAV0TYQ1KESWER45A2QP", sort: "DESC"))
                    .asObservable()
                    .flatMap { entity -> Observable<ProfileViewReactor.Mutation> in
                        var sectionItem: [ProfileFeedSectionItem] = []
                        entity.results.forEach {
                            sectionItem.append(.feedCategoryItem(ProfileFeedCellReactor(imageURL: $0.imageUrl, title: $0.content, date: DateFormatter.yyyyMMdd.string(from: $0.createdAt))))
                            
                        }
                        return .concat(
                            .just(.setProfilePostItems(entity)),
                            .just(.setFeedCategroySection(sectionItem)),
                            .just(.setLoading(false))
                        )

                    }
            )
            
        }
    }
    
    
    public func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case let .setLoading(isLoading):
            newState.isLoading = isLoading
        case let .setFeedCategroySection(section):
            let sectionIndex = getSection(.feedCategory([]))
            newState.feedSection[sectionIndex] = .feedCategory(section)
            
        case let .setProfilePostItems(entity):
            print("ProfilePost Entity: \(entity)")
            newState.profilePostEntity = entity
            
        case let .setProfileMemberItems(entity):
            print("ProfileMember Entity: \(entity)")
            newState.profileMemberEntity = entity
        }
        
        return newState
    }
    
}


extension ProfileViewReactor {
 
    func getSection(_ section: ProfileFeedSectionModel) -> Int {
        var index: Int = 0
        
        for i in 0 ..< self.currentState.feedSection.count where self.currentState.feedSection[i].getSectionType() == section.getSectionType() {
            index = i
        }
        
        return index
    }
}
