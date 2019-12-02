ORK1Kit Framework
===========

The *ORK1Kit™ framework* is an open source software framework that makes it easy to create apps
for medical research or for other research projects.

* [Getting Started](#gettingstarted)
* Documentation:
    * [Programming Guide](http://researchkit.org/docs/docs/Overview/GuideOverview.html)
    *  [Framework Reference](http://researchkit.org/docs/index.html)
* [Best Practices](../../wiki/best-practices)
* [Contributing to ORK1Kit](CONTRIBUTING.md)
* [Website](http://researchkit.org) and [Blog](http://researchkit.org/blog.html)
* [ORK1Kit BSD License](#license)

Getting More Information
========================

* Join the [*ORK1Kit* Forum](https://forums.developer.apple.com/community/researchkit) for discussing uses of the *ORK1Kit framework and* related projects.

Use Cases
===========

A task in the *ORK1Kit framework* contains a set of steps to present to a user. Everything,
whether it’s a *survey*, the *consent process*, or *active tasks*, is represented as a task that can
be presented with a task view controller.

Surveys
-------

The *ORK1Kit framework* provides a pre-built user interface for surveys, which can be presented
modally on an *iPhone*, *iPod Touch*, or *iPad*. See
 *[Creating Surveys](http://researchkit.org/docs/docs/Survey/CreatingSurveys.html)* for more
 information.


Consent
----------------

The *ORK1Kit framework* provides visual consent templates that you can customize to explain the
details of your research study and obtain a signature if needed.
See *[Obtaining Consent](http://researchkit.org/docs/docs/InformedConsent/InformedConsent.html)* for
more information.


Active Tasks
------------

Some studies may need data beyond survey questions or the passive data collection capabilities
available through use of the *HealthKit* and *CoreMotion* APIs if you are programming for *iOS*.
*ORK1Kit*'s active tasks invite users to perform activities under semi-controlled conditions,
while *iPhone* sensors actively collect data. See
*[Active Tasks](http://researchkit.org/docs/docs/ActiveTasks/ActiveTasks.html)* for more
information.

Charts
------------
*ORK1Kit* includes a *Charts module*. It features three chart types: a *pie chart* (`ORK1PieChartView`), a *line graph chart* (`ORK1LineGraphChartView`), and a *discrete graph chart* (`ORK1DiscreteGraphChartView`).

The views in the *Charts module* can be used independently of the rest of *ORK1Kit*. They don't automatically connect with any other part of *ORK1Kit*: the developer has to supply the data to be displayed through the views' `dataSources`, which allows for maximum flexibility.


Getting Started<a name="gettingstarted"></a>
===============


Requirements
------------

The primary *ORK1Kit framework* codebase supports *iOS* and requires *Xcode 8.0* or newer. The
*ORK1Kit framework* has a *Base SDK* version of *8.0*, meaning that apps using the *ORK1Kit
framework* can run on devices with *iOS 8.0* or newer.


Installation
------------

The latest stable version of *ORK1Kit framework* can be cloned with

```
git clone -b stable https://github.com/ORK1Kit/ORK1Kit.git
```

Or, for the latest changes, use the `master` branch:

```
git clone https://github.com/ORK1Kit/ORK1Kit.git
```

Building
--------

Build the *ORK1Kit framework* by opening `ORK1Kit.xcodeproj` and running the `ORK1Kit`
framework target. Optionally, run the unit tests too.


Adding the ORK1Kit framework to your App
------------------------------

This walk-through shows how to embed the *ORK1Kit framework* in your app as a dynamic framework,
and present a simple task view controller.

### 1. Add the ORK1Kit framework to Your Project

To get started, drag `ORK1Kit.xcodeproj` from your checkout into your *iOS* app project
in *Xcode*:

<center>
<figure>
  <img src="../../wiki/AddingORK1KitXcode.png" alt="Adding the ORK1Kit framework to your
   project" align="middle"/>
</figure>
</center>

Then, embed the *ORK1Kit framework* as a dynamic framework in your app, by adding it to the
*Embedded Binaries* section of the *General* pane for your target as shown in the figure below.

<center>
<figure>
  <img src="../../wiki/AddedBinaries.png" width="100%" alt="Adding the ORK1Kit framework to
   Embedded Binaries" align="middle"/>
   <figcaption><center>Adding the ORK1Kit framework to Embedded Binaries</center></figcaption>
</figure>
</center>

Note: You can also import *ORK1Kit* into your project using a
 [dependency manager](./docs-standalone/dependency-management.md) such as *CocoaPods* or *Carthage*.

### 2. Create a Step

In this walk-through, we will use the *ORK1Kit framework* to modally present a simple
 single-step task showing a single instruction.

Create a step for your task by adding some code, perhaps in `viewDidAppear:` of an existing view
controller. To keep things simple, we'll use an instruction step (`ORK1InstructionStep`) and name
the step `myStep`.

*Objective-C*

```objc
ORK1InstructionStep *myStep =
  [[ORK1InstructionStep alloc] initWithIdentifier:@"intro"];
myStep.title = @"Welcome to ORK1Kit";
```

*Swift*

```swift
let myStep = ORK1InstructionStep(identifier: "intro")
myStep.title = "Welcome to ORK1Kit"
```

### 3. Create a Task

Use the ordered task class (`ORK1OrderedTask`) to create a task that contains `myStep`. An ordered
task is just a task where the order and selection of later steps does not depend on the results of
earlier ones. Name your task `task` and initialize it with `myStep`.

*Objective-C*

```objc
ORK1OrderedTask *task =
  [[ORK1OrderedTask alloc] initWithIdentifier:@"task" steps:@[myStep]];
```

*Swift*

```swift
let task = ORK1OrderedTask(identifier: "task", steps: [myStep])
```

### 4. Present the Task

Create a task view controller (`ORK1TaskViewController`) and initialize it with your `task`. A task
view controller manages a task and collects the results of each step. In this case, your task view
controller simply displays your instruction step.

*Objective-C*

```objc
ORK1TaskViewController *taskViewController =
  [[ORK1TaskViewController alloc] initWithTask:task taskRunUUID:nil];
taskViewController.delegate = self;
[self presentViewController:taskViewController animated:YES completion:nil];
```

*Swift*

```swift
let taskViewController = ORK1TaskViewController(task: task, taskRunUUID: nil)
taskViewController.delegate = self
presentViewController(taskViewController, animated: true, completion: nil)
```

The above snippet assumes that your class implements the `ORK1TaskViewControllerDelegate` protocol.
This has just one required method, which you must implement in order to handle the completion of
 the task:

*Objective-C*

```objc
- (void)taskViewController:(ORK1TaskViewController *)taskViewController
       didFinishWithReason:(ORK1TaskViewControllerFinishReason)reason
                     error:(NSError *)error {

    ORK1TaskResult *taskResult = [taskViewController result];
    // You could do something with the result here.

    // Then, dismiss the task view controller.
    [self dismissViewControllerAnimated:YES completion:nil];
}
```

*Swift*

```swift
func taskViewController(_ taskViewController: ORK1TaskViewController, 
                didFinishWith reason: ORK1TaskViewControllerFinishReason, 
                                    error: Error?) {
    let taskResult = taskViewController.result
    // You could do something with the result here.

    // Then, dismiss the task view controller.
    dismiss(true, completion: nil)
}
```


If you now run your app, you should see your first *ORK1Kit framework* instruction step:

<center>
<figure>
  <img src="../../wiki/HelloWorld.png" width="50%" alt="HelloWorld example screenshot" align="middle"/>
</figure>
</center>



What else can the ORK1Kit framework do?
-----------------------------

The *ORK1Kit* [`ORK1Catalog`](samples/ORK1Catalog) sample app is a good place to start. Find the
project in ORK1Kit's [`samples`](samples) directory. This project includes a list of all the
types of steps supported by the *ORK1Kit framework* in the first tab, and displays a browser for the
results of the last completed task in the second tab. The third tab shows some examples from the *Charts module*.



License<a name="license"></a>
=======

The source in the *ORK1Kit* repository is made available under the following license unless
another license is explicitly identified:

```
Copyright (c) 2015 - 2017, Apple Inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1.  Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2.  Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. Neither the name of the copyright holder(s) nor the names of any contributors
may be used to endorse or promote products derived from this software without
specific prior written permission. No license is granted to the trademarks of
the copyright holders even if such marks are included in this software.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```
