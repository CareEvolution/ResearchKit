#
<sub>These materials are for informational purposes only and do not constitute legal advice. You should contact an attorney to obtain advice with respect to the development of a research app and any applicable laws.</sub>

#ORK1Kit Framework Programming Guide

The *ORK1Kit™ framework* is an open source software framework that makes it easy for app
developers and researchers to create research apps. This new framework takes advantage of sensors
and capabilities of iPhone to track movement, take measurements, and record data. Users can perform
activities and generate data from anywhere.

##Modules   

The *ORK1Kit framework* provides three customizable modules that address some of  the most
common elements of research: *surveys*, *consent*, and *active tasks*. You can use these modules as they
are, build on them, and even create completely new modules of your own.

###Surveys

The survey module's predefined user interface lets you quickly build surveys simply by specifying
the questions and types of answers. The survey module is already localized, so all you need to do is
to localize your questions. To learn more about surveys, see
[Creating Surveys](CreatingSurveys-template).

###Consent

Participants in research studies are often asked to share sensitive information as part of their
enrollment and involvement in the study. That’s why it’s critical to clarify exactly what
information will be collected from users and who will have access to their information. The
*ORK1Kit framework* provides templates that you can customize to explain the details of your
study and to obtain the participant’s consent. To learn more about consent, see
[Creating a Consent Document](InformedConsent-template).

### Active Tasks
Some studies may need more data than is provided by responses to survey questions or the data
collection capabilities of the *HealthKit* and *CoreMotion* APIs on *iOS*. Active tasks invite users
to perform activities under partially controlled conditions using iPhone sensors to actively collect
data. To learn more about active tasks, see [Active Tasks](ActiveTasks-template).

##Tasks and Steps

A task in the *ORK1Kit framework* can be a simple ordered sequence of steps, or it can be
dynamic, with previous results informing what is presented. The task view controller supports saving
progress in the middle of a long task and restoring it later, as well as UI state restoration to
prevent data loss if the user switches out of your app in the middle of a task.

Whether your app is giving instructions, presenting a form or survey, obtaining consent, or running
an active task, everything in the *ORK1Kit framework* is a collection of steps
(`ORK1Step` objects), which together form a task (an `ORK1Task` object). To present a task, attach the
task to a task view controller object (`ORK1TaskViewController`). When the user completes a step in a
task, the task view controller generates a step result object (`ORK1StepResult`) that records the
start and end time for that step, and any results from the step.

<center><img src="overview.png" width="80%" alt="ORK1Kit framework Overview"/></center>

In a simple app, you can build up your tasks directly in code, collect the results, and serialize
them to disk for later manual collection and analysis. A large-scale deployment might dynamically
download predefined surveys from a server and deserialize them to produce a *ORK1Kit framework*
object hierarchy. Similarly, results from tasks can be serialized and uploaded to a server for later
analysis.

##Current Limitations

The *ORK1Kit framework* feature list will continue to grow as useful modules are contributed by
the community.  Keep in mind that the *ORK1Kit framework* currently doesn’t include:

* Background sensor data collection. APIs like *HealthKit* and *CoreMotion* on *iOS* already support
    this.
* Secure communication mechanisms between your app and your server; you will need to provide this.
* The ability to schedule surveys and active tasks for your participants.
* A defined data format for how the *ORK1Kit framework* structured data is serialized. All the
    *ORK1Kit framework* objects conform to the `NSSecureCoding` protocol, and sample code exists
  protocol, and sample code exists outside the framework for
  serializing objects to JSON.

You are responsible for complying with applicable law for each
territory in which the app is made available.

## Logging Errors and Warnings

The *ORK1Kit framework* supports four log levels, controlled by four preprocessor macros and their corresponding *`NSLog()`-like* logging macros:
* `ORK1_LOG_LEVEL_NONE`
* `ORK1_LOG_LEVEL_DEBUG`, `ORK1_Log_Debug()`
* `ORK1_LOG_LEVEL_WARNING`, `ORK1_Log_Warning()`
* `ORK1_LOG_LEVEL_ERROR`, `ORK1_Log_Error()`

Setting the *ORK1Kit framework* `ORK1_LOG_LEVEL_NONE` macro to `1` completely silences all ORK1Kit logs, overriding any other specified log level. Setting `ORK1_LOG_LEVEL_DEBUG`, `ORK1_LOG_LEVEL_WARNING`, or `ORK1_LOG_LEVEL_ERROR` to `1` enables logging at that level and at those of higher seriousness.

If you do not explicitly set a log level, `ORK1_LOG_LEVEL_WARNING=1` is used by default.

You have to set any of these preprocessor macros in your ORK1Kit subproject, not in your main project. Within *Xcode*, you can do so by setting any of them in the `Preprocessor Macros` list on the `Build Settings` of your `ORK1Kit` framework target.

See these resources if you are using ORK1Kit through CocoaPods and need to change the log level: [[1]](http://stackoverflow.com/a/30038120/269753) [[2]](http://www.mokacoding.com/blog/cocoapods-and-custom-build-configurations/).
