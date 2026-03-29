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
    @State private var screenshots: [ImportScreenshotAsset] = []
    @State private var recognizedScreenshots: [RecognizedImportScreenshot] = []
    @State private var isLoadingSelection = false
    @State private var isRecognizingText = false
    @State private var loadErrorMessage: String?
    @State private var failedOCRCount = 0

    private let ocrPipeline: ScreenshotImportOCRPipeline

    init(
        bank: Bank,
        ocrPipeline: ScreenshotImportOCRPipeline = ScreenshotImportOCRPipeline()
    ) {
        self.bank = bank
        self.ocrPipeline = ocrPipeline
    }

    var body: some View {
        let hasSelectedScreenshots = !screenshots.isEmpty
        let photoPickerTitle = hasSelectedScreenshots ? "Изменить набор скриншотов" : "Выбрать скриншоты"

        List {
            Section("Импорт в месяц") {
                LabeledContent("Банк", value: bank.name)
                LabeledContent("Месяц", value: currentMonthLabel)

                Text(
                    "Добавьте скриншоты экрана категорий и, при необходимости, tooltip или hint экраны с условиями. "
                    + "Приложение локально извлечет raw text и подготовит основу для будущего draft review."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Section("Скриншоты") {
                if !hasSelectedScreenshots, !isLoadingSelection {
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

                if hasSelectedScreenshots {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(selectionSummary)
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

                        if isRecognizingText {
                            HStack(spacing: 12) {
                                ProgressView()
                                Text("Извлекаем текст локально на устройстве…")
                                    .foregroundStyle(.secondary)
                            }
                            .accessibilityIdentifier("import.ocrLoadingState")
                        } else if !recognizedScreenshots.isEmpty {
                            Text("OCR завершен. Ниже показан raw text перед будущим parser/draft шагом.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .accessibilityIdentifier("import.ocrReadyState")
                        } else {
                            Text("Следующим шагом приложение локально извлечет текст и покажет raw OCR output.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .accessibilityIdentifier("import.readyState")
                        }

                        Button {
                            Task { @MainActor in
                                await runOCR(for: screenshots)
                            }
                        } label: {
                            Label("Повторить локальный OCR", systemImage: "text.viewfinder")
                        }
                        .disabled(screenshots.isEmpty || isRecognizingText)
                        .accessibilityIdentifier("import.runOCRButton")

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

            if !recognizedScreenshots.isEmpty {
                Section("OCR результат") {
                    ForEach(recognizedScreenshots) { screenshot in
                        ImportOCRPreviewCard(screenshot: screenshot)
                            .accessibilityIdentifier("import.ocrPreviewCard")
                    }
                }
            }

            Section("Действия") {
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 10,
                    matching: .images
                ) {
                    Label(
                        photoPickerTitle,
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
            Task { @MainActor in
                await loadSelectedItems(newItems)
            }
        }
    }
}

private extension ScreenshotImportView {
    private var currentMonthLabel: String {
        appModel.currentMonthKey
    }

    private var selectionSummary: String {
        if isRecognizingText {
            return "\(screenshots.count) скриншотов готовы к OCR"
        }

        if !recognizedScreenshots.isEmpty {
            if failedOCRCount > 0 {
                return "\(recognizedScreenshots.count) скриншотов обработаны, \(failedOCRCount) с ошибкой"
            }

            return "\(recognizedScreenshots.count) скриншотов обработаны локально"
        }

        return "\(screenshots.count) скриншотов готовы к локальному разбору"
    }

    private func clearSelection() {
        selectedItems = []
        screenshots = []
        recognizedScreenshots = []
        loadErrorMessage = nil
        isLoadingSelection = false
        isRecognizingText = false
        failedOCRCount = 0
    }

    private func loadDemoScreenshots() {
        let demoScreenshots = [
            ImportScreenshotAsset(
                title: "Категории месяца",
                placeholderSystemImage: "list.bullet.rectangle.portrait",
                demoRecognizedText: "АЗС 5%\nКафе и рестораны 7%\nМаркетплейсы 3%"
            ),
            ImportScreenshotAsset(
                title: "Условия категории",
                placeholderSystemImage: "text.bubble",
                demoRecognizedText: "Лимит 1000 ₽ в месяц\nНе действует при оплате по QR"
            )
        ]

        screenshots = demoScreenshots
        recognizedScreenshots = []
        loadErrorMessage = nil
        isLoadingSelection = false

        Task { @MainActor in
            await runOCR(for: demoScreenshots)
        }
    }

    @MainActor
    private func loadSelectedItems(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else {
            clearSelection()
            return
        }

        isLoadingSelection = true
        isRecognizingText = false
        loadErrorMessage = nil
        recognizedScreenshots = []
        failedOCRCount = 0

        var loadedScreenshots: [ImportScreenshotAsset] = []
        for (index, item) in items.enumerated() {
            do {
            if let imageData = try await item.loadTransferable(type: Data.self) {
                    loadedScreenshots.append(ImportScreenshotAsset(
                        title: "Скриншот \(index + 1)",
                        imageData: imageData
                    ))
                }
            } catch {
                loadErrorMessage = "Не удалось прочитать часть скриншотов. Попробуйте выбрать их снова."
            }
        }

        screenshots = loadedScreenshots
        isLoadingSelection = false

        guard !loadedScreenshots.isEmpty else {
            if loadErrorMessage == nil {
                loadErrorMessage = "Не удалось загрузить выбранные изображения."
            }
            return
        }

        await runOCR(for: loadedScreenshots)
    }

    @MainActor
    private func runOCR(for screenshotsToProcess: [ImportScreenshotAsset]) async {
        guard !screenshotsToProcess.isEmpty else {
            recognizedScreenshots = []
            isRecognizingText = false
            failedOCRCount = 0
            return
        }

        let expectedScreenshotIDs = screenshotsToProcess.map(\.id)
        isRecognizingText = true
        loadErrorMessage = nil
        recognizedScreenshots = []
        failedOCRCount = 0

        let result = await ocrPipeline.recognize(screenshotsToProcess)

        guard screenshots.map(\.id) == expectedScreenshotIDs else {
            return
        }

        recognizedScreenshots = result.screenshots
        failedOCRCount = result.failedScreenshotCount
        isRecognizingText = false

        if result.failedScreenshotCount > 0 {
            loadErrorMessage = "Часть скриншотов не удалось обработать локально. Проверьте выбранные изображения."
        } else if result.screenshots.isEmpty {
            loadErrorMessage = "Не удалось извлечь текст из выбранных изображений."
        }
    }
}

private struct ImportScreenshotCard: View {
    let screenshot: ImportScreenshotAsset

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

private struct ImportOCRPreviewCard: View {
    let screenshot: RecognizedImportScreenshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(screenshot.title)
                .font(.headline)
                .accessibilityIdentifier("import.ocrPreviewTitle")

            if screenshot.hasRecognizedText {
                Text(screenshot.recognizedText)
                    .font(.footnote.monospaced())
                    .textSelection(.enabled)
                    .accessibilityIdentifier("import.ocrPreviewText")
            } else {
                Text(
                    "Текст не найден. На следующем шаге пользователь сможет заменить "
                        + "скриншот или продолжить с пустым raw OCR результатом."
                )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("import.ocrEmptyText")
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ScreenshotImportView(bank: Bank(name: "Т-Банк"))
            .environment(AppModel())
    }
}
