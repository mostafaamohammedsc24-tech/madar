import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../features/property/domain/models/property_documents.dart';
import 'chat_room_screen.dart';
import 'chat_session_store.dart';
import 'models/chat_models.dart';
import 'open_sales_chat.dart';

/// Routes listing contact: Madar/owner → Sales Team; office listings → agent.
Future<void> openListingContact(
  BuildContext context, {
  required PropertyPublisher? publisher,
  Map<String, dynamic>? property,
  String? propertyId,
  String? title,
  String? priceLine,
  String? imageUrl,
  String? address,
}) async {
  if (publisher?.routesToAgent == true) {
    await openListingAgentChat(
      context,
      publisher: publisher!,
      property: property,
      propertyId: propertyId,
      title: title,
      priceLine: priceLine,
      imageUrl: imageUrl,
      address: address,
    );
    return;
  }

  await openSalesChat(
    context,
    property: property,
    propertyId: propertyId,
    title: title,
    priceLine: priceLine,
    imageUrl: imageUrl,
    address: address,
  );
}

Future<void> openListingAgentChat(
  BuildContext context, {
  required PropertyPublisher publisher,
  Map<String, dynamic>? property,
  String? propertyId,
  String? title,
  String? priceLine,
  String? imageUrl,
  String? address,
}) async {
  final loc = AppLocalizations.of(context);
  final agentId = publisher.id ?? publisher.displayName;
  final thread = ChatThread(
    id: 'listing-agent-${propertyId ?? agentId}',
    kind: ChatThreadKind.agent,
    icon: Icons.person_outline,
    displayName: publisher.displayName,
  );

  final id = propertyId ?? property?['id']?.toString();
  final name = title ??
      property?['title']?.toString() ??
      property?['title_ar']?.toString() ??
      'Property';
  final price = priceLine ??
      property?['asking_price']?.toString() ??
      property?['price']?.toString();
  final img = imageUrl ??
      property?['imageUrl']?.toString() ??
      property?['image_url']?.toString();
  final addr = address ??
      property?['address']?.toString() ??
      property?['address_text']?.toString();

  if (id != null && id.isNotEmpty) {
    final payload = jsonEncode({
      'id': id,
      'title': name,
      if (price != null) 'price': price,
      if (img != null) 'imageUrl': img,
      if (addr != null) 'address': addr,
    });
    ChatSessionStore.instance.add(
      thread.id,
      ChatMessage(
        id: 'prop-${DateTime.now().millisecondsSinceEpoch}',
        content: payload,
        isUser: true,
        createdAt: DateTime.now(),
        type: ChatMessageType.propertyCard,
        senderType: 'user',
      ),
    );
    ChatSessionStore.instance.add(
      thread.id,
      ChatMessage(
        id: 'agent-ack-${DateTime.now().millisecondsSinceEpoch}',
        content: loc.listingAgentChatAck,
        isUser: false,
        createdAt: DateTime.now().add(const Duration(seconds: 1)),
        type: ChatMessageType.text,
        senderType: 'agent',
      ),
    );
  }

  if (!context.mounted) return;
  await Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(builder: (_) => ChatRoomScreen(thread: thread)),
  );
}
