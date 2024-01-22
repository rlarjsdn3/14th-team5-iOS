//
//  PostReactor.swift
//  App
//
//  Created by 마경미 on 09.12.23.
//

import Foundation
import Core
import Domain

import ReactorKit
import RxDataSources

final class PostReactor: Reactor {
    enum Action {
        case tapBackButton
        case setPost(Int)
        case fetchPost(String)
    }
    
    enum Mutation {
        case setPop
        case setSelectedPostIndex(Int)
        case fetchedPost(PostData?)
        case showReactionSheet([String])
        case presentPostCommentSheet(String, Int)
    }
    
    struct State {
        let selectedIndex: Int
        let originPostLists: PostSection.Model
        
        var isPop: Bool = false
        var selectedPost: PostListData = .init(postId: "", author: .init(memberId: "", profileImageURL: "", name: ""), emojiCount: 0, imageURL: "", content: "", time: "")
        
        @Pulse var fetchedPost: PostData? = nil
        @Pulse var reactionMemberIds: [String] = []
        @Pulse var shouldPresentPostCommentSheet: (String, Int) = (.none, 0)
    }
    
    let initialState: State
    
    let postRepository: PostListUseCaseProtocol
    let emojiRepository: EmojiUseCaseProtocol
    let provider: GlobalStateProviderProtocol
    
    init(provider: GlobalStateProviderProtocol, postRepository: PostListUseCaseProtocol, emojiRepository: EmojiUseCaseProtocol, initialState: State) {
        self.provider = provider
        self.postRepository = postRepository
        self.emojiRepository = emojiRepository
        self.initialState = initialState
    }
}

extension PostReactor {
    func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        let eventMutation = provider.reactionSheetGloablState.event
            .flatMap { event -> Observable<Mutation> in
                switch event {
                case let .showReactionMemberSheet(memberIds):
                    return Observable<Mutation>.just(.showReactionSheet(memberIds))
                }
            }
        
        let postMutation = provider.postGlobalState.event
            .flatMap { event -> Observable<Mutation> in
                switch event {
                case let .presentPostCommentSheet(postId, commentCount):
                    return Observable<Mutation>.just(.presentPostCommentSheet(postId, commentCount))
                }
            }
        
        return Observable<Mutation>.merge(mutation, eventMutation, postMutation)
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case let .fetchPost(postId):
            let query: PostQuery = PostQuery(postId: postId)
            return postRepository.excute(query: query)
                .asObservable()
                .flatMap { post in
                    return Observable.just(Mutation.fetchedPost(post))
                }
        case let .setPost(index):
            return Observable.just(Mutation.setSelectedPostIndex(index))
        case .tapBackButton:
            return Observable.just(Mutation.setPop)
        }
    }
        
        func reduce(state: State, mutation: Mutation) -> State {
            var newState = state
            switch mutation {
            case let .fetchedPost(post):
                newState.fetchedPost = post
            case let .setSelectedPostIndex(index):
                if case let .main(postData) = newState.originPostLists.items[index] {
                    newState.selectedPost = postData
                }
            case .setPop:
                newState.isPop = true
            case let .showReactionSheet(memberIds):
                newState.reactionMemberIds = memberIds
                
            case let .presentPostCommentSheet(postId, commentCount):
                newState.shouldPresentPostCommentSheet = (postId, commentCount)
            }
            return newState
        }
}
