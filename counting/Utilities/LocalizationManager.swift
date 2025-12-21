
import SwiftUI
import Combine

enum AppLanguage: String, CaseIterable, Identifiable {
    case korean = "ko"
    case english = "en"
    case japanese = "ja"
    case spanish = "es"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .korean: return "한국어"
        case .english: return "English"
        case .japanese: return "日本語"
        case .spanish: return "Español"
        }
    }
}

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "selectedLanguage")
            // 워치 앱으로 언어 설정 동기화
            ConnectivityProvider.shared.sendLanguage(language.rawValue)
        }
    }
    
    init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage"),
           let appLanguage = AppLanguage(rawValue: savedLanguage) {
            self.language = appLanguage
        } else {
            self.language = .korean
        }
        
        ConnectivityProvider.shared.onReceiveLanguage = { [weak self] langCode in
            self?.setLanguage(from: langCode)
        }
    }
    
    func localized(_ key: String) -> String {
        guard let dict = translations[key], let value = dict[language] else {
            return key // 번역 없으면 키 그대로 반환
        }
        return value
    }
    
    // 외부(ConnectivityProvider)에서 언어를 변경할 수 있도록 메서드 추가
    func setLanguage(from rawValue: String) {
        if let newLang = AppLanguage(rawValue: rawValue) {
             // UI 업데이트를 위해 메인 스레드 보장
             DispatchQueue.main.async { [weak self] in
                 self?.language = newLang
             }
        }
    }
    
    // 번역 데이터 딕셔너리
    private let translations: [String: [AppLanguage: String]] = [
        // 공통
        "confirm": [.korean: "확인", .english: "OK", .japanese: "確認", .spanish: "Confirmar"],
        "cancel": [.korean: "취소", .english: "Cancel", .japanese: "キャンセル", .spanish: "Cancelar"],
        "delete": [.korean: "삭제", .english: "Delete", .japanese: "削除", .spanish: "Eliminar"],
        "edit": [.korean: "편집", .english: "Edit", .japanese: "編集", .spanish: "Editar"],
        "save": [.korean: "저장", .english: "Save", .japanese: "保存", .spanish: "Guardar"],
        "share": [.korean: "공유하기", .english: "Share", .japanese: "共有", .spanish: "Compartir"],
        
        // 메인/홈
        "my_counters": [.korean: "나의 카운터", .english: "My Counters", .japanese: "マイカウンター", .spanish: "Mis Contadores"],
        "add_category": [.korean: "카테고리 추가", .english: "Add Category", .japanese: "カテゴリー追加", .spanish: "Añadir Categoría"],
        "no_categories": [.korean: "카테고리가 없습니다.\n새로운 카테고리를 추가해주세요.", .english: "No categories.\nPlease add a new category.", .japanese: "カテゴリーがありません。\n新しいカテゴリーを追加してください。", .spanish: "No hay categorías.\nAñade una nueva categoría."],
        
        // 설정 메인
        "settings": [.korean: "설정", .english: "Settings", .japanese: "設定", .spanish: "Ajustes"],
        "language": [.korean: "언어", .english: "Language", .japanese: "言語", .spanish: "Idioma"],
        "feedback": [.korean: "피드백", .english: "Feedback", .japanese: "フィードバック", .spanish: "Comentarios"],
        "review_app": [.korean: "앱 리뷰 남기기", .english: "Review App", .japanese: "レビューを書く", .spanish: "Reseñar App"],
        "contact_us": [.korean: "문의하기", .english: "Contact Us", .japanese: "お問い合わせ", .spanish: "Contáctanos"],
        "security": [.korean: "보안", .english: "Security", .japanese: "セキュリティ", .spanish: "Seguridad"],
        "data_management": [.korean: "데이터 관리", .english: "Data Management", .japanese: "データ管理", .spanish: "Gestión de Datos"],
        
        // 잠금/보안
        "enable_lock": [.korean: "잠금 활성화", .english: "App Lock", .japanese: "アプリロック", .spanish: "Bloqueo de App"],
        "lock_description": [.korean: "앱 잠금을 활성화하면 앱을 실행하거나 백그라운드에서 불러올 때 암호 또는 생체 인증이 필요합니다.", .english: "Enabling App Lock requires a PIN or biometric authentication to access the app.", .japanese: "アプリロックを有効にすると、アプリへのアクセスにPINまたは生体認証が必要になります。", .spanish: "Activar el bloqueo requiere PIN o autenticación biométrica para acceder."],
        "use_face_id": [.korean: "Face ID 사용", .english: "Use Face ID", .japanese: "Face IDを使用", .spanish: "Usar Face ID"],
        "change_pin": [.korean: "암호 변경", .english: "Change PIN", .japanese: "PIN変更", .spanish: "Cambiar PIN"],
        "biometry_error": [.korean: "생체 인증 오류", .english: "Biometric Error", .japanese: "生体認証エラー", .spanish: "Error Biométrico"],
        
        // PIN 관련
        "enter_pin_4": [.korean: "암호 4자리를 입력하세요", .english: "Enter 4-digit PIN", .japanese: "4桁のPINを入力", .spanish: "Introduce PIN de 4 dígitos"],
        "enter_pin_again": [.korean: "암호를 다시 한 번 입력하세요", .english: "Re-enter PIN", .japanese: "もう一度入力してください", .spanish: "Introduce el PIN de nuevo"],
        "pin_mismatch": [.korean: "비밀번호가 일치하지 않습니다", .english: "PINs do not match", .japanese: "パスワードが一致しません", .spanish: "Los PIN no coinciden"],
        "pin_save_error": [.korean: "암호 저장에 실패했습니다. 다시 시도해주세요.", .english: "Failed to save PIN. Please try again.", .japanese: "PINの保存に失敗しました。再試行してください。", .spanish: "Error al guardar PIN. Inténtalo de nuevo."],
        "enter_password": [.korean: "암호를 입력하세요", .english: "Enter Password", .japanese: "パスワードを入力", .spanish: "Introduce la contraseña"],
        "password_mismatch": [.korean: "암호가 일치하지 않습니다", .english: "Incorrect Password", .japanese: "パスワードが違います", .spanish: "Contraseña incorrecta"],
        "unlock_reason": [.korean: "잠금을 해제하기 위해 인증해주세요.", .english: "Authenticate to unlock.", .japanese: "ロック解除のために認証してください。", .spanish: "Autentícate para desbloquear."],
     
        // 데이터/사용성
        "haptic_feedback": [.korean: "햅틱 피드백", .english: "Haptic Feedback", .japanese: "触覚フィードバック", .spanish: "Respuesta Háptica"],
        "sound_effects": [.korean: "사운드 효과", .english: "Sound Effects", .japanese: "効果音", .spanish: "Efectos de Sonido"],
        "reset_data": [.korean: "데이터 초기화", .english: "Reset Data", .japanese: "データ初期化", .spanish: "Restablecer Datos"],
        "reset_warning": [.korean: "모든 카테고리와 카운터가 삭제됩니다. 이 작업은 되돌릴 수 없습니다.", .english: "All categories and counters will be deleted. This cannot be undone.", .japanese: "すべてのカテゴリーとカウンターが削除されます。元に戻すことはできません。", .spanish: "Se eliminarán todas las categorías y contadores. No se puede deshacer."],
        
        //Watch App
        "no_counters": [.korean: "카운터가 없습니다", .english: "No Counters", .japanese: "カウンターがありません", .spanish: "Sin contadores"],
        "no_registered_counters": [.korean: "등록된 카운터가 없습니다.", .english: "No registered counters.", .japanese: "登録されたカウンターがありません。", .spanish: "No hay contadores registrados."],
        "watch_add_on_iphone": [.korean: "아이폰 앱에서\n카테고리를 추가해주세요.", .english: "Please add categories\non the iPhone app.", .japanese: "iPhoneアプリで\nカテゴリーを追加してください。", .spanish: "Añade categorías\nen la app de iPhone."],
        "watch_check_iphone": [.korean: "아이폰 앱에서 추가해주세요.", .english: "Check iPhone app.", .japanese: "iPhoneアプリを確認。", .spanish: "Revisar app iPhone."],
        "tap_to_count": [.korean: "탭하여 카운팅", .english: "Tap to count", .japanese: "タップしてカウント", .spanish: "Toca para contar"],
        "reset_counter_msg": [.korean: "정말 0으로 초기화하시겠습니까?", .english: "Reset count to 0?", .japanese: "0にリセットしますか？", .spanish: "¿Restablecer a 0?"],

        // 추가된 로컬라이제이션 키
        // AddCategoryView
        "category_name": [.korean: "카테고리 이름", .english: "Category Name", .japanese: "カテゴリー名", .spanish: "Nombre de la categoría"],
        "category_placeholder": [.korean: "예: 하루 커피 잔 수", .english: "Ex: Daily Coffee Cups", .japanese: "例: 1日のコーヒー", .spanish: "Ej: Tazas de café"],
        "allow_negative": [.korean: "음수 허용", .english: "Allow Negative", .japanese: "負の数を許可", .spanish: "Permitir negativos"],
        "allow_decimals": [.korean: "소수점 사용", .english: "Allow Decimals", .japanese: "小数点を使用", .spanish: "Usar decimales"],
        "choose_color": [.korean: "색상 선택", .english: "Choose Color", .japanese: "色を選択", .spanish: "Elegir color"],
        "choose_icon": [.korean: "아이콘 선택", .english: "Choose Icon", .japanese: "アイコンを選択", .spanish: "Elegir icono"],
        "edit_category_title": [.korean: "카테고리 수정", .english: "Edit Category", .japanese: "カテゴリー編集", .spanish: "Editar categoría"],
        "new_category": [.korean: "새 카테고리", .english: "New Category", .japanese: "新しいカテゴリー", .spanish: "Nueva categoría"],
        "create": [.korean: "만들기", .english: "Create", .japanese: "作成", .spanish: "Crear"],
        "update": [.korean: "수정하기", .english: "Update", .japanese: "更新", .spanish: "Actualizar"],
        
        // AddCounterView
        "counter_name": [.korean: "이름", .english: "Name", .japanese: "名前", .spanish: "Nombre"],
        "counter_placeholder": [.korean: "예: 턱걸이, 물 한 잔", .english: "Ex: Pull-ups, Water", .japanese: "例: 懸垂, 水一杯", .spanish: "Ej: Dominadas, Agua"],
        "initial_value": [.korean: "초기 시작 값 (선택)", .english: "Initial Value (Optional)", .japanese: "初期値 (オプション)", .spanish: "Valor inicial (Opcional)"],
        "add_counter": [.korean: "새 카운터 추가", .english: "Add New Counter", .japanese: "新しいカウンターを追加", .spanish: "Añadir nuevo contador"],
        "add_action": [.korean: "추가하기", .english: "Add", .japanese: "追加", .spanish: "Añadir"],
        
        // CategoryDetailView
        "quick_count_mode": [.korean: "리스트에서 바로 카운팅", .english: "Quick Count Mode", .japanese: "クイックカウントモード", .spanish: "Modo de conteo rápido"],
        "category_not_found": [.korean: "카테고리를 찾을 수 없습니다.", .english: "Category not found.", .japanese: "カテゴリーが見つかりません。", .spanish: "Categoría no encontrada."],
        "go_back": [.korean: "돌아가기", .english: "Go Back", .japanese: "戻る", .spanish: "Regresar"],
        "tap_to_view_detail": [.korean: "터치하여 상세 보기", .english: "Tap to view details", .japanese: "タップして詳細を表示", .spanish: "Toca para ver detalles"],
        "qr_share": [.korean: "QR 공유", .english: "QR Share", .japanese: "QR共有", .spanish: "Compartir QR"],
        "qr_generation_failed": [.korean: "QR 코드를 생성할 수 없습니다.", .english: "Failed to generate QR code.", .japanese: "QRコードを生成できません。", .spanish: "Error al generar código QR."],
        "qr_scan_instruction": [.korean: "이 QR 코드를 스캔하여 카테고리를 공유하세요.", .english: "Scan this QR code to share the category.", .japanese: "このQRコードをスキャンしてカテゴリーを共有してください。", .spanish: "Escanea este código QR para compartir la categoría."],
        "close": [.korean: "닫기", .english: "Close", .japanese: "閉じる", .spanish: "Cerrar"],
        
        // CounterView
        "screen_always_on": [.korean: "화면 꺼짐 방지 설정", .english: "Screen Always On Enabled", .japanese: "常時表示を有効にしました", .spanish: "Pantalla siempre encendida activada"],
        "screen_always_off": [.korean: "화면 꺼짐 방지 해제", .english: "Screen Always On Disabled", .japanese: "常時表示を無効にしました", .spanish: "Pantalla siempre encendida desactivada"],
        "reset_counter_title": [.korean: "카운터 초기화", .english: "Reset Counter", .japanese: "カウンターをリセット", .spanish: "Restablecer contador"],
        "reset_counter_message": [.korean: "정말로 이 카운터를 0으로 초기화하시겠습니까?", .english: "Reset this counter to 0?", .japanese: "このカウンターを0にリセットしますか？", .spanish: "¿Restablecer este contador a 0?"],
        "reset_action": [.korean: "초기화", .english: "Reset", .japanese: "リセット", .spanish: "Restablecer"],
        "rename_title": [.korean: "이름 수정", .english: "Rename", .japanese: "名前を変更", .spanish: "Renombrar"],
        "counter_name_label": [.korean: "카운터 이름", .english: "Counter Name", .japanese: "カウンター名", .spanish: "Nombre del contador"],
        "tap_to_count_en": [.korean: "탭하여 카운팅", .english: "TAP TO COUNT", .japanese: "タップしてカウント", .spanish: "TOCA PARA CONTAR"],
        
        // HomeView
        "home_greeting_subtitle": [.korean: "오늘도 목표를 달성하세요", .english: "Achieve your goals today", .japanese: "今日も目標を達成しましょう", .spanish: "Logra tus objetivos hoy"],
        "home_tab": [.korean: "홈", .english: "Home", .japanese: "ホーム", .spanish: "Inicio"],
        "category_options": [.korean: "카테고리 옵션", .english: "Category Options", .japanese: "カテゴリーオプション", .spanish: "Opciones de categoría"],
        "delete_category": [.korean: "카테고리 삭제", .english: "Delete Category", .japanese: "カテゴリー削除", .spanish: "Eliminar categoría"],
        "selected_category": [.korean: "선택된 카테고리", .english: "Selected Category", .japanese: "選択されたカテゴリー", .spanish: "Categoría seleccionada"],
        "delete_category_confirmation": [.korean: "정말 삭제하시겠습니까?", .english: "Are you sure you want to delete?", .japanese: "本当に削除しますか？", .spanish: "¿Seguro que quieres eliminar?"],
        "irreversible_action": [.korean: "이 동작은 되돌릴 수 없습니다.", .english: "This action cannot be undone.", .japanese: "この操作は取り消せません。", .spanish: "Esta acción no se puede deshacer."],
        "items_count_suffix": [.korean: "개 항목", .english: " Items", .japanese: "個の項目", .spanish: " ítems"],
        
        // Bulk Delete
        "delete_selected_title": [.korean: "선택한 항목 삭제", .english: "Delete Selected", .japanese: "選択項目を削除", .spanish: "Eliminar seleccionados"],
        "delete_selected_message": [.korean: "선택한 %d개의 카테고리들을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.", .english: "Are you sure you want to delete the %d selected categories? This cannot be undone.", .japanese: "選択された%d個のカテゴリーを削除しますか？この操作は取り消せません。", .spanish: "¿Eliminar las %d categorías seleccionadas? No se puede deshacer."],
        
        // Sync
        "sync_confirmation_title": [.korean: "동기화 하시겠습니까?", .english: "Sync Data?", .japanese: "同期しますか？", .spanish: "¿Sincronizar datos?"],
        "sync_confirmation_message": [.korean: "아이폰의 데이터로 애플워치의 데이터가 덮어씌워집니다.", .english: "iPhone data will overwrite Apple Watch data.", .japanese: "iPhoneのデータでApple Watchのデータが上書きされます。", .spanish: "Los datos del iPhone sobrescribirán los del Apple Watch."],
        "sync_now": [.korean: "동기화", .english: "Sync Now", .japanese: "今すぐ同期", .spanish: "Sincronizar ahora"],
        "syncing_status": [.korean: "동기화 중...", .english: "Syncing...", .japanese: "同期中...", .spanish: "Sincronizando..."],
        
        // Error & Sync Messages (Shared with Watch)
        "error": [.korean: "오류", .english: "Error", .japanese: "エラー", .spanish: "Error"],
        "notice": [.korean: "알림", .english: "Notice", .japanese: "通知", .spanish: "Aviso"],
        "sync_error_message": [.korean: "동기화에 실패했습니다.\n기기가 연결되어 있는지 확인해주세요.", .english: "Sync failed.\nPlease check connection.", .japanese: "同期に失敗しました。\n接続を確認してください。", .spanish: "Error de sincronización.\nVerifique la conexión."],
        "watch_unreachable_alert": [.korean: "연결되어 있지 않습니다.\n요청이 대기열에 추가되었습니다.", .english: "Unreachable.\nRequest has been queued.", .japanese: "接続されていません。\nリクエストがキューに追加されました。", .spanish: "No disponible.\nSolicitud en cola."],
        "sync_success": [.korean: "동기화 성공", .english: "Sync Successful", .japanese: "同期成功", .spanish: "Sincronización exitosa"],
        "sync_queued": [.korean: "동기화 대기열 추가됨", .english: "Sync Queued", .japanese: "同期キュー追加", .spanish: "Sincronización en cola"],
        
        // Bluetooth Device List
        "bluetooth_devices": [.korean: "블루투스 기기", .english: "Bluetooth Devices", .japanese: "Bluetoothデバイス", .spanish: "Dispositivos Bluetooth"],
        "connected_devices": [.korean: "연결된 기기", .english: "Connected Devices", .japanese: "接続済みデバイス", .spanish: "Dispositivos conectados"],
        "available_devices": [.korean: "사용 가능한 기기", .english: "Available Devices", .japanese: "利用可能なデバイス", .spanish: "Dispositivos disponibles"],
        "no_devices_found": [.korean: "기기를 찾을 수 없습니다", .english: "No Devices Found", .japanese: "デバイスが見つかりません", .spanish: "No se encontraron dispositivos"],
        "tap_scan_button": [.korean: "스캔 버튼을 눌러 주변 기기를 검색하세요", .english: "Tap the scan button to search for nearby devices", .japanese: "スキャンボタンをタップして近くのデバイスを検索", .spanish: "Toca el botón de escaneo para buscar dispositivos cercanos"],
        "scanning": [.korean: "스캔 중", .english: "Scanning", .japanese: "スキャン中", .spanish: "Escaneando"],
        "connected": [.korean: "연결됨", .english: "Connected", .japanese: "接続済み", .spanish: "Conectado"],
        "connecting": [.korean: "연결 중...", .english: "Connecting...", .japanese: "接続中...", .spanish: "Conectando..."],
        "disconnected": [.korean: "연결 해제됨", .english: "Disconnected", .japanese: "切断済み", .spanish: "Desconectado"],
        "bluetooth_permission_required": [.korean: "블루투스 권한 필요", .english: "Bluetooth Permission Required", .japanese: "Bluetooth権限が必要", .spanish: "Permiso de Bluetooth requerido"],
        "enable_bluetooth_message": [.korean: "다른 기기와 연결하려면 설정에서 블루투스를 활성화해주세요.", .english: "Please enable Bluetooth in Settings to connect with other devices.", .japanese: "他のデバイスと接続するには、設定でBluetoothを有効にしてください.", .spanish: "Habilita Bluetooth en Ajustes para conectar con otros dispositivos."],
        "bluetooth_powered_off": [.korean: "블루투스가 꺼져있습니다", .english: "Bluetooth is Off", .japanese: "Bluetoothがオフです", .spanish: "El Bluetooth está apagado"],
        "bluetooth_permission_denied_message": [.korean: "앱 설정에서 블루투스 접근 권한을 허용해주세요.", .english: "Please allow Bluetooth access in App Settings.", .japanese: "アプリの設定でBluetoothアクセスを許可してください。", .spanish: "Permita el acceso a Bluetooth en la configuración, por favor."],
        "generating_qr_code": [.korean: "QR 코드 생성 중...", .english: "Generating QR Code...", .japanese: "QRコード生成中...", .spanish: "Generando código QR..."],
        "counter_count": [.korean: "카운터 개수:", .english: "Counter Count:", .japanese: "カウンター数:", .spanish: "Cantidad de contadores:"],
        "qr_scan_guide": [.korean: "QR 코드를 스캔하세요", .english: "Scan QR Code", .japanese: "QRコードをスキャン", .spanish: "Escanear código QR"],
        "qr_scan_description": [.korean: "다른 기기의 QR 코드를 카메라에 비춰주세요", .english: "Point your camera at the QR code from another device", .japanese: "他のデバイスのQRコードをカメラに向けてください", .spanish: "Apunta tu cámara al código QR de otro dispositivo"],
        "import_category_title": [.korean: "카테고리 가져오기", .english: "Import Category", .japanese: "カテゴリをインポート", .spanish: "Importar categoría"],
        "import_category_message": [.korean: "'%@' 카테고리를 가져오시겠습니까?", .english: "Import '%@' category?", .japanese: "'%@'カテゴリをインポートしますか？", .spanish: "¿Importar categoría '%@'?"],
        "import": [.korean: "가져오기", .english: "Import", .japanese: "インポート", .spanish: "Importar"],
        
        "sync_success_title": [.korean: "동기화 성공", .english: "Sync Successful", .japanese: "同期成功", .spanish: "Sincronización exitosa"],
        "sync_success_message": [.korean: "데이터가 전송되었습니다.", .english: "Data has been sent.", .japanese: "データが送信されました。", .spanish: "Se han enviado los datos."],
        "sync_failure_title": [.korean: "동기화 실패", .english: "Sync Failed", .japanese: "同期失敗", .spanish: "Error de sincronización"],
        "sync_failure_message": [.korean: "Apple Watch와 연결할 수 없습니다.", .english: "Cannot connect to Apple Watch.", .japanese: "Apple Watchに接続できません。", .spanish: "No se puede conectar al Apple Watch."],
        
        "sync": [.korean: "동기화", .english: "Sync", .japanese: "同期", .spanish: "Sincronizar"],

        "add": [.korean: "추가", .english: "Add", .japanese: "追加", .spanish: "Añadir"],
    ]
}

// 편의를 위한 String 확장
extension String {
    var localized: String {
        return LocalizationManager.shared.localized(self)
    }
}
