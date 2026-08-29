import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'models/models.dart';
import 'services/chat_service.dart';
import 'create_lobby_page.dart';

class ChatDetailScreen extends StatefulWidget {
  final ProfileModel athlete;

  const ChatDetailScreen({super.key, required this.athlete});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isUploading = false;

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSendMessage({String? imageUrl, bool isReceipt = false}) async {
    final text = _msgController.text.trim();
    if (text.isEmpty && imageUrl == null) return;

    _msgController.clear();

    try {
      await _chatService.sendMessage(
        receiverId: widget.athlete.id,
        content: text,
        imageUrl: imageUrl,
        isReceipt: isReceipt,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send message: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _pickAndAttachImage(ImageSource source, {bool isReceipt = false}) async {
    try {
      final picked = await _imagePicker.pickImage(source: source, imageQuality: 70);
      if (picked == null) return;

      setState(() => _isUploading = true);

      final url = await _chatService.uploadChatImage(picked);
      if (url != null) {
        await _handleSendMessage(imageUrl: url, isReceipt: isReceipt);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to upload image. Please try again."), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      debugPrint("Attachment error: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              const Text(
                "SHARE ATTACHMENT / PAYMENT PROOF",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF39FF14).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF39FF14), size: 20),
                ),
                title: const Text("Forward Payment Receipt 🧾", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text("Attach FPX / DuitNow payment screenshot", style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndAttachImage(ImageSource.gallery, isReceipt: true);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Colors.blueAccent, size: 20),
                ),
                title: const Text("Photo Gallery", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text("Select image from your phone", style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndAttachImage(ImageSource.gallery, isReceipt: false);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.purpleAccent, size: 20),
                ),
                title: const Text("Take Photo / Scan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text("Capture live photo or court view", style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndAttachImage(ImageSource.camera, isReceipt: false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              clipBehavior: Clip.none,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF222222),
                  child: ClipOval(
                    child: _buildAvatarImage(widget.athlete.imageUrl),
                  ),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF39FF14),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF141414), width: 1.5),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.athlete.name,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "${widget.athlete.sport.toUpperCase()} • ${widget.athlete.skill}",
                    style: const TextStyle(color: Color(0xFF39FF14), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Create Lobby",
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF39FF14)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateLobbyPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat Stream Area
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessagesStream(widget.athlete.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF39FF14)));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 56, color: Colors.white.withValues(alpha: 0.15)),
                        const SizedBox(height: 12),
                        Text(
                          "NO MESSAGES YET",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Say hello to start planning your game!",
                          style: TextStyle(color: Colors.white24, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                return _buildMessageListView(messages);
              },
            ),
          ),

          // Message Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            ),
            child: Row(
              children: [
                // Attachment / Receipt Button
                IconButton(
                  icon: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Color(0xFF39FF14), strokeWidth: 2),
                        )
                      : const Icon(Icons.attach_file_rounded, color: Color(0xFF39FF14), size: 22),
                  tooltip: "Attach Receipt / Image",
                  onPressed: _isUploading ? null : _showAttachmentSheet,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: TextField(
                      controller: _msgController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _handleSendMessage(),
                      decoration: const InputDecoration(
                        hintText: "Type message or attach receipt...",
                        hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _handleSendMessage(),
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: const BoxDecoration(
                      color: Color(0xFF39FF14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.black, size: 19),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageListView(List<MessageModel> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isMe = msg.senderId == _chatService.currentUserId || msg.senderId.startsWith('local');
        final hasImage = msg.imageUrl != null && msg.imageUrl!.isNotEmpty;

        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF39FF14) : const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Image Attachment / Receipt Display
                if (hasImage) ...[
                  GestureDetector(
                    onTap: () => _showFullScreenImage(msg.imageUrl!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        alignment: Alignment.bottomLeft,
                        children: [
                          Image.network(
                            msg.imageUrl!,
                            width: 220,
                            height: 180,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                width: 220,
                                height: 180,
                                color: Colors.black26,
                                child: const Center(child: CircularProgressIndicator(color: Color(0xFF39FF14), strokeWidth: 2)),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 220,
                              height: 120,
                              color: Colors.black38,
                              child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.white38)),
                            ),
                          ),
                          if (msg.isReceipt)
                            Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF39FF14), width: 1),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.receipt_rounded, color: Color(0xFF39FF14), size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    "PAYMENT RECEIPT",
                                    style: TextStyle(color: Color(0xFF39FF14), fontSize: 9, fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],

                if (msg.content.isNotEmpty && !(hasImage && (msg.content == '📷 Image Attachment' || msg.content == '🧾 Payment Receipt')))
                  Text(
                    msg.content,
                    style: TextStyle(
                      color: isMe ? Colors.black : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(msg.createdAt),
                  style: TextStyle(
                    color: isMe ? Colors.black54 : Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarImage(String? imgPath) {
    if (imgPath != null && imgPath.startsWith('http')) {
      return Image.network(
        imgPath,
        fit: BoxFit.cover,
        width: 40, height: 40,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Color(0xFF39FF14)),
      );
    } else if (imgPath != null && imgPath.isNotEmpty) {
      return Image.asset(
        imgPath,
        fit: BoxFit.cover,
        width: 40, height: 40,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Color(0xFF39FF14)),
      );
    }
    return const Icon(Icons.person, color: Color(0xFF39FF14));
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }
}
