/*
Copyright (c) 2015, Apple Inc. All rights reserved.

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

import ResearchKitLegacy

struct StudyTasks {
    
    static let microphoneTask: ORKLegacyOrderedTask = {
        let intendedUseDescription = "Everyone's voice has unique characteristics."
        let speechInstruction = "After the countdown, say Aaaaaaaaaaah for as long as you can. You'll have 10 seconds."
        let shortSpeechInstruction = "Say Aaaaaaaaaaah for as long as you can."
        
        return ORKLegacyOrderedTask.audioTask(withIdentifier: "AudioTask", intendedUseDescription: intendedUseDescription, speechInstruction: speechInstruction, shortSpeechInstruction: shortSpeechInstruction, duration: 10, recordingSettings: nil, checkAudioLevel: false, options: ORKLegacyPredefinedTaskOption.excludeAccelerometer)
    }()
    
    static let tappingTask: ORKLegacyOrderedTask = {
        let intendedUseDescription = "Finger tapping is a universal way to communicate."
        
        return ORKLegacyOrderedTask.twoFingerTappingIntervalTask(withIdentifier: "TappingTask", intendedUseDescription: intendedUseDescription, duration: 10, handOptions: .both, options: ORKLegacyPredefinedTaskOption())
    }()
    
    static let trailmakingTask: ORKLegacyOrderedTask = {
        let intendedUseDescription = "Tests visual attention and task switching"
        
        return ORKLegacyOrderedTask.trailmakingTask(withIdentifier: "TrailmakingTask", intendedUseDescription: intendedUseDescription, trailmakingInstruction: nil, trailType: .B, options: ORKLegacyPredefinedTaskOption())
    }()
    
    static let surveyTask: ORKLegacyOrderedTask = {
        var steps = [ORKLegacyStep]()
        
        // Instruction step
        let instructionStep = ORKLegacyInstructionStep(identifier: "IntroStep")
        instructionStep.title = "Knoweledge of the Universe Survey"
        instructionStep.text = "Please answer these 6 questions to the best of your ability. It's okay to skip a question if you don't know the answer."
        
        steps += [instructionStep]
        
        // Quest question using text choice
        let questQuestionStepTitle = "Which of the following is not a planet?"
        let textChoices = [
            ORKLegacyTextChoice(text: "Saturn", value: 0 as NSCoding & NSCopying & NSObjectProtocol),
            ORKLegacyTextChoice(text: "Uranus", value: 1 as NSCoding & NSCopying & NSObjectProtocol),
            ORKLegacyTextChoice(text: "Pluto", value: 2 as NSCoding & NSCopying & NSObjectProtocol),
            ORKLegacyTextChoice(text: "Mars", value: 3 as NSCoding & NSCopying & NSObjectProtocol)
        ]
        let questAnswerFormat: ORKLegacyTextChoiceAnswerFormat = ORKLegacyAnswerFormat.choiceAnswerFormat(with: .singleChoice, textChoices: textChoices)
        let questQuestionStep = ORKLegacyQuestionStep(identifier: "TextChoiceQuestionStep", title: questQuestionStepTitle, answer: questAnswerFormat)
        
        steps += [questQuestionStep]
        
        // Name question using text input
        let nameAnswerFormat = ORKLegacyTextAnswerFormat(maximumLength: 25)
        nameAnswerFormat.multipleLines = false
        let nameQuestionStepTitle = "What do you think the next comet that's discovered should be named?"
        let nameQuestionStep = ORKLegacyQuestionStep(identifier: "NameQuestionStep", title: nameQuestionStepTitle, answer: nameAnswerFormat)
        
        steps += [nameQuestionStep]
        
        let shapeQuestionStepTitle = "Which shape is the closest to the shape of Messier object 101?"
        let shapeTuples = [
            (UIImage(named: "square")!, "Square"),
            (UIImage(named: "pinwheel")!, "Pinwheel"),
            (UIImage(named: "pentagon")!, "Pentagon"),
            (UIImage(named: "circle")!, "Circle")
        ]
        let imageChoices : [ORKLegacyImageChoice] = shapeTuples.map {
            return ORKLegacyImageChoice(normalImage: $0.0, selectedImage: nil, text: $0.1, value: $0.1 as NSCoding & NSCopying & NSObjectProtocol)
        }
        let shapeAnswerFormat: ORKLegacyImageChoiceAnswerFormat = ORKLegacyAnswerFormat.choiceAnswerFormat(with: imageChoices)
        let shapeQuestionStep = ORKLegacyQuestionStep(identifier: "ImageChoiceQuestionStep", title: shapeQuestionStepTitle, answer: shapeAnswerFormat)
        
        steps += [shapeQuestionStep]
        
        // Date question
        let today = NSDate()
        let dateAnswerFormat =  ORKLegacyAnswerFormat.dateAnswerFormat(withDefaultDate: nil, minimumDate: today as Date, maximumDate: nil, calendar: nil)
        let dateQuestionStepTitle = "When is the next solar eclipse?"
        let dateQuestionStep = ORKLegacyQuestionStep(identifier: "DateQuestionStep", title: dateQuestionStepTitle, answer: dateAnswerFormat)
        
        steps += [dateQuestionStep]
        
        // Boolean question
        let booleanAnswerFormat = ORKLegacyBooleanAnswerFormat()
        let booleanQuestionStepTitle = "Is Venus larger than Saturn?"
        let booleanQuestionStep = ORKLegacyQuestionStep(identifier: "BooleanQuestionStep", title: booleanQuestionStepTitle, answer: booleanAnswerFormat)
        
        steps += [booleanQuestionStep]
        
        // Continuous question
        let continuousAnswerFormat = ORKLegacyAnswerFormat.scale(withMaximumValue: 150, minimumValue: 30, defaultValue: 20, step: 10, vertical: false, maximumValueDescription: "Objects", minimumValueDescription: " ")
        let continuousQuestionStepTitle = "How many objects are in Messier's catalog?"
        let continuousQuestionStep = ORKLegacyQuestionStep(identifier: "ContinuousQuestionStep", title: continuousQuestionStepTitle, answer: continuousAnswerFormat)
        
        steps += [continuousQuestionStep]
        
        // Summary step
        
        let summaryStep = ORKLegacyCompletionStep(identifier: "SummaryStep")
        summaryStep.title = "Thank you."
        summaryStep.text = "We appreciate your time."
        
        steps += [summaryStep]
        
        return ORKLegacyOrderedTask(identifier: "SurveyTask", steps: steps)
    }()
}
