import 'package:example/models/event.dart';
import 'package:example/widgets/calendar_header.dart';
import 'package:example/widgets/calendar_tiles/tiles_export.dart';
import 'package:example/widgets/dialogs/event_edit_dialog.dart';
import 'package:example/widgets/dialogs/new_event_dialog.dart';
import 'package:flutter/material.dart';
import 'package:kalender/kalender.dart';

class MobileScreen extends StatefulWidget {
  const MobileScreen({super.key, required this.eventsController});

  final CalendarEventsController<Event> eventsController;

  @override
  State<MobileScreen> createState() => _MobileScreenState();
}

class _MobileScreenState extends State<MobileScreen> {
  late CalendarEventsController<Event> eventsController;
  late CalendarController<Event> calendarController;
  late CalendarComponents components;
  late CalendarEventHandlers<Event> eventHandlers;

  /// The current view configuration.
  late ViewConfiguration currentConfiguration = viewConfigurations.first;

  /// The list of view configurations that can be used.
  List<ViewConfiguration> viewConfigurations = [
    const DayConfiguration(),
    const WeekConfiguration(),
    const WorkWeekConfiguration(),
    const ThreeDayConfiguration(),
    const MonthConfiguration(),
  ];

  @override
  void initState() {
    super.initState();
    eventsController = widget.eventsController;
    calendarController = CalendarController<Event>();
  }

  @override
  void didUpdateWidget(covariant MobileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.eventsController != oldWidget.eventsController) {
      eventsController = widget.eventsController;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CalendarView<Event>(
      controller: calendarController,
      eventsController: eventsController,
      viewConfiguration: currentConfiguration,
      eventTileBuilder: _eventTileBuilder,
      multiDayEventTileBuilder: _multiDayEventTileBuilder,
      monthEventTileBuilder: _monthEventTileBuilder,
      components: CalendarComponents(
        calendarHeaderBuilder: _calendarHeader,
      ),
      eventHandlers: CalendarEventHandlers<Event>(
        onEventChanged: onEventChanged,
        onEventTapped: onEventTapped,
        onCreateEvent: onCreateEvent,
        onDateTapped: onDateTapped,
      ),
    );
  }

  /// This function is called when a new event is created.
  Future<CalendarEvent<Event>?> onCreateEvent(newEvent) async {
    newEvent.eventData = Event(
      title: 'New Event',
      color: Colors.blue,
    );

    // Show the new event dialog.
    CalendarEvent<Event>? event = await showDialog<CalendarEvent<Event>>(
      context: context,
      builder: (BuildContext context) {
        return NewEventDialog(
          dialogTitle: 'Create Event',
          event: newEvent,
        );
      },
    );

    // return the new event. (if the user cancels the dialog, null is returned)
    return event;
  }

  /// This function is called when an event is tapped.
  Future<void> onEventTapped(event) async {
    // Make a copy of the event to restore it if the user cancels the changes.
    CalendarEvent<Event> copyOfEvent = event.copyWith();

    // Show the edit dialog.
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return EventEditDialog(
          dialogTitle: 'Edit Event',
          event: event,
          deleteEvent: (event) => eventsController.removeEvent(event),
          cancelEdit: () => event.repalceWith(event: copyOfEvent),
        );
      },
    );
  }

  /// This function is called when an event is changed.
  Future<void> onEventChanged(initialDateTimeRange, event) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    // Show the snackbar and undo the changes if the user presses the undo button.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${event.eventData?.title} changed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            eventsController.updateEvent(
              newEventData: event.eventData,
              newDateTimeRange: initialDateTimeRange,
              test: (other) => other.eventData == event.eventData,
            );
          },
        ),
      ),
    );
  }

  /// This function is called when a date is tapped.
  void onDateTapped(date) {
    // If the current view is not the single day view, change the view to the single day view.
    if (currentConfiguration is! SingleDayViewConfiguration) {
      setState(() {
        // Set the selected date to the tapped date.
        calendarController.selectedDate = date;
        currentConfiguration = viewConfigurations.first;
      });
    }
  }

  Widget _calendarHeader(dateTimeRange) {
    return CalendarHeader(
      calendarController: calendarController,
      viewConfigurations: viewConfigurations,
      currentConfiguration: currentConfiguration,
      onViewConfigurationChanged: (viewConfiguration) {
        setState(() {
          currentConfiguration = viewConfiguration;
        });
      },
      dateTimeRange: dateTimeRange,
    );
  }

  Widget _multiDayEventTileBuilder(event, tileType, continuesBefore, continuesAfter) {
    return MultiDayEventTile(
      event: event,
      tileType: tileType,
      continuesBefore: continuesBefore,
      continuesAfter: continuesAfter,
    );
  }

  Widget _eventTileBuilder(event, tileType, drawOutline, continuesBefore, continuesAfter) {
    return EventTile(
      event: event,
      tileType: tileType,
      drawOutline: drawOutline,
      continuesBefore: continuesBefore,
      continuesAfter: continuesAfter,
    );
  }

  Widget _monthEventTileBuilder(event, tileType, date, continuesBefore, continuesAfter) {
    return MonthEventTile(
      event: event,
      tileType: tileType,
      date: date,
      continuesBefore: continuesBefore,
      continuesAfter: continuesAfter,
    );
  }
}
