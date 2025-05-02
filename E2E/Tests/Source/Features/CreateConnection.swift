import TestFramework

final class ConnectionFeature: Feature {
    override func title() -> String {
        "Create connection"
    }
    
    override func description() -> String {
        "The Edge Agent should be able to create a connection to Open Enterprise Agent"
    }
    
    func testConnection() async throws {
        let variants: [[String: String]] = [
            ["label": "alice", "goalCode": "automation", "goal": "automation description"],
            ["label": ""     , "goalCode": "",           "goal": ""                      ],
            ["label": "alice", "goalCode": "null",       "goal": "null"                  ],
            ["label": "null" , "goalCode": "automation", "goal": "null"                  ],
            ["label": "null" , "goalCode": "null",       "goal": "automation description"],
            ["label": "null" , "goalCode": "null",       "goal": "null"                  ],
        ]
        
        currentScenario = ParameterizedScenario("Create connection: [label=<label>; goalCode=<goalCode>; goal=<goal>]")
            .parameters(variants)
            .given("Cloud Agent has a connection invitation with '<label>', '<goalCode>' and '<goal>' parameters")
            .given("Cloud Agent shares invitation to Edge Agent")
            .when("Edge Agent connects through the invite")
            .then("Cloud Agent should have the connection status updated to 'ConnectionResponseSent'")
    }
}
