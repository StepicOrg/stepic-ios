//
//  LessonPlainObject.swift
//  ExamEGERussian
//
//  Created by Ivan Magda on 24/07/2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation

struct LessonPlainObject: Codable, Equatable {
    let id: Int
    let steps: [Int]
    let title: String
    let slug: String
}

extension LessonPlainObject {
    init(lesson: Lesson) {
        self.id = lesson.id
        self.steps = lesson.stepsArray
        self.title = lesson.title
        self.slug = lesson.slug
    }

    init(lesson: KnowledgeGraphLesson) {
        self.id = lesson.id
        self.steps = []
        self.title = ""
        self.slug = ""
    }
}
