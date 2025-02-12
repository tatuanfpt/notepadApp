//
//  NoteModel.swift
//  notepadApp
//
//  Created by TuanTa on 12/2/25.
//

import CoreData

@objc(NoteModel)
class NoteModel: NSManagedObject {
    @NSManaged var id: Int
    @NSManaged var title: String
    @NSManaged var content: String
    @NSManaged var createdTime: Date
    @NSManaged var lastEditTime: Date
    @NSManaged var backgroundTheme: String
}
