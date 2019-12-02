/*
Copyright (c) 2015, Ricardo Sánchez-Sáez.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1.  Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2.  Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3.  Neither the name of the copyright holder(s) nor the names of any contributors
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
*/

import Foundation
import ORK1Kit

@objc class TaskFactory : NSObject {

   @objc class func makeNavigableOrderedTask(_ taskIdentifier : String) -> ORK1NavigableOrderedTask {
        var steps: [ORK1Step] = []
        var answerFormat: ORK1AnswerFormat
        var step: ORK1Step
        var textChoices: [ORK1TextChoice]
        
        // Form step
        textChoices = [
            ORK1TextChoice(text: "Good", value: "good" as NSCoding & NSCopying & NSObjectProtocol),
            ORK1TextChoice(text: "Bad", value: "bad" as NSCoding & NSCopying & NSObjectProtocol)
        ]
        answerFormat = ORK1AnswerFormat.choiceAnswerFormat(with: ORK1ChoiceAnswerStyle.singleChoice, textChoices: textChoices)
        let formItemFeeling: ORK1FormItem = ORK1FormItem(identifier: "formFeeling", text: "How do you feel", answerFormat: answerFormat)
        let formItemMood: ORK1FormItem = ORK1FormItem(identifier: "formMood", text: "How is your mood", answerFormat: answerFormat)
        let formStep: ORK1FormStep = ORK1FormStep(identifier: "introForm")
        formStep.isOptional = false
        formStep.formItems = [formItemFeeling, formItemMood]
        steps.append(formStep)
        
        // Question steps
        textChoices = [
            ORK1TextChoice(text: "Headache", value: "headache" as NSCoding & NSCopying & NSObjectProtocol),
            ORK1TextChoice(text: "Dizziness", value: "dizziness" as NSCoding & NSCopying & NSObjectProtocol),
            ORK1TextChoice(text: "Nausea", value: "nausea" as NSCoding & NSCopying & NSObjectProtocol)
        ]
        answerFormat = ORK1TextChoiceAnswerFormat(style: ORK1ChoiceAnswerStyle.singleChoice, textChoices: textChoices)
        step = ORK1QuestionStep(identifier: "symptom", title: "Which is your most severe symptom?", answer: answerFormat)
        step.isOptional = false
        steps.append(step)
        
        answerFormat = ORK1AnswerFormat.booleanAnswerFormat()
        step = ORK1QuestionStep(identifier: "severity", title: "Does your symptom interfere with your daily life?", answer: answerFormat)
        step.isOptional = false
        steps.append(step)
        
        // Instruction steps
        step = ORK1InstructionStep(identifier: "blank")
        step.title = "This step is intentionally left blank (you should not see it)"
        steps.append(step)
        
        step = ORK1InstructionStep(identifier: "severe_headache")
        step.title = "You have a severe headache"
        steps.append(step)
        
        step = ORK1InstructionStep(identifier: "light_headache")
        step.title = "You have a light headache"
        steps.append(step)
        
        step = ORK1InstructionStep(identifier: "other_symptom")
        step.title = "Your symptom is not a headache"
        steps.append(step)
        
        step = ORK1InstructionStep(identifier: "survey_skipped")
        step.title = "Please come back to this survey when you don't feel good or your mood is low."
        steps.append(step)
        
        step = ORK1InstructionStep(identifier: "end")
        step.title = "You have finished the task"
        steps.append(step)
        
        step = ORK1InstructionStep(identifier: "blankB")
        step.title = "This step is intentionally left blank (you should not see it)"
        steps.append(step)
        
        let task: ORK1NavigableOrderedTask = ORK1NavigableOrderedTask(identifier: taskIdentifier, steps: steps)
        
        // Navigation rules
        var predicateRule: ORK1PredicateStepNavigationRule
        
        // From the feel/mood form step, skip the survey if the user is feeling okay and has a good mood
        var resultSelector = ORK1ResultSelector.init(stepIdentifier: "introForm", resultIdentifier: "formFeeling");
        let predicateGoodFeeling: NSPredicate = ORK1ResultPredicate.predicateForChoiceQuestionResult(with: resultSelector, expectedAnswerValue: "good" as NSCoding & NSCopying & NSObjectProtocol)
        resultSelector = ORK1ResultSelector.init(stepIdentifier: "introForm", resultIdentifier: "formMood");
        let predicateGoodMood: NSPredicate = ORK1ResultPredicate.predicateForChoiceQuestionResult(with: resultSelector, expectedAnswerValue: "good" as NSCoding & NSCopying & NSObjectProtocol)
        let predicateGoodMoodAndFeeling: NSCompoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateGoodFeeling, predicateGoodMood])
        predicateRule = ORK1PredicateStepNavigationRule(resultPredicatesAndDestinationStepIdentifiers:
            [ (predicateGoodMoodAndFeeling, "survey_skipped") ])
        task.setNavigationRule(predicateRule, forTriggerStepIdentifier: "introForm")
        
        // From the "symptom" step, go to "other_symptom" is user didn't chose headache.
        // Otherwise, default to going to next step (the regular ORK1OrderedTask order applies
        //  when the defaultStepIdentifier argument is omitted).
        
        // User chose headache at the symptom step
        // Equivalent to:
        //      [NSPredicate predicateWithFormat:
        //          @"SUBQUERY(SELF, $x, $x.identifier like 'symptom' \
        //                     AND SUBQUERY($x.answer, $y, $y like 'headache').@count > 0).@count > 0"];
        resultSelector = ORK1ResultSelector.init(resultIdentifier: "symptom");
        let predicateHeadache: NSPredicate = ORK1ResultPredicate.predicateForChoiceQuestionResult(with: resultSelector, expectedAnswerValue: "headache" as NSCoding & NSCopying & NSObjectProtocol)
        
        // User didn't chose headache at the symptom step
        let predicateNotHeadache: NSCompoundPredicate = NSCompoundPredicate(notPredicateWithSubpredicate: predicateHeadache)

        predicateRule = ORK1PredicateStepNavigationRule(resultPredicatesAndDestinationStepIdentifiers:
            [ (predicateNotHeadache, "other_symptom") ])
        task.setNavigationRule(predicateRule, forTriggerStepIdentifier: "symptom")
        
        // From the "severity" step, go to "severe_headache" or "light_headache" depending on the user answer
        
        // User chose YES at the severity step
        // Equivalent to:
        //      [NSPredicate predicateWithFormat:
        //          @"SUBQUERY(SELF, $x, $x.identifier like 'severity' AND $x.answer == YES).@count > 0"];
        resultSelector = ORK1ResultSelector.init(resultIdentifier: "severity");
        let predicateSevereYes: NSPredicate = ORK1ResultPredicate.predicateForBooleanQuestionResult(with: resultSelector, expectedAnswer: true)
        
        // User chose NO at the severity step
        resultSelector = ORK1ResultSelector.init(resultIdentifier: "severity");
        let predicateSevereNo: NSPredicate = ORK1ResultPredicate.predicateForBooleanQuestionResult(with: resultSelector, expectedAnswer: false)
        
        let predicateSevereHeadache: NSCompoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateHeadache, predicateSevereYes])
        let predicateLightHeadache: NSCompoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateHeadache, predicateSevereNo])
        
        predicateRule = ORK1PredicateStepNavigationRule(resultPredicatesAndDestinationStepIdentifiers:
            [ (predicateSevereHeadache, "severe_headache"), (predicateLightHeadache, "light_headache") ])
        task.setNavigationRule(predicateRule, forTriggerStepIdentifier: "severity")
        
        // Direct rules to skip unneeded steps
        var directRule: ORK1DirectStepNavigationRule
        
        directRule = ORK1DirectStepNavigationRule(destinationStepIdentifier: "end")
        task.setNavigationRule(directRule, forTriggerStepIdentifier: "severe_headache")
        task.setNavigationRule(directRule, forTriggerStepIdentifier: "light_headache")
        task.setNavigationRule(directRule, forTriggerStepIdentifier: "other_symptom")
        task.setNavigationRule(directRule, forTriggerStepIdentifier: "survey_skipped")
        
        directRule = ORK1DirectStepNavigationRule(destinationStepIdentifier: ORK1NullStepIdentifier)
        task.setNavigationRule(directRule, forTriggerStepIdentifier: "end")
        
        return task
    }
}
