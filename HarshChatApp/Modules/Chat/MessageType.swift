//
//  MessageType.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//

import Foundation
import MessageKit
import UIKit

struct Sender: SenderType {
    var senderId: String
    var displayName: String
}

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}

struct ImageMediaItem: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}
