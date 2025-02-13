#  Swift library test automation

## Description

Due the lack of BDD frameworks that allows swift libraries to be tested this framework was built using concepts of:

- Cucumber
- SerenityBDD

## Getting started

The lifecycle of the framework is based on XCTest lifecycle.

The `TestFramework` provides a base configuration class named `TestConfiguration` which must be extended.

For now, only `1` child class is supported and we'll refer to that class as `Configuration`.

```swift
class MyConfig: TestConfiguration {
    // ...
}
```

### Defining the actors

To create the `actors`, in the `Configuration` file you should override the base class method `createActors()`

```swift
    override func createActors() async throws -> [Actor]  {
        let actor1 = Actor("Bob").whoCanUse(MyCustomAbility.self)
        let actor2 = Actor("Alice").whoCanUse(OtherCustomAbility.self )
        return [actor1, actor2]
    }
```

### Defining parsers

Parsers are a method that enable us to convert the data provided in step to parameterized arguments in steps

To parameterize a step we use curly brackets and the type inside (`{type}`). For example: `{actor} counts to {int}`

If no `type` is inside the curly brackets, the framework will use `string` as default.

Parsers that are native to the framework:

- String: converts the value to `string`
- Int: converts the value to `int`
- Actor: converts the value to an existing `actor`. Note: the actor must exist.

To declare new parsers in the `Configuration` class you can add a new parser as the following example:

```swift
    @ParameterParser
    var myCustomParser = { (data: String) in
        return MyCustomType(data: data)
    }
```

### Defining reporter

In the `Configuration` file you have to setup the reporters you want.

By default it's `JunitReporter`, `HtmlReporter` and `DotReporter`.

Example:

```swift
    override func createReporters() async throws -> [Reporter] {
        return [ConsoleReporter(), HtmlReporter()]
    }
```

#### Available reporters:

- ConsoleReporter: pretty print bdd in console
- DotReporter: prints `.` for each action and in the end prints a summary
- HtmlReporter: generates a HTML file. Note: for now it's only creating a .txt file
- JunitReporter: generates a XML file in junit format

### Defining the steps

To create steps using the framework you should extend the `Steps` class and define the `Step` variables through annotation.

Here's an example:

```swift
class MyCustomSteps: Steps {
    @Step("The {actor} counts to {int}")
    var theActorCountsToANumber = { (myActor: Actor, number: Int) in
        <#code#>
    }
    // ...
}
```

### Defining the feature

Extends `Feature` class and override the `title` and optionally the `description`.

```swift
class MyFeature: Feature {
    override func title() -> String {
        "My custom feature"
    }
    
    override func description() -> String {
        "My custom feature description"
    }
    
    // ...
}
```

### Defining the scenario

Inside the `Feature` we define the scenarios that will be executed.

```swift
class MyFeature: Feature {
    // ...
    
    func myTestCase() async throws {
        currentScenario = Scenario("My custom scenario")
            .given("Bob knows how to count")
            .when("Bob counts to 10")
            .then("The system should have waited at least 10 seconds")
    }
}
```

For now it's not possible to parameterize the scenarios.

## Additional information

### Defining the abilities

Abilities are a concept inherited from `Serenity BDD`. This allows the `actors` to execute commands only if they have the ability to.

#### Adding the ability to the actor

You can add an ability to the `Actor` using the method `whoCanUse`

```swift
    let myActor = Actor("My Actor").whoCanUse(MyAbility.self)
```

or adding to an existing `Actor`:

```swift
    myActor.whoCanUse(MyAbility.self)
```

### Defining reporters

#### Console reporter

Prints in a readable way all the actions taken during the execution.

#### Dot reporter

Simple reporter that prints `.` for the actions taken during the test and prints the overall results.

#### Junit reporter

Generates the result in a `junit.xml` format. That can be used in CI/CD tools.

The result is available in the path provided by `Configuration` method `targetDirectory`.

#### HTML reporter

Generates a readable report with the steps executed and its results.

The result is available in the path provided by `Configuration` method `targetDirectory`.

Note: For now it's a plain txt file.

#### Creating a custom reporter

To create a custom reporter you have to create the class and extend the `Reporter` base class and implement the protocol methods.

```swift
class MyCustomReporter: Reporter {
    func beforeFeature(_ feature: Feature) async throws {
        <#code#>
    }
    
    // ...
}
```

And add the reporter to the reporters list.

## Assertions

### Hamcrest

This framework enable the usage of `Hamcrest`.

Usage:

```swift
import Hamcrest

class MySteps: Steps {
    @Step("{actor} should see the calculator shows {int}")
    var bobShouldSeeTheCalculatorShowsExpectedNumber = { (bob: Actor, expectedNumber: Int) in
        assertThat(expectedNumber, equalTo(result))
    }
}
```

### Wait

There's an assertion method to wait for an asynchronous verification. The method accepts an optional timeout (seconds) - default: 30.

It expects a boolean response for the assertion result.

Example:

```swift
func myTest() {
    try await Wait.until(timeout: 60) {
        let response = try await api.getSomething()
        return response.data == "EXPECTED"
    }
}
```

## Full example

```swift
import Foundation
import XCTest
import Hamcrest

class MyTest: Feature {
    override func title() -> String {
        "My custom title"
    }
    
    override class func description() -> String {
        "My custom title"
    }
    
    func testMyCustomScenario1() {
        currentScenario = Scenario("My custom scenario")
            .given("Bob has a calculator")
            .when("Bob sums 1 + 1")
            .then("Bob should see the calculator shows 2")
    }
    
    func testMyCustomScenario2() {
        currentScenario = Scenario("My custom scenario")
            .given("Bob has a calculator")
            .when("Bob sums 1 + 2")
            .then("Bob should see the calculator shows 2")
    }
}

class MySteps: Steps {
    static var result = 0
    
    @Step("{actor} has a calculator")
    var bobHasCalculator = { (bob: Actor) in
        
    }
    
    @Step("{actor} sums {int} + {int}")
    var bobSumsOnePlusOne = { (bob: Actor, n1: Int, n2: Int) in
        result = n1 + n2
    }
    
    @Step("{actor} should see the calculator shows {int}")
    var bobShouldSeeTheCalculatorShowsExpectedNumber = { (bob: Actor, expectedNumber: Int) in
        assertThat(expectedNumber, equalTo(result))
    }
}

class MyConfig: TestConfiguration {
    override class func createInstance() -> ITestConfiguration {
        MyConfig()
    }
    
    override func createActors() async throws -> [Actor] {
        let bob = Actor("Bob")
        return [bob]
    }
    
    override func setUp() async throws {
        
    }
    
    override func tearDown() async throws {
        
    }
    
    override func targetDirectory() -> URL {
        return URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Target")
    }
}
```

## Disclaimer

The framework is still under development.

## References

- Cucumber - https://cucumber.io/docs/cucumber/
- Serenity screenplay - https://serenity-bdd.github.io/docs/screenplay/screenplay_fundamentals
