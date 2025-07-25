import SwiftUI
import Charts

struct BalanceChartView: View {
    let points: [DailyBalance]

    @State private var selectedBalance: DailyBalance?
        @State private var indicatorPosition: CGPoint = .zero
    
    private var tickDates: [Date] {
        guard let first = points.first?.date,
              let last  = points.last?.date else { return [] }
        let mid = Date(timeInterval: (last.timeIntervalSince1970 - first.timeIntervalSince1970)/2,
                       since: first)
        return [first, mid, last]
    }

    var body: some View {
        
        
        // +1 день — фейковая точка, чтобы ось не обрезалась
        let last = points.last?.date ?? Date()
        let paddedDate = Calendar.current.date(byAdding: .day, value: 1, to: last)!
        let paddedPoints = points + [DailyBalance(date: paddedDate, income: 0, expense: 0)]

        Chart {
            ForEach(paddedPoints) { p in
                // не рисуем «пустую» точку
                if p.date != paddedDate {
                    let h = NSDecimalNumber(decimal: p.net.magnitude).doubleValue
                    if #available(iOS 17, *) {
                        BarMark(
                            x: .value("Дата", p.date, unit: .day),
                            yStart: .value("Start", 0),
                            yEnd:   .value("End", h)
                        )
                        .foregroundStyle(p.expense > p.income ? .red : .green)
                        .cornerRadius(6)
                    } else {
                        RectangleMark(
                            x: .value("Дата", p.date, unit: .day),
                            yStart: .value("Start", 0),
                            yEnd:   .value("End", h)
                        )
                        .foregroundStyle(p.expense > p.income ? .red : .green)
                    }
                }
                // invisible padding point
                               if let last = points.last?.date {
                                   let pad = Calendar.current.date(byAdding: .day, value: 1, to: last)!
                                   RuleMark(x: .value("pad", pad))
                                       .opacity(0.001)
                               }
            }
        }
        .chartXAxis {
            AxisMarks(values: tickDates) { v in
                AxisValueLabel(format: .dateTime.day().month(.twoDigits))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine().foregroundStyle(.clear)
                AxisTick().foregroundStyle(.clear)
            }
        }
        .chartOverlay { proxy in
                     Rectangle().fill(Color.clear).contentShape(Rectangle())
                         .gesture(
                             DragGesture(minimumDistance: 0)
                                 .onChanged { value in
                                     let location = value.location
                                     if let date: Date = proxy.value(atX: location.x) {
                                         // найти ближайшую точку
                                         if let nearest = points.min(by: { abs($0.date.timeIntervalSince1970 - date.timeIntervalSince1970) <
                                                                             abs($1.date.timeIntervalSince1970 - date.timeIntervalSince1970) }) {
                                             selectedBalance = nearest
                                             indicatorPosition = CGPoint(x: location.x, y: location.y)
                                         }
                                     }
                                 }
                         )
                 }
                 .overlay(alignment: .topLeading) {
                     if let sel = selectedBalance {
                         VStack(alignment: .leading, spacing: 4) {
                             Text(sel.date, format: .dateTime.day().month().year())
                                 .font(.caption)
                             Text((sel.net as NSNumber) as! Decimal.FormatStyle.FormatInput, format: .number)
                         }
                         .padding(8)
                         .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                         .position(x: indicatorPosition.x + 16, y: indicatorPosition.y - 32)
                         .transition(.opacity)
                     }
                 }
        .chartPlotStyle { $0.background(.clear) }
        .frame(maxWidth: .infinity, minHeight: 220)
        .background(Color(.systemGray6))
        .padding(.trailing, 12) // воздух, чтоб List ничего не резал
    }
}
