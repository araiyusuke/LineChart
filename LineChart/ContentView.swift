//
//  ContentView.swift
//  LineChart
//
//  Created by 名前なし on 2022/07/23.
//

import SwiftUI

struct ContentView: View {

    @State private var lineChartItems: [LineChartData.Items]?

    let items: LineChartData.Items

    init() {

        var lineChartData: [LineChartData] = []

        for _ in 1...200 {
                 let data = LineChartData.init(type: .measure, value: CGFloat.random(in: 40...100), datetime: .init(time: "01:00", date: "12"))
                 lineChartData.append(data)
             }

        items = LineChartData.Items(
            data: lineChartData
        )
    }


    var body: some View {
        ZStack {
            GeometryReader { geometry in
                LineChart(
                    items: items
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: geometry.size.height
                )
            }
        }
        .frame(height: 140)
    }
}

extension LineChartData {
    enum type {
        case target // 目標値
        case initial // 初回値
        case measure // 測定値
    }
}

extension LineChartData {
    struct DateTime {
        let time: String
        let date: String
    }
}

struct LineChartData  {
    let type: type
    let value: CGFloat?
    let datetime: DateTime
}

struct LineChart: View {

    let items: LineChartData.Items

    // グラフの線と文字の間のスペース
    let yAxisSpaceLabel: CGFloat = 11.0

    // グラフにプロットする円の半径
    let circleRadius: CGFloat = 5

    // グラフの線の太さ
    let lineWidth: CGFloat = 0.5

    // 最大ステップカウント数
    var stepMaxCount: Int {
        items.data.count
    }

    let padding: CGFloat = LineChartData.Items.padding

    // 初回値、目標値の横軸線の表示系管理

    var body: some View {

        GeometryReader { geometry in

            VStack(spacing: 0) {
                ScrollView(.horizontal) {

                    ZStack(alignment: .top) {

                        borderTop
                        verticalLine

                        ZStack {
                            lineAndCircle
                            label
                            optionLine
                        }
                        .padding(.vertical, padding / 2)
                    }
                    .frame(width: 2000, height: geometry.size.height)
                }
            }
        }
    }

    var label: some View {

        GeometryReader { geometry in

            let points = items.plots(size: geometry.size)
            let labels:[String] = items.measureLabels
            let stepWidth: CGFloat = 40

            ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                if let unwrappedPoint = point {
                    Text(labels[index])
                        .frame(width: stepWidth, alignment: .center)
                        .offset(x: unwrappedPoint.x - stepWidth / 2, y: unwrappedPoint.y + yAxisSpaceLabel)
                }
            }
        }
    }

    //　グラフの上部線
    private var borderTop: some View {
        Border(color: Color.gray)
            .frame(height: 1)
    }

    // 初回値、目標値の横軸ライン
    private var optionLine: some View {

        GeometryReader { geometry in

            ZStack {

                if let initialValue = items.initialValue {
                    Border(color: Color.red)
                        .frame(height: 2)
                        .offset(y: initialValue)
                    //                        .opacity(options.`init` == true ? 1 : 0)
                }

                if let targetValue = items.targetValue {
                    Border(color: Color.blue)
                        .frame(height: 2)
                        .offset(y: targetValue)
                    //                        .opacity(options.target == true ? 1 : 0)
                }
            }
        }
    }

    // グラフの縦線
    private var verticalLine: some View {

        GeometryReader { geometry in
            Path.verticalLine(
                max: stepMaxCount,
                size: geometry.size
            )
            .stroke(Color.gray, style: StrokeStyle(lineWidth: lineWidth, dash: [2]))
        }
    }

    // グラフの円と線
    private var lineAndCircle: some View {

        GeometryReader { geometry in

            Path
                .line(points: items.plots(size: geometry.size), size: geometry.size)
                .stroke(
                    Color.red.opacity(0.5),
                    style: StrokeStyle(lineWidth: lineWidth)
                )

            Path
                .circle(
                    points: items.plots(size: geometry.size),
                    size: geometry.size,
                    radius: circleRadius
                )
                .fill(
                    Color.red
                )
        }
    }
}

extension Path {

    // 円表示
    static func circle(points: [CGPoint?], size: CGSize, radius: CGFloat) -> Path {
        var path = Path()
        points.enumerated().forEach { index, point in

            guard let unwrappedPoint = point else {
                return
            }

            path.move(to: unwrappedPoint)
            path.addArc(center: unwrappedPoint,
                        radius: radius,
                        startAngle: Angle(degrees: 0),
                        endAngle:   Angle(degrees: 360),
                        clockwise: false)
        }
        return path
    }

    // 線表示
    static func line(points: [CGPoint?], size: CGSize) -> Path {

        var path = Path()

        let notNillIndex = points.indices.filter {
            points[$0] != nil
        }

        points.enumerated().forEach { index, point in

            guard let unwrappedPoint = point else {
                return
            }

            if index != notNillIndex.first {
                path.addLine(to: unwrappedPoint)
            } else {
                path.move(to: unwrappedPoint)
            }
        }
        return path
    }

    // 縦軸のダッシュ線
    static func verticalLine(max: Int,  size: CGSize) -> Path {

        let stepWidth: CGFloat = 40
        let space: CGFloat = stepWidth * 0.5
        var path = Path()
        for index in 0...max {
            path.move(to: .init(x: stepWidth * CGFloat(index) + space, y: 0))
            path.addLine(to: .init(x: stepWidth * CGFloat(index) + space, y: size.height))
        }
        return path
    }
}

extension LineChartData {

    struct Items {

        // グラフデータ
        let data: [LineChartData]

        // 最大値(nullは前後値で変換済み)
        var max: CGFloat {
            let notNill: [CGFloat] = measures.compactMap{ $0 }
            return notNill.max() ?? CGFloat(0)
        }

        // 最小値(nullは前後値で変換済み)
        var min: CGFloat {
            let notNill: [CGFloat] = measures.compactMap{ $0 }
            return notNill.min() ?? CGFloat(0)
        }

        // 　上下の余白
        static var padding: CGFloat = 60

        // グラフ全体の高さ
        let totalHeight: CGFloat = 140

        // プロットエリア
        var plotAreaHeight: CGFloat {
            return totalHeight - Self.padding
        }

        // 測定結果データ
        var measures: [CGFloat?] {
            return data.filter {
                $0.type == .measure
            }.map {
                $0.value
            }
        }

        // ラベルを返す(エラーの場合は空文字)
        var measureLabels: [String] {
            return data.filter {
                $0.type == .measure
            }.map {
                return  String(format: "%.1f", $0.value ?? 0)
            }
        }

        public func plots(size: CGSize) ->  [CGPoint?] {

            var result: [CGPoint?] = []

            measures.enumerated().forEach { index, value in

                guard let nonNillValue = value else {
                    return result.append(nil)
                }

                let stepWidth = CGFloat(40)
                let height = size.height

                let x = stepWidth * CGFloat(index) + stepWidth * 0.5
                let y: CGFloat


                if max == min {
                    y = height / 2
                } else {
                    y = height - (height / ( max - min) * (max - min  - (max - nonNillValue)))
                }

                result.append(CGPoint(x: x,y: y))
            }
            return result
        }

        func getLineChartData(_ types: type...) -> [LineChartData]? {
            return data.filter {
                types.contains($0.type)
            }
        }

        var initialValue: CGFloat? {

            if let first = getLineChartData(.initial)?.first {

                guard let valueNotNill = first.value else {
                    return nil
                }

                if valueNotNill >= max {
                    return 0
                }

                if valueNotNill <= min {
                    return  plotAreaHeight
                }

                return calculateYAxis(y: valueNotNill)

            }
            return nil
        }

        var targetValue: CGFloat? {

            if let target = getLineChartData(.target)?.first {

                guard let valueNotNill = target.value else {
                    return nil
                }

                if valueNotNill >= max {
                    return 0
                }

                if valueNotNill <= min {
                    return  plotAreaHeight
                }

                return calculateYAxis(y: valueNotNill)

            }
            return nil
        }

        func calculateYAxis(y: CGFloat) -> CGFloat {
            return plotAreaHeight - (plotAreaHeight / ( max - min) * (max - min  - (max - y)))
        }
    }

}

struct Border: View {

    let color: Color

    init(color: Color = Color.gray) {
        self.color = color
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Rectangle()
                    .fill(color)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)

        }
    }
}

