//
//  CalendarUseCase.swift
//  Domain
//
//  Created by 김건우 on 12/29/23.
//

import Core
import Foundation

import RxSwift

public protocol CalendarUseCaseProtocol {
    func executeFetchCalednarResponse(yearMonth: String) -> Observable<ArrayResponseCalendarEntity?>
    func executeFetchDailyCalendarResponse(yearMonthDay: String) -> Observable<ArrayResponseDailyCalendarEntity?>
    func executeFetchStatisticsSummary(yearMonth: String) -> Observable<FamilyMonthlyStatisticsEntity?>
    func executeFetchCalendarBenner(yearMonth: String) -> Observable<BannerEntity?>
}

public final class CalendarUseCase: CalendarUseCaseProtocol {
    private let calendarRepository: CalendarRepositoryProtocol
    
    public init(calendarRepository: CalendarRepositoryProtocol) {
        self.calendarRepository = calendarRepository
    }

    public func executeFetchCalednarResponse(yearMonth: String) -> Observable<ArrayResponseCalendarEntity?> {
        return calendarRepository.fetchCalendarResponse(yearMonth: yearMonth)
    }
    
    public func executeFetchDailyCalendarResponse(yearMonthDay: String) -> Observable<ArrayResponseDailyCalendarEntity?> {
        return calendarRepository.fetchDailyCalendarResponse(yearMonthDay: yearMonthDay)
    }
    
    public func executeFetchStatisticsSummary(yearMonth: String) -> Observable<FamilyMonthlyStatisticsEntity?> {
        return calendarRepository.fetchStatisticsSummary(yearMonth: yearMonth)
    }
    
    public func executeFetchCalendarBenner(yearMonth: String) -> Observable<BannerEntity?> {
        return calendarRepository.fetchCalendarBanner(yearMonth: yearMonth)
    }
}


public extension InjectIdentifier {
    static var calendarUseCase: InjectIdentifier<CalendarUseCaseProtocol> {
        .by(type: CalendarUseCaseProtocol.self)
    }
}
