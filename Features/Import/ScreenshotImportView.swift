import PhotosUI
import SwiftUI
import UIKit

struct ScreenshotImportView: View {
    private enum FeatureFlags {
        static let isUITestSmoke = ProcessInfo.processInfo.arguments.contains("UITEST_SMOKE")
    }

    let bank: Bank

    @Environment(AppModel.self) private var appModel
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var screenshots: [SelectedImportScreenshot] = []
    @State private var isLoadingSelection = false
    @State private var loadErrorMessage: String?

    var body: some View {
        List {
            Section("Импорт в месяц") {
                LabeledContent("Банк", value: bank.name)
                LabeledContent("Месяц", value: currentMonthLabel)

                Text(
                    "Добавьте скриншоты экрана категорий и, при необходимости, tooltip или hint экраны с условиями. "
                    + "Разбор и черновик будут выполнены локально на устройстве."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Section("Скриншоты") {
                if screenshots.isEmpty, !isLoadingSelection {
                    ContentUnavailableView(
                        "Скриншоты пока не выбраны",
                        systemImage: "photo.on.rectangle.angled",
                        description: Text(
                            "Начните с главного экрана категорий кешбека, затем при необходимости "
                                + "добавьте экраны с условиями."
                        )
                    )
                    .accessibilityIdentifier("import.emptyState")
                }

                if isLoadingSelection {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Подготавливаем скриншоты…")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityIdentifier("import.loadingState")
                }

                if !screenshots.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("\(screenshots.count) скриншотов готовы к локальному разбору")
                            .font(.subheadline.weight(.medium))
                            .accessibilityIdentifier("import.selectedCount")

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(screenshots) { screenshot in
                                    ImportScreenshotCard(screenshot: screenshot)
                                        .accessibilityIdentifier("import.screenshotCard")
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        Text("Следующим шагом приложение извлечет текст и соберет черновик правил на месяц.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("import.readyState")

                        Button(role: .destructive) {
                            clearSelection()
                        } label: {
                            Label("Очистить выбор", systemImage: "trash")
                        }
                    }
                }

                if let loadErrorMessage {
                    Label(loadErrorMessage, systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .accessibilityIdentifier("import.errorMessage")
                }
            }

            Section("Действия") {
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 10,
                    matching: .images
                ) {
                    Label(
                        screenshots.isEmpty ? "Выбрать скриншоты" : "Изменить набор скриншотов",
                        systemImage: "photo.badge.plus"
                    )
                }
                .accessibilityIdentifier("import.photoPickerButton")

                if FeatureFlags.isUITestSmoke {
                    Button {
                        loadDemoScreenshots()
                    } label: {
                        Label("Загрузить демо-скриншоты", systemImage: "photo.stack")
                    }
                    .accessibilityIdentifier("import.loadDemoScreenshotsButton")
                }
            }
        }
        .navigationTitle("Импорт кешбека")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("import.screen")
        .onChange(of: selectedItems) { _, newItems in
            Task {
                await loadSelectedItems(newItems)
            }
        }
    }

    private var currentMonthLabel: String {
        appModel.currentMonthKey
    }

    private func clearSelection() {
        selectedItems = []
        screenshots = []
        loadErrorMessage = nil
        isLoadingSelection = false
    }

    private func loadDemoScreenshots() {
        screenshots = [
            SelectedImportScreenshot(
                title: "Категории месяца",
                placeholderSystemImage: "list.bullet.rectangle.portrait"
            ),
            SelectedImportScreenshot(
                title: "Условия категории",
                placeholderSystemImage: "text.bubble"
            )
        ]
        loadErrorMessage = nil
        isLoadingSelection = false
    }

    private func loadSelectedItems(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else {
            screenshots = []
            loadErrorMessage = nil
            isLoadingSelection = false
            return
        }

        isLoadingSelection = true
        loadErrorMessage = nil

        var loadedScreenshots: [SelectedImportScreenshot] = []
        for (index, item) in items.enumerated() {
            do {
                if let imageData = try await item.loadTransferable(type: Data.self) {
                    loadedScreenshots.append(
                        SelectedImportScreenshot(
                            title: "Скриншот \(index + 1)",
                            imageData: imageData
                        )
                    )
                }
            } catch {
                loadErrorMessage = "Не удалось прочитать часть скриншотов. Попробуйте выбрать их снова."
            }
        }

        screenshots = loadedScreenshots
        if loadedScreenshots.isEmpty, loadErrorMessage == nil {
            loadErrorMessage = "Не удалось загрузить выбранные изображения."
        }
        isLoadingSelection = false
    }
}

private struct SelectedImportScreenshot: Identifiable, Equatable {
    let id: UUID
    let title: String
    let imageData: Data?
    let placeholderSystemImage: String?

    init(
        id: UUID = UUID(),
        title: String,
        imageData: Data? = nil,
        placeholderSystemImage: String? = nil
    ) {
        self.id = id
        self.title = title
        self.imageData = imageData
        self.placeholderSystemImage = placeholderSystemImage
    }
}

private struct ImportScreenshotCard: View {
    let screenshot: SelectedImportScreenshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            preview
                .frame(width: 120, height: 160)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(screenshot.title)
                .font(.caption.weight(.medium))
                .lineLimit(2)
        }
        .frame(width: 120, alignment: .leading)
    }

    @ViewBuilder
    private var preview: some View {
        if let imageData = screenshot.imageData,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            VStack(spacing: 10) {
                Image(systemName: screenshot.placeholderSystemImage ?? "photo")
                    .font(.title2)
                Text("Preview")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    NavigationStack {
        ScreenshotImportView(bank: Bank(name: "Т-Банк"))
            .environment(AppModel())
    }
}
