#!/usr/bin/python

# Nicolas Seriot
# 2009-09-28
# http://github.com/nst/iCalTop

import sys
import datetime
import re
from optparse import OptionParser, OptionGroup
from Foundation import NSProcessInfo

class CalTop(object):
    
    def __init__(self, cal_name, field='title'):
    
        if field not in ['location', 'title']:
            raise Exception('Not a suitable field: %s' % field)
    
        self.cal_name = cal_name
        self.field = field
        
        self.store = CalCalendarStore.defaultCalendarStore()
        
        predicate = NSPredicate.predicateWithFormat_("title == \"%s\"" % self.cal_name)
        
        self.calendars = self.store.calendars().filteredArrayUsingPredicate_(predicate)

        if len(self.calendars) != 1:
            print "Error: %d calendars with title %s" % (len(self.calendars), self.cal_name)
            sys.exit(1)

    def print_digest(self, start_date, stop_date):
    
        predicate = CalCalendarStore.eventPredicateWithStartDate_endDate_calendars_(start_date, stop_date, self.calendars)
        
        events = self.store.eventsWithPredicate_(predicate)
        
        projects = {}
        
        for e in events:
            name = e.location() if self.field == 'location' else e.title()
            
            if not name in projects:
                projects[name] = 0.0
            
            projects[name] += e.endDate().timeIntervalSinceDate_(e.startDate())
        
        total = 0.0
        
        print "-" * 30
        print "From", start_date, "to", stop_date
        print "-" * 30
        
        for (p, s) in projects.iteritems():
            if not p:
                p = ''

            print p.ljust(20, ' '), "%0.2f" % (s / 3600.0)
            total += s
        
        print "-" * 30
        print "Total".ljust(20, ' '), "%0.2f" % (total / 3600.0)
        print "-" * 30

if __name__ == '__main__':

    os_version = NSProcessInfo.processInfo().operatingSystemVersionString()
    os_version = re.compile("Version (\d+\.\d+)\.\d+ .*").match(os_version).groups()[0]
    
    if float(os_version) < 10.6:
        print "icaltop needs Mac OS X 10.6 or later"
        sys.exit(1)
        
    from CalendarStore import *

    now = datetime.datetime.now()

    parser = OptionParser()

    parser.add_option("-c", help="Name of the calendar (mandatory)", dest="cal_name", metavar="NAME",)
    parser.add_option("-m", action="store", type="int", dest="month_start", metavar="MONTH",
                      help="Number of the month for which to report (default: current)")
    parser.add_option("-u", action="store", type="int", dest="month_stop", metavar="MONTH_NB",
                      help="Number of the month until which to report (default: month_start)")
    parser.add_option("-l", action="store_true", dest="use_location",
                      help="Look for projects in events locations (default: titles)")

    group = OptionGroup(parser, "Purpose", "Report the time spent on projects by reading iCal events.")
    parser.add_option_group(group)
                      
    group = OptionGroup(parser, "Example", "$ icaltop -c MyHours -m 9 -u 10 -l")
    parser.add_option_group(group)
    
    (options, args) = parser.parse_args()
    
    if not parser.values.cal_name:
        parser.print_help()
        sys.exit(1)
    
    if parser.values.month_start:
        month_start = options.month_start
    else:
        month_start = now.month
    
    month_stop = month_start
    
    if parser.values.month_stop:
        month_stop = parser.values.month_stop
    else:
        month_stop = month_start
    
    month_stop = (month_stop) % 12 + 1

    year_shift = 1 if (month_stop <= month_start) else 0
            
    start_date = datetime.date(year=now.year, month=month_start, day=1)
    stop_date = datetime.date(year=now.year+year_shift, month=month_stop, day=1) - datetime.timedelta(days=1)
    
    field = 'location' if parser.values.use_location else 'title'
    
    ct = CalTop(cal_name=parser.values.cal_name, field=field)
    ct.print_digest(start_date, stop_date)
        
    