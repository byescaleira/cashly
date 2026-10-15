import CashlyDomain
import Foundation

extension ChallengeRun {
    typealias Outcome = (ChallengeState.Status, ChallengeMeasure)

    func outcome() -> Outcome {
        switch challenge.kind {
        case .noSpendWeekend, .noSpendWeek: noSpend()
        case .quietDays: quietDays()
        case .weekendLighter: weekendLighter()
        case .belowAverage: belowAverage()
        case .cap: cap()
        case .lessThanLastMonth: lessThanLastMonth()
        case .cutBiggest: cutBiggest()
        case .trackWeek, .everyDay: everyDay()
        case .tagWeek: tagWeek()
        case .sameDay: sameDay()
        case .planEveryCategory: planEveryCategory()
        case .weeklyBudget: weeklyBudget()
        case .blueMonth: blueMonth()
        case .allBudgetsBlue: allBudgetsBlue()
        }
    }

    private func noSpend() -> Outcome {
        let scope = challenge.kind == .noSpendWeek ? category : nil
        let spent = snapshot.spent(from: period.start, to: horizon, categoryID: scope)
        let status: ChallengeState.Status =
            spent > 0 ? .failed : finished ? .completed : .active(progress: elapsed)
        return (status, ChallengeMeasure(cleanDays, of: periodDays, .days))
    }

    private func quietDays() -> Outcome {
        let tracked = snapshot.trackedDays
        let quiet = dayList(from: period.start, to: horizon).filter { day in
            let next = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            return tracked.contains(day) && snapshot.spent(from: day, to: next) == 0
        }
        let target = Challenge.quietDayTarget
        let status: ChallengeState.Status =
            quiet.count >= target
            ? .completed
            : finished ? .failed : .active(progress: Double(quiet.count) / Double(target))
        return (status, ChallengeMeasure(Int64(quiet.count), of: Int64(target), .days))
    }

    private func weekendLighter() -> Outcome {
        let postings = snapshot.expenses(from: period.start, to: horizon)
        let weekend = postings.filter { isWeekend($0.date) }.reduce(0) { $0 + $1.minorUnits }
        let weekdays = postings.filter { !isWeekend($0.date) }.reduce(0) { $0 + $1.minorUnits }
        let success = weekend == 0 || weekend * 5 < weekdays * 2
        return (
            atEnd(success, progress: elapsed),
            ChallengeMeasure(weekend / 2, of: weekdays / 5, .money)
        )
    }

    private func belowAverage() -> Outcome {
        let target = snapshot.weeklyAverage(before: startDay)
        let spent = snapshot.spent(from: period.start, to: horizon)
        return (within(spent, of: target), ChallengeMeasure(spent, of: target, .money))
    }

    private func cap() -> Outcome {
        let limit = challenge.limit ?? 0
        let spent = snapshot.spent(in: month, categoryID: category)
        return (within(spent, of: limit), ChallengeMeasure(spent, of: limit, .money))
    }

    private func lessThanLastMonth() -> Outcome {
        let spent = snapshot.spent(in: month, categoryID: category)
        let previous = snapshot.spent(in: month.adding(months: -1), categoryID: category)
        let progress = previous > 0 ? Double(spent) / Double(previous) : 0
        return (
            atEnd(spent < previous, progress: progress),
            ChallengeMeasure(spent, of: previous, .money)
        )
    }

    private func cutBiggest() -> Outcome {
        let previous = snapshot.spent(in: month.adding(months: -1), categoryID: category)
        let target = previous - previous * Challenge.cutPercent / 100
        let spent = snapshot.spent(in: month, categoryID: category)
        return (within(spent, of: target), ChallengeMeasure(spent, of: target, .money))
    }

    private func everyDay() -> Outcome {
        let status: ChallengeState.Status =
            missedDay ? .failed : finished ? .completed : .active(progress: elapsed)
        return (status, ChallengeMeasure(trackedSoFar, of: periodDays, .days))
    }

    private func tagWeek() -> Outcome {
        let expenses = snapshot.transactions.filter {
            $0.kind == .expense && $0.status != .canceled && $0.date >= period.start
                && $0.date < horizon
        }
        let tagged = Int64(expenses.filter { !$0.tagIDs.isEmpty }.count)
        let target = Int64(Challenge.taggedTarget)
        let status: ChallengeState.Status =
            tagged < Int64(expenses.count) ? .failed : atEnd(tagged >= target, progress: elapsed)
        return (status, ChallengeMeasure(tagged, of: target, .count))
    }

    private func sameDay() -> Outcome {
        let transactions = Dictionary(
            snapshot.transactions.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let late = snapshot.events(.transactionRecorded).contains { event in
            guard event.date < horizon, let transaction = transactions[event.value],
                transaction.kind == .expense, period.contains(transaction.date),
                transaction.date < period.end
            else { return false }
            return snapshot.day(event.date) > snapshot.day(transaction.date)
        }
        let status: ChallengeState.Status =
            late || missedDay ? .failed : finished ? .completed : .active(progress: elapsed)
        return (status, ChallengeMeasure(trackedSoFar, of: periodDays, .days))
    }

    private func planEveryCategory() -> Outcome {
        let used = snapshot.spentCategories(in: month)
        let planned = snapshot.budgetedCategories(in: month)
        let covered = used.intersection(planned).count
        let success = !planned.isEmpty && used.isSubset(of: planned)
        let progress = used.isEmpty ? 0 : Double(covered) / Double(used.count)
        return (
            atEnd(success, progress: progress),
            ChallengeMeasure(Int64(covered), of: Int64(used.count), .count)
        )
    }

    private func weeklyBudget() -> Outcome {
        let target = snapshot.weeklyShare(of: month)
        let spent = snapshot.spent(from: period.start, to: horizon)
        return (within(spent, of: target), ChallengeMeasure(spent, of: target, .money))
    }

    private func blueMonth() -> Outcome {
        let score = snapshot.score(in: month) ?? 0
        return (
            atEnd(score >= GameEngine.blueScore, progress: elapsed),
            ChallengeMeasure(Int64(score), of: Int64(GameEngine.blueScore), .score)
        )
    }

    private func allBudgetsBlue() -> Outcome {
        let budgets = snapshot.budgetsByCategory(in: month)
        let within = budgets.filter { snapshot.spent(in: month, categoryID: $0.key) <= $0.value }
        let status: ChallengeState.Status =
            within.count < budgets.count
            ? .failed : atEnd(!budgets.isEmpty, progress: elapsed)
        return (status, ChallengeMeasure(Int64(within.count), of: Int64(budgets.count), .count))
    }

    private func isWeekend(_ date: Date) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }
}
