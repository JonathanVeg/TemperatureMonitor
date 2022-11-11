//
//  ContentView.swift
//  TemperatureMonitor
//
//  Created by Jonathan Gonçalves Da Silva on 29/10/22.
//

import SwiftUI
import HealthKit
import Charts

struct TemperatureEntry: Identifiable {
    var id: UUID
    var temperature: Double
    var startDate: Date
    var endDate: Date
}

struct ContentView: View {
    @State var temperatures: [TemperatureEntry] = []
    
    func readData() {
        print("reading data")
        
        guard let sampleType = HKQuantityType.quantityType(forIdentifier: .appleSleepingWristTemperature) else {
            fatalError("*** This method should never fail ***")
        }
        
        
        let query = HKSampleQuery(sampleType: sampleType, predicate: nil, limit: Int(HKObjectQueryNoLimit), sortDescriptors: nil) {
            query, results, error in
            
            guard let samples = results as? [HKQuantitySample] else {
                print("Error reading data")
                return
            }
            
            var temps: [TemperatureEntry] = []
            
            for sample in samples {
                let temp = sample.quantity.doubleValue(for: HKUnit.degreeCelsius())
                let startDate = sample.startDate
                let endDate = sample.endDate
                let id = sample.uuid
                temps.append(TemperatureEntry(id: id, temperature: temp, startDate: startDate, endDate: endDate))
            }
            
            // The results come back on an anonymous background queue.
            // Dispatch to the main queue before modifying the UI.
            
            DispatchQueue.main.async {
                self.temperatures = temps
            }
        }
        
        let healthStore = HKHealthStore()
        healthStore.execute(query)
    }
    
    func askPermission() {
        if HKHealthStore.isHealthDataAvailable() {
            let healthStore = HKHealthStore()
            
            let types = Set([HKQuantityType.quantityType(forIdentifier: .appleSleepingWristTemperature)!])
            
            healthStore.requestAuthorization(toShare: Set([]), read: types) { (success, error) in
                if !success {
                    print("Error!")
                } else {
                    print ("Has access to data")
                    readData()
                }
            }
        }
    }
    
    func minTemp() -> Double {
        if (temperatures.count == 0) {
            return 34
        }
        
        var min = 40.0
        for temp in temperatures {
            if temp.temperature < min {
                min = temp.temperature
            }
        }
        
        return min - 0.5
    }
    
    func maxTemp() -> Double {
        if (temperatures.count == 0) {
            return 41
        }
        
        var max = 30.0
        for temp in temperatures {
            if temp.temperature > max {
                max = temp.temperature
            }
        }
        
        return max + 0.5
    }
    
    let dateFormat = Date.FormatStyle()
        .day(.twoDigits)
        .month(.twoDigits)
        .hour(.twoDigits(amPM: .abbreviated))
        .minute(.twoDigits)
    
    var body: some View {
        VStack {
            if temperatures.count > 0 {
                Text("Sleep Wrist Temperature")
                    .font(.title)
                    .padding()
                
                Chart(temperatures) {
                    LineMark(x: .value("", $0.startDate), y: .value("", $0.temperature))
                        .foregroundStyle($0.temperature > 36 ? .red : .blue)
                }
                .chartYScale(domain: minTemp()...maxTemp())
                .frame(height: 250)
                
                List(temperatures.sorted(by: { $0.startDate > $1.startDate } )) { temp in
                    VStack(alignment: .leading) {
                        Text("\(String(format: "%.2f", temp.temperature))ºC")
                        
                        HStack {
                            Text("Measure interval: \(temp.startDate.formatted(dateFormat)) - \(temp.endDate.formatted(dateFormat))")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                    }
                }
            } else {
                // align the text to the center
                Text("HealthKit data not permitted or no data available yet")
                    .multilineTextAlignment(.center)
                    .font(.title)
                    .padding()
                Text("You can check if you have access to the data in the Health app")
                    .multilineTextAlignment(.center)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding()
                
                // button to open health app settings
                Button(action: {
                    UIApplication.shared.open(URL(string: "x-apple-health://com.jonathanveg.TemperatureMonitor")!)
                }) {
                    // text with button style
                    Text("Open Health app")
                        .font(.headline)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
                
                Spacer()
                    .frame(height: 20)
                
                
                Button(action: {
                    askPermission()
                }) {
                    Text("Try again")
                        .foregroundColor(.gray)
                }
                
                
            }
        }
        .padding()
        .onAppear(perform: askPermission)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
