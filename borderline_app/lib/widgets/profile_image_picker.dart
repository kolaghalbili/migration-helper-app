import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileImagePicker extends StatefulWidget {
  /// Called whenever the list of picked files changes.
  final void Function(List<XFile>) onChanged;
  final int maxImages;

  const ProfileImagePicker({
    super.key,
    required this.onChanged,
    this.maxImages = 3,
  });

  @override
  State<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker> {
  final _picker = ImagePicker();
  final List<XFile> _images = [];

  Future<void> _pick(int slotIndex) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() {
      if (slotIndex < _images.length) {
        _images[slotIndex] = file;
      } else {
        _images.add(file);
      }
    });
    widget.onChanged(List.unmodifiable(_images));
  }

  void _remove(int index) {
    setState(() => _images.removeAt(index));
    widget.onChanged(List.unmodifiable(_images));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text(
            'Profile Photos',
            style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C), fontSize: 15),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text(
            'Add up to 3 photos. First photo is required.',
            style: TextStyle(fontSize: 12, color: Color(0xFF7A8B9A)),
          ),
        ),
        Row(
          children: List.generate(widget.maxImages, (i) => _buildSlot(i)),
        ),
      ],
    );
  }

  Widget _buildSlot(int i) {
    final hasImage = i < _images.length;
    final isRequired = i == 0;

    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: i < widget.maxImages - 1 ? 10 : 0),
        child: GestureDetector(
          onTap: () => _pick(i),
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isRequired && !hasImage
                          ? const Color(0xFFE8944A)
                          : const Color(0xFFDCE5ED),
                      width: isRequired && !hasImage ? 2 : 1.5,
                    ),
                  ),
                  child: hasImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: FutureBuilder<dynamic>(
                            future: _images[i].readAsBytes(),
                            builder: (context, snap) {
                              if (!snap.hasData) {
                                return const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2));
                              }
                              return Image.memory(
                                snap.data!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              );
                            },
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: isRequired
                                  ? const Color(0xFFE8944A)
                                  : const Color(0xFFB0BEC5),
                              size: 32,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isRequired ? 'Required' : 'Optional',
                              style: TextStyle(
                                fontSize: 11,
                                color: isRequired
                                    ? const Color(0xFFE8944A)
                                    : const Color(0xFFB0BEC5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                ),

                // Remove button
                if (hasImage)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _remove(i),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(3),
                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                      ),
                    ),
                  ),

                // Primary badge on first slot
                if (i == 0 && hasImage)
                  Positioned(
                    bottom: 6,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A3A5C),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Main',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
