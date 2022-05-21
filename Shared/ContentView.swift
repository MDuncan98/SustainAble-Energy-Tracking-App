//
//  ContentView.swift
//  Shared
//
//  Created by Michael Duncan on 11/02/2022.
//

import SwiftUI
import Foundation
import Firebase
import FirebaseCore
import FirebaseDatabase
import FirebaseAuth


class AppViewModel: ObservableObject {
    let auth = Auth.auth()
    private let database = Database.database(url: "https://sustainable-backend-default-rtdb.europe-west1.firebasedatabase.app/").reference()
    public static var shared = AppViewModel()
    @Published var signedIn = false
    @Published var name: String = ""
    @Published var aLog = log(date: Date.init())
    @Published var finalFeedback = ""
    
    var isSignedIn: Bool {
        return auth.currentUser != nil
    }
    
    func signIn(email: String, password: String) {
       auth.signIn(withEmail: email, password: password) { [weak self] result, error in
           guard result != nil, error == nil else {
               return
           }
           DispatchQueue.main.async {
               // Success
               self?.signedIn = true
           }
       }
    }
    
    func signUp(email: String, password: String, name: String) {
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            guard result != nil, error == nil else {
                return
            }

            DispatchQueue.main.async {
                let userID = self?.auth.currentUser?.uid
                self?.database.child("Users").child(userID!).setValue(["name": name, "email": email])
                self?.signedIn = true
                // Success
            }
        }
    }
    
    func signOut() {
        try? auth.signOut()
        
        self.signedIn = false
    }
    
    @objc func writeDB(obj: [String: Any], childName: String) {
        database.child("Users").child(childName).setValue(obj)
    }
    
    func getDateString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-YY"
        let logDate = dateFormatter.string(from: date)
        
        return logDate
    }
    
    func writeLog(list: [Activity], time: String, date: Date) {
        let userID = self.auth.currentUser?.uid
        var i = 0
        let logDate = getDateString(date: date)
        for obj in list {
            database.child("Users").child(userID!).child("logs").child(logDate).child(obj.timeOfDay).child("\(i)").setValue([
                "name": obj.name,
                "duration": obj.duration,
                "device": obj.device.name] as NSDictionary)
            i += 1
        }
    }
    
    func writeTotal(total: Float, date: Date){
        let userID = self.auth.currentUser?.uid
        let logDate = getDateString(date: date)
        database.child("Users").child(userID!).child("logs").child(logDate).child(
            "Total").setValue(total)
    }
    
    func getUser() -> String {
        let userID = self.auth.currentUser?.uid
        database.child("Users").child(userID!).observeSingleEvent(of: .value, with: { snapshot in
            let value = snapshot.value as? NSDictionary
            self.name = value?["name"] as? String ?? ""
        }) { error in
            print(error.localizedDescription)
        }
        return self.name
    }
    
    func getLog(date: Date) -> log {
        let userID = self.auth.currentUser?.uid
        let logDate = getDateString(date: date)
        let times = ["Morning", "Afternoon", "Evening"]
        @State var devicesList = deviceList()
        for time in times {
            database.child("Users").child(userID!).child("logs").child(logDate).child(time).observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.childrenCount > 0 {
                    for data in snapshot.children.allObjects as! [DataSnapshot] {
                        if let data = data.value as? [String:Any]{
                            let name = data["name"] as? String
                            let deviceName = data["device"] as? String
                            let duration = data["duration"] as? Float
                            let activity = Activity(name: name!, timeOfDay: time, duration: duration!, device: devicesList.devices.first(where: {$0.name == deviceName!})!)
                            self.aLog.addActivity(timeOfDay: time, activity: activity)
                        }
                    }
                }
            })
        }
        self.aLog.mTotal = getTotal(list: self.aLog.morningList)
        return self.aLog
    }
    
    func getTotal(list: [Activity]) -> Float {
        var totalValue: Float = 0
        if list.count > 0 {
            for i in list {
                if let energy = Float(i.energyUsage) {
                    totalValue += energy
                }
            }
        }
        return totalValue
    }
    
    func setFeedback(fb: String){
        self.finalFeedback = fb
    }
}


struct ContentView: View {
    init() {
        UITableView.appearance().backgroundColor = .systemGray6
    }
    let today = Date()
    @ObservedObject private var viewModel = AppViewModel.shared
    
    func setUser() -> String {
        let user = viewModel.getUser()
        
        return user
    }
    
    var body: some View {
        NavigationView {
            if viewModel.isSignedIn {
                LogView(currentDate: today, currentLog: viewModel.getLog(date: today), name: viewModel.getUser())
            }
            else {
                SignInView()
            }
        }
    }
}

struct SignInView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var userData: [String:Any] = [:]
    @ObservedObject private var viewModel = AppViewModel.shared
    

    var body: some View {
        VStack {
            Title(titleText: "SustainAble")
            Form {
                TextField("Email", text: $email)
                        .padding()
                        .cornerRadius(5.0)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .accentColor(.blue)
                SecureField("Password", text: $password)
                        .padding()
                        .cornerRadius(5.0)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .accentColor(.blue)
                Section {
                    Button(action: {
                        guard !email.isEmpty, !password.isEmpty else {
                            return
                        }
                        viewModel.signIn(email: email, password: password)
                    }) {
                        Text("Sign In")
                            .frame(maxWidth:.infinity, maxHeight: .infinity, alignment: .center)
                            .foregroundColor(Color.white)
                            .background(Color("SecondaryAccent"))
                            .cornerRadius(8)
                            .padding(.leading, 10)
                    }
                    .padding()
                }
                .listRowBackground(Color("SecondaryAccent"))
                Section {
                    NavigationLink("Create an Account", destination: SignUpView())
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct SignUpView: View {
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    @State private var emailExists = false
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var email2: String = ""
    @State private var password2: String = ""
    @ObservedObject private var viewModel = AppViewModel.shared
    @State var signUpSuccess = false
    @State var invalidForm = false
    @State private var userInfo: [String: Any] = [:]
    
    
    var body: some View {
        VStack {
            Title(titleText: "Create an account")
            Form {
                Section  {
                    TextField("First Name", text: $name)
                        .padding()
                        .cornerRadius(5.0)
                        .accentColor(.blue)
                }
                Section {
                    TextField("Email", text: $email)
                        .padding()
                        .cornerRadius(5.0)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .accentColor(.blue)
                    TextField("Confirm Email", text: $email2)
                        .padding()
                        .cornerRadius(5.0)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .accentColor(.blue)
                }
                Section {
                    SecureField("Password", text: $password)
                        .padding()
                        .cornerRadius(5.0)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .accentColor(.blue)
                    SecureField("Confirm Password", text: $password2)
                        .padding()
                        .cornerRadius(5.0)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .accentColor(.blue)
                }
                Section {
                    Button(action: {
                        guard !name.isEmpty, !email.isEmpty, !email2.isEmpty, !password.isEmpty, !password2.isEmpty else {
                            return
                        }
                        if (email == email2 && password == password2) {
                            viewModel.signUp(email: email, password: password, name: name)
                            signUpSuccess = true
                            self.mode.wrappedValue.dismiss()
                        }
                        else {
                            invalidForm = true
                        }
                    }) {
                        Text("Sign Up")
                            .frame(maxWidth:.infinity, maxHeight: .infinity, alignment: .center)
                            .foregroundColor(Color.white)
                            .background(Color("SecondaryAccent"))
                            .cornerRadius(8)
                            .padding(.leading, 10)
                    }
                    .alert("Sign Up Successful", isPresented: $signUpSuccess) {
                        Button("OK", role: .cancel) { }
                    }
                    .alert("Email or Password did not match. Please try again.", isPresented: $invalidForm) {
                        Button("OK", role: .cancel) { invalidForm = false }
                    }
                }
                .listRowBackground(Color("SecondaryAccent"))
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

/*struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}*/

struct Title: View {
    @State var titleText: String
    var body: some View {
        Text(titleText)
            .font(.largeTitle)
            .frame(maxWidth: .infinity, maxHeight: 100, alignment: .center)
            .background(Color("Accent"))
            .foregroundColor(Color.white)
    }
}
