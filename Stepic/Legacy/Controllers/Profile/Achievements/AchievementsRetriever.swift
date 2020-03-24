//
//  AchievementsRetriever.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 08.06.2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation
import PromiseKit

final class AchievementsRetriever {
    private var userId: Int

    private var achievementsAPI: AchievementsAPI
    private var achievementProgressesAPI: AchievementProgressesAPI

    init(userId: Int, achievementsAPI: AchievementsAPI, achievementProgressesAPI: AchievementProgressesAPI) {
        self.userId = userId
        self.achievementsAPI = achievementsAPI
        self.achievementProgressesAPI = achievementProgressesAPI
    }

    func loadAllAchievements(breakCondition: @escaping ([Achievement]) -> Bool) -> Promise<[Achievement]> {
        var allAchievements = [Achievement]()

        func load(page: Int) -> Guarantee<Bool> {
            return Guarantee { seal in
                achievementsAPI.retrieve(page: page).done { (achievements, meta) in
                    allAchievements.append(contentsOf: achievements)
                    seal(meta.hasNext)
                }.catch { _ in
                    seal(false)
                }
            }
        }

        func collect(page: Int) -> Promise<[Achievement]> {
            return load(page: page).then { hasNext -> Promise<[Achievement]> in
                if !breakCondition(allAchievements) && hasNext {
                    return collect(page: page + 1)
                } else {
                    return .value(allAchievements)
                }
            }
        }

        return collect(page: 1)
    }

    func loadAllAchievementProgresses(breakCondition: @escaping ([AchievementProgress]) -> Bool) -> Promise<[AchievementProgress]> {
        var allProgresses = [AchievementProgress]()

        func load(page: Int) -> Guarantee<Bool> {
            return Guarantee { seal in
                achievementProgressesAPI.retrieve(user: userId, sortByObtainDateDesc: true, page: page).done { (progresses, meta) in
                    allProgresses.append(contentsOf: progresses)
                    seal(meta.hasNext)
                }.catch { _ in
                    seal(false)
                }
            }
        }

        func collect(page: Int) -> Promise<[AchievementProgress]> {
            return load(page: page).then { hasNext -> Promise<[AchievementProgress]> in
                if !breakCondition(allProgresses) && hasNext {
                    return collect(page: page + 1)
                } else {
                    return .value(allProgresses)
                }
            }
        }

        return collect(page: 1)
    }

    func loadAchievementProgress(for achievement: Achievement) -> Promise<AchievementProgressData> {
        self.loadAchievementProgress(for: achievement.kind)
    }

    func loadAchievementProgress(for kind: String) -> Promise<AchievementProgressData> {
        Promise { seal in
            let allAchievementsWithKind: Promise<[Achievement]> = Promise { seal in
                achievementsAPI.retrieve(kind: kind).done { achievements, _ in
                    seal.fulfill(achievements)
                }.catch { error in
                    seal.reject(error)
                }
            }
            let allProgressesWithKind: Promise<[AchievementProgress]> = Promise { seal in
                achievementProgressesAPI.retrieve(user: userId, kind: kind).done { progresses, _ in
                    seal.fulfill(progresses)
                }.catch { error in
                    seal.reject(error)
                }
            }

            when(fulfilled: allAchievementsWithKind, allProgressesWithKind).done { (achievements, progresses) in
                // achievement id -> target score
                var idToTargetScore = [Int: Int]()
                for achievement in achievements.sorted(by: { $0.targetScore < $1.targetScore }) {
                    idToTargetScore[achievement.id] = achievement.targetScore
                }

                var levelCount = 0
                let progressesSortedByMaxScore = progresses.sorted(by: { a, b in
                    let lhs = idToTargetScore[a.achievement] ?? 0
                    let rhs = idToTargetScore[b.achievement] ?? 0
                    return lhs < rhs
                })

                // Sort achievements by progress and find first non-obtained
                for progress in progressesSortedByMaxScore {
                    if progress.obtainDate == nil {
                        // Non-completed achievement, but have progress object
                        seal.fulfill(AchievementProgressData(currentScore: progress.score,
                                                        maxScore: idToTargetScore[progress.achievement] ?? 0,
                                                        currentLevel: levelCount,
                                                        maxLevel: achievements.count,
                                                        kind: kind))
                        return
                    }
                    levelCount += 1
                }

                // No non-obtained achievements were found
                if let lastProgress = progressesSortedByMaxScore.last {
                    // Fulfilled achievement
                    seal.fulfill(AchievementProgressData(currentScore: lastProgress.score,
                        maxScore: idToTargetScore[lastProgress.achievement] ?? 0,
                        currentLevel: achievements.count,
                        maxLevel: achievements.count,
                        kind: kind))
                } else {
                    let maxScoreForFirstLevel = achievements.sorted(by: { $0.targetScore < $1.targetScore }).first?.targetScore
                    // Non-completed achievement, empty progress
                    seal.fulfill(AchievementProgressData(currentScore: 0,
                        maxScore: maxScoreForFirstLevel ?? 0,
                        currentLevel: 0,
                        maxLevel: achievements.count,
                        kind: kind))
                }
            }.catch { error in
                seal.reject(error)
            }
        }
    }
}

struct AchievementProgressData {
    var currentScore: Int
    var maxScore: Int
    var currentLevel: Int
    var maxLevel: Int
    var kind: String
}
