//
//  ContentView.swift
//  LineChart
//
//  Created by 名前なし on 2022/07/23.
//

import SwiftUI

struct ContentView: View {

    @StateObject var items: LineChartDataItems = LineChartDataItems()
    let randomPlotsCount: Int = 4
    let graphHeight: CGFloat = 140

    var body: some View {
        VStack {
            ZStack {
                GeometryReader { geometry in
                    LineChart(
                        items: items
                    )
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: geometry.size.height
                    )
                    .background(Color.red.opacity(0.3))
                }
            }
            .frame(height: self.graphHeight)
        }
    }
}

struct LineChart: View {

    @StateObject var items: LineChartDataItems

    // グラフの線と文字の間のスペース
    let yAxisSpaceLabel: CGFloat = 11.0

    // グラフにプロットする円の半径
    let circleRadius: CGFloat = 5

    // グラフの線の太さ
    let lineWidth: CGFloat = 0.5

    // ステップのサイズ
    let stepWidth: CGFloat = 40

    // 最大ステップカウント数
    var stepMaxCount: Int {
        items.data.count
    }

    let padding: CGFloat = LineChartDataItems.padding

    // 初回値、目標値の横軸線の表示系管理

    var body: some View {

        GeometryReader { geometry in

            ScrollViewReader { reader in

                VStack(spacing: 0) {

                    ScrollView(.horizontal) {

                        ZStack(alignment: .center) {

                            verticalLine

                            ZStack {
                                lineAndCircle
                                label
                                    .frame(maxWidth: .infinity, maxHeight: geometry.size.height)
                                    .id(999)

                            }
                            // 画面操作しない時は自動でスクロールされない
                            .padding(10)
                            .background(Color.green.opacity(0.3))
                            
                        }
                        .frame(width: CGFloat(stepMaxCount) * stepWidth, height: geometry.size.height)

                    }
                    
                    .onChange(of: items.data) { id in
                        reader.scrollTo(999, anchor: .trailing)
                    }
                    .onTapGesture {

                        let data = LineChartData.init(
                            scrollId: items.data.count + 1 ,
                            value: CGFloat.random(in: 0...100),
                            datetime: .init(time: "01:00", date: "12")
                        )
                        items.data.append(data)
                    }
                }
            }
        }
    }

    var label: some View {

        GeometryReader { geometry in

            let points = items.plots(size: geometry.size)
            let labels:[String] = items.measureLabels
            let scrollIds:[String] = items.measureLabels

            ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                if let point = point {
                    Text(labels[index])
                        .frame(width: self.stepWidth, alignment: .center)
                        .offset(x: point.x - self.stepWidth / 2, y: point.y + yAxisSpaceLabel)

                }
            }
        }
    }

    //　グラフの上部線
    private var borderTop: some View {
        Border(color: Color.gray)
            .frame(height: 1)
    }

    // グラフの縦線
    private var verticalLine: some View {

        GeometryReader { geometry in
            Path.verticalLine(
                max: stepMaxCount,
                stepWidth: self.stepWidth,
                height: geometry.size.height
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
    static func verticalLine(max: Int,  stepWidth: CGFloat, height: CGFloat) -> Path {
        let space: CGFloat = stepWidth * 0.5
        var path = Path()
        for index in 0...max {
            path.move(to: .init(x: stepWidth * CGFloat(index) + space, y: 0))
            path.addLine(to: .init(x: stepWidth * CGFloat(index) + space, y: height))
        }
        return path
    }
}


class LineChartDataItems: ObservableObject {

    // グラフデータ
    @Published var data: [LineChartData] = []

    // グラフ全体の高さ
    @Published var graphHeight: CGFloat = 140

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


    // プロットエリア
    var plotAreaHeight: CGFloat {
        return graphHeight - Self.padding
    }

    // 測定結果データ
    var measures: [CGFloat?] {
        return data.map {
            $0.value
        }
    }

    // ラベルを返す(エラーの場合は空文字)
    var measureLabels: [String] {
        return data.map {
            return  String(format: "%.1f", $0.value ?? 0)
        }
    }

    var ids: [Int] {
        return data.map {
            return $0.scrollId
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

    func calculateYAxis(y: CGFloat) -> CGFloat {
        return plotAreaHeight - (plotAreaHeight / ( max - min) * (max - min  - (max - y)))
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

extension LineChartData {
    struct DateTime: Hashable {
        let time: String
        let date: String
    }
}

struct LineChartData: Hashable  {
    static func == (lhs: LineChartData, rhs: LineChartData) -> Bool {
        return lhs.scrollId == rhs.scrollId
    }

    let id = UUID()
    let scrollId: Int
    let value: CGFloat?
    let datetime: DateTime
}

