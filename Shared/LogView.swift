//
//  LogView.swift
//  SustainAble
//
//  Created by Michael Duncan on 14/02/2022.
//

import SwiftUI
import Foundation
import Firebase
import FirebaseCore
import FirebaseDatabase
import FirebaseAuth
import nanopb

struct tod_names: Identifiable {
    let name: String
    var id: String { name }
}

public class log: ObservableObject {
    @Published var date: Date
    @Published var morningList: [Activity] = []
    @Published var afternoonList: [Activity] = []
    @Published var eveningList: [Activity] = []
    @Published var allLists = []
    @Published var mTotal: Float = 0.0
    @Published var aTotal: Float = 0.0
    @Published var eTotal: Float = 0.0
    
    init(date: Date) {
        self.date = date
        self.morningList = morningList
        self.afternoonList = afternoonList
        self.eveningList = eveningList
    }
    
    func addActivity(timeOfDay: String, activity: Activity) {
        switch timeOfDay {
        case "Morning":
            morningList.append(activity)
            
        case "Afternoon":
            afternoonList.append(activity)
            
        case "Evening":
            eveningList.append(activity)
            
        default:
            print("You must select a time of day!")
        }
    }
    
    func writeLogToDatabase(total: Float){
        AppViewModel.shared.writeLog(list: morningList, time: "Morning", date: date)
        AppViewModel.shared.writeLog(list: afternoonList, time: "Afternoon", date: date)
        AppViewModel.shared.writeLog(list: eveningList, time: "Evening", date: date)
        if total > 0 {
            AppViewModel.shared.writeTotal(total: total, date: date)
        }
    }
    
    func clearLog() {
        self.morningList = []
        self.afternoonList = []
        self.eveningList = []
    }
}


struct LogView: View {
    @State var currentDate: Date
    var width: CGFloat = 100
    @ObservedObject private var viewModel = AppViewModel.shared
    var timesOfDay: [String] = [
        "Morning",
        "Afternoon",
        "Evening"
    ]
    @StateObject var currentLog: log
    @State var toda: String = ""
    @State var currentList: [Activity] = []
    @State private var showingPopover = false
    var userID = ""
    @State var name: String
    @State var dateText = "Today"
    @State var dailyTotal: Float = 0.0
    @State var mTotal: Float = 0.0
    @State var aTotal: Float = 0.0
    @State var eTotal: Float = 0.0
    @State var feedback: [String] = []
    @State var resetAlert: Bool = false
    
    func setList(timeOfDay: String) -> [Activity] {
        @State var li: [Activity] = []
        switch timeOfDay {
        case "Morning":
            li = currentLog.morningList
        case "Afternoon":
            li = currentLog.afternoonList
        case "Evening":
            li = currentLog.eveningList
        default:
            print("Default")
        }
        return li
    }
    
    func calcTotalUsage(list: [Activity], time: String) -> Float {
        var totalValue: Float = 0
        if list.count > 0 {
            for i in list {
                if let energy = Float(i.energyUsage) {
                    totalValue += energy
                }
            }
        }
        switch time {
        case "Morning":
            self.mTotal = totalValue
        case "Afternoon":
            self.aTotal = totalValue
        case "Evening":
            self.eTotal = totalValue
        default:
            print("Error setting total value")
        }
        dailyTotal = mTotal + aTotal + eTotal
        return totalValue
    }
    
    func calculateAverage() -> Float {
        var average: Float = 0
        let numOfActivities = currentLog.morningList.count + currentLog.afternoonList.count + currentLog.eveningList.count
        if numOfActivities != 0 {
            average = dailyTotal / Float(numOfActivities)
            average = round(average)
        }
        
        return average
    }
    
    func calculateDailyTotal() -> Float{
        var dt = dailyTotal
        dt = round(dt)
        
        return dt
    }
    
    func feedbackColour() -> Color {
        let average = calculateAverage()
        var feedback: String = ""
        var colour: Color = .black
        if average < 150 {
            colour = .green
            feedback = "This is a great score, good work!"
        } else if average < 300 {
            colour = .yellow
            feedback = "This score was okay; not the worst but could be improved."
        } else {
            colour = .red
            feedback = "You've had quite an intense day today. Try to take it easy tomorrow and save some energy!"
        }
        viewModel.setFeedback(fb: feedback)
        return colour
    }
    
    func giveFeedback() -> [String] {
        let lists = [currentLog.morningList, currentLog.afternoonList, currentLog.eveningList]
        var devices: [String] = []
        var activity: [String] = []
        var feedback: [String] = []
        for i in lists {
            for act in i {
                devices.append(act.device.name)
                activity.append(act.name)
            }
        }
        if devices.contains("PC, VR Headset") {
            feedback.append("Gaming in VR is unmatched - both in the experience as well as the energy consumption. It is one of the most power hungry forms of entertainment, therefore ensure that it is switched off when not in use!")
        }
        if activity.contains("Video Streaming - 4K") {
            feedback.append("Watching shows in 4K provides an unparalleled viewing experience. Just be mindful that if you are watching older shows, or on a smaller device, you may not notice the quality difference, but will be using more energy!")
        }
        if devices.contains("Gaming PC") {
            feedback.append("Of course using your gaming PC for gaming is okay, however using it for anything else often means most of that power goes to waste! If you have another device such as a laptop/mobile device, this would use much less energy.")
        }
        if devices.contains("Phone, Tablet") {
            feedback.append("Brilliant work on using your mobile device today! These are some of the most energy efficient devices for everyday activities. Keep it up!")
        }
        if devices.contains("PC") {
            feedback.append("You used your PC for some activites today. Using a smaller device such as a laptop, phone or tablet will reduce the amount of energy used for the same task.")
        }
        if devices.contains("Laptop") {
            feedback.append("Good job for using your laptop today! However, you can save even more energy by using a tablet or mobile device.")
        }
        if devices.contains("TV") {
            feedback.append("We all love watching shows on the big screen, but not only does watching on a mobile device save energy, you can likely reduce the streaming quality without any reduction in viewing quality - this saves even more energy and internet bandwidth!")
        }
        if devices.contains("Games Console") {
            feedback.append("That was a nice gaming session you had on your console earlier. In fact, this form of gaming is one of the most energy efficient - second only to mobile gaming!")
        }
        if activity.contains("Gaming") {
            feedback.append("Gaming is extremely fun - but it's also one of the most demanding activites for your device to handle. Using a smaller device where possible can allow for much lower energy usage.")
        }
        if activity.contains("Video Streaming - HD") || activity.contains("Video Streaming - 4G, Auto") {
            feedback.append("We hope you enjoyed your video content earlier. Good work on watching in a lower quality - it really makes a difference!")
        }
        
        if feedback.count > 3 {
            var reducedFeedback: [String] = []
            var indexes: [Int] = []
            while reducedFeedback.count < 3 {
                let randIndex = Int.random(in: 0...feedback.count - 1)
                if !indexes.contains(randIndex) {
                    reducedFeedback.append(feedback[randIndex])
                    indexes.append(randIndex)
                }
            }
            feedback = reducedFeedback
        } else if feedback.count == 0 {
            feedback.append("We don't have any feedback about your day. Either you've been very quiet today (if so, great job!), or you haven't logged all of your activities. Add some more or come back tomorrow!")
        }
        return feedback
    }
    
    func changeDate(date: Date){
        let currentDateString = viewModel.getDateString(date: date)
        let todayDateString = viewModel.getDateString(date: Date())
        if (currentDateString == todayDateString) {
            dateText = "Today"
        }  else {
            dateText = viewModel.getDateString(date: date)
        }
    }

    var body: some View {
        VStack {
            ZStack (alignment: .top){
                HStack{
                    Spacer()
                    VStack {
                        Spacer()
                        Button(action: {
                            currentLog.clearLog()
                            viewModel.signOut()
                        }) {
                            Text("Sign Out")
                                .frame(width:100, height: 40, alignment: .center)
                                .foregroundColor(Color.white)
                                .background(Color("SecondaryAccent"))
                                .cornerRadius(8)
                                .padding(.trailing, 10)
                        }
                        Spacer()
                    }
                }
            }
            .frame(maxHeight: 60, alignment: .top)
            .background(Color("Accent"))
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        currentLog.writeLogToDatabase(total: dailyTotal)
                        currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
                        changeDate(date: currentDate)
                        currentLog.clearLog()
                        currentLog.date = currentDate
                        viewModel.getLog(date: currentDate)
                    }) {
                        Text("<")
                    }
                    .frame(width: 50, height: 25, alignment: .center)
                    .background(Color("SecondaryAccent"))
                    .cornerRadius(8)
                    .foregroundColor(Color.white)
                    Spacer()
                    Text(dateText)
                        .frame(alignment: .center)
                        .font(.largeTitle)
                    Spacer()
                    Button(action: {
                        currentLog.writeLogToDatabase(total: dailyTotal)
                        currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
                        changeDate(date: currentDate)
                        currentLog.clearLog()
                        currentLog.date = currentDate
                        viewModel.getLog(date: currentDate)
                    }) {
                        Text(">")
                    }
                    .frame(width: 50, height: 25, alignment: .center)
                    .background(Color("SecondaryAccent"))
                    .cornerRadius(8)
                    .foregroundColor(Color.white)
                }
                .padding(.top, 10)
                .padding(.bottom, 10)
                .padding(.trailing, 40.0)
                .padding(.leading, 40.0)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: 50)
            Divider()
            ScrollView {
                ZStack {
                    VStack {
                        //Spacer()
                        Text("Hello, \(viewModel.name)")
                            .font(.system(size: 30, weight: .medium, design: .default))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color.white)
                        Text("Here is your daily log:")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.system(size: 15, design:.default))
                            .foregroundColor(Color.white)
                        //Spacer()
                    }
                }
                
                .padding(.trailing, 50)
                .padding(.top, 50)
                .padding(.bottom, 50)
                .padding(.leading, 10)
                .background(
                    Image("SustainAble Banner")
                        .resizable()
                        .frame(maxWidth: .infinity, maxHeight: 250, alignment: .top)
                        .clipped()
                )
                VStack{
                    ForEach(timesOfDay, id: \.self) { tod in
                        Divider()
                        HStack {
                            Text(tod)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 10)
                            NavigationLink(destination: ActivityView(currentLog: currentLog, toda: tod).onAppear {
                            }) {
                                Text("+")
                                    .background(Color("SecondaryAccent"))
                                    .foregroundColor(Color.white)
                                    .font(.system(size: 20, weight: .heavy, design: .default))
                                    .padding(.trailing, 10)
                                    .frame(width: 40, height: 25, alignment: .center)
                                    .cornerRadius(8)
                            }
                        }
                        if tod == "Morning" {
                            Divider()
                            ForEach(currentLog.morningList) { li in
                                HStack {
                                    Text(li.description)
                                        .padding(.leading, 10)
                                        .font(.system(size: 15, weight: .light, design: .default))
                                    Spacer()
                                    Divider()
                                    Text(li.energyUsage)
                                        .frame(width: width)
                                }
                                .frame(height: 25, alignment: .top)
                                //Turn into function?
                            }
                            Divider()
                            HStack {
                                Text("Total")
                                    .padding(.leading, 10)
                                    .font(Font.headline.weight(.heavy))
                                Spacer()
                                Divider()
                                Text(String(calcTotalUsage(list: currentLog.morningList, time: tod)))
                                    .padding(.trailing, 10)
                                    .font(Font.headline.weight(.heavy))
                                    .frame(width: width)
                            }
                            Divider()
                            Spacer()
                        }
                        else if tod == "Afternoon" {
                            Divider()
                            ForEach(currentLog.afternoonList) { li in
                                HStack {
                                    Text(li.description)
                                        .padding(.leading, 10)
                                        .font(.system(size: 15, weight: .light, design: .default))
                                    Spacer()
                                    Divider()
                                    Text(String(li.energyUsage))
                                        .padding(.trailing, 10)
                                        .frame(width: width)
                                }
                                .frame(height: 25, alignment: .top)
                            }
                            Divider()
                            HStack {
                                Text("Total")
                                    .padding(.leading, 10)
                                    .font(Font.headline.weight(.heavy))
                                Spacer()
                                Divider()
                                Text(String(calcTotalUsage(list: currentLog.afternoonList, time: tod)))
                                    .padding(.trailing, 10)
                                    .font(Font.headline.weight(.heavy))
                                    .frame(width: width)
                            }
                            Divider()
                            Spacer()
                        }
                        else if tod == "Evening" {
                            Divider()
                            ForEach(currentLog.eveningList) { li in
                                HStack {
                                    Text(li.description)
                                        .padding(.leading, 10)
                                        .font(.system(size: 15, weight: .light, design: .default))
                                    Spacer()
                                    Divider()
                                    Text(String(li.energyUsage))
                                        .padding(.trailing, 10)
                                        .frame(width: width)
                                }
                                .frame(height: 25, alignment: .top)
                            }
                            Divider()
                            HStack {
                                Text("Total")
                                    .padding(.leading, 10)
                                    .font(Font.headline.weight(.heavy))
                                Spacer()
                                Divider()
                                Text(String(calcTotalUsage(list: currentLog.eveningList, time: tod)))
                                    .padding(.trailing, 10)
                                    .font(Font.headline.weight(.heavy))
                                    .frame(width: width)
                            }
                            Divider()
                            Spacer()
                        }
                        Spacer()
                    }
                    Spacer()
                }
            }
            VStack {
                Divider()
                HStack {
                    Text("Daily Total")
                        .padding(.leading, 10)
                        .font(Font.headline.weight(.heavy))
                        .foregroundColor(Color.white)
                    Spacer()
                    Divider()
                    Text(String(Int(calculateDailyTotal())))
                        .foregroundColor(Color.white)
                        .padding(.trailing, 10)
                        .font(Font.headline.weight(.heavy))
                        .frame(width: width)
                }
                Divider()
                HStack {
                    Text("Average Activity")
                        .padding(.leading, 10)
                        .font(Font.headline.weight(.heavy))
                        .foregroundColor(Color.white)
                    Spacer()
                    Divider()
                    Text(String(Int(calculateAverage())))
                        .foregroundColor(Color.white)
                        .padding(.trailing, 10)
                        .font(Font.headline.weight(.heavy))
                        .frame(width: width)
                }
                .frame(height: 30)
                Divider()
                HStack {
                    Spacer()
                    Button(action: {
                        resetAlert = true
                    }) {
                        Text("Reset Log")
                            .frame(width:150, height: 40, alignment: .center)
                            .foregroundColor(Color.white)
                            .background(Color("SecondaryAccent"))
                            .cornerRadius(8)
                            .padding(.leading, 10)
                    }
                    .alert("Reset this log?", isPresented: $resetAlert, actions: {
                        Button("Reset", role: .destructive) { currentLog.clearLog() }
                        Button("Keep", role: .cancel) { }
                    }, message: {
                        Text("Are you sure you want to reset this log? All previous data will be lost!")
                    })
                    Spacer()
                    Divider()
                    Spacer()
                    Button("Confirm Log") {
                        currentLog.writeLogToDatabase(total: dailyTotal)
                        feedback = giveFeedback()
                        showingPopover = true
                    }
                    .frame(width:150, height: 40, alignment: .center)
                    .background(Color("SecondaryAccent"))
                    .foregroundColor(Color.white)
                    .cornerRadius(8)
                    .popover(isPresented: $showingPopover) {
                        VStack {
                            Text("Log confirmed!")
                                .font(.largeTitle)
                                .frame(maxWidth: .infinity, maxHeight: 100, alignment: .center)
                                .background(Color("Accent"))
                                .foregroundColor(Color.white)
                            Text("Here is some feedback based on your day:")
                                .font(.title)
                                .multilineTextAlignment(.center)
                            Divider()
                            Text("**Activity Feedback:**")
                                .multilineTextAlignment(.center)
                            Spacer()
                            ForEach(feedback, id: \.self ) { feedback in
                                Text(feedback)
                                    .multilineTextAlignment(.center)
                                    .font(.caption)
                                Spacer()
                            }
                            Divider()
                            Group {
                                Text("**Overall feedback:**")
                                Spacer()
                                Text("Your average score per activity was: ")
                                    .multilineTextAlignment(.center)
                                Spacer()
                                Text(String(Int(calculateAverage())))
                                    .font(.title)
                                    .foregroundColor(feedbackColour())
                                    .multilineTextAlignment(.center)
                                Spacer()
                                Text(viewModel.finalFeedback)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            Divider()
                            Button("Close") {
                                showingPopover = false
                            }
                            .frame(width:100, height: 40, alignment: .center)
                            .foregroundColor(Color.white)
                            .background(Color("SecondaryAccent"))
                            .cornerRadius(8)
                            .padding(.trailing, 10)
                        }
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                    Spacer()
                }
            }
            .background(Color("Accent"))
            .frame(maxWidth: .infinity, maxHeight: 100)
            .navigationBarHidden(true)
        }
    }
}


/*struct LogView_Previews: PreviewProvider {
    static var previews: some View {
        LogView(toda: "Evening")
    }
}*/
