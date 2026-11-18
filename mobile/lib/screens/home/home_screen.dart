import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/room_service.dart';
import '../auth/login_screen.dart';
import '../room_analysis/room_analysis_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = '/home';

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _imagePicker = ImagePicker();
  final _roomService = RoomService();

  XFile? _selectedRoomImage;

  bool _isPickingImage = false;
  bool _isLoggingOut = false;
  bool _isUploadingRoom = false;
  bool _isStartingAnalysis = false;
  bool _isPollingRequestRunning = false;
  bool _hasOpenedAnalysisScreen = false;

  Map<String, dynamic>? _uploadedRoom;
  Map<String, dynamic>? _analysisResponse;

  Timer? _analysisPollingTimer;

  String? _analysisRoomId;
  String? _analysisStatus;
  String? _analysisError;

  static const Duration _pollingInterval =
  Duration(seconds: 5);

  @override
  void dispose() {
    _stopAnalysisPolling();
    super.dispose();
  }

  Future<void> _pickRoomImage(
      ImageSource source,
      ) async {
    if (_isPickingImage ||
        _isUploadingRoom ||
        _isStartingAnalysis ||
        _analysisStatus == 'analyzing') {
      return;
    }

    setState(() {
      _isPickingImage = true;
    });

    try {
      final image =
      await _imagePicker.pickImage(
        source: source,
        imageQuality: 92,
        maxWidth: 2400,
      );

      if (!mounted || image == null) {
        return;
      }

      _stopAnalysisPolling();

      setState(() {
        _selectedRoomImage = image;
        _uploadedRoom = null;
        _analysisResponse = null;
        _analysisRoomId = null;
        _analysisStatus = null;
        _analysisError = null;
        _hasOpenedAnalysisScreen = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open the camera or gallery. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  void _removeSelectedImage() {
    if (_isUploadingRoom ||
        _isStartingAnalysis ||
        _analysisStatus == 'analyzing') {
      return;
    }

    _stopAnalysisPolling();

    setState(() {
      _selectedRoomImage = null;
      _uploadedRoom = null;
      _analysisResponse = null;
      _analysisRoomId = null;
      _analysisStatus = null;
      _analysisError = null;
      _hasOpenedAnalysisScreen = false;
    });
  }

  Future<void> _uploadSelectedRoom() async {
    final image = _selectedRoomImage;

    if (image == null ||
        _isUploadingRoom ||
        _isStartingAnalysis ||
        _analysisStatus == 'analyzing') {
      return;
    }

    setState(() {
      _isUploadingRoom = true;
      _analysisError = null;
      _hasOpenedAnalysisScreen = false;
    });

    try {
      final uploadResponse =
      await _roomService.uploadRoomImage(
        image.path,
      );

      if (!mounted) {
        return;
      }

      final roomData =
      uploadResponse['room'];

      if (roomData is! Map<String, dynamic>) {
        throw const ApiException(
          statusCode: 500,
          message:
          'Invalid room upload response.',
        );
      }

      final roomId =
      roomData['id']?.toString();

      if (roomId == null || roomId.isEmpty) {
        throw const ApiException(
          statusCode: 500,
          message:
          'Room ID was not returned by the server.',
        );
      }

      setState(() {
        _uploadedRoom = uploadResponse;
        _analysisRoomId = roomId;
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Room uploaded. Starting analysis...',
          ),
        ),
      );

      await _startRoomAnalysis(
        roomId,
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to upload the room. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingRoom = false;
        });
      }
    }
  }

  Future<void> _startRoomAnalysis(
      String roomId,
      ) async {
    if (_isStartingAnalysis) {
      return;
    }

    _stopAnalysisPolling();

    setState(() {
      _isStartingAnalysis = true;
      _analysisResponse = null;
      _analysisStatus = null;
      _analysisError = null;
      _hasOpenedAnalysisScreen = false;
    });

    try {
      final response =
      await _roomService.startAnalysis(
        roomId,
      );

      if (!mounted) {
        return;
      }

      final status =
      response['status']
          ?.toString()
          .toLowerCase();

      setState(() {
        _analysisStatus =
            status ?? 'analyzing';
      });

      if (_analysisStatus == 'analyzing') {
        _startAnalysisPolling(
          roomId,
        );
      } else {
        await _checkAnalysisStatus(
          roomId,
        );
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _analysisStatus = 'failed';
        _analysisError = error.message;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _analysisStatus = 'failed';
        _analysisError =
        'Unable to start room analysis.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to start room analysis. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isStartingAnalysis = false;
        });
      }
    }
  }

  void _startAnalysisPolling(
      String roomId,
      ) {
    _stopAnalysisPolling();

    _analysisPollingTimer =
        Timer.periodic(
          _pollingInterval,
              (_) {
            _checkAnalysisStatus(
              roomId,
            );
          },
        );
  }

  void _stopAnalysisPolling() {
    _analysisPollingTimer?.cancel();
    _analysisPollingTimer = null;
  }

  Future<void> _checkAnalysisStatus(
      String roomId,
      ) async {
    if (_isPollingRequestRunning ||
        !mounted) {
      return;
    }

    _isPollingRequestRunning = true;

    try {
      final response =
      await _roomService.getAnalysis(
        roomId,
      );

      if (!mounted) {
        return;
      }

      final status =
      response['status']
          ?.toString()
          .toLowerCase();

      setState(() {
        _analysisStatus = status;
        _analysisResponse = response;
        _analysisError =
            response['analysisError']
                ?.toString();
      });

      if (status == 'analyzed') {
        _stopAnalysisPolling();

        await _openAnalysisScreen(
          response,
        );
      } else if (status == 'failed') {
        _stopAnalysisPolling();

        final message =
        _analysisError == null ||
            _analysisError!
                .trim()
                .isEmpty
            ? 'Room analysis failed. Please try again.'
            : _analysisError!;

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
            ),
          ),
        );
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      if (error.statusCode == 401) {
        _stopAnalysisPolling();

        setState(() {
          _analysisStatus = 'failed';
          _analysisError = error.message;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.message,
            ),
          ),
        );
      }
    } catch (_) {
      // Temporary network errors are ignored.
      // The next polling cycle will try again.
    } finally {
      _isPollingRequestRunning = false;
    }
  }

  Future<void> _openAnalysisScreen(
      Map<String, dynamic> response,
      ) async {
    if (_hasOpenedAnalysisScreen ||
        !mounted) {
      return;
    }

    final rawAnalysis =
    response['analysis'];

    if (rawAnalysis is! Map) {
      return;
    }

    final analysis =
    rawAnalysis.map(
          (key, value) => MapEntry(
        key.toString(),
        value,
      ),
    );

    _hasOpenedAnalysisScreen = true;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            RoomAnalysisScreen(
              analysis: analysis,
              roomId: _analysisRoomId ??
                  response['roomId']?.toString() ??
                  '',
              imagePath:
              _selectedRoomImage?.path,
            ),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _viewCompletedAnalysis() async {
    final response =
        _analysisResponse;

    if (response == null) {
      return;
    }

    _hasOpenedAnalysisScreen = false;

    await _openAnalysisScreen(
      response,
    );
  }

  Future<void> _retryAnalysis() async {
    final roomId =
        _analysisRoomId;

    if (roomId == null ||
        roomId.isEmpty) {
      return;
    }

    await _startRoomAnalysis(
      roomId,
    );
  }

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }

    _stopAnalysisPolling();

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _authService.logout();
    } catch (_) {
      // Local tokens are still cleared
      // by AuthService.
    }

    if (!mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      LoginScreen.routeName,
          (route) => false,
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final analysisRunning =
        _analysisStatus == 'analyzing';

    return Scaffold(
      backgroundColor:
      AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.fromLTRB(
            22,
            18,
            22,
            30,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(
                height: 34,
              ),

              const Text(
                'Design your room\nwith confidence.',
                style: TextStyle(
                  color:
                  AppColors.forestDark,
                  fontSize: 32,
                  height: 1.08,
                  fontWeight:
                  FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              const Text(
                'Start with a clear photo of your room. RoomStylo will use it as the foundation for your new design.',
                style: TextStyle(
                  color:
                  AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.55,
                ),
              ),

              const SizedBox(
                height: 28,
              ),

              if (_selectedRoomImage == null)
                _buildEmptyRoomCard()
              else
                _buildSelectedRoomCard(),

              const SizedBox(
                height: 20,
              ),

              Row(
                children: [
                  Expanded(
                    child: _SourceButton(
                      icon:
                      Icons.photo_camera_outlined,
                      label:
                      'Take Photo',
                      onPressed:
                      _isPickingImage ||
                          analysisRunning ||
                          _isUploadingRoom ||
                          _isStartingAnalysis
                          ? null
                          : () => _pickRoomImage(
                        ImageSource.camera,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: _SourceButton(
                      icon:
                      Icons.photo_library_outlined,
                      label:
                      'Gallery',
                      onPressed:
                      _isPickingImage ||
                          analysisRunning ||
                          _isUploadingRoom ||
                          _isStartingAnalysis
                          ? null
                          : () => _pickRoomImage(
                        ImageSource.gallery,
                      ),
                    ),
                  ),
                ],
              ),

              if (_isPickingImage) ...[
                const SizedBox(
                  height: 18,
                ),
                const Center(
                  child:
                  CircularProgressIndicator(
                    color:
                    AppColors.forest,
                  ),
                ),
              ],

              if (_selectedRoomImage != null) ...[
                const SizedBox(
                  height: 22,
                ),

                SizedBox(
                  width:
                  double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed:
                    _isUploadingRoom ||
                        _isStartingAnalysis ||
                        analysisRunning ||
                        _uploadedRoom != null
                        ? null
                        : _uploadSelectedRoom,
                    icon:
                    _isUploadingRoom ||
                        _isStartingAnalysis ||
                        analysisRunning
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color:
                        AppColors.white,
                      ),
                    )
                        : Icon(
                      _uploadedRoom != null
                          ? Icons
                          .check_circle_rounded
                          : Icons
                          .cloud_upload_outlined,
                    ),
                    label: Text(
                      _uploadButtonText,
                    ),
                  ),
                ),
              ],

              if (_analysisStatus != null) ...[
                const SizedBox(
                  height: 20,
                ),
                _buildAnalysisCard(),
              ],

              const SizedBox(
                height: 28,
              ),

              _buildPhotoTips(),
            ],
          ),
        ),
      ),
    );
  }

  String get _uploadButtonText {
    if (_isUploadingRoom) {
      return 'Uploading room...';
    }

    if (_isStartingAnalysis) {
      return 'Starting analysis...';
    }

    if (_analysisStatus == 'analyzing') {
      return 'Analyzing your room...';
    }

    if (_analysisStatus == 'analyzed') {
      return 'Room analyzed';
    }

    if (_analysisStatus == 'failed') {
      return 'Analysis needs attention';
    }

    if (_uploadedRoom != null) {
      return 'Room uploaded';
    }

    return 'Continue with this room';
  }

  Widget _buildAnalysisCard() {
    final status =
        _analysisStatus;

    if (status == 'analyzing') {
      return Container(
        width:
        double.infinity,
        padding:
        const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color:
          AppColors.surfaceSoft,
          borderRadius:
          BorderRadius.circular(18),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child:
              CircularProgressIndicator(
                strokeWidth: 2.4,
                color:
                AppColors.forest,
              ),
            ),
            SizedBox(
              width: 14,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analyzing your room',
                    style: TextStyle(
                      color:
                      AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  Text(
                    'RoomStylo is identifying the room layout, furniture, colours, lighting and usable areas.',
                    style: TextStyle(
                      color:
                      AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'failed') {
      return Container(
        width:
        double.infinity,
        padding:
        const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color:
          AppColors.surfaceSoft,
          borderRadius:
          BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color:
                  AppColors.goldDark,
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Text(
                    'Room analysis could not be completed',
                    style: TextStyle(
                      color:
                      AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            if (_analysisError != null &&
                _analysisError!
                    .trim()
                    .isNotEmpty) ...[
              const SizedBox(
                height: 10,
              ),
              Text(
                _analysisError!,
                style:
                const TextStyle(
                  color:
                  AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],

            const SizedBox(
              height: 14,
            ),

            OutlinedButton.icon(
              onPressed:
              _isStartingAnalysis
                  ? null
                  : _retryAnalysis,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label:
              const Text(
                'Retry analysis',
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'analyzed') {
      final analysis =
      _analysisResponse?['analysis'];

      String roomType =
          'Room';

      if (analysis is Map) {
        final value =
        analysis['roomType']
            ?.toString()
            .trim();

        if (value != null &&
            value.isNotEmpty) {
          roomType = value;
        }
      }

      return InkWell(
        borderRadius:
        BorderRadius.circular(18),
        onTap:
        _viewCompletedAnalysis,
        child: Container(
          width:
          double.infinity,
          padding:
          const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color:
            AppColors.surfaceSoft,
            borderRadius:
            BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color:
                AppColors.forest,
                size: 25,
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Room analysis complete',
                      style: TextStyle(
                        color:
                        AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      'Detected room type: $roomType',
                      style:
                      const TextStyle(
                        color:
                        AppColors.textSecondary,
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(
                      height: 7,
                    ),

                    const Text(
                      'Tap to view full analysis',
                      style: TextStyle(
                        color:
                        AppColors.forest,
                        fontSize: 13,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color:
                AppColors.forest,
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Image.asset(
            'assets/branding/roomstylo_logo.png',
            height: 52,
            alignment:
            Alignment.centerLeft,
            fit: BoxFit.contain,
          ),
        ),

        IconButton(
          tooltip: 'Logout',
          onPressed:
          _isLoggingOut
              ? null
              : _logout,
          icon:
          _isLoggingOut
              ? const SizedBox(
            width: 22,
            height: 22,
            child:
            CircularProgressIndicator(
              strokeWidth: 2.2,
              color:
              AppColors.forest,
            ),
          )
              : const Icon(
            Icons.logout_rounded,
            color:
            AppColors.forestDark,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyRoomCard() {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 42,
      ),
      decoration: BoxDecoration(
        color:
        AppColors.surface,
        borderRadius:
        BorderRadius.circular(24),
        border: Border.all(
          color:
          AppColors.divider,
        ),
      ),
      child: const Column(
        children: [
          _RoomIcon(),
          SizedBox(
            height: 20,
          ),
          Text(
            'Add a room photo',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              color:
              AppColors.textPrimary,
              fontSize: 20,
              fontWeight:
              FontWeight.w700,
            ),
          ),
          SizedBox(
            height: 8,
          ),
          Text(
            'Take a new photo or choose an existing room photo from your gallery.',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              color:
              AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedRoomCard() {
    return ClipRRect(
      borderRadius:
      BorderRadius.circular(24),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio:
            4 / 3,
            child: Image.file(
              File(
                _selectedRoomImage!.path,
              ),
              width:
              double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color:
              AppColors.surface,
              shape:
              const CircleBorder(),
              child: IconButton(
                onPressed:
                _isUploadingRoom ||
                    _isStartingAnalysis ||
                    _analysisStatus ==
                        'analyzing'
                    ? null
                    : _removeSelectedImage,
                icon:
                const Icon(
                  Icons.close_rounded,
                  color:
                  AppColors.forestDark,
                ),
              ),
            ),
          ),

          Positioned(
            left: 14,
            bottom: 14,
            child: Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color:
                AppColors.forestDark
                    .withValues(
                  alpha: 0.88,
                ),
                borderRadius:
                BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 17,
                    color:
                    AppColors.white,
                  ),
                  SizedBox(
                    width: 7,
                  ),
                  Text(
                    'Room photo selected',
                    style: TextStyle(
                      color:
                      AppColors.white,
                      fontSize: 13,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoTips() {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
        AppColors.surfaceSoft,
        borderRadius:
        BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color:
            AppColors.goldDark,
            size: 22,
          ),
          SizedBox(
            width: 12,
          ),
          Expanded(
            child: Text(
              'For best results, capture the room in good light and keep the walls, floor and main furniture clearly visible.',
              style: TextStyle(
                color:
                AppColors.textSecondary,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomIcon extends StatelessWidget {
  const _RoomIcon();

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      width: 76,
      height: 76,
      decoration:
      const BoxDecoration(
        shape: BoxShape.circle,
        gradient:
        AppColors.primaryGradient,
      ),
      child: const Icon(
        Icons.chair_alt_outlined,
        color:
        AppColors.white,
        size: 34,
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(
      BuildContext context,
      ) {
    return SizedBox(
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 21,
        ),
        label: Text(
          label,
        ),
      ),
    );
  }
}