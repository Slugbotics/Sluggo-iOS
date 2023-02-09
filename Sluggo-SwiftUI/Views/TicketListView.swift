//
//  TicketListView.swift
//  Sluggo-SwiftUI
//
//  Created by Andrew Gavgavian on 1/2/22.
//

import SwiftUI

struct TicketListView: View {
    
    @EnvironmentObject var identity: AppIdentity
    @StateObject private var alertContext = AlertContext()
    @StateObject private var viewModel = ViewModel()
    
    var body: some View {
        NavigationView {
            AsyncContentView(source: viewModel,
                             loadingMessage: "Retrieving Tickets",
                             errorMessage: "Failed to retrieve Tickets") {
                TicketList(tickets: viewModel.searchedTickets) {
                    Group {
                        if viewModel.hasMore {
                            ProgressView()
                                .task {
                                    self.viewModel.showMessage = true
                                    await self.viewModel.handleTicketsList(page: viewModel.nextPage)
                                }
                        } else {
                            if viewModel.showMessage {
                                Text("Congrats! No More Tickets")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .onAppear(perform: viewModel.setDismissTimer)
                            }
                            
                        }
                    }
                }
                .searchable(text: $viewModel.searchKey)
                .refreshable {
                    self.viewModel.showMessage = true
                    await viewModel.load()
                }
            }
         .task {
             viewModel.setup(identity: identity, alertContext: alertContext)
             await viewModel.load()
         }
         .toolbar {
             Menu {
                 Button {} label: {Label("Create New", systemImage: "plus")}
                 Button {viewModel.showFilter.toggle()} label: {Label("Filter", systemImage: "folder")}
             } label: {
                 Image(systemName: "ellipsis")
             }
         }
         .sheet(isPresented: $viewModel.showFilter, onDismiss: viewModel.onFilter) {
             NavigationView {
                 FilterView(filter: $viewModel.filterParams, identity: identity, alertContext: alertContext)
                     .navigationTitle("Filter")
                     .toolbar {
                         ToolbarItem {
                             Button("Done") {
                                 viewModel.showFilter.toggle()
                             }
                         }
                     }
             }
         }
         .navigationTitle("Tickets")
        }
        .navigationViewStyle(.stack)
        .alert(context: alertContext)
    }
}

struct FilterView : View {
    @Binding var filter: TicketFilterParameters
    @State var identity: AppIdentity
    @State var alertContext: AlertContext
    @State var teamMembers: [MemberRecord] = []
    @State var ticketTags: [TagRecord] = []
    @State var ticketStatuses: [StatusRecord] = []
    var body: some View {
        List {
            Section("Assigned User") {
                SingleSelectionList (items: teamMembers, didChange:$filter.didChange, selection:$filter.assignedUser) { item in
                    HStack {
                        Text(item.getTitle())
                        Spacer()
                    }
                }
            }
            Section("Tags") {
                SingleSelectionList (items: ticketTags, didChange:$filter.didChange, selection:$filter.ticketTag) { item in
                    HStack {
                        Text(item.getTitle())
                        Spacer()
                    }
                }
            }
            Section("Statuses") {
                SingleSelectionList (items: ticketStatuses, didChange:$filter.didChange, selection:$filter.ticketStatus) { item in
                    HStack {
                        Text(item.getTitle())
                        Spacer()
                    }
                }
            }
        }
        .task(doLoad)
    }
    
    @Sendable func doLoad() async {
        let tagManager = TagManager(identity: self.identity)
        let statusManger = StatusManager(identity: self.identity)
        let memberManager = MemberManager(identity: self.identity)
        
        switch await tagManager.listFromTeams() {
        case .success(let tags):
            self.ticketTags = tags
        case .failure(let error):
            print(error)
            self.alertContext.presentError(error: error)
        }
        
        switch await statusManger.listFromTeams() {
        case .success(let statuses):
            self.ticketStatuses = statuses
        case .failure(let error):
            print(error)
            self.alertContext.presentError(error: error)
        }
        
        unwindPagination(manager: memberManager,
                         startingPage: 1,
                         onSuccess: { members in
            self.teamMembers = members
        },
                         onFailure:  nil,
                         after: nil)
    }
    
}


struct TicketList<Content:View>: View {
    //    Simple struct to account for all the fancy styling on lists and Zstack
    var tickets: [TicketRecord]
    var loadMore: () -> Content
    @State private var selected: TicketRecord?
    var body: some View {
        List {
            ForEach(tickets) { ticket in
                ZStack{
                    NavigationLink(destination: Text(ticket.title), tag: ticket, selection: $selected) {
                        EmptyView()
                    }
                    .hidden()
                    TicketPill(ticket: ticket)
                        .overlay(selected == ticket ? Color(white: 0.75, opacity: 0.25) : Color.clear)
                        .onTapGesture {
                            self.selected = ticket
                        }
                }
            }
            .listRowSeparator(.hidden)
            .listRowInsets(.none)
            .listRowBackground(Color.clear)
            loadMore()
        }
        .listStyle(.plain)
        
    }
}


