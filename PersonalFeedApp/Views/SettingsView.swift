import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    // 从本地读取现有配置，若没有则使用默认配置
    @State private var cfg: TranslationConfig = (try? LocalStorage.shared.loadTranslationConfig()) ?? .defaultConfig

    var body: some View {
        Form {
            // =========================
            // 你原有的其它设置（黑/白名单等）
            // =========================
            // Section(header: Text("黑白名单")) { ... }

            // =========================
            // 翻译设置
            // =========================
            Section(header: Text("翻译")) {
                Picker("提供商", selection: bindingProvider()) {
                    Text("系统翻译（Safari）").tag("systemWeb")
                    Text("LibreTranslate").tag("libre")
                    Text("DeepL").tag("deepl")
                    Text("Google").tag("google")
                    Text("Microsoft").tag("microsoft")
                }
                .pickerStyle(.menu)

                providerDetailFields()

                TextField("目标语言（ISO 代码，例：zh / en / ja）", text: $cfg.targetLang)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section {
                Button("保存") {
                    TranslationService.shared.updateConfig(cfg)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 子视图：根据不同提供商展示不同输入项
    @ViewBuilder
    private func providerDetailFields() -> some View {
        switch cfg.provider {
        case .systemWeb:
            Text("使用 Safari 打开翻译网页，无需密钥。")
                .font(.footnote)
                .foregroundStyle(.secondary)

        case .libreTranslate(let base, let key):
            TextField("Base URL", text: Binding(
                get: { base },
                set: { setLibre(baseURL: $0, apiKey: key) }
            ))
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            TextField("API Key（可空）", text: Binding(
                get: { key ?? "" },
                set: { setLibre(baseURL: base, apiKey: $0.isEmpty ? nil : $0) }
            ))
            .textContentType(.oneTimeCode)
            .autocorrectionDisabled()

        case .deepl(let key):
            SecureField("DeepL API Key", text: Binding(
                get: { key },
                set: { cfg.provider = .deepl(apiKey: $0) }
            ))

        case .google(let key):
            SecureField("Google API Key", text: Binding(
                get: { key },
                set: { cfg.provider = .google(apiKey: $0) }
            ))

        case .microsoft(let key, let region):
            SecureField("Microsoft API Key", text: Binding(
                get: { key },
                set: { cfg.provider = .microsoft(apiKey: $0, region: region) }
            ))
            TextField("Region（例如 eastasia）", text: Binding(
                get: { region },
                set: { cfg.provider = .microsoft(apiKey: key, region: $0) }
            ))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        }
    }

    // MARK: - Provider 选择绑定
    private func bindingProvider() -> Binding<String> {
        Binding<String>(
            get: {
                switch cfg.provider {
                case .systemWeb:                 return "systemWeb"
                case .libreTranslate:            return "libre"
                case .deepl:                     return "deepl"
                case .google:                    return "google"
                case .microsoft:                 return "microsoft"
                }
            },
            set: { tag in
                switch tag {
                case "systemWeb":
                    cfg.provider = .systemWeb
                case "libre":
                    cfg.provider = .libreTranslate(baseURL: "https://libretranslate.com", apiKey: nil)
                case "deepl":
                    cfg.provider = .deepl(apiKey: "")
                case "google":
                    cfg.provider = .google(apiKey: "")
                case "microsoft":
                    cfg.provider = .microsoft(apiKey: "", region: "")
                default:
                    break
                }
            }
        )
    }

    // MARK: - 辅助：设置 LibreTranslate 的字段
    private func setLibre(baseURL: String, apiKey: String?) {
        cfg.provider = .libreTranslate(baseURL: baseURL, apiKey: apiKey)
    }
}
