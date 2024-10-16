import Foundation
import Dependencies


struct CalendarClient {
    var weekOf: (Date) -> Int
    var monthOf: (Date) -> Int
    var yearOf:  (Date) -> Int
}

extension CalendarClient: DependencyKey {
    static let liveValue: CalendarClient = .init 
    { date in
        Calendar.current.component(.weekOfYear, from: date)
    } monthOf: { date in
        Calendar.current.component(.month, from: date)
    } yearOf: { date in
        Calendar.current.component(.year, from: date)
    }
}

extension CalendarClient: TestDependencyKey {
    static let testValue: CalendarClient  = Self 
    { _ in
        Calendar.current.component(.weekOfYear, from: Date())
    } monthOf: { _ in
        Calendar.current.component(.month, from: Date())
    } yearOf: { _ in
        Calendar.current.component(.year, from: Date())
    }
}

extension DependencyValues {
    var calendarClient: CalendarClient {
        get { self[CalendarClient.self] }
        set { self[CalendarClient.self] = newValue }
    }
}
