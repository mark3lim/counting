
import SwiftUI
import Combine

enum AppLanguage: String, CaseIterable, Identifiable {
    case korean = "ko"
    case english = "en"
    case japanese = "ja"
    case spanish = "es"
    
    var id: String { self.rawValue }
}

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "selectedLanguage")
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
            DispatchQueue.main.async { [weak self] in
                self?.language = newLang
            }
        }
    }
    
    // 번역 데이터 딕셔너리 (iOS와 동일)
    private let translations: [String: [AppLanguage: String]] = [
        // 공통
        "confirm": [.korean: "확인", .english: "OK", .japanese: "確認", .spanish: "Confirmar"],
        "cancel": [.korean: "취소", .english: "Cancel", .japanese: "キャンセル", .spanish: "Cancelar"],
        "delete": [.korean: "삭제", .english: "Delete", .japanese: "削除", .spanish: "Eliminar"],
        "edit": [.korean: "편집", .english: "Edit", .japanese: "編集", .spanish: "Editar"],
        "save": [.korean: "저장", .english: "Save", .japanese: "保存", .spanish: "Guardar"],
        
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
        "watch_add_on_iphone": [.korean: "아이폰 앱에서\n카테고리를 추가해주세요.", .english: "Please add categories\non the iPhone app.", .japanese: "iPhoneアプリで\nカテゴリーを追加してください。", .spanish: "Añade categorías\nen la app de iPhone."],
        "watch_check_iphone": [.korean: "아이폰 앱에서 추가해주세요.", .english: "Check iPhone app.", .japanese: "iPhoneアプリを確認。", .spanish: "Revisar app iPhone."],
        "tap_to_count": [.korean: "탭하여 카운팅", .english: "Tap to count", .japanese: "タップしてカウント", .spanish: "Toca para contar"],
        "reset_counter_msg": [.korean: "정말 0으로 초기화하시겠습니까?", .english: "Reset count to 0?", .japanese: "0にリセットしますか？", .spanish: "¿Restablecer a 0?"],
        
        // Missing Keys
        "no_counters": [.korean: "등록된 카운터가 없습니다.", .english: "No counters.", .japanese: "カウンターがありません。", .spanish: "Sin contadores."],
        "sync_now": [.korean: "동기화", .english: "Sync Now", .japanese: "今すぐ同期", .spanish: "Sincronizar ahora"],
        
        // Error & Sync Messages
        "error": [.korean: "오류", .english: "Error", .japanese: "エラー", .spanish: "Error"],
        "notice": [.korean: "알림", .english: "Notice", .japanese: "通知", .spanish: "Aviso"],
        "sync_error_message": [.korean: "동기화에 실패했습니다.\niPhone이 연결되어 있지 않습니다.", .english: "Sync failed.\niPhone is not reachable.", .japanese: "同期に失敗しました。\niPhoneに接続されていません。", .spanish: "Error de sincronización.\niPhone no disponible."],
        "watch_unreachable_alert": [.korean: "iPhone이 연결되어 있지 않습니다.\n요청이 대기열에 추가되었습니다.", .english: "iPhone is unreachable.\nRequest has been queued.", .japanese: "iPhoneに接続されていません。\nリクエストがキューに追加されました。", .spanish: "iPhone no disponible.\nSolicitud en cola."],
    ]
}

extension String {
    var localized: String {
        return LocalizationManager.shared.localized(self)
    }
}
