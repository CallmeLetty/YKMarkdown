import SwiftUI

struct SettingsView: View {
    @AppStorage("editorFontSize") private var editorFontSize = 14.0
    @AppStorage("documentOpeningMode") private var documentOpeningMode = DocumentOpeningMode.tabs.rawValue
    @AppStorage(AppThemeColor.modeKey) private var themeColorMode = AppThemeColorMode.system.rawValue
    @AppStorage(AppThemeColor.customHexKey) private var themeColorHex = AppThemeColor.defaultCustomHex
    @AppStorage("blogOwner") private var blogOwner = BlogUploadSettings.default.owner
    @AppStorage("blogRepo") private var blogRepo = BlogUploadSettings.default.repo
    @AppStorage("blogBranch") private var blogBranch = BlogUploadSettings.default.branch
    @AppStorage("blogContentDirectory") private var blogContentDirectory = BlogUploadSettings.default.contentDirectory

    @State private var tokenDraft = ""
    @State private var tokenSavedMessage: String?

    var body: some View {
        Form {
            Section("Editor") {
                Slider(value: $editorFontSize, in: 11...22, step: 1) {
                    Text("Font Size")
                } minimumValueLabel: {
                    Text("11")
                } maximumValueLabel: {
                    Text("22")
                }
                Text("Current size: \(Int(editorFontSize)) pt")
                    .foregroundStyle(.secondary)
            }

            Section("外观") {
                Picker("主题色", selection: $themeColorMode) {
                    ForEach(AppThemeColorMode.allCases) { mode in
                        Text(mode.title)
                            .tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                if AppThemeColorMode.stored(rawValue: themeColorMode) == .custom {
                    ColorPicker("自定义颜色", selection: customThemeColor, supportsOpacity: false)
                }

                Text("用于工具栏控件、目录高亮和预览链接。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("文档") {
                Picker("打开方式", selection: $documentOpeningMode) {
                    ForEach(DocumentOpeningMode.allCases) { mode in
                        Text(mode.title)
                            .tag(mode.rawValue)
                    }
                }
                .pickerStyle(.inline)

                Text(DocumentOpeningMode.stored(rawValue: documentOpeningMode).note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Yakamoz Blog 上传") {
                TextField("Owner", text: $blogOwner)
                TextField("Repository", text: $blogRepo)
                TextField("Branch", text: $blogBranch)
                TextField("Content 目录", text: $blogContentDirectory)

                SecureField("GitHub Token (repo 权限)", text: $tokenDraft)
                HStack {
                    Button("保存 Token 到钥匙串") {
                        saveToken()
                    }
                    .disabled(tokenDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if KeychainStore.get(account: GitHubBlogUploader.tokenAccount) != nil {
                        Button("清除 Token", role: .destructive) {
                            KeychainStore.delete(account: GitHubBlogUploader.tokenAccount)
                            tokenDraft = ""
                            tokenSavedMessage = "已清除"
                        }
                    }
                }

                if let tokenSavedMessage {
                    Text(tokenSavedMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("默认上传到 CallmeLetty/Yakamoz-Blog 的 content/ 目录。Token 仅保存在本机钥匙串。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 420, minHeight: 420)
        .padding()
        .animation(.easeInOut(duration: 0.18), value: themeColorMode)
        .onAppear {
            if KeychainStore.get(account: GitHubBlogUploader.tokenAccount) != nil {
                tokenSavedMessage = "钥匙串中已有 Token"
            }
        }
    }

    private var customThemeColor: Binding<Color> {
        Binding(
            get: { AppThemeColor.customColor(hex: themeColorHex) },
            set: { color in
                themeColorHex = AppThemeColor.hex(from: color)
            }
        )
    }

    private func saveToken() {
        let token = tokenDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else { return }
        do {
            try KeychainStore.set(token, account: GitHubBlogUploader.tokenAccount)
            tokenDraft = ""
            tokenSavedMessage = "Token 已保存"
        } catch {
            tokenSavedMessage = error.localizedDescription
        }
    }
}

#Preview {
    SettingsView()
}
