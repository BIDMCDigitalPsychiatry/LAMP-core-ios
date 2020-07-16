// watchkitapp Extension

import SwiftUI

struct LoginView: View {
    @ObservedObject var userAuth: UserAuth
    @State var userName = "U3998365801"
    @State var password = "12345"
    @State var isAlert: Bool = false
    
    var body: some View {
        return VStack {
            TextField("User Name", text: $userName)
                .textContentType(.username)
                .multilineTextAlignment(.center)
            SecureField("Password", text: $password)
                .textContentType(.password)
                .multilineTextAlignment(.center)
            Button(action: {
                self.userAuth.login(userName: self.userName, password: self.password) { (isSuccess) in
                    self.isAlert = !isSuccess
                }
            }) {
                Text("Done")
            }.disabled(userName.isEmpty || password.isEmpty)
            
        }.alert(isPresented: $isAlert) { () -> Alert in
            Alert(title: Text(""), message: Text(self.userAuth.errorMsg!), dismissButton: .default(Text("Ok")))
        }
    }
}

struct HomeView: View {
    
    var body: some View {
        return VStack {
            Text("Signed In")
            Image("appImage").resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 60.0, height: 60.0, alignment: .center)
            .clipped()
        }
    }
}

struct ContentView: View {
    
    @ObservedObject var userAuth: UserAuth
    var body: some View {
        if userAuth.isLoggedin {
            return AnyView(HomeView())
        } else {
            return AnyView(LoginView(userAuth: userAuth))
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(userAuth: UserAuth(false))
    }
}
