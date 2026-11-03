//
//  FriendProfileView.swift
//  bulkup
//
//  A friend's card: streak, the last workouts they saved and their best
//  records. Training data only; never body measurements or diet.
//

import SwiftUI

struct FriendProfileView: View {
    let friend: FriendProfile
    @ObservedObject private var friendsManager = FriendsManager.shared
    @Environment(\.dismiss) private var dismiss

    enum Phase {
        case loading
        case loaded(FriendPublicProfile)
        case failed
    }

    @State private var phase: Phase = .loading
    @State private var showingRemoveAlert = false

    #if DEBUG
    var previewProfile: FriendPublicProfile? = nil
    #endif

    var body: some View {
        ZStack {
            BulkUpGround()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    header

                    switch phase {
                    case .loading:
                        ProgressView()
                            .controlSize(.large)
                            .tint(BulkUpColors.accent)
                            .frame(maxWidth: .infinity, minHeight: 200)
                    case .failed:
                        failedBlock
                    case .loaded(let profile):
                        statsStrip(profile)
                        sessionsSlab(profile.recentSessions)
                        recordsSlab(profile.bestRecords)
                        removeLink
                    }
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .presentationDragIndicator(.visible)
        .presentationBackground(BulkUpColors.background)
        .task { await load() }
        .alert("Eliminar amigo", isPresented: $showingRemoveAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Eliminar", role: .destructive) {
                Task {
                    await friendsManager.removeFriend(friendId: friend.userId)
                    dismiss()
                }
            }
        } message: {
            Text(String(format: NSLocalizedString("%@ dejará de ver tu racha y tú la suya.", comment: ""), friend.name))
        }
    }

    // MARK: - Header

    private var memberSince: String? {
        guard case .loaded(let profile) = phase else { return nil }
        let f = DateFormatter()
        f.locale = LanguageManager.shared.locale
        f.setLocalizedDateFormatFromTemplate("MMM yyyy")
        return String(format: NSLocalizedString("En BulkUp desde %@", comment: ""), f.string(from: profile.memberSince))
    }

    private var header: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            ProfileAvatar(name: friend.name, url: friend.profileImageURL, size: 56)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(friend.name)
                    .titleVoice(.title)
                    .foregroundColor(BulkUpColors.textPrimary)
                    .lineLimit(2)
                if let memberSince {
                    Text(memberSince)
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
            }

            Spacer(minLength: Spacing.md)

            Button {
                dismiss()
            } label: {
                Text("Cerrar")
                    .font(.system(.footnote, weight: .semibold))
                    .foregroundColor(BulkUpColors.textSecondary)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Stats

    private func statsStrip(_ profile: FriendPublicProfile) -> some View {
        StatsStrip(cells: [
            StatCell(value: "\(profile.streak.currentStreak)", unit: nil, label: "Días seguidos",
                     detail: String(format: NSLocalizedString("Mejor %lld", comment: ""), profile.streak.longestStreak)),
            StatCell(value: "\(profile.streak.totalDays)", unit: nil, label: "Entrenos", detail: nil),
            StatCell(value: "\(profile.workoutsLast7Days)", unit: nil, label: "Esta semana",
                     detail: String(format: NSLocalizedString("%lld en 30 días", comment: ""), profile.workoutsLast30Days)),
        ])
    }

    // MARK: - Sessions

    private func sessionsSlab(_ sessions: [FriendSessionSummary]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            slabTitle("Últimos entrenos")

            if sessions.isEmpty {
                Text("Todavía no ha guardado ningún entreno.")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.md)
            } else {
                ForEach(Array(sessions.enumerated()), id: \.element.id) { i, session in
                    SlabRow(showsSeparator: i < sessions.count - 1, minHeight: 56) {
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.md) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.workoutName?.isEmpty == false ? session.workoutName! : session.dayName)
                                    .font(.system(.subheadline, weight: .semibold))
                                    .foregroundColor(BulkUpColors.textPrimary)
                                    .lineLimit(1)
                                Text(Self.sessionDate(session.date))
                                    .font(BulkUpFont.caption())
                                    .foregroundColor(BulkUpColors.textSecondary)
                            }
                            Spacer(minLength: Spacing.sm)
                            Text(sessionMetric(session))
                                .font(BulkUpFont.numeric(.footnote, weight: .medium))
                                .foregroundColor(BulkUpColors.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .slab()
    }

    private func sessionMetric(_ s: FriendSessionSummary) -> String {
        let sets = String(format: NSLocalizedString("%lld series", comment: ""), s.totalSets)
        guard s.totalVolume > 0 else { return sets }
        return "\(sets) · \(BulkUpFormat.decimal(s.totalVolume, fraction: 0)) kg"
    }

    private static func sessionDate(_ raw: String) -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: raw) else { return raw }
        let f = DateFormatter()
        f.locale = LanguageManager.shared.locale
        f.setLocalizedDateFormatFromTemplate("EEE d MMM")
        return f.string(from: date)
    }

    // MARK: - Records

    private func recordsSlab(_ records: [FriendRecordSummary]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            slabTitle("Récords")

            if records.isEmpty {
                Text("Sin récords todavía.")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.md)
            } else {
                ForEach(Array(records.enumerated()), id: \.element.id) { i, record in
                    SlabRow(showsSeparator: i < records.count - 1, minHeight: 56) {
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.md) {
                            Text(record.exerciseName)
                                .font(.system(.subheadline, weight: .semibold))
                                .foregroundColor(BulkUpColors.textPrimary)
                                .lineLimit(1)
                            Spacer(minLength: Spacing.sm)
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(BulkUpFormat.decimal(record.weight, fraction: 1)) kg × \(record.reps)")
                                    .font(BulkUpFont.mono(17, weight: .semibold, relativeTo: .body))
                                    .foregroundColor(BulkUpColors.textPrimary)
                                Text(String(format: NSLocalizedString("1RM %@ kg", comment: ""),
                                            BulkUpFormat.decimal(record.estimatedOneRM, fraction: 0)))
                                    .font(BulkUpFont.numeric(.caption, weight: .medium))
                                    .foregroundColor(BulkUpColors.textTertiary)
                            }
                        }
                    }
                }
            }
        }
        .slab()
    }

    private func slabTitle(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(BulkUpFont.cardTitle())
            .foregroundColor(BulkUpColors.textPrimary)
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.sm)
    }

    // MARK: - Footer / failure

    private var removeLink: some View {
        Button {
            showingRemoveAlert = true
        } label: {
            Text("Eliminar amigo")
                .font(BulkUpFont.caption())
                .foregroundColor(BulkUpColors.textTertiary)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var failedBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("No hemos podido cargar su perfil.")
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.warning)
            Button {
                Task { await load() }
            } label: {
                Text("Reintentar")
                    .font(.system(.headline, weight: .semibold))
                    .foregroundColor(BulkUpColors.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(BulkUpColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func load() async {
        #if DEBUG
        if let previewProfile {
            phase = .loaded(previewProfile)
            return
        }
        #endif
        phase = .loading
        do {
            let profile = try await APIService.shared.getFriendProfile(friendId: friend.userId)
            phase = .loaded(profile)
        } catch {
            phase = .failed
        }
    }
}

// MARK: - Avatar (shared by the profile tab, the friend card and the ranking)

/// A round photo on the raised fill, or the name's initial in secondary text.
struct ProfileAvatar: View {
    let name: String
    var url: String?
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle().fill(BulkUpColors.surfaceElevated)
            if let url, let u = URL(string: url.replacingOccurrences(of: "http://", with: "https://")) {
                CachedAsyncImage(url: u, content: { image, _ in
                    image.resizable().scaledToFill()
                }, placeholder: { initial })
            } else {
                initial
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }

    private var initial: some View {
        Text(name.prefix(1).uppercased())
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundColor(BulkUpColors.textSecondary)
    }
}
