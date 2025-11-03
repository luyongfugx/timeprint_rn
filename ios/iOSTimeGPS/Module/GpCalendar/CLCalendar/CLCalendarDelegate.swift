//
//  CLCalendarDelegate.swift
//  Created by waynelu on 2024/12/16.
//

import Foundation

protocol CLCalendarDelegate: AnyObject {
    func didSelectDate(date: Date, in view: CalendarView)
}

extension CLCalendarDelegate {
    func didSelectDate(date: Date, in view: CalendarView) {}
}
