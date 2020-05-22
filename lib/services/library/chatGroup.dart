import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:the_spot/services/library/userProfile.dart';

class ChatGroup {
  String id;
  String name;
  String imageDownloadPath;
  List<String> adminsIds;
  List<String> membersIds;
  String creatorId;
  List<Message> messages;
  bool onlyAdminsCanChangeChatNameOrPicture;
  bool hasArchiveMessages;
  int activeMessagesCount;
  int totalMessagesCount;

  Timestamp lastMessage;
  Timestamp lastUpdate;
  Timestamp creationDate;

  List<UserProfile> members;
  bool isGroup;


  ChatGroup(
      {this.id,
      this.name,
      this.imageDownloadPath,
      this.adminsIds,
      this.membersIds,
      this.creatorId,
      this.messages,
      this.onlyAdminsCanChangeChatNameOrPicture,
      this.hasArchiveMessages,
      this.activeMessagesCount,
      this.totalMessagesCount,
      this.lastMessage,
      this.lastUpdate,
      this.creationDate,
      this.members});

  Map<String, dynamic> toMap() {
    return {
      'Name': name,
      'ImageDownloadPath': imageDownloadPath,
      'AdminsIds': adminsIds,
      'MembersIds': membersIds,
      'CreatorId' : creatorId,
      'Messages': convertListOfMessagesToListOfMap(messages),
      'OnlyAdminsCanChangeChatNameOrPicture': onlyAdminsCanChangeChatNameOrPicture,
      'HasArchiveMessages': hasArchiveMessages,
      'ActiveMessagesCount': activeMessagesCount,
      'TotalMessagesCount': totalMessagesCount,
      'LastMessage': lastMessage,
      'LastUpdate': lastUpdate,
      'CreationDate': creationDate
    };
  }
}

ChatGroup convertMapToChatGroup(Map map) {
  ChatGroup chatGroup = ChatGroup(
      name: map['Name'],
      imageDownloadPath: map['ImageDownloadPath'],
      adminsIds: map['AdminsIds'].cast<String>(),
      membersIds: map['MembersIds'].cast<String>(),
      creatorId: map['CreatorId'],
      messages: convertListOfMapsToListOfMessages(map['Messages'].cast<Map>()),
      onlyAdminsCanChangeChatNameOrPicture: map['OnlyAdminsCanChangeChatNameOrPicture'],
      hasArchiveMessages: map['HasArchiveMessages'],
      activeMessagesCount: map['ActiveMessagesCount'],
      totalMessagesCount: map['TotalMessagesCount'],
      lastMessage: map['LastMessage'],
      lastUpdate: map['LastUpdate'],
      creationDate: map['CreationDate']);
  if (chatGroup.membersIds.length > 2)
    chatGroup.isGroup = true;
  else
    chatGroup.isGroup = false;
  return chatGroup;
}

enum MessageType{
  TEXT,
  PICTURE,
  VOICE_RECORD,
}
class Message {
  String senderId;
  Timestamp date;
  String data;
  MessageType messageType;

  Message(this.senderId, this.date, this.data);

  Map<String, dynamic> toMap() {
    return {
      "SenderId": senderId,
      "Date": date,
      "Data": data,
    };
  }

  void setMessageTypeAndTransformData(){
    if(data.contains("%#%PICTURE%#%")){
      data = data.replaceAll("%#%PICTURE%#%", "");
      messageType = MessageType.PICTURE;
    } else if (data.contains("%#%VOICE_RECORD%#%")){
      data = data.replaceAll("%#%VOICE_RECORD%#%", "");
      messageType = MessageType.VOICE_RECORD;
    } else{
      messageType = MessageType.TEXT;
    }
  }
}

Message convertMapToMessage(Map map) {
  return Message(map['SenderId'], map['Date'], map['Data']);
}

List<Message> convertListOfMapsToListOfMessages(List<Map> maps) {
  List<Message> messages = [];
  maps.forEach((map) => messages.add(convertMapToMessage(map)));
  return messages;
}

List<Map> convertListOfMessagesToListOfMap(List<Message> messages, {bool reverse = false}) {
  if(reverse)
    messages = messages.reversed.toList();
  List<Map> messagesMaps = [];
  messages.forEach((element) => messagesMaps.add(element.toMap()));
  return messagesMaps;
}