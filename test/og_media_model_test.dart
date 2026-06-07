import 'package:flutter_test/flutter_test.dart';
import 'package:opengraph/opengraph.dart';

void main() {
  group('OgImage', () {
    test('toJson/fromJson roundtrip keeps every field', () {
      const image = OgImage(
        url: 'https://example.com/a.png',
        secureUrl: 'https://secure.example.com/a.png',
        type: 'image/png',
        width: 1200,
        height: 630,
        alt: 'An image',
      );

      final restored = OgImage.fromJson(image.toJson());

      expect(restored.url, image.url);
      expect(restored.secureUrl, image.secureUrl);
      expect(restored.type, image.type);
      expect(restored.width, image.width);
      expect(restored.height, image.height);
      expect(restored.alt, image.alt);
    });

    test('toJson omits null fields', () {
      const image = OgImage(url: 'https://example.com/a.png');

      expect(image.toJson(), {'url': 'https://example.com/a.png'});
    });

    test('copyWith replaces the url and keeps the rest', () {
      const image = OgImage(url: '/a.png', width: 10, alt: 'alt');

      final resolved = image.copyWith(
          url: 'https://example.com/a.png',
          secureUrl: 'https://secure.example.com/a.png');

      expect(resolved.url, 'https://example.com/a.png');
      expect(resolved.secureUrl, 'https://secure.example.com/a.png');
      expect(resolved.width, 10);
      expect(resolved.alt, 'alt');
    });

    test('copyWith without arguments keeps every value', () {
      const image = OgImage(url: 'u', secureUrl: 's');
      const video = OgVideo(url: 'u', secureUrl: 's');
      const audio = OgAudio(url: 'u', secureUrl: 's');

      expect(image.copyWith().url, 'u');
      expect(image.copyWith().secureUrl, 's');
      expect(video.copyWith().url, 'u');
      expect(video.copyWith().secureUrl, 's');
      expect(audio.copyWith().url, 'u');
      expect(audio.copyWith().secureUrl, 's');
    });

    test('copyWith on video and audio behaves the same', () {
      const video = OgVideo(url: '/v.mp4', type: 'video/mp4', width: 1);
      const audio = OgAudio(url: '/a.mp3', type: 'audio/mpeg');

      final resolvedVideo = video.copyWith(url: 'https://e.com/v.mp4');
      final resolvedAudio = audio.copyWith(url: 'https://e.com/a.mp3');

      expect(resolvedVideo.url, 'https://e.com/v.mp4');
      expect(resolvedVideo.type, 'video/mp4');
      expect(resolvedVideo.width, 1);
      expect(resolvedAudio.url, 'https://e.com/a.mp3');
      expect(resolvedAudio.type, 'audio/mpeg');
    });
  });

  group('OgVideo and OgAudio', () {
    test('roundtrip via json', () {
      const video = OgVideo(
          url: 'https://example.com/v.mp4',
          type: 'video/mp4',
          width: 1280,
          height: 720);
      const audio =
          OgAudio(url: 'https://example.com/a.mp3', type: 'audio/mpeg');

      final restoredVideo = OgVideo.fromJson(video.toJson());
      final restoredAudio = OgAudio.fromJson(audio.toJson());

      expect(restoredVideo.url, video.url);
      expect(restoredVideo.width, 1280);
      expect(restoredVideo.height, 720);
      expect(restoredAudio.url, audio.url);
      expect(restoredAudio.type, 'audio/mpeg');
    });

    test('toString includes the type name', () {
      expect(const OgVideo(url: 'u').toString(), startsWith('OgVideo('));
      expect(const OgAudio(url: 'u').toString(), startsWith('OgAudio('));
      expect(const OgImage(url: 'u').toString(), startsWith('OgImage('));
    });
  });

  group('OpenGraphEntity rich fields', () {
    test('json roundtrip keeps lists, tags and favicon', () {
      final entity = OpenGraphEntity(
        title: 'T',
        description: 'D',
        locale: 'en_US',
        type: 'article',
        url: 'https://example.com',
        siteName: 'Example',
        image: 'https://example.com/a.png',
        images: const [
          OgImage(url: 'https://example.com/a.png', width: 100, height: 50),
          OgImage(url: 'https://example.com/b.png'),
        ],
        videos: const [OgVideo(url: 'https://example.com/v.mp4')],
        audios: const [OgAudio(url: 'https://example.com/a.mp3')],
        structuredTags: const {
          'article:tag': ['flutter', 'opengraph'],
          'article:author': ['https://example.com/author'],
        },
        faviconUrl: 'https://example.com/favicon.ico',
      );

      final restored = OpenGraphEntity.fromJson(entity.toJson());

      expect(restored.images.length, 2);
      expect(restored.images.first.width, 100);
      expect(restored.videos.single.url, 'https://example.com/v.mp4');
      expect(restored.audios.single.url, 'https://example.com/a.mp3');
      expect(restored.structuredTags['article:tag'], ['flutter', 'opengraph']);
      expect(restored.faviconUrl, 'https://example.com/favicon.ico');
    });

    test('fromJson without the new keys yields empty defaults', () {
      final entity = OpenGraphEntity.fromJson({
        'title': 'T',
        'description': 'D',
        'locale': 'en_US',
        'type': 'website',
        'url': 'https://example.com',
        'siteName': '',
        'image': '',
      });

      expect(entity.images, isEmpty);
      expect(entity.videos, isEmpty);
      expect(entity.audios, isEmpty);
      expect(entity.structuredTags, isEmpty);
      expect(entity.faviconUrl, isNull);
    });
  });
}
