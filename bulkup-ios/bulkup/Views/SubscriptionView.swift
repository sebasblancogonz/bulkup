//
//  SubscriptionView.swift
//  bulkup
//
//  PRO paywall: what unlocks, the two plans, one action. Prices and the trial
//  come from StoreKit; nothing commercial is hard-coded.
//

import StoreKit
import SwiftUI

struct SubscriptionView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject private var storeManager = StoreKitManager.shared
    @Environment(\.dismiss) var dismiss

    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""

    #if DEBUG
    /// Design-preview only: StoreKit products never load outside Xcode's
    /// StoreKit configuration, so the simulator review renders these rows.
    var previewPlans: [PlanRowContent.Model] = []
    /// Design-preview only: open scrolled to the legal footer.
    var previewScrollToFooter = false
    @State private var previewSelection = 0
    #endif

    var body: some View {
        NavigationStack {
            ZStack {
                BulkUpGround()

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.xl) {
                            headline
                            proofStrip
                            if storeManager.hasActiveSubscription {
                                activeSubscriptionSection
                            } else {
                                unlockList
                                legalFooter
                                    .id("legal")
                            }
                        }
                        .padding(.horizontal, Spacing.screenH)
                        .padding(.top, Spacing.sm)
                        .padding(.bottom, Spacing.lg)
                    }
                    .scrollIndicators(.hidden)
                    // Content slides under the panel through a short fade instead of
                    // a hard cut, so a half-visible row reads as "more below".
                    .overlay(alignment: .bottom) {
                        LinearGradient(colors: [.clear, BulkUpColors.background], startPoint: .top, endPoint: .bottom)
                            .frame(height: 28)
                            .allowsHitTesting(false)
                    }
                    .onAppear {
                        #if DEBUG
                        if previewScrollToFooter {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                proxy.scrollTo("legal", anchor: .bottom)
                            }
                        }
                        #endif
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !storeManager.hasActiveSubscription {
                    purchasePanel
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(.footnote, weight: .bold))
                    }
                    .tint(BulkUpColors.textPrimary)
                    .accessibilityLabel("Cerrar")
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .onAppear { selectDefaultPlanIfNeeded() }
            .onChange(of: storeManager.products) { _, _ in selectDefaultPlanIfNeeded() }
            .overlay {
                if isPurchasing {
                    ZStack {
                        BulkUpColors.shadow.opacity(0.55).ignoresSafeArea()
                        VStack(spacing: Spacing.md) {
                            ProgressView().tint(BulkUpColors.accent)
                            Text("Procesando…")
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.textPrimary)
                        }
                        .padding(Spacing.lg)
                        .background(BulkUpColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
                        .hairline()
                    }
                }
            }
        }
    }

    /// Default the selection to the annual plan (the anchor) once products load.
    private func selectDefaultPlanIfNeeded() {
        guard selectedProduct == nil, !storeManager.products.isEmpty else { return }
        selectedProduct = storeManager.products.first(where: { storeManager.isYearly($0) })
            ?? storeManager.products.first
    }

    // MARK: - Headline

    private var headline: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Tu progreso, visible.")
                .displayVoice(40, weight: .extraBold, relativeTo: .largeTitle)
                .foregroundColor(BulkUpColors.textPrimary)
                .lineSpacing(-4)
                .fixedSize(horizontal: false, vertical: true)

            Text("PRO mete tu plan en la app desde el PDF, guarda cada kilo y te enseña si avanzas.")
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, Spacing.md)
    }

    // MARK: - Proof strip (product facts only)

    private var proofStrip: some View {
        HStack(spacing: 0) {
            proofItem(value: "1.000+", label: "ejercicios")
            proofDivider
            proofItem(value: "1RM", label: "fórmulas reales")
            proofDivider
            proofItem(value: "iOS + Watch", label: "en la muñeca")
        }
        .padding(.vertical, Spacing.md)
        .overlay(Rectangle().frame(height: 1).foregroundColor(BulkUpColors.line), alignment: .top)
        .overlay(Rectangle().frame(height: 1).foregroundColor(BulkUpColors.line), alignment: .bottom)
    }

    private func proofItem(value: String, label: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(BulkUpFont.mono(15, weight: .semibold, relativeTo: .subheadline))
                .foregroundColor(BulkUpColors.accentText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(BulkUpFont.caption())
                .foregroundColor(BulkUpColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var proofDivider: some View {
        Rectangle()
            .fill(BulkUpColors.line)
            .frame(width: 1, height: 30)
            .padding(.horizontal, Spacing.sm)
    }

    // MARK: - What unlocks

    private var unlockList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Lo que desbloqueas")
                .microLabel()
                .padding(.bottom, Spacing.sm)

            unlockRow(icon: "doc.viewfinder", title: "Importación con IA",
                      detail: "Sube el PDF o una foto de tu plan y queda listo para registrar.")
            unlockRow(icon: "square.stack.3d.up", title: "Planes ilimitados",
                      detail: "Gratis tienes un plan activo de entreno y uno de dieta.")
            unlockRow(icon: "qrcode", title: "Compartir e importar por código",
                      detail: "Pasa tu plan a un colega o usa el de tu entrenador.")
            unlockRow(icon: "chart.line.uptrend.xyaxis", title: "Progreso y medidas corporales",
                      detail: "Volumen por semana, composición y tendencias.")
            unlockRow(icon: "trophy", title: "Récords personales",
                      detail: "Tus RM calculados y el historial de cada marca.")
            unlockRow(icon: "fork.knife", title: "Recetas con IA y fidelidad de dieta",
                      detail: "Platos con lo que tienes en casa y los días que te saltaste.",
                      last: true)
        }
    }

    private func unlockRow(icon: String, title: LocalizedStringKey, detail: LocalizedStringKey,
                           last: Bool = false) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(.body, weight: .medium))
                .foregroundColor(BulkUpColors.accentText)
                .frame(width: 24, alignment: .center)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(BulkUpFont.cardTitle())
                    .foregroundColor(BulkUpColors.textPrimary)
                Text(detail)
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, Spacing.md)
        .overlay(alignment: .bottom) {
            if !last {
                Rectangle().fill(BulkUpColors.line).frame(height: 1)
            }
        }
    }

    // MARK: - Active subscription

    private var activeSubscriptionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(BulkUpColors.complete)
                Text("Ya eres PRO")
                    .font(BulkUpFont.cardTitle())
                    .foregroundColor(BulkUpColors.textPrimary)
            }

            if let expirationDate = storeManager.expirationDate {
                HStack(spacing: Spacing.xs) {
                    Text("Se renueva el")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                    Text(expirationDate.formatted(date: .abbreviated, time: .omitted))
                        .font(BulkUpFont.mono(13, relativeTo: .footnote))
                        .foregroundColor(BulkUpColors.textPrimary)
                }
            }

            Button {
                Task { await storeManager.openSubscriptionManagement() }
            } label: {
                Text("Gestionar suscripción")
                    .secondaryButtonStyle()
            }
        }
        .padding(Spacing.md)
        .background(BulkUpColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .hairline()
    }

    // MARK: - Plans + CTA (pinned)

    @ViewBuilder
    private var purchasePanel: some View {
        VStack(spacing: Spacing.md) {
            if storeManager.isLoading && storeManager.products.isEmpty && previewPlanRows == nil {
                ProgressView()
                    .tint(BulkUpColors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
            } else if let previewPlanRows {
                previewPlanRows
            } else if storeManager.products.isEmpty {
                emptyProducts
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(storeManager.products.sorted(by: { $0.price > $1.price }), id: \.id) { product in
                        PlanRow(
                            product: product,
                            isSelected: selectedProduct?.id == product.id,
                            onSelect: { selectedProduct = product }
                        )
                    }
                }

                if let product = selectedProduct {
                    Button {
                        Task { await purchaseProduct(product) }
                    } label: {
                        Text(ctaTitle(for: product))
                            .primaryButtonStyle()
                    }
                    .pressable()

                    Text(shortRenewalLine(for: product))
                        .font(.system(.caption2))
                        .foregroundColor(BulkUpColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
        .background(
            BulkUpColors.background
                .overlay(Rectangle().frame(height: 1).foregroundColor(BulkUpColors.line), alignment: .top)
                .ignoresSafeArea()
        )
    }

    /// Auto-renewal terms, restore and the legal links live in the scroll
    /// content so the pinned panel stays short enough to leave the unlock list
    /// visible.
    private var legalFooter: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if !previewPlanRenewalLine.isEmpty {
                Text(previewPlanRenewalLine)
                    .font(.system(.caption2))
                    .foregroundColor(BulkUpColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let product = selectedProduct {
                Text(renewalLine(for: product))
                    .font(.system(.caption2))
                    .foregroundColor(BulkUpColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: Spacing.md) {
                Button {
                    Task { await restorePurchases() }
                } label: {
                    Text("Restaurar compras")
                        .frame(minHeight: 32)
                }
                Text("·").foregroundColor(BulkUpColors.textTertiary)
                Link("Términos de Uso", destination: URL(string: "https://getbulkup.com/terms")!)
                Text("·").foregroundColor(BulkUpColors.textTertiary)
                Link("Privacidad", destination: URL(string: "https://getbulkup.com/privacy")!)
            }
            .font(.system(.caption2, weight: .medium))
            .foregroundColor(BulkUpColors.textSecondary)
        }
        .padding(.top, Spacing.sm)
    }

    private var previewPlanRenewalLine: String {
        #if DEBUG
        return previewPlans.indices.contains(previewSelection) ? previewPlans[previewSelection].renewalLine : ""
        #else
        return ""
        #endif
    }

    /// Under the CTA: just price and period ("Después, 39,99 € al año.").
    private func shortRenewalLine(for product: Product) -> String {
        let period = storeManager.isYearly(product)
            ? NSLocalizedString("al año", comment: "")
            : NSLocalizedString("al mes", comment: "")
        let price = "\(storeManager.priceString(for: product)) \(period)"
        if storeManager.trialDescription(for: product) != nil {
            return String(format: NSLocalizedString("Después, %@.", comment: "after trial"), price)
        }
        return String(format: NSLocalizedString("%@.", comment: "price period"), price)
    }

    /// nil outside DEBUG design previews.
    @ViewBuilder
    private var previewPlanRowsBuilder: some View {
        #if DEBUG
        VStack(spacing: Spacing.sm) {
            ForEach(previewPlans.indices, id: \.self) { i in
                PlanRowContent(model: previewPlans[i], isSelected: previewSelection == i) {
                    previewSelection = i
                }
            }
        }
        if previewPlans.indices.contains(previewSelection) {
            let plan = previewPlans[previewSelection]
            Button {} label: {
                Text(plan.trial.map { String(format: NSLocalizedString("Empezar %@", comment: ""), $0) }
                     ?? String(format: NSLocalizedString("Suscribirse · %@", comment: ""), plan.price))
                    .primaryButtonStyle()
            }
            Text(plan.renewalLine.components(separatedBy: ". ").first.map { $0 + "." } ?? "")
                .font(.system(.caption2))
                .foregroundColor(BulkUpColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        #else
        EmptyView()
        #endif
    }

    private var previewPlanRows: AnyView? {
        #if DEBUG
        return previewPlans.isEmpty ? nil : AnyView(previewPlanRowsBuilder)
        #else
        return nil
        #endif
    }

    private func ctaTitle(for product: Product) -> String {
        if let trial = storeManager.trialDescription(for: product) {
            return String(format: NSLocalizedString("Empezar %@", comment: "trial CTA"), trial)
        }
        return String(format: NSLocalizedString("Suscribirse · %@", comment: ""),
                      storeManager.priceString(for: product))
    }

    /// The sentence Apple expects under the CTA: price, period, auto-renewal.
    private func renewalLine(for product: Product) -> String {
        let period = storeManager.isYearly(product)
            ? NSLocalizedString("al año", comment: "")
            : NSLocalizedString("al mes", comment: "")
        let price = "\(storeManager.priceString(for: product)) \(period)"
        let base: String
        if storeManager.trialDescription(for: product) != nil {
            base = String(format: NSLocalizedString("Después, %@.", comment: "after trial"), price)
        } else {
            base = String(format: NSLocalizedString("%@.", comment: "price period"), price)
        }
        return base + " " + NSLocalizedString(
            "Se renueva automáticamente hasta que la canceles, al menos 24 h antes del fin del período, desde los ajustes de tu cuenta del App Store.",
            comment: "")
    }

    private var emptyProducts: some View {
        VStack(spacing: Spacing.sm) {
            Text("No se pudieron cargar los planes")
                .font(BulkUpFont.cardTitle())
                .foregroundColor(BulkUpColors.textPrimary)
            if let error = storeManager.errorMessage {
                Text(error)
                    .font(.system(.caption2))
                    .foregroundColor(BulkUpColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Button {
                Task { await storeManager.loadProducts() }
            } label: {
                Label("Reintentar", systemImage: "arrow.clockwise")
                    .secondaryButtonStyle()
            }
        }
    }

    // MARK: - Purchase

    private func purchaseProduct(_ product: Product) async {
        isPurchasing = true
        do {
            if (try await storeManager.purchase(product)) != nil {
                isPurchasing = false
                dismiss()
            } else {
                isPurchasing = false
            }
        } catch {
            isPurchasing = false
            errorMessage = String(format: NSLocalizedString("Error al procesar la compra: %@", comment: ""), error.localizedDescription)
            showingError = true
        }
    }

    private func restorePurchases() async {
        isPurchasing = true
        await storeManager.restorePurchases()
        isPurchasing = false

        if storeManager.hasActiveSubscription {
            dismiss()
        } else {
            errorMessage = NSLocalizedString("No se encontraron compras previas para restaurar.", comment: "")
            showingError = true
        }
    }
}

// MARK: - Plan Row

/// One selectable plan: name + billing detail on the left, price in mono on the
/// right, a lime radio. The yearly plan carries the "MEJOR VALOR" chip and its
/// per-month equivalent so the two prices compare at a glance.
struct PlanRow: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void

    @ObservedObject private var storeManager = StoreKitManager.shared

    var body: some View {
        PlanRowContent(
            model: .init(
                title: planTitle,
                detail: planDetail,
                price: storeManager.priceString(for: product),
                perMonth: monthlyEquivalent,
                highlightPerMonth: savings != nil,
                isBestValue: storeManager.isYearly(product),
                trial: storeManager.trialDescription(for: product),
                renewalLine: ""
            ),
            isSelected: isSelected,
            onSelect: onSelect
        )
    }

    private var planTitle: LocalizedStringKey {
        if storeManager.isMonthly(product) { return "Mensual" }
        if storeManager.isYearly(product) { return "Anual" }
        return LocalizedStringKey(storeManager.periodString(for: product).capitalized)
    }

    private var planDetail: String {
        var parts: [String] = []
        if let trial = storeManager.trialDescription(for: product) { parts.append(trial) }
        if let savings { parts.append(savings) }
        if parts.isEmpty {
            return storeManager.isYearly(product)
                ? NSLocalizedString("Facturado una vez al año", comment: "")
                : NSLocalizedString("Facturado cada mes", comment: "")
        }
        return parts.joined(separator: " · ")
    }

    /// "3,33 €/mes" for the yearly plan, so both rows compare per month.
    private var monthlyEquivalent: String? {
        guard storeManager.isYearly(product) else { return nil }
        let perMonth = product.price / 12
        let formatted = perMonth.formatted(product.priceFormatStyle)
        return String(format: NSLocalizedString("%@/mes", comment: ""), formatted)
    }

    private var savings: String? {
        guard storeManager.isYearly(product),
              let monthly = storeManager.products.first(where: { storeManager.isMonthly($0) }) else { return nil }
        let yearlyCost = NSDecimalNumber(decimal: product.price).doubleValue
        let monthlyPerYear = NSDecimalNumber(decimal: monthly.price).doubleValue * 12
        let saved = monthlyPerYear - yearlyCost
        guard saved > 0 else { return nil }
        return String(format: NSLocalizedString("Ahorra %lld%%", comment: ""), Int((saved / monthlyPerYear) * 100))
    }
}

/// The plan row's rendering, separated from StoreKit so the design preview
/// (and any future offer type) can draw the same row from plain values.
struct PlanRowContent: View {
    struct Model {
        var title: LocalizedStringKey
        var detail: String
        var price: String
        var perMonth: String?
        var highlightPerMonth: Bool
        var isBestValue: Bool
        var trial: String?
        var renewalLine: String
    }

    let model: Model
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? BulkUpColors.accent : BulkUpColors.textTertiary, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle().fill(BulkUpColors.accent).frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: Spacing.sm) {
                        Text(model.title)
                            .font(BulkUpFont.cardTitle())
                            .foregroundColor(BulkUpColors.textPrimary)
                        if model.isBestValue {
                            Text("Mejor valor")
                                .font(.system(.caption2, weight: .bold))
                                .textCase(.uppercase)
                                .tracking(0.8)
                                .foregroundColor(BulkUpColors.onAccent)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(BulkUpColors.accent)
                                .clipShape(Capsule())
                        }
                    }
                    Text(model.detail)
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }

                Spacer(minLength: Spacing.sm)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(model.price)
                        .font(BulkUpFont.mono(17, weight: .semibold, relativeTo: .headline))
                        .foregroundColor(BulkUpColors.textPrimary)
                    if let perMonth = model.perMonth {
                        Text(perMonth)
                            .font(BulkUpFont.mono(12, relativeTo: .caption))
                            .foregroundColor(model.highlightPerMonth ? BulkUpColors.accentText : BulkUpColors.textSecondary)
                    }
                }
            }
            .padding(Spacing.md)
            .frame(minHeight: 64)
            .background(isSelected ? BulkUpColors.surfaceElevated : BulkUpColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
            .hairline(color: isSelected ? BulkUpColors.accent : BulkUpColors.line)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
