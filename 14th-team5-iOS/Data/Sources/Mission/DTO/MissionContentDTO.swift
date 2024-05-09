//
//  MissionContentDTO.swift
//  Data
//
//  Created by Kim dohyun on 5/8/24.
//

import Foundation

import Domain


struct MissionContentResponse: Decodable {
    let missionId: String
    let missionContent: String
    
    
    enum CodingKeys: String, CodingKey {
        case missionId = "id"
        case missionContent = "content"
    }
}


extension MissionContentResponse {
    func toDomain() -> MissionContentData {
        return .init(
            missionId: missionId,
            missionContent: missionContent
        )
    }
}
