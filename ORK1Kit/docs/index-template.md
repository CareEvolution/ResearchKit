The ORK1Kit™ framework is an open source framework that developers and researchers can use to create apps that let iOS users participate in medical research.

This is the API documentation for the ORK1Kit framework. For an overview of framework and a more general guide to using and extending the framework, see the [Programming Guide](GuideOverview).


Constructing Tasks
--------------------

ORK1Kit tasks are actions to be performed by participants in a research study. Tasks are the building blocks for ORK1Kit modules, which address the most common components of medical studies: surveys, consent documents, and active tasks.

Tasks are constructed using a hierarchy of model objects.
At the root of the hierarchy is an ORK1OrderedTask object (or another object that implements the ORK1Task protocol). The task defines the order in which steps are presented, and how progress through the task is represented.

A task consists of steps, which are subclasses of ORK1Step. Most steps are designed for data presentation or data entry, but the ORK1ActiveStep subclasses can also enable data collection.
The ORK1QuestionStep and ORK1FormStep survey step classes describe a question to be asked. The format of the answer is modeled with subclasses of ORK1AnswerFormat.


Presenting Tasks
--------------------

To present a task, you create an ORK1TaskViewController object and give it the task. The task view controller manages the task and returns the result through delegate methods.

For each step, ORK1TaskViewController instantiates an appropriate subclass of ORK1StepViewController to display the step.


Getting Results
--------------------

The `result` property of ORK1TaskViewController provides the results of the task, both while the task is in progress, and upon completion of the task.

Results are constructed with a hierarchy that’s similar to the task model hierarchy. In the hierarchy for a result, ORK1TaskResult is the root and ORK1StepResult objects form the immediate children.

For survey question steps, the answers collected are reported as ORK1QuestionResult objects, which are children of ORK1StepResult. Active steps may include additional result objects as children, depending on the types of data that are recorded. To help you get data from various device features, such as the accelerometer or HealthKit, the ORK1Kit framework provides the ORK1Recorder and ORK1RecorderConfiguration classes, which work together to collect and configure data into a serialized format during the duration of an active step.


Predefined Active Tasks
--------------------

An active task invites users to perform activities under semi-controlled conditions, while iPhone sensors actively collect data. A category on ORK1OrderedTask provides factory methods for generating ORK1OrderedTask instances that correspond to ORK1Kit's predefined active tasks, such as the short walk or fitness task.


Consent
--------------------

The consent features in the ORK1Kit framework are implemented using three special steps that can be added to tasks:

* ORK1VisualConsentStep. The visual consent step presents a series of simple graphics to help participants understand the content of an consent document. The default graphics have animated transitions.

* ORK1ConsentSharingStep. The consent sharing step has predefined transitions that can be used to establish user preferences regarding how widely personal data can be shared.

* ORK1ConsentReviewStep. The consent review step makes the consent document available for review, and provides facilities for collecting the user's name and signature.

Creating the visual consent step and the consent review step requires a consent document model (that is, an ORK1ConsentDocument object).
