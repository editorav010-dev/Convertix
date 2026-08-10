import 'package:go_router/go_router.dart';
import '../features/home/home_screen.dart';
import '../features/image_converter/image_converter_screen.dart';
import '../features/video_to_audio/video_to_audio_screen.dart';
import '../features/audio_converter/audio_converter_screen.dart';
import '../features/video_converter/video_converter_screen.dart';
import '../features/video_compression/video_compression_screen.dart';
import '../features/image_to_pdf/image_to_pdf_screen.dart';
import '../features/document_convert/document_convert_screen.dart';
import '../features/greyscale_pdf/greyscale_pdf_screen.dart';
import '../features/merge_pdf/merge_pdf_screen.dart';
import '../features/split_pdf/split_pdf_screen.dart';
import '../features/settings/licenses_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/image-converter',
      name: 'image-converter',
      builder: (context, state) => const ImageConverterScreen(),
    ),
    GoRoute(
      path: '/video-to-audio',
      name: 'video-to-audio',
      builder: (context, state) => const VideoToAudioScreen(),
    ),
    GoRoute(
      path: '/audio-converter',
      name: 'audio-converter',
      builder: (context, state) => const AudioConverterScreen(),
    ),
    GoRoute(
      path: '/video-converter',
      name: 'video-converter',
      builder: (context, state) => const VideoConverterScreen(),
    ),
    GoRoute(
      path: '/video-compression',
      name: 'video-compression',
      builder: (context, state) => const VideoCompressionScreen(),
    ),
    GoRoute(
      path: '/image-to-pdf',
      name: 'image-to-pdf',
      builder: (context, state) => const ImageToPdfScreen(),
    ),
    GoRoute(
      path: '/document-convert',
      name: 'document-convert',
      builder: (context, state) => const DocumentConvertScreen(),
    ),
    GoRoute(
      path: '/greyscale-pdf',
      name: 'greyscale-pdf',
      builder: (context, state) => const GreyscalePdfScreen(),
    ),
    GoRoute(
      path: '/merge-pdf',
      name: 'merge-pdf',
      builder: (context, state) => const MergePdfScreen(),
    ),
    GoRoute(
      path: '/split-pdf',
      name: 'split-pdf',
      builder: (context, state) => const SplitPdfScreen(),
    ),
    GoRoute(
      path: '/licenses',
      name: 'licenses',
      builder: (context, state) => const LicensesScreen(),
    ),
  ],
);