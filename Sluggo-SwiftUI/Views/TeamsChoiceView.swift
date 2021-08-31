//
//  TeamsChoiceView.swift
//  TeamsChoiceView
//
//  Created by Andrew Gavgavian on 8/30/21.
//

import SwiftUI

struct TeamsChoiceView: View {
    
    @Binding var showModal: Bool
    
    var body: some View {
        Text("Teams View!")
    }
}

struct TeamsChoiceView_Previews: PreviewProvider {
    static var previews: some View {
        TeamsChoiceView(showModal: .constant(true))
    }
}
