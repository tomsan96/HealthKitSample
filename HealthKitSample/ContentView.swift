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
            fromDate: dateformatter.date(from: "2022/06/15 00:00:00")!,
            toDate: dateformatter.date(from: "2022/06/21 23:59:59")!
        )
    }
    
    var body: some View {
        Text(String(contentVM.totalCount))
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
    @Published var totalCount: Double = 0.0
    
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
            
            let distanceType = HKObjectType.quantityType(forIdentifier: .stepCount)!
            let predicate = HKQuery.predicateForSamples(withStart: fromDate, end: toDate, options: [])
            
            let query = HKStatisticsQuery(
                quantityType: distanceType,
                quantitySamplePredicate: predicate,
                options: [.cumulativeSum]) { query, statistics, error in
                    print(statistics!.sumQuantity()!) // 6902 count
                    if let quantity = statistics?.sumQuantity() {
                        let stepValue = quantity.doubleValue(for: HKUnit.count())
                        
                        DispatchQueue.main.async {
                            print(stepValue)
                            self.totalCount = stepValue
                        }
                        
                    } else {
                        DispatchQueue.main.async {
                            print("0歩数")
                        }
                    }
                }
            healthStore.execute(query)
        })
    }
}
