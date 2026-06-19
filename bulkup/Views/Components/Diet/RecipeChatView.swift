//
//  RecipeChatView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 19/6/26.
//

import SwiftUI

struct RecipeChatView: View {
    @StateObject private var manager: RecipeChatManager
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storeKit = StoreKitManager.shared

    @State private var inputText: String = ""
    @State private var showingSubscription = false

    init(mealType: String, ingredients: [String]) {
        _manager = StateObject(wrappedValue: RecipeChatManager(mealType: mealType, ingredients: ingredients))
    }

    var body: some View {
        NavigationStack {
            Group {
                if storeKit.isSubscribed {
                    chatContent
                } else {
                    SubscriptionRequiredView(
                        onSubscribe: { showingSubscription = true },
                        title: "Recetas con IA",
                        subtitle: "Sugerencias de recetas con los ingredientes de tu dieta."
                    )
                    .sheet(isPresented: $showingSubscription) {
                        SubscriptionView()
                    }
                }
            }
            .navigationTitle("Receta con IA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(BulkUpColors.accent)
                }
            }
        }
    }

    // MARK: - Chat Content

    private var chatContent: some View {
        VStack(spacing: 0) {
            messageList
            Divider()
                .background(BulkUpColors.border)
            inputBar
        }
        .background(BulkUpColors.background)
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(manager.messages) { message in
                        messageBubble(message)
                            .id(message.id)
                    }
                    if manager.isLoading {
                        thinkingIndicator
                            .id("thinking")
                    }
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.vertical, Spacing.md)
            }
            .onChange(of: manager.messages.count) { _ in
                withAnimation {
                    if manager.isLoading {
                        proxy.scrollTo("thinking", anchor: .bottom)
                    } else if let last = manager.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: manager.isLoading) { _ in
                withAnimation {
                    if manager.isLoading {
                        proxy.scrollTo("thinking", anchor: .bottom)
                    } else if let last = manager.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Message Bubble

    @ViewBuilder
    private func messageBubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.role == "user" {
                Spacer(minLength: Spacing.xl)
                Text(message.content)
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.onAccent)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(BulkUpColors.accent)
                    .cornerRadius(CornerRadius.medium)
            } else {
                let bgColor = message.isError
                    ? BulkUpColors.error.opacity(0.15)
                    : BulkUpColors.surface
                Text(message.content)
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textPrimary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(bgColor)
                    .cornerRadius(CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                            .stroke(BulkUpColors.border, lineWidth: 0.5)
                    )
                Spacer(minLength: Spacing.xl)
            }
        }
    }

    // MARK: - Thinking Indicator

    private var thinkingIndicator: some View {
        HStack {
            HStack(spacing: Spacing.xs) {
                Text("Pensando…")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
                    .italic()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(BulkUpColors.surface)
            .cornerRadius(CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(BulkUpColors.border, lineWidth: 0.5)
            )
            Spacer(minLength: Spacing.xl)
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: Spacing.sm) {
            TextField("Pregunta sobre tu receta…", text: $inputText)
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.textPrimary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(BulkUpColors.surface)
                .cornerRadius(CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .stroke(BulkUpColors.border, lineWidth: 0.5)
                )
                .disabled(manager.isLoading)
                .submitLabel(.send)
                .onSubmit { sendMessage() }

            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(
                        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || manager.isLoading
                            ? BulkUpColors.textTertiary
                            : BulkUpColors.accent
                    )
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || manager.isLoading)
            .animation(.easeInOut(duration: 0.15), value: inputText.isEmpty)
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.vertical, Spacing.md)
        .background(BulkUpColors.background)
    }

    // MARK: - Actions

    private func sendMessage() {
        let text = inputText
        inputText = ""
        Task {
            await manager.send(text)
        }
    }
}
