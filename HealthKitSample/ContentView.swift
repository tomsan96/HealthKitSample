//
//  ContentView.swift
//  HealthKitSample
//
//  Created by 山崎定知 on 2022/08/20.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @ObservedObject var contentVM: ContentViewModel
    let dateformatter = DateFormatter()
    init(){
        
        contentVM = ContentViewModel()
 
        dateformatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        dateformatter.locale = Locale(identifier: "ja_JP")
        dateformatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        
        // 歩数データを取得する関数を呼ぶ（引数は期間）
        contentVM.get(
            fromDate: dateformatter.date(from: "2022/01/01 00:00:00")!,
            toDate: dateformatter.date(from: "2022/03/01 23:59:59")!
        )
    }
    
    var body: some View {
        NavigationView {
            List {
                if contentVM.dataSource.count == 0 {
                    Text("データがありません。")
                } else {
                    ForEach( contentVM.dataSource ){ item in
                        HStack{
                            Text(dateformatter.string(from: item.datetime))
                            Text(" \(item.count)")
                        }
                    }
                }
            }.navigationBarTitle(Text("歩数一覧"), displayMode: .inline)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct ListRowItem: Identifiable {
    var id: String
    var datetime: Date
    var count: String
}

class ContentViewModel: ObservableObject, Identifiable {
 
    @Published var dataSource:[ListRowItem] = []
    
    func get( fromDate: Date, toDate: Date)  {
 
        if HKHealthStore.isHealthDataAvailable() {
            print("使用可能")
        } else {
            print("使用できません")
        }
        let healthStore = HKHealthStore()
        let readTypes = Set([
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount )!
        ])
        
        healthStore.requestAuthorization(toShare: [], read: readTypes, completion: { success, error in
            
            if success == false {
                print("データにアクセスできません")
                return
            }
            
            // 歩数を取得
            let query = HKSampleQuery(sampleType: HKSampleType.quantityType(forIdentifier: .stepCount)!,
                                           predicate: HKQuery.predicateForSamples(withStart: fromDate, end: toDate, options: []),
                                           limit: HKObjectQueryNoLimit,
                                           sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)]){ (query, results, error) in
                
                guard error == nil else { print("error"); return }
                
                if let tmpResults = results as? [HKQuantitySample] {
                    
                    // 取得したデータを１件ずつ ListRowItem 構造体に格納
                    // ListRowItemは、dataSource配列に追加します。ViewのListでは、この dataSource配列を参照して歩数を表示します。
                    for item in tmpResults {
 
                        let listItem = ListRowItem(
                            id: item.uuid.uuidString,
                            datetime: item.endDate,
                            count: String(item.quantity.doubleValue(for: .count()))
                        )
 
                        self.dataSource.append(listItem)
                    }
                }
            }
            healthStore.execute(query)
        })
    }
}
