import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../design_suggestions/design_suggestions_screen.dart';

class RoomAnalysisScreen extends StatelessWidget {
  const RoomAnalysisScreen({
    super.key,
    required this.analysis,
    required this.roomId,
    this.imagePath,
  });

  final Map<String, dynamic> analysis;
  final String roomId;
  final String? imagePath;

  String _stringValue(
      String key, {
        String fallback = 'Not detected',
      }) {
    final value =
    analysis[key]?.toString().trim();

    if (value == null ||
        value.isEmpty) {
      return fallback;
    }

    return value;
  }

  List<String> _stringList(
      String key,
      ) {
    final value =
    analysis[key];

    if (value is! List) {
      return const [];
    }

    return value
        .map(
          (item) =>
          item.toString().trim(),
    )
        .where(
          (item) =>
      item.isNotEmpty,
    )
        .toList();
  }

  String _titleCase(
      String value,
      ) {
    if (value.isEmpty) {
      return value;
    }

    return value
        .split(' ')
        .map(
          (word) {
        if (word.isEmpty) {
          return word;
        }

        return '${word[0].toUpperCase()}${word.substring(1)}';
      },
    )
        .join(' ');
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final roomType =
    _titleCase(
      _stringValue(
        'roomType',
        fallback: 'Room',
      ),
    );

    final walls =
    _stringList(
      'walls',
    );

    final windows =
    _stringList(
      'windows',
    );

    final doors =
    _stringList(
      'doors',
    );

    final furniture =
    _stringList(
      'furniture',
    );

    final colors =
    _stringList(
      'colors',
    );

    final lighting =
    _stringList(
      'lighting',
    );

    final usableAreas =
    _stringList(
      'usableAreas',
    );

    final observations =
    _stringList(
      'observations',
    );

    final floor =
    _stringValue(
      'floor',
    );

    return Scaffold(
      backgroundColor:
      AppColors.background,
      appBar: AppBar(
        backgroundColor:
        AppColors.background,
        surfaceTintColor:
        Colors.transparent,
        elevation: 0,
        leading:
        IconButton(
          onPressed: () {
            Navigator.pop(
              context,
            );
          },
          icon:
          const Icon(
            Icons
                .arrow_back_rounded,
            color:
            AppColors
                .forestDark,
          ),
        ),
        title:
        const Text(
          'Room Analysis',
          style:
          TextStyle(
            color:
            AppColors
                .forestDark,
            fontSize: 19,
            fontWeight:
            FontWeight.w700,
          ),
        ),
      ),
      body:
      SafeArea(
        top: false,
        child:
        SingleChildScrollView(
          padding:
          const EdgeInsets
              .fromLTRB(
            20,
            8,
            20,
            36,
          ),
          child:
          Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              if (imagePath !=
                  null) ...[
                _RoomImage(
                  imagePath:
                  imagePath!,
                ),

                const SizedBox(
                  height: 22,
                ),
              ],

              Container(
                width:
                double.infinity,
                padding:
                const EdgeInsets
                    .all(
                  20,
                ),
                decoration:
                BoxDecoration(
                  gradient:
                  AppColors
                      .primaryGradient,
                  borderRadius:
                  BorderRadius
                      .circular(
                    22,
                  ),
                ),
                child:
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration:
                      BoxDecoration(
                        color:
                        AppColors
                            .white
                            .withValues(
                          alpha: 0.14,
                        ),
                        shape:
                        BoxShape
                            .circle,
                      ),
                      child:
                      const Icon(
                        Icons
                            .auto_awesome_rounded,
                        color:
                        AppColors
                            .white,
                        size: 27,
                      ),
                    ),

                    const SizedBox(
                      width: 15,
                    ),

                    Expanded(
                      child:
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          const Text(
                            'Detected Room',
                            style:
                            TextStyle(
                              color:
                              Color(
                                0xFFDDE9E3,
                              ),
                              fontSize:
                              13,
                              fontWeight:
                              FontWeight
                                  .w500,
                            ),
                          ),

                          const SizedBox(
                            height: 3,
                          ),

                          Text(
                            roomType,
                            style:
                            const TextStyle(
                              color:
                              AppColors
                                  .white,
                              fontSize:
                              24,
                              fontWeight:
                              FontWeight
                                  .w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons
                          .check_circle_rounded,
                      color:
                      AppColors
                          .goldLight,
                      size: 26,
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              const Text(
                'RoomStylo analyzed the visible layout, furniture, finishes and usable spaces in your photo.',
                style:
                TextStyle(
                  color:
                  AppColors
                      .textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(
                height: 26,
              ),

              _AnalysisSection(
                icon:
                Icons
                    .wallpaper_rounded,
                title:
                'Walls',
                items:
                walls,
              ),

              _AnalysisSection(
                icon:
                Icons
                    .layers_outlined,
                title:
                'Floor',
                items: [
                  floor,
                ],
              ),

              _AnalysisSection(
                icon:
                Icons
                    .chair_alt_outlined,
                title:
                'Furniture',
                items:
                furniture,
              ),

              _AnalysisSection(
                icon:
                Icons
                    .palette_outlined,
                title:
                'Colours',
                items:
                colors,
                useChips:
                true,
              ),

              _AnalysisSection(
                icon:
                Icons
                    .light_mode_outlined,
                title:
                'Lighting',
                items:
                lighting,
              ),

              _AnalysisSection(
                icon:
                Icons
                    .window_outlined,
                title:
                'Windows',
                items:
                windows,
              ),

              _AnalysisSection(
                icon:
                Icons
                    .door_front_door_outlined,
                title:
                'Doors',
                items:
                doors,
              ),

              _AnalysisSection(
                icon:
                Icons
                    .open_in_full_rounded,
                title:
                'Usable Areas',
                items:
                usableAreas,
              ),

              _AnalysisSection(
                icon:
                Icons
                    .visibility_outlined,
                title:
                'Observations',
                items:
                observations,
              ),

              const SizedBox(
                height: 8,
              ),

              Container(
                width:
                double.infinity,
                padding:
                const EdgeInsets
                    .all(
                  17,
                ),
                decoration:
                BoxDecoration(
                  color:
                  AppColors
                      .surfaceSoft,
                  borderRadius:
                  BorderRadius
                      .circular(
                    18,
                  ),
                ),
                child:
                const Row(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Icon(
                      Icons
                          .info_outline_rounded,
                      color:
                      AppColors
                          .goldDark,
                      size: 21,
                    ),

                    SizedBox(
                      width: 11,
                    ),

                    Expanded(
                      child:
                      Text(
                        'AI analysis is based on what is visible in the photo. Hidden areas or objects may not be detected.',
                        style:
                        TextStyle(
                          color:
                          AppColors
                              .textSecondary,
                          fontSize:
                          13,
                          height:
                          1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              SizedBox(
                width:
                double.infinity,
                height: 56,
                child:
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            DesignSuggestionsScreen(
                          roomId: roomId,
                          imagePath: imagePath,
                        ),
                      ),
                    );
                  },
                  icon:
                  const Icon(
                    Icons
                        .arrow_forward_rounded,
                  ),
                  label:
                  const Text(
                    'Continue to Design Suggestions',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomImage
    extends StatelessWidget {
  const _RoomImage({
    required this.imagePath,
  });

  final String imagePath;

  @override
  Widget build(
      BuildContext context,
      ) {
    return ClipRRect(
      borderRadius:
      BorderRadius.circular(
        22,
      ),
      child:
      AspectRatio(
        aspectRatio:
        16 / 10,
        child:
        Image.file(
          File(
            imagePath,
          ),
          fit:
          BoxFit.cover,
          errorBuilder: (
              context,
              error,
              stackTrace,
              ) {
            return Container(
              color:
              AppColors
                  .surfaceSoft,
              alignment:
              Alignment.center,
              child:
              const Icon(
                Icons
                    .image_not_supported_outlined,
                color:
                AppColors
                    .textLight,
                size: 44,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AnalysisSection
    extends StatelessWidget {
  const _AnalysisSection({
    required this.icon,
    required this.title,
    required this.items,
    this.useChips = false,
  });

  final IconData icon;
  final String title;
  final List<String> items;
  final bool useChips;

  @override
  Widget build(
      BuildContext context,
      ) {
    final cleanItems =
    items
        .map(
          (item) =>
          item.trim(),
    )
        .where(
          (item) =>
      item.isNotEmpty &&
          item !=
              'Not detected',
    )
        .toList();

    return Container(
      width:
      double.infinity,
      margin:
      const EdgeInsets
          .only(
        bottom: 14,
      ),
      padding:
      const EdgeInsets
          .all(
        18,
      ),
      decoration:
      BoxDecoration(
        color:
        AppColors.surface,
        borderRadius:
        BorderRadius
            .circular(
          20,
        ),
        border:
        Border.all(
          color:
          AppColors
              .divider,
        ),
      ),
      child:
      Column(
        crossAxisAlignment:
        CrossAxisAlignment
            .start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration:
                BoxDecoration(
                  color:
                  AppColors
                      .surfaceSoft,
                  borderRadius:
                  BorderRadius
                      .circular(
                    12,
                  ),
                ),
                child:
                Icon(
                  icon,
                  color:
                  AppColors
                      .forest,
                  size: 21,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Text(
                title,
                style:
                const TextStyle(
                  color:
                  AppColors
                      .textPrimary,
                  fontSize: 16,
                  fontWeight:
                  FontWeight
                      .w700,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 15,
          ),

          if (cleanItems.isEmpty)
            const Text(
              'Not detected',
              style:
              TextStyle(
                color:
                AppColors
                    .textLight,
                fontSize: 14,
              ),
            )
          else if (useChips)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
              cleanItems
                  .map(
                    (item) =>
                    Container(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal:
                        12,
                        vertical:
                        8,
                      ),
                      decoration:
                      BoxDecoration(
                        color:
                        AppColors
                            .surfaceSoft,
                        borderRadius:
                        BorderRadius
                            .circular(
                          30,
                        ),
                      ),
                      child:
                      Text(
                        item,
                        style:
                        const TextStyle(
                          color:
                          AppColors
                              .forestDark,
                          fontSize:
                          13,
                          fontWeight:
                          FontWeight
                              .w500,
                        ),
                      ),
                    ),
              )
                  .toList(),
            )
          else
            Column(
              children:
              cleanItems
                  .map(
                    (item) =>
                    Padding(
                      padding:
                      const EdgeInsets
                          .only(
                        bottom:
                        10,
                      ),
                      child:
                      Row(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          Container(
                            width:
                            6,
                            height:
                            6,
                            margin:
                            const EdgeInsets
                                .only(
                              top:
                              7,
                            ),
                            decoration:
                            const BoxDecoration(
                              color:
                              AppColors
                                  .gold,
                              shape:
                              BoxShape
                                  .circle,
                            ),
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          Expanded(
                            child:
                            Text(
                              item,
                              style:
                              const TextStyle(
                                color:
                                AppColors
                                    .textSecondary,
                                fontSize:
                                14,
                                height:
                                1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              )
                  .toList(),
            ),
        ],
      ),
    );
  }
}