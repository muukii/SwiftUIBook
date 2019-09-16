//
//  FluxContentView.swift
//  SwiftUIBook
//
//  Created by muukii on 2019/09/16.
//  Copyright © 2019 muukii. All rights reserved.
//

import SwiftUI

struct FluxContentView: View {
  
  var body: some View {
    EmptyView()
  }
}

final class RootStore: ObservableObject {
  
}

final class FragmentStore: ObservableObject {
  
}

enum Test {
  static func foo() {
    
    let store = RootStore()
    
  }
}
