//
//  ContentView.swift
//  LineChart
//
//  Created by 名前なし on 2022/07/23.
//

import SwiftUI

struct ContentView: View {

    @StateObject var items: LineChartDataItems = LineChartDataItems()

    var body: some View {
        LineChart(
            items: items,
            columnCount: 10,
            circleRadius: 4,
            circleColor: Color.red,
            labelSize: 13,
            labelColor: Color.red
        )
        .frame(
            maxWidth: 320,
            maxHeight: 130
        )
    }
}

struct LineChart: View {

    @StateObject var items: LineChartDataItems

    // グラフの線と文字の間のスペース
    let yAxisSpaceLabel: CGFloat = 11.0

    // グラフの線の太さ
    let lineWidth: CGFloat = 0.5

    // ステップのサイズ
    @State var stepWidth: CGFloat = 0

    let columnCount: Int

    // グラフにプロットする円の半径
    let circleRadius: CGFloat

    /// 丸の色
    let circleColor: Color

    let labelSize: CGFloat

    let labelColor: Color

    // 最大ステップカウント数
    var stepMaxCount: Int {
        items.data.count
    }

    // 初回値、目標値の横軸線の表示系管理

    var body: some View {

        GeometryReader { geometry in

            ScrollViewReader { reader in

                VStack(spacing: 0) {

                    ScrollView(.horizontal, showsIndicators: false) {

                        ZStack {

                            //縦線は親のViewギリギリまで表示
                            verticalLine(stepWidth: stepWidth)

                            ZStack {

                                lineAndCircle(stepWidth: stepWidth)

                                label
                            }

                            // 親のサイズ - 30の余白をしないと文字がはみ出た時に綺麗に表示されない
                            .padding(.vertical, 30)
                            // 親のサイズ
                            .frame(maxWidth: .infinity, maxHeight: geometry.size.height)
                            .id(999)
                        }
                        .frame(width: CGFloat(stepMaxCount) * stepWidth, height: geometry.size.height)
//                        .id(999)

                    }
                    .onChange(of: items.data) { id in
                        reader.scrollTo(999, anchor: .bottom)
                    }

                }
                .border(Color.gray, width: 0.5)

                Text("値を送信")
                    .onTapGesture {
                        let data = LineChartData.init(
                            scrollId: items.data.count + 1 ,
                            value: CGFloat.random(in: 0...100),
                            datetime: .init(time: "01:00", date: "12")
                        )
                        items.data.append(data)
                    }
            }
            .onAppear() {
                self.stepWidth = geometry.size.width / CGFloat(self.columnCount)
            }
        }
    }

    var label: some View {

        GeometryReader { geometry in

            let points = items.plots(height: geometry.size.height, stepWidth: stepWidth)
            let labels:[String] = items.measureLabels

            ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                if let point = point {
                    Text(labels[index])
                        .font(.system(size: self.labelSize, weight: .thin, design: .default))
                        .foregroundColor(labelColor)
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
    private func verticalLine(stepWidth: CGFloat) -> some View {
        GeometryReader { geometry in
            Path.verticalLine(
                max: stepMaxCount,
                stepWidth: stepWidth,
                height: geometry.size.height
            )
            .stroke(Color.gray, style: StrokeStyle(lineWidth: lineWidth, dash: [2]))
        }
    }

    // グラフの円と線
    private func lineAndCircle(stepWidth: CGFloat) -> some View {

        GeometryReader { geometry in

            let points = items.plots(height: geometry.size.height, stepWidth: stepWidth)

            Path
                .line(points: points)
                .stroke(
                    Color.red.opacity(0.5),
                    style: StrokeStyle(lineWidth: lineWidth)
                )

            Path
                .circle(
                    points: points,
                    radius: self.circleRadius
                )
                .fill(
                    circleColor
                )
        }
    }
}

extension Path {
    // 円表示
    static func circle(points: [CGPoint?], radius: CGFloat) -> Path {
        var path = Path()
        points.enumerated().forEach { index, point in

            guard let point = point else {
                return
            }

            path.move(to: point)
            path.addArc(center: point,
                        radius: radius,
                        startAngle: Angle(degrees: 0),
                        endAngle:   Angle(degrees: 360),
                        clockwise: false)
        }
        return path
    }

    // 線表示
    static func line(points: [CGPoint?]) -> Path {

        var path = Path()

        let notNillIndex = points.indices.filter {
            points[$0] != nil
        }

        points.enumerated().forEach { index, point in

            guard let point = point else {
                return
            }

            if index != notNillIndex.first {
                path.addLine(to: point)
            } else {
                path.move(to: point)
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

    public func plots(height: CGFloat, stepWidth: CGFloat) ->  [CGPoint?] {

        var result: [CGPoint?] = []

        measures.enumerated().forEach { index, value in

            guard let nonNillValue = value else {
                return result.append(nil)
            }

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

