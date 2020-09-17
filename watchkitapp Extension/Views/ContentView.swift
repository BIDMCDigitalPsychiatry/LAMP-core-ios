// watchkitapp Extension

import SwiftUI

struct LoginView: View {
    @ObservedObject var userAuth: UserAuth
    @State var userName: String = ""
    @State var password = ""
    @State var isAlert: Bool = false
    
    var body: some View {
        return
            VStack(alignment: .center, spacing: 2) {
                
                TextField("Email Address", text: Binding<String>(
                    get: { self.userName },
                    set: {
                        self.userName = $0
                        self.userAuth.userName = self.userName
                })).onAppear {
                    self.userName = self.userAuth.userName ?? ""
                }.textContentType(.username)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                
                SecureField("Password", text: Binding<String>(
                    get: { self.password },
                    set: {
                        self.password = $0
                        self.userAuth.password = self.password
                })).onAppear {
                    self.password = self.userAuth.password ?? ""
                }.textContentType(.password)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                Spacer()
                Spacer()
                HStack(alignment: .bottom) {
                    Button(action: {
                        self.userAuth.login(userName: self.userName, password: self.password) { (isSuccess) in
                            self.isAlert = !isSuccess
                        }
                    }) {
                        Text("Go")
                    }.disabled(userName.isEmpty || password.isEmpty)
                        .frame(width: 80, height: 40, alignment: Alignment.bottom)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    Spacer()
                    
                    Button(action: {
                        self.userAuth.showServerURL()
                    }) {
                        Image(systemName: "info")
                    }.frame(width: 25, height: 25)
                        .foregroundColor(.black)
                        .background(Color.white)
                    .clipShape(Circle())
                }
            }
            .alert(isPresented: $isAlert) { () -> Alert in
                Alert(title: Text(""), message: Text(self.userAuth.errorMsg!), dismissButton: .default(Text("Ok")))
        }
    }
}

struct HomeView: View {
    @ObservedObject var userAuth: UserAuth
    var body: some View {
        return VStack {
            Button(action: {
                self.userAuth.logout()
            }) {
                Text("Logout")
            }
        }
    }
}

struct LaunchView: View {
    @ObservedObject var userAuth: UserAuth
    var body: some View {
        return VStack {
            Button(action: {
                self.userAuth.startLogin()
            }) {
                Text("Login")
            }
        }
    }
}

struct ServerURLView: View {
    @ObservedObject var userAuth: UserAuth
    @State var serverURLDomain = ""
    var body: some View {
        return VStack {
            Spacer()
            TextField("Server URL", text: Binding<String>(
                get: { self.serverURLDomain },
                set: {
                    self.serverURLDomain = $0
                    self.userAuth.serverURLDomain = self.serverURLDomain
            })).onAppear {
                self.serverURLDomain = self.userAuth.serverURLDomainDisplayValue
            }.multilineTextAlignment(.center)
            .foregroundColor(.white)

            Spacer()
            HStack(alignment: .bottom) {
                Spacer()
                Button(action: {
                    self.userAuth.backToLoginEdit()
                }) {
                    Image(systemName: "info")
                }.frame(width: 25, height: 25)
                    .foregroundColor(.black)
                    .background(Color.white)
                .clipShape(Circle())
            }
        }
    }
}

struct ContentView: View {
    
    @ObservedObject var userAuth: UserAuth
    var body: some View {
        switch userAuth.loginStatus {
            
        case .logout:
            return AnyView(LaunchView(userAuth: userAuth))
        case .loginInput:
            return AnyView(LoginView(userAuth: userAuth))
        case .serverURLInput:
            return AnyView(ServerURLView(userAuth: userAuth))
        case .loggedIn:
            return AnyView(HomeView(userAuth: userAuth))
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(userAuth: UserAuth(false))
    }
}
