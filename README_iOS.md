# 📱 Counting App for iOS

**Counting**은 일상 속의 모든 숫자를 기록하고 관리할 수 있는 프리미엄 카운팅 앱입니다. 세련된 Glassmorphism 디자인과 직관적인 사용자 경험을 제공하며, Apple Watch와 완벽하게 연동됩니다.

## ✨ 주요 특징 (Key Features)

### 1. 🎨 심미적인 디자인 (Premium Aesthetics)
- **Glassmorphism UI**: 최신 트렌드인 글래스모피즘을 적용하여 투명하고 깊이감 있는 인터페이스를 제공합니다.
- **Dynamic Animations**: 부드러운 전환 효과와 미세한 인터랙션 애니메이션으로 생동감 넘치는 사용자 경험을 선사합니다.
- **Custom Color Palettes**: 각 카테고리별로 세련된 파스텔 톤 및 네온 컬러를 지정할 수 있어 시각적인 즐거움을 줍니다.

### 2. 📂 강력한 카테고리 관리
- **유연한 그룹화**: '운동', '습관', '업무' 등 다양한 주제로 카운터들을 그룹화하여 관리할 수 있습니다.
- **상세 옵션**:
    - **음수 허용 (Allow Negative)**: 0 미만의 숫자 기록 가능.
    - **소수점 허용 (Allow Decimals)**: 0.5단위 등 정밀한 측정 가능.
- **직관적인 제스처**: 
    - 카드를 길게 눌러(Long Press) 즉시 삭제 모드로 진입할 수 있습니다.
    - 삭제 시 드라마틱한 축소 애니메이션을 제공합니다.

### 3. 🔢 스마트 카운터 (Smart Counters)
- **손쉬운 조작**: 탭, 스와이프 등 간단한 동작으로 숫자를 증가시키거나 감소시킬 수 있습니다.
- **정밀한 기록**: 각 카운터의 현재 상태를 한눈에 파악할 수 있는 대형 숫자를 제공합니다.

### 4. 🔄 완벽한 동기화 (Seamless Sync)
- **Apple Watch 연동**: 별도의 설정 없이 아이폰과 애플워치 간 데이터가 실시간으로 양방향 동기화됩니다.
- **마스터 데이터 관리**: 아이폰이 메인 데이터 허브 역할을 하여 데이터 유실을 방지하고 안정성을 보장합니다.
- **동기화 상태 표시**: 데이터 전송 시 'Syncing...' 인디케이터를 통해 현재 상태를 시각적으로 보여줍니다.

### 5. 🌍 다국어 지원 (Localization)
- 한국어, 영어를 포함한 다국어 지원을 통해 전 세계 사용자들이 편리하게 이용할 수 있습니다.
- 시스템 언어 설정에 따라 앱 내 언어가 자동으로 변경됩니다.

---

## 🛠 기술 스택 (Tech Stack)
- **Language**: Swift 5.9+
- **Framework**: SwiftUI (iOS 17+)
- **Architecture**: MVVM with Observation Framework
- **Data Persistence**: UserDefaults (Optimized for JSON)
- **Connectivity**: WatchConnectivity (WCSession)

---

## 📁 프로젝트 구조 (Project Structure)

Swift 권장 방식에 따라 **기능별 + 레이어별 혼합 구조**로 구성되어 있습니다:

```
counting/
├── App/                        # 앱 엔트리 포인트
│   └── countingApp.swift
│
├── Models/                     # 데이터 모델
│   └── Models.swift           # TallyCounter, TallyCategory, TallyStore
│
├── Views/                      # UI 레이어
│   ├── Home/                  # 메인 홈 화면
│   │   ├── HomeView.swift
│   │   └── ContentView.swift
│   ├── Category/              # 카테고리 관련 화면
│   │   ├── AddCategoryView.swift
│   │   └── CategoryDetailView.swift
│   ├── Counter/               # 카운터 관련 화면
│   │   ├── AddCounterView.swift
│   │   └── CounterView.swift
│   ├── Settings/              # 설정 화면
│   │   └── SettingsView.swift
│   ├── Lock/                  # 보안 관련 화면
│   │   ├── LockView.swift
│   │   └── PinSetupView.swift
│   └── Components/            # 재사용 가능한 UI 컴포넌트
│       └── UIComponents.swift
│
├── Services/                   # 비즈니스 로직 및 외부 서비스
│   ├── ConnectivityProvider.swift  # Watch 연동
│   └── KeychainHelper.swift        # 보안 저장소
│
├── Utilities/                  # 유틸리티 및 헬퍼
│   ├── LocalizationManager.swift   # 다국어 지원
│   └── Theme.swift                 # 테마/스타일 정의
│
└── Resources/                  # 리소스 파일
    └── Assets.xcassets        # 이미지, 색상 등
```

### 구조의 이점
- ✅ **명확한 책임 분리**: 각 폴더가 명확한 역할 수행
- ✅ **확장성**: 새 기능 추가 시 적절한 위치가 명확
- ✅ **유지보수 용이**: 관련 파일이 그룹화되어 검색 용이
- ✅ **Apple 권장 패턴**: WWDC 세션 및 샘플 코드와 일치

---

## 🚀 시작하기 (Getting Started)

1. 앱을 실행하면 '내 카운터(My Counters)' 홈 화면이 나타납니다.
2. 하단의 **'+' 버튼**을 눌러 새로운 카테고리를 생성하세요.
3. 운동, 독서 등 원하는 주제를 입력하고 테마 색상을 선택합니다.
4. 생성된 카테고리 내부로 들어가 개별 카운터(예: 스쿼트, 물 한 잔)를 추가하세요.
5. 이제 카드를 탭하여 숫자를 세기 시작하면 됩니다!
