//
//  TopicsCollectionSource.swift
//  ExamEGERussian
//
//  Created by Ivan Magda on 28/08/2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import UIKit

final class TopicsCollectionSource: NSObject {
    var topics: [TopicPlainObject]

    init(topics: [TopicPlainObject] = []) {
        self.topics = topics
        super.init()
    }

    func register(for collectionView: UICollectionView) {
        collectionView.register(cellClass: CardCollectionViewCell.self)
        collectionView.dataSource = self
        collectionView.delegate = self
    }
}

extension TopicsCollectionSource: UICollectionViewDataSource {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return topics.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let topic = topics[indexPath.row]
        let cell: CardCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
        cell.titleLabel.text = topic.title
        cell.bodyLabel.text = topic.description
        cell.commentLabel.text = "\(topic.lessons.count) pages"

        return cell
    }
}

extension TopicsCollectionSource: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return CGSize(width: 240, height: collectionView.bounds.height)
    }
}
