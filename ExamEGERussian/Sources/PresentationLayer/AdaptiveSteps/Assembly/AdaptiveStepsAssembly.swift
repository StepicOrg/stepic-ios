//
//  AdaptiveStepsAssembly.swift
//  ExamEGERussian
//
//  Created by Ivan Magda on 20/08/2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import UIKit

final class AdaptiveStepsAssembly: BaseAssembly, AdaptiveStepsAssemblyProtocol {
    func module(topicId: String) -> UIViewController? {
        let knowledgeGraph = serviceFactory.knowledgeGraphProvider.knowledgeGraph
        guard let courseId = getCourseId(for: topicId, knowledgeGraph: knowledgeGraph) else {
            return nil
        }

        let controller = AdaptiveStepsViewController()
        let presenter = AdaptiveStepsPresenter(view: controller, courseId: courseId)

        controller.presenter = presenter
        controller.title = knowledgeGraph[topicId]?.key.title

        return controller
    }

    private func getCourseId(for topicId: String, knowledgeGraph: KnowledgeGraph) -> String? {
        guard let vertex = knowledgeGraph[topicId]?.key else {
            print("Couldn't fide topic with id: \(topicId)")
            return nil
        }

        let coursesIds = vertex.lessons
            .filter { $0.type == .practice }
            .map { $0.courseId }

        return Set(coursesIds).randomElement()
    }
}
