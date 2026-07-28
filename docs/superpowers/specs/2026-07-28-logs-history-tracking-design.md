# Logs History Tracking Design

## Goal

Logs should let the user create a tracked item, such as weight, then add numeric data points over time and review the item's week or month history as a line chart.

## Current State

The existing data model already separates tracked items from data points:

- `LogItem` represents a tracked item, including name, optional unit, color, creation time, and archived state.
- `LogEntry` represents one numeric data point for a `LogItem`, including value, optional notes, logged time, and creation time.

The current UI makes this relationship unclear. The list row has both a plus icon and a chevron close together, so users can easily open the add-entry form when they intended to open history. The chart uses data-point index positions for the x-axis, so the line does not reflect actual time spacing within a week or month.

## Design

Keep the existing `LogItem` and `LogEntry` schema. Update the presentation layer so each page has one clear job:

- Logs list page: manage tracked items. Each row shows item name, unit, total entry count, latest value, and latest logged date. Tapping the row or chevron opens that item's history page. The row plus button remains the fast path for adding a new data point.
- Log detail page: show one tracked item's history. It has week/month range controls, a true time-based line chart, a recent data list, and a right-side plus button for adding a new data point.
- Add entry page: save one numeric data point for the selected item. After save, the caller refreshes so list summaries and chart data stay current.

## Data Flow

`LogBloc` remains the source for the list page and summary data. The list page provides the existing bloc to child routes with `BlocProvider.value`, so row-level and detail-level add-entry flows can reload the list.

The detail page loads entries for the selected `LogItem` and selected range from `LogEntryRepository.listByItemInRange`. The range calculation uses existing `PeriodCalculator` helpers. Switching week/month reloads the detail query. Returning from add-entry reloads the detail query and the shared list bloc.

## Chart Behavior

The line chart should map x-values to real elapsed time inside the selected range instead of using the data point index. Weekly and monthly charts both use the same approach:

- `minX` is the start of the selected range.
- `maxX` is the end of the selected range.
- Each point's x-value is derived from `loggedAt`.
- Bottom labels show readable dates selected from the range.

This makes irregular entries visually meaningful; two entries logged one day apart should appear closer than entries logged two weeks apart.

## Empty And Error States

If the item has no data in the selected range, the detail page should show an explicit empty state, not a spinner. Loading errors should show an error message. The page must not remain indefinitely in a loading state.

## Testing

Add focused tests before implementation:

- A widget regression test that tapping a log row opens the history page, while tapping the row plus opens the add-entry page.
- A chart widget test or unit-level chart mapping test that verifies entries use time-based x-values rather than index positions.
- A detail page widget test that verifies a populated range shows chart content and a range with no data shows the empty state.

Run the focused Logs tests first, then run the full Flutter test suite.
