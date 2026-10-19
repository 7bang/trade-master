# 폰거래장 온 — 브랜드 & 디자인 가이드

> 버전 1.0 · 2026-10-15
> 이 문서는 앱·웹 개발과 디자인 작업에서 그대로 참조할 수 있도록 정리한 단일 기준 문서입니다.

---

## 1. 브랜드 핵심

| 항목 | 내용 |
|---|---|
| 서비스명 | **폰거래장 온** (구 거래클립) |
| 한 줄 정의 | 종이 거래장을 폰에 담아 찍고, 저장하고, 공유하는 거래장 앱 |
| 미션 | 장사하는 손은 바쁘게, 장부는 온전하게 |
| 태그라인 | 종이 거래장 그대로, 폰 안에 온전히 |
| 타깃 | 40대 이상 시장 상인 및 도매업체 사장님 |
| 성격 | 믿음직한 동네 경리 실장님 — 꼼꼼하고 차분하며 잘난 척하지 않음 |
| 포지셔닝 | 복잡한 회계 앱이 아닌, 원래 쓰던 거래장 그대로 |

**'온'의 세 가지 의미**
- **On(켜짐)**: 폰만 켜면 언제든 장부가 열려 있다
- **온전함**: 빠짐없이, 틀림없이 기록된다
- **溫(따뜻함)**: 사람과 사람 사이의 거래를 존중한다

---

## 2. 로고

### 2.1 심볼 「찍는 온」

한글 '온'을 **도장 + 장부**로 설계한 심볼.

| 요소 | 형태 | 의미 |
|---|---|---|
| ㅇ | 인주색 고리 | 도장의 인주 면, 켜진 불빛(On) |
| ㅗ | 짧은 목 + 두꺼운 도장 바닥 | 도장 몸체 |
| ㄴ | 장부 모서리(왼쪽 여백선 + 맨 아래 줄) | 장부 한 장 |
| 인주 자국 | 장부 줄 위 인주색 블록 | 거래가 확정됨 |

**구성 규칙**
- 기준 그리드 120 × 120, 획 두께 14 단위
- 도장 바닥과 장부 사이 틈은 12 단위 이상 유지
- 모서리는 직각 (라운드 없음)
- 색은 최대 2색 (인주 + 먹), 단색으로도 성립

### 2.2 심볼 SVG 소스

**기본 심볼** (32px 초과)
```svg
<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" aria-label="폰거래장 온">
  <circle cx="60" cy="24" r="15" fill="none" stroke="#C4321E" stroke-width="14"/>
  <path d="M52 46 H68 V54 H100 V80 H20 V54 H52 Z" fill="#1F2A36"/>
  <path d="M20 92 H34 V104 H100 V118 H20 Z" fill="#1F2A36"/>
  <rect x="44" y="104" width="32" height="14" fill="#C4321E"/>
</svg>
```

**마이크로 심볼** (32px 이하: 파비콘, 알림 아이콘)
```svg
<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" aria-label="폰거래장 온">
  <circle cx="60" cy="30" r="18" fill="none" stroke="#C4321E" stroke-width="17"/>
  <path d="M51 56 H69 V64 H104 V92 H16 V64 H51 Z" fill="#1F2A36"/>
  <rect x="38" y="102" width="44" height="14" fill="#C4321E"/>
</svg>
```

> 어두운 배경: 고리·자국 `#EF6A4A`, 몸체 `#F6F2EA`
> 인주 배경: 심볼 전체 `#F6F2EA`
> 모노: 심볼 전체 `#1F2A36` (또는 반전 시 `#F6F2EA`)

### 2.3 로고 버전

| 버전 | 구성 | 사용처 | 최소 크기 |
|---|---|---|---|
| 메인 | 심볼 + 워드마크 + 태그라인 | 웹 첫 화면, 앱스토어 소개 이미지, 제안서 표지 | 폭 480px / 인쇄 60mm |
| 가로형 (기본) | 심볼 + 워드마크 한 줄 | 웹 헤더, 앱 상단, 명함, 영수증, 간판 | 폭 120px / 인쇄 25mm |
| 세로형 | 심볼 위, 워드마크 아래 | 스티커, 쇼핑백, 앞치마, SNS 게시물 | 폭 96px / 인쇄 20mm |
| 앱 아이콘 | 흰 배경 + 기본 심볼 | 앱 아이콘(기본), 홈 화면 추가 | 48px |
| 소셜 프로필 | 인주 원형 배경 + 한지색 심볼 | 인스타그램, 카카오 채널 | — |
| 파비콘 | 마이크로 심볼 | 브라우저 탭 16·32·48px | 16px |
| 모노크롬 | 먹 단색 / 반전 / 인주 단색 | 팩스, 흑백 인쇄, 고무 도장 | 인쇄 20mm |

**크기별 자동 전환**
- 폭 240px 이상 → 가로형
- 폭 120–240px → 마이크로 심볼 + 워드마크
- 폭 120px 미만 → 심볼 단독

### 2.4 워드마크

- 표기: `폰거래장 온` (띄어쓰기 필수, 간격 = 글자 크기 × 0.34)
- 현재 서체: Gothic A1 ExtraBold(800) — **임시**. 최종은 심볼 획 두께·직각 모서리에 맞춘 전용 레터링 권장
- 장기 방향: '온'을 브랜드의 얼굴로 키우고, '폰거래장'은 검색용 설명어 역할

### 2.5 사용 규칙

- 여백: 로고 주변에 ㅇ 고리 지름만큼 비운다
- 금지: 비율 변형, 그림자, 그라데이션, 외곽선 추가, 서체 교체, 회전
- 사진 위: 흰색 또는 한지색 바탕을 깔고 올린다
- 자수·실크인쇄·고무 도장: 심볼 높이 20mm 이상, 미만이면 마이크로 심볼

---

## 3. 브랜드 컬러

### 3.1 핵심 팔레트

| 역할 | 이름 | HEX | RGB | 의미 |
|---|---|---|---|---|
| 메인 | 먹남 | `#1F2A36` | 31, 42, 54 | 신뢰, 기록의 무게감 |
| 서브 | 한지 | `#F6F2EA` | 246, 242, 234 | 익숙함, 종이 장부의 온기 |
| 포인트 | 인주 | `#C4321E` | 196, 50, 30 | 확정, 따뜻함, 켜짐 |

### 3.2 확장 팔레트

| 이름 | HEX | 용도 |
|---|---|---|
| 짙은 인주 | `#A82A18` | 버튼 눌림, 작은 강조 글자 |
| 밝은 인주 | `#EF6A4A` | 어두운 배경 전용 포인트 |
| 장부 먹회색 | `#5A6370` | 보조 글자, 날짜, 설명 |
| 장부선 | `#E2DCCF` | 구분선, 테두리 |
| 밤 | `#151C24` | 어두운 배경, 야간 간판 |
| 흰색 | `#FFFFFF` | 카드, 앱 아이콘 배경 |

### 3.3 비율

**한지 60 : 먹남 30 : 인주 10**
인주색은 행동과 확정의 순간(저장 버튼, 확정 표시, 심볼)에만 쓴다. 적게 쓸수록 신호가 강해진다.

### 3.4 인쇄용 (참고값)

| 이름 | HEX | CMYK (근사) |
|---|---|---|
| 먹남 | `#1F2A36` | C80 M65 Y45 K55 |
| 한지 | `#F6F2EA` | C3 M4 Y8 K0 |
| 인주 | `#C4321E` | C10 M90 Y95 K5 |

> CMYK는 근사값입니다. 인쇄 전 인쇄소에서 인주색 샘플을 반드시 확인하세요.

### 3.5 환경별 적용

| 환경 | 배경 | 글자·몸체 | 포인트 |
|---|---|---|---|
| 밝은 배경 (기본) | `#F6F2EA` / `#FFFFFF` | `#1F2A36` | `#C4321E` |
| 어두운 배경 | `#151C24` | `#F6F2EA` | `#EF6A4A` |
| 인주 배경 | `#C4321E` | `#F6F2EA` | — |
| 모노톤 | 흰색 | `#1F2A36` 단색 | — |

---

## 4. 앱 디자인 색상 시스템

### 4.1 라이트 모드

| 토큰 | HEX | 용도 | 대비 |
|---|---|---|---|
| `primary` | `#C4321E` | 주요 버튼, 선택 상태 | 흰 글자 5.5:1 |
| `primary-pressed` | `#A82A18` | 눌림, 작은 강조 글자 | 흰 글자 7.0:1 |
| `on-primary` | `#FFFFFF` | primary 위 글자 | — |
| `bg` | `#F6F2EA` | 화면 배경 | — |
| `surface` | `#FFFFFF` | 카드, 입력창, 시트 | — |
| `text` | `#1F2A36` | 본문, 금액 | bg 대비 13.0:1 |
| `text-sub` | `#5A6370` | 날짜, 설명 | bg 대비 5.5:1 |
| `border` | `#E2DCCF` | 구분선, 테두리 | — |
| `success` | `#2E7D4F` | 입금완료 | 흰 배경 5.1:1 |
| `warning` | `#9A6212` | 미수, 확인 필요 | 흰 배경 5.1:1 |
| `info` | `#2F5D8A` | 공유됨, 안내 | 흰 배경 6.9:1 |
| `danger` | `#C4321E` | 삭제 등 파괴적 동작 (아이콘·문구 필수) | — |

### 4.2 다크 모드

| 토큰 | HEX | 용도 |
|---|---|---|
| `primary` | `#EF6A4A` | 주요 버튼 |
| `primary-pressed` | `#D9542F` | 눌림 |
| `on-primary` | `#151C24` | primary 위 글자 (5.6:1) |
| `bg` | `#151C24` | 화면 배경 |
| `surface` | `#1F2A36` | 카드 |
| `text` | `#F6F2EA` | 본문 (15.4:1) |
| `text-sub` | `#9AA3AE` | 보조 글자 (6.7:1) |
| `border` | `#2A3542` | 구분선 |
| `success` | `#5FB383` | 입금완료 |
| `warning` | `#E0A33E` | 미수 |
| `info` | `#7FA9D6` | 공유됨 |

### 4.3 상태 표시 원칙

- **미수는 빨강이 아닌 `warning`(황토색)** — 인주색이 브랜드 색이라 빨강을 오류로 쓰면 헷갈린다
- 상태는 색만으로 구분하지 않는다: `✓ 입금완료`, `! 미수`처럼 **기호 + 글자**를 함께 쓴다
- 상태 배지는 배경 채움보다 **테두리 + 글자색** 방식 (시장 야외 햇빛에서 더 선명)

### 4.4 타이포그래피 & 레이아웃

| 항목 | 값 |
|---|---|
| 서체 | Pretendard 또는 Gothic A1 (fallback: Apple SD Gothic Neo, Malgun Gothic) |
| 본문 최소 | **17px** (40대 이상 노안 고려) |
| 금액 | 20–32px, ExtraBold, `font-variant-numeric: tabular-nums` |
| 보조 글자 | 15–16px |
| 버튼 높이 | 최소 56px (터치 영역 48px 이상) |
| 모서리 | 카드 14px, 버튼 14px, 배지 8px |
| 간격 단위 | 4의 배수 (8 · 12 · 16 · 20 · 24) |
| 그림자 | 쓰지 않음 — 테두리(`border`)로 구분 |

---

## 5. 코드 토큰

### 5.1 CSS 변수

```css
:root {
  /* brand */
  --on-ink: #1F2A36;
  --on-paper: #F6F2EA;
  --on-vermilion: #C4321E;
  --on-vermilion-deep: #A82A18;
  --on-vermilion-light: #EF6A4A;
  --on-gray: #5A6370;
  --on-line: #E2DCCF;
  --on-night: #151C24;

  /* app (light) */
  --color-primary: #C4321E;
  --color-primary-pressed: #A82A18;
  --color-on-primary: #FFFFFF;
  --color-bg: #F6F2EA;
  --color-surface: #FFFFFF;
  --color-text: #1F2A36;
  --color-text-sub: #5A6370;
  --color-border: #E2DCCF;
  --color-success: #2E7D4F;
  --color-warning: #9A6212;
  --color-info: #2F5D8A;
  --color-danger: #C4321E;

  --radius-card: 14px;
  --radius-badge: 8px;
  --font-base: 17px;
}

@media (prefers-color-scheme: dark) {
  :root {
    --color-primary: #EF6A4A;
    --color-primary-pressed: #D9542F;
    --color-on-primary: #151C24;
    --color-bg: #151C24;
    --color-surface: #1F2A36;
    --color-text: #F6F2EA;
    --color-text-sub: #9AA3AE;
    --color-border: #2A3542;
    --color-success: #5FB383;
    --color-warning: #E0A33E;
    --color-info: #7FA9D6;
    --color-danger: #EF6A4A;
  }
}
```

### 5.2 Flutter (`lib/theme/on_colors.dart`)

```dart
import 'package:flutter/material.dart';

class OnColors {
  // brand
  static const ink = Color(0xFF1F2A36);
  static const paper = Color(0xFFF6F2EA);
  static const vermilion = Color(0xFFC4321E);
  static const vermilionDeep = Color(0xFFA82A18);
  static const vermilionLight = Color(0xFFEF6A4A);
  static const gray = Color(0xFF5A6370);
  static const line = Color(0xFFE2DCCF);
  static const night = Color(0xFF151C24);

  // status (light)
  static const success = Color(0xFF2E7D4F);
  static const warning = Color(0xFF9A6212);
  static const info = Color(0xFF2F5D8A);

  // status (dark)
  static const successDark = Color(0xFF5FB383);
  static const warningDark = Color(0xFFE0A33E);
  static const infoDark = Color(0xFF7FA9D6);
  static const textSubDark = Color(0xFF9AA3AE);
  static const borderDark = Color(0xFF2A3542);
}

class OnTheme {
  static ThemeData light() => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: OnColors.paper,
        colorScheme: const ColorScheme.light(
          primary: OnColors.vermilion,
          onPrimary: Colors.white,
          secondary: OnColors.ink,
          onSecondary: OnColors.paper,
          surface: Colors.white,
          onSurface: OnColors.ink,
          onSurfaceVariant: OnColors.gray,
          outline: OnColors.line,
          error: OnColors.vermilion,
          onError: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 17, color: OnColors.ink),
          bodyMedium: TextStyle(fontSize: 16, color: OnColors.gray),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: OnColors.vermilion,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
            textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: OnColors.line),
          ),
        ),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: OnColors.night,
        colorScheme: const ColorScheme.dark(
          primary: OnColors.vermilionLight,
          onPrimary: OnColors.night,
          secondary: OnColors.paper,
          onSecondary: OnColors.night,
          surface: OnColors.ink,
          onSurface: OnColors.paper,
          onSurfaceVariant: OnColors.textSubDark,
          outline: OnColors.borderDark,
          error: OnColors.vermilionLight,
          onError: OnColors.night,
        ),
      );
}
```

### 5.3 Tailwind (`tailwind.config.js`)

```js
module.exports = {
  theme: {
    extend: {
      colors: {
        ink: '#1F2A36',
        paper: '#F6F2EA',
        vermilion: { DEFAULT: '#C4321E', deep: '#A82A18', light: '#EF6A4A' },
        ledger: { gray: '#5A6370', line: '#E2DCCF' },
        night: '#151C24',
        status: { success: '#2E7D4F', warning: '#9A6212', info: '#2F5D8A' },
      },
      borderRadius: { card: '14px', badge: '8px' },
      fontSize: { base: '17px' },
    },
  },
};
```

### 5.4 JSON 토큰 (`tokens.json`)

```json
{
  "brand": {
    "ink": "#1F2A36",
    "paper": "#F6F2EA",
    "vermilion": "#C4321E",
    "vermilionDeep": "#A82A18",
    "vermilionLight": "#EF6A4A",
    "gray": "#5A6370",
    "line": "#E2DCCF",
    "night": "#151C24"
  },
  "light": {
    "primary": "#C4321E", "primaryPressed": "#A82A18", "onPrimary": "#FFFFFF",
    "bg": "#F6F2EA", "surface": "#FFFFFF", "text": "#1F2A36", "textSub": "#5A6370",
    "border": "#E2DCCF", "success": "#2E7D4F", "warning": "#9A6212", "info": "#2F5D8A"
  },
  "dark": {
    "primary": "#EF6A4A", "primaryPressed": "#D9542F", "onPrimary": "#151C24",
    "bg": "#151C24", "surface": "#1F2A36", "text": "#F6F2EA", "textSub": "#9AA3AE",
    "border": "#2A3542", "success": "#5FB383", "warning": "#E0A33E", "info": "#7FA9D6"
  }
}
```

---

## 6. 체크리스트 (출시 전)

- [ ] 시장 사장님 대상 심볼 5초 테스트 ("뭐로 보이세요?")
- [ ] 폰 홈 화면에서 당근마켓 등 주황 계열 아이콘과 나란히 비교
- [ ] KIPRIS 상표 검색 ('폰거래장 온', 심볼 도형)
- [ ] 워드마크 전용 레터링 제작 또는 상업용 서체 라이선스 확인
- [ ] 인쇄소 인주색 샘플 확인
- [ ] 앱 아이콘 iOS 1024px / Android 512px 원본 제작
