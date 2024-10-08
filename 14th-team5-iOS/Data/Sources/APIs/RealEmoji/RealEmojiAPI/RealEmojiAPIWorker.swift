//
//  RealEmojiAPIWorker.swift
//  Data
//
//  Created by 마경미 on 22.01.24.
//

import Foundation

import Core
import Domain

import Alamofire
import RxSwift

typealias RealEmojiAPIWorker = RealEmojiAPIs.Worker
extension RealEmojiAPIs {
    public final class Worker: APIWorker {
        static let queue = {
            ConcurrentDispatchQueueScheduler(queue: DispatchQueue(label: "RealEmojiAPIQueue", qos: .utility))
        }()
        
        public override init() {
            super.init()
            self.id = "RealEmojiAPIWorker"
        }
        
        var headers: [APIHeader] {
            var headers: [any APIHeader] = []

            _headers.subscribe(onNext: { result in
                if let unwrappedHeaders = result {
                    headers = unwrappedHeaders
                }
            }).dispose()

            return headers
        }
    }
}

extension RealEmojiAPIWorker {
    
    func fetchRealEmoji(query: FetchRealEmojiQuery) -> Single<[EmojiEntity]?> {
        let query = FetchRealEmojiListParameter(postId: query.postId)
        let spec = RealEmojiAPIs.fetchRealEmojiList(query).spec
        
        return request(spec: spec, headers: headers)
            .subscribe(on: Self.queue)
            .map(FetchRealEmojiListResponseDTO.self)
            .catchAndReturn(nil)
            .map {
                $0?.toDomain()
            }
            .asSingle()
    }
    
    func fetchMyRealEmoji() -> Single<[MyRealEmojiEntity?]> {
        let spec = RealEmojiAPIs.fetchMyRealEmoji.spec
        
        return request(spec: spec, headers: headers)
            .subscribe(on: Self.queue)
            .map(MyRealEmojiResponseDTO.self)
            .catchAndReturn(nil)
            .map {
                return $0?.toDomain() ?? Array(repeating: nil, count: 5)
            }
            .asSingle()
    }
    
    func addRealEmoji(query: CreateReactionQuery, body: CreateReactionRequest) -> Single<Void?> {
        let spec = RealEmojiAPIs.addRealEmoji(.init(postId: query.postId)).spec
        let body = AddRealEmojiRequestDTO(realEmojiId: body.emojiId)
        
        return request(spec: spec, headers: headers, jsonEncodable: body)
            .subscribe(on: Self.queue)
            .map(AddRealEmojiResponseDTO.self)
            .catchAndReturn(nil)
            .map {
                return $0?.toDomain()
            }
            .asSingle()
    }
    
    func removeRealEmoji(query: RemoveRealEmojiQuery) -> Single<Void?> {
        let spec = RealEmojiAPIs.removeRealEmoji(.init(postId: query.postId, realEmojiId: query.realEmojiId)).spec
        
        return request(spec: spec, headers: headers)
            .subscribe(on: Self.queue)
            .map(RemoveRealEmojiResponseDTO.self)
            .catchAndReturn(nil)
            .map {
                return $0?.toDomain()
            }
            .asSingle()
    }
}
