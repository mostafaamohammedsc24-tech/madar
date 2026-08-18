import 'dart:convert';

import 'package:flutter/material.dart';

import 'chat_room_screen.dart';
import 'chat_session_store.dart';
import 'models/chat_models.dart';

/// Opens the Sales Team chat and optionally seeds a property card message.
Future<void> openSalesChat(
  BuildContext context, {
  Map<String, dynamic>? property,
  String? propertyId,
  String? title,
  String? priceLine,
  String? imageUrl,
  String? address,
}) async {
  final thread = ChatThread.pinned.firstWhere(
    (t) => t.kind == ChatThreadKind.sales,
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
        id: 'sales-ack-${DateTime.now().millisecondsSinceEpoch}',
        content:
            'شكراً لاهتمامك بهذا العقار. فريق المبيعات سيتواصل معك قريباً.',
        isUser: false,
        createdAt: DateTime.now().add(const Duration(seconds: 1)),
        type: ChatMessageType.text,
        senderType: 'sales',
      ),
    );
  }

  if (!context.mounted) return;
  await Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(builder: (_) => ChatRoomScreen(thread: thread)),
  );
}

/// Delivers office-generated transaction barcodes into the Agent chat
/// (buyer + seller copies). Office keeps its own QR screen copy.
void deliverOfficeBarcodesToAgentChat({
  required String transactionNumber,
  required String buyerBarcode,
  required String sellerBarcode,
  required String buyerPhone,
  required String sellerPhone,
}) {
  final threadId = 'agent';
  final now = DateTime.now();
  ChatSessionStore.instance.add(
    threadId,
    ChatMessage(
      id: 'bc-buyer-$now',
      content: 'باركود المشتري ($buyerPhone) — عملية $transactionNumber\n$buyerBarcode',
      isUser: false,
      createdAt: now,
      type: ChatMessageType.barcode,
      senderType: 'agent',
    ),
  );
  ChatSessionStore.instance.add(
    threadId,
    ChatMessage(
      id: 'bc-seller-$now',
      content: 'باركود البائع ($sellerPhone) — عملية $transactionNumber\n$sellerBarcode',
      isUser: false,
      createdAt: now.add(const Duration(seconds: 1)),
      type: ChatMessageType.barcode,
      senderType: 'agent',
    ),
  );
}
