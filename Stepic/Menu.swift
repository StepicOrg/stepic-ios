//
//  Menu.swift
//  Stepic
//
//  Created by Ostrenkiy on 29.08.17.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import Foundation

protocol MenuDelegate: class {
    func update(at index: Int)
    func insert(at index: Int)
    func remove(at index: Int)
}

final class Menu {
    var blocks: [MenuBlock]
    weak var delegate: MenuDelegate?

    init(blocks: [MenuBlock]) {
        self.blocks = blocks
    }

    func getBlockIndex(id: String) -> Int? {
        return blocks.index(where: {
            $0.id == id
        })
    }

    func getBlock(id: String) -> MenuBlock? {
        return blocks.first(where: {
            $0.id == id
        })
    }

    func willAppear() {
        for block in blocks {
            block.onAppearance?()
        }
    }

    // MARK: - Insert

    @discardableResult func insert(block: MenuBlock, beforeBlockWithId id: String) -> Bool {
        guard let beforeBlock = getBlock(id: id) else {
            return false
        }
        return insert(block: block, before: beforeBlock)
    }

    @discardableResult func insert(block: MenuBlock, afterBlockWithId id: String) -> Bool {
        guard let afterBlock = getBlock(id: id) else {
            return false
        }
        return insert(block: block, after: afterBlock)
    }

    @discardableResult func insert(block: MenuBlock, at index: Int) -> Bool {
        guard getBlock(id: block.id) == nil else {
            return false
        }
        blocks.insert(block, at: index)
        delegate?.insert(at: index)
        return true
    }

    @discardableResult func insert(block: MenuBlock, before: MenuBlock) -> Bool {
        if let index = blocks.find({
            $0 === before
        }) {
            return insert(block: block, at: index)
        }
        return false
    }

    @discardableResult func insert(block: MenuBlock, after: MenuBlock) -> Bool {
        if let index = blocks.find({
            $0 === after
        }) {
            return insert(block: block, at: index + 1)
        }
        return false
    }

    // MARK: - Update

    @discardableResult func update(id: String) -> Bool {
        guard let block = getBlock(id: id) else {
            return false
        }
        return update(block: block)
    }

    @discardableResult func update(block: MenuBlock) -> Bool {
        if let index = blocks.find({
            $0 === block
        }) {
            return update(at: index)
        }
        return false
    }

    @discardableResult func update(at index: Int) -> Bool {
        guard index < blocks.count else {
            return false
        }
        delegate?.update(at: index)
        return true
    }

    // MARK: - Remove

    @discardableResult func remove(id: String) -> Bool {
        guard let block = getBlock(id: id) else {
            return false
        }
        return remove(block: block)
    }

    @discardableResult func remove(block: MenuBlock) -> Bool {
        if let index = blocks.find({
            $0 === block
        }) {
            return remove(at: index)
        }
        return false
    }

    @discardableResult func remove(at index: Int) -> Bool {
        blocks.remove(at: index)
        delegate?.remove(at: index)
        return true
    }
}
