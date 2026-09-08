// lib/core/common/widgets/user_avatar.dart
//
// One place that knows how to find and render a user's photo.
//
// Why this exists: profile photos in this project are stored in several ways
// and the old per-screen helpers each missed a case, so some avatars rendered
// and some did not:
//
//   • users/{uid}.faceImage                  — sometimes a URL, sometimes base64
//   • users/{uid}/profile_data/image.faceImage — the Cloudinary URL for most accounts
//   • junk values: the literal strings 'null' / 'undefined', or blank space.
//     These are NOT empty, so the old code treated them as a valid photo and
//     never fell back to the subcollection. That is the main reason photos
//     were missing even though the image clearly existed in Firestore.
//   • base64 without correct '=' padding, which makes base64Decode throw
//   • URLs saved without a scheme ("res.cloudinary.com/..." or "//res...")
//
// UserImage handles every one of those; UserAvatar renders it and resolves the
// subcollection on demand, caching the result so a long list fetches each user
// at most once.

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserImage {
  UserImage._();

  /// Field names that have been used for a profile photo over time.
  static const List<String> imageFields = [
    'faceImage',
    'image',
    'imageUrl',
    'photoUrl',
    'profileImage',
    'profilePic',
  ];

  static final Map<String, String> _cache = {};
  static final Map<String, Future<String>> _inFlight = {};

  /// Trims a raw Firestore value and throws away the placeholders that are
  /// not really images.
  static String clean(dynamic raw) {
    if (raw == null) return '';
    var value = raw.toString().trim();
    // Values that came back from an interpolated string at some point.
    const junk = {'null', 'undefined', 'nan', 'n/a', '-', 'false'};
    if (value.isEmpty || junk.contains(value.toLowerCase())) return '';
    // Occasionally a value got saved wrapped in quotes.
    if (value.length > 1 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      value = value.substring(1, value.length - 1).trim();
    }
    return value;
  }

  /// Can this string actually be turned into an image?
  static bool isUsable(dynamic raw) => clean(raw).length > 8;

  /// Picks the first usable photo field out of a Firestore document map.
  static String fromMap(Map<String, dynamic>? data) {
    if (data == null) return '';
    for (final field in imageFields) {
      final value = clean(data[field]);
      if (value.length > 8) return value;
    }
    return '';
  }

  static String? cached(String uid) => _cache[uid];

  static void remember(String uid, String image) {
    final value = clean(image);
    if (value.length > 8) _cache[uid] = value;
  }

  static void clearCache() {
    _cache.clear();
    _inFlight.clear();
  }

  /// Finds this user's photo: the value already at hand, then the cache, then
  /// users/{uid}/profile_data/image, then the user document itself.
  /// Concurrent calls for the same uid share one network round trip.
  static Future<String> resolve(String uid, {String? known}) {
    final direct = clean(known);
    if (direct.length > 8) {
      _cache[uid] = direct;
      return Future.value(direct);
    }

    final hit = _cache[uid];
    if (hit != null) return Future.value(hit);
    if (uid.isEmpty) return Future.value('');

    return _inFlight[uid] ??= _fetch(uid).whenComplete(() {
      _inFlight.remove(uid);
    });
  }

  static Future<String> _fetch(String uid) async {
    final db = FirebaseFirestore.instance;
    try {
      final doc = await db
          .collection('users')
          .doc(uid)
          .collection('profile_data')
          .doc('image')
          .get();
      final image = fromMap(doc.data());
      if (image.isNotEmpty) {
        _cache[uid] = image;
        return image;
      }
    } catch (_) {
      // Permission or network problem — fall through to the user document.
    }

    try {
      final doc = await db.collection('users').doc(uid).get();
      final image = fromMap(doc.data());
      if (image.isNotEmpty) {
        _cache[uid] = image;
        return image;
      }
    } catch (_) {}

    return '';
  }

  /// Turns a stored value into something Image can display.
  /// Returns null when the value cannot be decoded.
  static ImageProvider? provider(dynamic raw) {
    var value = clean(raw);
    if (value.length < 9) return null;

    // A data: URI, e.g. data:image/jpeg;base64,XXXX
    if (value.startsWith('data:')) {
      final comma = value.indexOf(',');
      if (comma == -1) return null;
      return _memory(value.substring(comma + 1));
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return NetworkImage(value);
    }
    // Saved without a scheme: "//res.cloudinary.com/..." or "res.cloudinary.com/..."
    if (value.startsWith('//')) return NetworkImage('https:$value');
    if (value.startsWith('www.') || value.contains('cloudinary.com/')) {
      return NetworkImage('https://$value');
    }

    return _memory(value);
  }

  static ImageProvider? _memory(String rawBase64) {
    try {
      // Strip whitespace/newlines, then fix the '=' padding — unpadded base64
      // is what makes base64Decode throw on otherwise valid photos.
      final clean = rawBase64.replaceAll(RegExp(r'\s+'), '');
      if (clean.length < 16) return null;
      return MemoryImage(base64Decode(base64.normalize(clean)));
    } catch (_) {
      return null;
    }
  }

  /// Renders a value that is already in hand (no uid lookup).
  static Widget render(
    dynamic raw, {
    BoxFit fit = BoxFit.cover,
    Widget? fallback,
    int? cacheWidth,
  }) {
    final image = provider(raw);
    if (image == null) {
      return fallback ??
          const Icon(Icons.person, color: Colors.black26, size: 35);
    }
    return Image(
      image: cacheWidth == null
          ? image
          : ResizeImage(image, width: cacheWidth, allowUpscaling: false),
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) =>
          fallback ??
          const Icon(Icons.person, color: Colors.black26, size: 35),
    );
  }
}

/// A round profile photo that resolves itself.
///
/// Give it whatever image string you already have; if that turns out to be
/// empty or junk, it looks the photo up once for that uid and caches it, so
/// scrolling a long list never refetches.
class UserAvatar extends StatefulWidget {
  final String uid;
  final String? imageData;
  final String name;
  final double size;
  final Color? borderColor;
  final double borderWidth;
  final Color background;

  const UserAvatar({
    super.key,
    required this.uid,
    required this.name,
    this.imageData,
    this.size = 48,
    this.borderColor,
    this.borderWidth = 0,
    this.background = const Color(0xFFEDEFF3),
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  String _image = '';
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid ||
        oldWidget.imageData != widget.imageData) {
      _load();
    }
  }

  void _load() {
    final direct = UserImage.clean(widget.imageData);
    if (direct.length > 8) {
      UserImage.remember(widget.uid, direct);
      _image = direct;
      _resolving = false;
      return;
    }

    final hit = UserImage.cached(widget.uid);
    if (hit != null) {
      _image = hit;
      _resolving = false;
      return;
    }

    _image = '';
    _resolving = true;
    UserImage.resolve(widget.uid).then((value) {
      if (!mounted) return;
      setState(() {
        _image = value;
        _resolving = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.background,
        border: widget.borderColor == null
            ? null
            : Border.all(color: widget.borderColor!, width: widget.borderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: UserImage.render(
        _image,
        cacheWidth: (widget.size * 3).round(),
        fallback: _resolving
            ? const SizedBox.shrink()
            : _Initial(name: widget.name, size: widget.size),
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  final String name;
  final double size;
  const _Initial({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return Icon(Icons.person, color: Colors.black26, size: size * 0.55);
    }
    return Center(
      child: Text(
        trimmed.characters.first.toUpperCase(),
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.bold,
          color: Colors.black38,
        ),
      ),
    );
  }
}
