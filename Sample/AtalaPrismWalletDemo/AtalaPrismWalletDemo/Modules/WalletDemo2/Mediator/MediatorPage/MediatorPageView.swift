import SwiftUI

protocol MediatorPageViewModel: ObservableObject {
    var mediator: MediatorPageStateView.Mediator? { get }
    var agentRunning: Bool { get }
    var loading: Bool { get }
    var error: FancyToast? { get set }

    func startAgent(mediatorDID: String)
    func stopAgent()
}

struct MediatorPageView<ViewModel: MediatorPageViewModel>: View {
    @StateObject var viewModel: ViewModel
    @State var didInput = "did:peer:2.Ez6LSghwSE437wnDE1pt3X6hVDUQzSjsHzinpX3XFvMjRAm7y.Vz6Mkhh1e5CEYYq6JBUcTZ6Cp2ranCWRrv7Yax3Le4N59R6dd.SeyJ0IjoiZG0iLCJzIjp7InVyaSI6Imh0dHBzOi8vbWVkaWF0b3IuYXRhbGFwcmlzbS5pbyIsImEiOlsiZGlkY29tbS92MiJdfX0.SeyJ0IjoiZG0iLCJzIjp7InVyaSI6IndzczovL21lZGlhdG9yLmF0YWxhcHJpc20uaW8vd3MiLCJhIjpbImRpZGNvbW0vdjIiXX19"

    var body: some View {
        VStack {
            if let mediator = viewModel.mediator {
                VStack(spacing: 16) {
                    Text("Mediator DID:")
                    Text(mediator.mediatorDID)
                    Text("Routing DID:")
                    Text(mediator.routingDID)
                    Text("State of agent: \(viewModel.agentRunning ? "Running" : "Stoped")")
                    Button {
                        if viewModel.agentRunning {
                            viewModel.stopAgent()
                        } else {
                            viewModel.startAgent(mediatorDID: mediator.mediatorDID)
                        }
                    } label: {
                        Text(viewModel.agentRunning ? "Stop" : "Start")
                    }
                    .disabled(viewModel.loading)
                }
            } else {
                VStack(spacing: 16) {
                    TextField("Mediator DID", text: $didInput)
                    Button {
                        viewModel.startAgent(mediatorDID: didInput)
                    } label: {
                        Text("Start")
                    }
                }
                .disabled(viewModel.loading)
            }
        }
        .padding()
        .toastView(toast: $viewModel.error)
    }
}
