// 전체 앱 테마모음

import 'package:wact/common/const/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final ThemeData appTheme = ThemeData(
  datePickerTheme: const DatePickerThemeData(),
  popupMenuTheme: const PopupMenuThemeData(color: bg_10),
  tabBarTheme: const TabBarTheme(
    unselectedLabelColor: Color.fromRGBO(0, 0, 0, 0),
    indicatorColor: Colors.transparent, // 밑줄 없애기
  ),
  appBarTheme: const AppBarTheme(
    surfaceTintColor: Colors.white,
    backgroundColor: Colors.white,
    systemOverlayStyle: SystemUiOverlayStyle(
      // 상태 표시줄 스타일 설정
      statusBarColor: Colors.white, // 상태 표시줄 배경색
      statusBarIconBrightness: Brightness.dark, // 아이콘 및 글씨 색상
    ),
  ),
  splashColor: Colors.transparent,
  highlightColor: Colors.white,
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    elevation: 0,
    shape: CircleBorder(), // FAB를 원형으로 만듦
    focusColor: primary,
    hoverColor: primary,
    foregroundColor: Colors.white,
    backgroundColor: bg_50,
  ),
  fontFamily: 'Pretendard',
);
