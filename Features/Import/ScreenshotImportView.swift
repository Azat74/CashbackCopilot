import PhotosUI
import SwiftUI
import UIKit

struct ScreenshotImportView: View {
    private enum DraftMonthTarget: String, CaseIterable, Identifiable {
        case current
        case next

        var id: String { rawValue }
    }

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
    @State private var parsedDraft: ParsedCashbackDraft?
    @State private var selectedPaymentMethodId: UUID?
    @State private var draftMonthTarget: DraftMonthTarget = .current
    @State private var isSavingDraft = false
    @State private var saveSuccessMessage: String?

    private let ocrPipeline: ScreenshotImportOCRPipeline
    private let draftParser: CashbackImportDraftParser

    init(
        bank: Bank,
        ocrPipeline: ScreenshotImportOCRPipeline = ScreenshotImportOCRPipeline(),
        draftParser: CashbackImportDraftParser = CashbackImportDraftParser()
    ) {
        self.bank = bank
        self.ocrPipeline = ocrPipeline
        self.draftParser = draftParser
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

            if let parsedDraft {
                Section("Черновик правил") {
                    Text("Проверьте категории и выгоду перед сохранением в месяц.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("import.draftReadyState")

                    if !parsedDraft.unassignedConditionLines.isEmpty {
                        ImportDraftConditionsCard(lines: parsedDraft.unassignedConditionLines)
                            .accessibilityIdentifier("import.draftUnassignedConditions")
                    }

                    ForEach(parsedDraft.rules.indices, id: \.self) { index in
                        ImportDraftRuleEditor(
                            rule: bindingForDraftRule(at: index)
                        )
                        .accessibilityIdentifier("import.draftRuleEditor")
                    }
                }
            }

            if !recognizedScreenshots.isEmpty {
                Section("Сохранение в месяц") {
                    if availablePaymentMethods.isEmpty {
                        Label(
                            "Добавьте способ оплаты в кошельке, чтобы сохранить импортированные правила.",
                            systemImage: "creditcard"
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("import.missingPaymentMethods")
                    } else {
                        Picker("Способ оплаты", selection: $selectedPaymentMethodId) {
                            ForEach(availablePaymentMethods) { method in
                                Text(method.displayName)
                                    .tag(Optional(method.id))
                            }
                        }
                        .accessibilityIdentifier("import.paymentMethodPicker")

                        Picker("Куда сохранить", selection: $draftMonthTarget) {
                            Text("Текущий месяц")
                                .tag(DraftMonthTarget.current)
                            Text("Следующий месяц")
                                .tag(DraftMonthTarget.next)
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("import.targetMonthPicker")

                        if let parsedDraft {
                            Text(
                                "Будет сохранено \(parsedDraft.rules.count) правил в \(targetMonthKey). "
                                    + "Текущий snapshot банка за этот месяц будет заменен импортом."
                            )
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                            if parsedDraft.rules.isEmpty {
                                Label(
                                    "Пока не распознано ни одного полноценного правила. "
                                        + "Проверьте raw conditions и при необходимости перенесите правила вручную.",
                                    systemImage: "exclamationmark.triangle"
                                )
                                .font(.footnote)
                                .foregroundStyle(.orange)
                                .accessibilityIdentifier("import.noRulesWarning")
                            }
                        }

                        Button {
                            saveDraft()
                        } label: {
                            if isSavingDraft {
                                Label("Сохраняем…", systemImage: "arrow.down.doc")
                            } else {
                                Label("Сохранить черновик в месяц", systemImage: "arrow.down.doc")
                            }
                        }
                        .disabled(isSavingDraft || selectedPaymentMethodId == nil || parsedDraft?.rules.isEmpty != false)
                        .accessibilityIdentifier("import.saveDraftButton")
                    }

                    if let saveSuccessMessage {
                        Label(saveSuccessMessage, systemImage: "checkmark.circle")
                            .font(.footnote)
                            .foregroundStyle(.green)
                            .accessibilityIdentifier("import.saveSuccessMessage")
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
        .onAppear {
            if selectedPaymentMethodId == nil {
                selectedPaymentMethodId = availablePaymentMethods.first?.id
            }
        }
    }
}

private extension ScreenshotImportView {
    private var currentMonthLabel: String {
        appModel.currentMonthKey
    }

    private var targetMonthKey: String {
        switch draftMonthTarget {
        case .current:
            appModel.currentMonthKey
        case .next:
            AppModel.nextMonthKey(from: Date())
        }
    }

    private var availablePaymentMethods: [PaymentMethod] {
        appModel.paymentMethods(for: bank.id)
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
        parsedDraft = nil
        saveSuccessMessage = nil
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
        parsedDraft = nil
        saveSuccessMessage = nil

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
        parsedDraft = nil
        saveSuccessMessage = nil

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
        rebuildDraft(from: result.screenshots)

        if result.failedScreenshotCount > 0 {
            loadErrorMessage = "Часть скриншотов не удалось обработать локально. Проверьте выбранные изображения."
        } else if result.screenshots.isEmpty {
            loadErrorMessage = "Не удалось извлечь текст из выбранных изображений."
        }
    }

    private func rebuildDraft(from screenshots: [RecognizedImportScreenshot]) {
        parsedDraft = draftParser.makeDraft(from: screenshots, bank: bank)
        if selectedPaymentMethodId == nil {
            selectedPaymentMethodId = availablePaymentMethods.first?.id
        }

        if !screenshots.isEmpty, parsedDraft == nil, loadErrorMessage == nil {
            loadErrorMessage = "OCR завершен, но черновик правил пока не удалось собрать автоматически."
        }
    }

    private func bindingForDraftRule(at index: Int) -> Binding<ParsedRuleDraft> {
        Binding(
            get: {
                parsedDraft?.rules[index]
                    ?? ParsedRuleDraft(
                        title: "",
                        category: .other,
                        sourceScreenshotTitle: "",
                        sourceLine: ""
                    )
            },
            set: { updatedRule in
                guard parsedDraft?.rules.indices.contains(index) == true else {
                    return
                }

                parsedDraft?.rules[index] = updatedRule
            }
        )
    }

    private func saveDraft() {
        guard let parsedDraft,
              let selectedPaymentMethodId else {
            return
        }

        isSavingDraft = true
        appModel.saveImportedDraft(
            parsedDraft,
            paymentMethodId: selectedPaymentMethodId,
            monthKey: targetMonthKey
        )
        isSavingDraft = false
        saveSuccessMessage = "Черновик сохранен в \(targetMonthKey)."
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

private struct ImportDraftRuleEditor: View {
    @Binding var rule: ParsedRuleDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                ConfidenceBadge(confidence: rule.confidence)
                    .accessibilityIdentifier("import.draftConfidenceBadge")

                if rule.needsReview {
                    Label("Нужно проверить", systemImage: "exclamationmark.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                        .accessibilityIdentifier("import.draftNeedsReviewBadge")
                }
            }

            TextField("Название категории", text: $rule.title)
                .accessibilityIdentifier("import.draftRuleTitleField")

            Picker("Категория", selection: $rule.category) {
                ForEach(CashbackCategory.allCases, id: \.self) { category in
                    Text(category.displayName)
                        .tag(category)
                }
            }
            .accessibilityIdentifier("import.draftRuleCategoryPicker")

            HStack(spacing: 12) {
                TextField(
                    "Кешбек %",
                    text: Binding(
                        get: { decimalString(rule.percent) },
                        set: { rule.percent = parseDecimal(from: $0) }
                    )
                )
                .keyboardType(.decimalPad)
                .accessibilityIdentifier("import.draftRulePercentField")

                TextField(
                    "Фикс. ₽",
                    text: Binding(
                        get: { decimalString(rule.fixedReward) },
                        set: { rule.fixedReward = parseDecimal(from: $0) }
                    )
                )
                .keyboardType(.decimalPad)
                .accessibilityIdentifier("import.draftRuleFixedRewardField")
            }

            TextField(
                "Особые условия",
                text: Binding(
                    get: { rule.specialConditionsText ?? "" },
                    set: { rule.specialConditionsText = normalizedOptionalText($0) }
                ),
                axis: .vertical
            )
            .lineLimit(2...4)
            .accessibilityIdentifier("import.draftSpecialConditions")

            Text("Источник: \(rule.sourceScreenshotTitle)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(rule.sourceLine)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("import.draftRuleSourceLine")
        }
        .padding(.vertical, 4)
    }

    private func normalizedOptionalText(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func parseDecimal(from text: String) -> Double? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    private func decimalString(_ value: Double?) -> String {
        guard let value else {
            return ""
        }

        if value.rounded() == value {
            return String(Int(value))
        }

        return String(value)
    }
}

private struct ImportDraftConditionsCard: View {
    let lines: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Неразобранные условия", systemImage: "text.quote")
                .font(.subheadline.weight(.semibold))

            Text("Эти строки не удалось надежно привязать к категории. Проверьте их перед сохранением месяца.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ConfidenceBadge: View {
    let confidence: Double

    var body: some View {
        Text(confidenceLabel)
            .font(.caption.weight(.semibold))
            .foregroundStyle(confidenceColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(confidenceColor.opacity(0.14), in: Capsule())
    }

    private var confidenceLabel: String {
        let percent = confidence.formatted(.percent.precision(.fractionLength(0)))
        switch confidence {
        case 0.8...:
            return "Уверенность: высокая (\(percent))"
        case 0.6..<0.8:
            return "Уверенность: средняя (\(percent))"
        default:
            return "Уверенность: низкая (\(percent))"
        }
    }

    private var confidenceColor: Color {
        switch confidence {
        case 0.8...:
            return .green
        case 0.6..<0.8:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    NavigationStack {
        ScreenshotImportView(bank: Bank(name: "Т-Банк"))
            .environment(AppModel())
    }
}
