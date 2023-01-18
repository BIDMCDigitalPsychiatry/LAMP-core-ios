// watchkitapp Extension

import SwiftUI

struct LoginView: View {
    @ObservedObject var userAuth: UserAuth
    @State var userName: String = ""
    @State var password = ""
    @State var isAlert: Bool = false
    
    var body: some View {
        return
            ZStack(alignment: .center) {
             
                VStack(alignment: .center, spacing: 2) {
                    
                    TextField("label.emailaddress".localized, text: Binding<String>(
                        get: { self.userName },
                        set: {
                            self.userName = $0
                            self.userAuth.userName = self.userName
                    })).onAppear {
                        self.userName = self.userAuth.userName ?? ""
                    }.textContentType(.username)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    
                    SecureField("label.password".localized, text: Binding<String>(
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
                            Text("button.go".localized)
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
                ActivityIndicatorView(isAnimating: self.$userAuth.shouldAnimate)
                
            }
            .alert(isPresented: $isAlert) { () -> Alert in
                Alert(title: Text(""), message: Text(self.userAuth.errorMsg!), dismissButton: .default(Text("alert.button.ok".localized)))
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
                Text("button.logout".localized)
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
                Text("button.login".localized)
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
            TextField("button.server.url".localized, text: Binding<String>(
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
