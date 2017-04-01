//
//  MessageModel.swift
//  Move App
//
//  Created by jiang.duan on 2017/4/1.
//  Copyright © 2017年 TCL Com. All rights reserved.
//

import Foundation

func transformMinuteOffSet(messages: [UUMessage]) -> [UUMessageFrame] {
    return minuteOffSet(messages: messages).map { UUMessageFrame(message: $0) }
}

private func minuteOffSet(messages: [UUMessage]) -> [UUMessage] {
    return messages.reduce([]) { (initianl, next) -> [UUMessage] in
        var message = next
        var result = initianl
        message.minuteOffSet(start: initianl.last?.time ?? Date(timeIntervalSince1970: 0), end: message.time)
        result.append(message)
        return result
    }
}

extension UUMessage {
    
    init(imVoice: ImVoice, user: UserInfo) {
        var content = UUMessage.Content()
        let voice = UUMessage.Voice()
        content.voice = voice
        if let fileUrl = imVoice.locationURL {
            content.voice?.data = try? Data(contentsOf: fileUrl)
            content.voice?.second = imVoice.duration
        }
        self.init(icon: user.profile?.iconUrl?.fsImageUrl ?? "",
                  msgId: imVoice.msg_id ?? "",
                  time: imVoice.ctime ?? Date(),
                  name: user.profile?.nickname ?? "",
                  content: content,
                  state: .unread,
                  type: .voice,
                  from: .me,
                  showDateLabel: true)
    }
    
    init(imEmoji: ImEmoji, user: UserInfo) {
        var content = UUMessage.Content()
        content.emoji = imEmoji.content
        self.init(icon: user.profile?.iconUrl?.fsImageUrl ?? "",
                  msgId: imEmoji.msg_id ?? "",
                  time: imEmoji.ctime ?? Date(),
                  name: user.profile?.nickname ?? "",
                  content: content,
                  state: .unread,
                  type: .emoji,
                  from: .me,
                  showDateLabel: true)
    }
    
    init(userId: String, messageEntity: MessageEntity) {
        var content = UUMessage.Content()
        
        let group = messageEntity.owners.first
        let from = group?.members.filter({ $0.id == messageEntity.from }).first
        let headURL = from?.headPortrait?.fsImageUrl ?? ""
        
        var type = MessageType.text
        let contentType = MessageEntity.ContentType(rawValue: messageEntity.contentType) ?? .unknown
        switch contentType {
        case .text:
            content.emoji = EmojiType(rawValue: messageEntity.content ?? EmojiType.warning.rawValue)
            type = .emoji
        case .voice:
            var voice = UUMessage.Voice()
            voice.url = URL(string: messageEntity.content?.fsImageUrl ?? "")
            content.voice = voice
            content.voice?.second = Int(messageEntity.duration)
            type = .voice
        default: ()
        }
        
        self.init(icon: headURL,
                  msgId: messageEntity.id ?? "",
                  time: messageEntity.createDate ?? Date(),
                  name: from?.nickname ?? "",
                  content: content,
                  state: MessageState(status: messageEntity.readStatus)!,
                  type: type,
                  from: (messageEntity.from == userId) ? .me : .other,
                  showDateLabel: true)
    }
    
}


fileprivate extension MessageState {
    
    init?(status: Int) {
        self.init(status: MessageEntity.ReadStatus(rawValue: status)!)
    }
    
    init?(status: MessageEntity.ReadStatus) {
        self = (status == .unread) ? .unread : .read
    }
    
}
